import AppKit
import AVFoundation
import CoreImage
import ImageIO
import Vision

struct CameraChoice: Identifiable {
    let id: String
    let name: String
}

struct TrackingSample {
    let time: Double
    let image: CGImage?
    let box: CGRect?
    let yaw: Double?
    let pitch: Double?
    let count: Int
    let error: String?
}

final class CameraTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "local.lookout.camera", qos: .userInitiated)
    private let session = AVCaptureSession()
    private let context = CIContext(options: [.cacheIntermediates: false])
    private var lastFrame = 0.0
    private var rotation = 0
    private var generation = 0
    private var selection: CGRect?
    var onSample: ((TrackingSample) -> Void)?

    static func devices() -> [CameraChoice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
            mediaType: .video, position: .unspecified).devices.map { CameraChoice(id: $0.uniqueID, name: $0.localizedName) }
    }

    func start(cameraID: String, rotation: Int) {
        queue.async { [self] in
            generation += 1
            session.stopRunning()
            session.beginConfiguration()
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
            self.rotation = rotation
            selection = nil
            lastFrame = 0
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera], mediaType: .video, position: .unspecified).devices
            guard let device = devices.first(where: { $0.uniqueID == cameraID }) ?? (cameraID.isEmpty ? devices.first : nil) else {
                session.commitConfiguration()
                publishError("找不到所选摄像头，请重新选择。")
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input) else { throw CameraFailure.input }
                session.addInput(input)
                if session.canSetSessionPreset(.vga640x480) { session.sessionPreset = .vga640x480 }
                let output = AVCaptureVideoDataOutput()
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: queue)
                guard session.canAddOutput(output) else { throw CameraFailure.output }
                session.addOutput(output)
                session.commitConfiguration()
                session.startRunning()
                if !session.isRunning { publishError("摄像头未能启动，可能正被其他软件占用。") }
            } catch {
                session.commitConfiguration()
                publishError("摄像头启动失败：\(error.localizedDescription)")
            }
        }
    }

    func stop() {
        queue.async { [self] in
            generation += 1
            session.stopRunning()
            session.beginConfiguration()
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
            session.commitConfiguration()
        }
    }

    private func publishError(_ message: String) {
        onSample?(TrackingSample(time: ProcessInfo.processInfo.systemUptime, image: nil,
            box: nil, yaw: nil, pitch: nil, count: 0, error: message))
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastFrame >= 0.125 else { return }
        lastFrame = now
        autoreleasepool {
            guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let orientation: CGImagePropertyOrientation = rotation == 90 ? .right : rotation == 180 ? .down : rotation == 270 ? .left : .up
            let ci = CIImage(cvPixelBuffer: buffer).oriented(orientation)
            guard let image = context.createCGImage(ci, from: ci.extent) else { return }
            do {
                let request = VNDetectFaceRectanglesRequest()
                request.revision = VNDetectFaceRectanglesRequestRevision3
                try VNImageRequestHandler(cgImage: image).perform([request])
                let faces = (request.results ?? []).filter { $0.confidence >= 0.65 && $0.boundingBox.width >= 0.10 }
                let chosen: VNFaceObservation?
                if let previous = selection,
                   let nearest = faces.min(by: { distance($0.boundingBox, previous) < distance($1.boundingBox, previous) }),
                   distance(nearest.boundingBox, previous) < 0.22 {
                    chosen = nearest
                } else {
                    chosen = faces.max { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }
                }
                selection = chosen?.boundingBox
                onSample?(TrackingSample(time: now, image: image, box: chosen?.boundingBox,
                    yaw: chosen?.yaw.map { $0.doubleValue * 180 / .pi },
                    pitch: chosen?.pitch.map { $0.doubleValue * 180 / .pi }, count: faces.count, error: nil))
            } catch { publishError("人脸分析失败：\(error.localizedDescription)") }
        }
    }

    private func distance(_ a: CGRect, _ b: CGRect) -> Double {
        hypot(a.midX - b.midX, a.midY - b.midY)
    }
    private enum CameraFailure: Error { case input, output }
}
