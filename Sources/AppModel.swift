import AppKit
import AVFoundation
import Combine

final class AppModel: ObservableObject {
    @Published var draft = ProtectionSettings()
    @Published private(set) var settings = ProtectionSettings()
    @Published private(set) var devices: [CameraChoice] = []
    @Published private(set) var image: CGImage?
    @Published private(set) var faceBox: CGRect?
    @Published private(set) var yaw: Double?
    @Published private(set) var pitch: Double?
    @Published private(set) var faceCount = 0
    @Published private(set) var status = "尚未启用"
    @Published private(set) var detail = "打开设置，校准正常坐姿后开始。"
    @Published private(set) var enabled = false
    @Published private(set) var covered = false
    @Published private(set) var editing = false
    @Published private(set) var calibrating = false
    @Published private(set) var calibrationMessage = "看着屏幕，保持自然坐姿。"
    @Published private(set) var permissionDenied = false
    @Published private(set) var cameraError: String?

    let tracker = CameraTracker()
    private let cover = ScreenCover()
    private var policy = AttentionPolicy()
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var distributedObservers: [NSObjectProtocol] = []
    private var latest: TrackingSample?
    private var requestTime = 0.0
    private var cameraWanted = false
    private var systemSuspended = false
    private var systemLocked = false
    private var calibrationStart = 0.0
    private var calibrationFrames: [(Double, Double?)] = []
    enum CalibrationAxis { case both, horizontal, vertical }
    private var calibrationAxis: CalibrationAxis = .both
    var closeSettings: (() -> Void)?

    init() {
        if let data = UserDefaults.standard.data(forKey: "settings.v1"),
           let saved = try? JSONDecoder().decode(ProtectionSettings.self, from: data) {
            settings = saved
        }
        draft = settings
        tracker.onSample = { [weak self] sample in
            DispatchQueue.main.async { self?.receive(sample) }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in self?.tick() }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.systemSuspended = true; self?.suspendCamera()
        })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }; self.systemSuspended = false; self.ensureCamera()
        })
        let dc = DistributedNotificationCenter.default()
        distributedObservers.append(dc.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            self?.systemLocked = true; self?.suspendCamera()
        })
        distributedObservers.append(dc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }; self.systemLocked = false; self.ensureCamera()
        })
    }

    func beginEditing() {
        draft = settings
        editing = true
        refreshDevices()
        setCover(false)
        ensureCamera()
    }

    func endEditing() {
        guard editing else { return }
        editing = false
        calibrating = false
        policy.reset()
        if enabled {
            setCover(true)
            restartCamera()
        } else { stopCamera(); status = "已暂停"; detail = "摄像头已释放。" }
    }

    func applyAndStart() {
        guard draft.calibrated else { calibrationMessage = "请先校准或手动设定正常方向。"; return }
        settings = draft
        if let data = try? JSONEncoder().encode(settings) { UserDefaults.standard.set(data, forKey: "settings.v1") }
        enabled = true
        endEditing()
        closeSettings?()
    }

    func toggleProtection() {
        if enabled { pause() }
        else if settings.calibrated {
            enabled = true
            policy.reset()
            if !editing { setCover(true) }
            ensureCamera()
        }
    }

    func pause() {
        enabled = false
        setCover(false)
        policy.reset()
        status = "已暂停"
        detail = editing ? "设置预览中，屏幕保持清晰。" : "摄像头已释放。"
        if !editing { stopCamera() }
    }

    func refreshDevices() { devices = CameraTracker.devices() }

    func cameraDraftChanged() {
        draft.calibrated = false
        calibrationMessage = "摄像头或画面方向已改变，请重新校准。"
        calibrating = false
        restartCamera()
    }

    func setManualBaseline(_ value: Double) {
        draft.baselineYaw = value
        draft.calibrated = true
        calibrationMessage = "正常方向已手动设定，应用后生效。"
    }

    func setManualPitch(_ value: Double) {
        draft.baselinePitch = min(90, max(-90, value))
        calibrationMessage = "垂直基准已手动设定，应用后生效。"
    }

    func calibrate(_ axis: CalibrationAxis = .both) {
        guard editing, let latest, latest.error == nil, latest.yaw != nil, latest.count == 1,
              ProcessInfo.processInfo.systemUptime - latest.time < 0.7 else {
            calibrationMessage = "请确保画面中只有你一人，且能够检测到朝向。"
            return
        }
        calibrationFrames = []
        calibrationAxis = axis
        calibrationStart = ProcessInfo.processInfo.systemUptime
        calibrating = true
        calibrationMessage = "正在采样，请看着屏幕并保持约 1 秒…"
    }

    private func receive(_ sample: TrackingSample) {
        guard cameraWanted, sample.time >= requestTime else { return }
        latest = sample
        image = sample.image
        faceBox = sample.box
        yaw = sample.yaw
        pitch = sample.pitch
        faceCount = sample.count
        cameraError = sample.error
        if calibrating {
            guard sample.count == 1, let yaw = sample.yaw, sample.error == nil else {
                calibrating = false
                calibrationMessage = "采样中断：请保持一张清楚的人脸，再试一次。"
                return
            }
            calibrationFrames.append((yaw, sample.pitch))
            if sample.time - calibrationStart >= 1.1 && calibrationFrames.count >= 7 {
                let values = calibrationFrames.map { $0.0 }
                let pitches = calibrationFrames.compactMap { $0.1 }
                if calibrationAxis != .horizontal && pitches.count != calibrationFrames.count {
                    calibrating = false
                    calibrationMessage = "暂时无法稳定读取垂直角度，请露出面部后重试。"
                    return
                }
                let stableYaw = values.max()! - values.min()! < 15
                let stablePitch = pitches.isEmpty || pitches.max()! - pitches.min()! < 15
                guard (calibrationAxis == .vertical || stableYaw) && (calibrationAxis == .horizontal || stablePitch) else {
                    calibrating = false; calibrationMessage = "刚才头部移动较大，请保持自然坐姿重新校准。"; return
                }
                if calibrationAxis != .vertical {
                    draft.baselineYaw = values.reduce(0, +) / Double(values.count)
                    draft.calibrated = true
                }
                if calibrationAxis != .horizontal {
                    draft.baselinePitch = pitches.reduce(0, +) / Double(pitches.count)
                }
                calibrating = false
                calibrationMessage = String(format: "已校准：水平 %+.0f°，垂直 %+.0f°。可用转轮继续微调。", draft.baselineYaw, draft.baselinePitch)
            }
        }
        evaluate(at: ProcessInfo.processInfo.systemUptime)
    }

    private func tick() {
        if calibrating && ProcessInfo.processInfo.systemUptime - calibrationStart > 4 {
            calibrating = false; calibrationMessage = "校准超时，请检查摄像头后重试。"
        }
        guard cameraWanted else { return }
        evaluate(at: ProcessInfo.processInfo.systemUptime)
    }

    private func evaluate(at now: Double) {
        guard !systemLocked, !systemSuspended else { return }
        let fresh = latest.map { now - $0.time < 1.5 && $0.error == nil } ?? false
        if editing {
            status = "设置预览"
            detail = fresh ? "调整时不会遮挡屏幕；应用后开始保护。" : cameraError ?? "等待摄像头画面…"
            setCover(false)
            return
        }
        guard enabled else { return }
        let input: AttentionInput
        if !fresh {
            input = .unavailable; status = "摄像头不可用"; detail = cameraError ?? "画面中断，已保持遮挡。"
        } else if let yaw = latest?.yaw {
            input = .face(yaw: yaw, pitch: latest?.pitch)
            status = "正在检测"
            detail = "根据相对正常坐姿的角度判断。"
        } else {
            input = .missing; status = "未检测到朝向"; detail = "等待人脸或朝向恢复。"
        }
        setCover(policy.update(input, at: now, settings: settings))
        if fresh {
            status = covered ? "屏幕已遮挡" : "正在保护 · 清晰"
            if (latest?.count ?? 0) > 1 { detail = "检测到多人；此版本不验证身份。" }
        }
        if covered && !cover.blurAvailable { detail = "背景模糊不可用，已使用不透明遮挡。" }
    }

    private func setCover(_ value: Bool) {
        if covered != value { covered = value }
        cover.setCovered(value, settings: settings)
    }

    private func restartCamera() {
        stopCamera()
        ensureCamera()
    }

    private func ensureCamera() {
        guard (editing || enabled), !cameraWanted, !systemLocked, !systemSuspended else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionDenied = false
            cameraWanted = true
            requestTime = ProcessInfo.processInfo.systemUptime
            latest = nil
            cameraError = nil
            let config = editing ? draft : settings
            tracker.start(cameraID: config.cameraID, rotation: config.rotation)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
                DispatchQueue.main.async { self?.ensureCamera() }
            }
        default:
            permissionDenied = true
            status = "需要摄像头权限"
            detail = "请在系统设置 → 隐私与安全性 → 摄像头中允许 Lookout。"
            if enabled && !editing { setCover(true) }
        }
    }

    private func stopCamera() {
        cameraWanted = false
        tracker.stop()
        latest = nil
        image = nil
        faceBox = nil
        yaw = nil
        pitch = nil
        faceCount = 0
    }

    private func suspendCamera() {
        calibrating = false
        stopCamera()
        setCover(false)
        policy.reset()
    }

    func shutdown() { pause(); stopCamera() }
}
