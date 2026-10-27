import SwiftUI
import AppKit

private let accent = Color(red: 0.22, green: 0.47, blue: 0.95)

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "eye.circle.fill").font(.system(size: 38)).foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lookout").font(.system(size: 23, weight: .semibold, design: .rounded))
                    Text("看向屏幕，内容自然清晰。").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Label("本机处理 · 不保存画面", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary)
            }.padding(.horizontal, 26).padding(.top, 20).padding(.bottom, 17)
            Divider()
            ScrollView {
                HStack(alignment: .top, spacing: 22) {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionTitle("摄像头", subtitle: "允许侧放，先确认画面方向正确。")
                        cameraPreview
                        Picker("设备", selection: $model.draft.cameraID) {
                            Text("系统默认摄像头").tag("")
                            ForEach(model.devices) { Text($0.name).tag($0.id) }
                            if !model.draft.cameraID.isEmpty && !model.devices.contains(where: { $0.id == model.draft.cameraID }) {
                                Text("所选摄像头（未连接）").tag(model.draft.cameraID)
                            }
                        }.onChange(of: model.draft.cameraID) { _, _ in model.cameraDraftChanged() }
                        Picker("画面旋转", selection: $model.draft.rotation) {
                            Text("0°").tag(0); Text("90°").tag(90)
                            Text("180°").tag(180); Text("270°").tag(270)
                        }.pickerStyle(.segmented)
                            .onChange(of: model.draft.rotation) { _, _ in model.cameraDraftChanged() }
                        HStack {
                            Text("画面为镜像预览").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button("重新连接", systemImage: "arrow.clockwise") {
                                model.refreshDevices(); model.cameraDraftChanged()
                            }.font(.caption)
                        }
                        HStack(spacing: 8) {
                            readout("水平角", value: model.yaw)
                            readout("垂直角", value: model.pitch)
                            readout("相对偏转", value: model.yaw.map { AttentionPolicy.difference($0, model.draft.baselineYaw) })
                        }
                        Label("此版本检测人脸与朝向，不识别身份。其他人也可能解除遮挡。", systemImage: "person.crop.circle.badge.questionmark")
                            .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        Label("摄像头长期启用时，系统摄像头指示灯会亮起。", systemImage: "video")
                            .font(.caption).foregroundStyle(.secondary)
                    }.frame(width: 350)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            sectionTitle("正常朝向", subtitle: "两个方向独立校准，也可拖动转轮微调。")
                            Spacer(minLength: 4)
                            Button("同时校准", systemImage: "scope") { model.calibrate() }
                                .disabled(model.calibrating)
                        }
                        HStack(alignment: .top, spacing: 12) {
                            directionCard(vertical: false)
                            directionCard(vertical: true)
                        }
                        Text("蓝色：正常方向　绿色：实时朝向　浅蓝：允许范围")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(model.calibrationMessage).font(.caption).foregroundStyle(model.draft.calibrated ? .secondary : Color.orange)
                            .frame(minHeight: 30, alignment: .topLeading)
                        Divider()
                        DisclosureGroup("触发延迟与遮挡效果") {
                            VStack(spacing: 12) {
                                sliderRow("转头后", value: $model.draft.awayDelay, range: 0.2...3, suffix: "s", decimals: 1)
                                sliderRow("无人时", value: $model.draft.missingDelay, range: 0.3...5, suffix: "s", decimals: 1)
                                sliderRow("回正后", value: $model.draft.returnDelay, range: 0.15...1, suffix: "s", decimals: 2)
                                sliderRow("模糊强度", value: $model.draft.blurRadius, range: 24...100, suffix: "")
                                sliderRow("压暗", value: $model.draft.dimming, range: 0.08...0.8, suffix: "", decimals: 2)
                                Text("背景模糊使用私有系统接口；不可用时自动改为不透明遮挡。").font(.caption).foregroundStyle(.secondary)
                            }.padding(.top, 12)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(26)
            }
            Divider()
            HStack(spacing: 12) {
                Circle().fill(model.image == nil ? Color.orange : Color.green).frame(width: 7, height: 7)
                VStack(alignment: .leading, spacing: 2) {
                    Text("设置预览 · 屏幕保持清晰").font(.system(size: 12, weight: .medium))
                    Text(model.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Button("暂停保护") { model.pause() }.disabled(!model.enabled)
                Button("应用并开始保护") { model.applyAndStart() }
                    .buttonStyle(.borderedProminent).tint(accent)
                    .disabled(!model.draft.calibrated || model.image == nil || model.calibrating)
            }.padding(.horizontal, 26).padding(.vertical, 15)
        }
        .frame(minWidth: 860, minHeight: 680)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func directionCard(vertical: Bool) -> some View {
        let baseline = vertical
            ? Binding(get: { model.draft.baselinePitch }, set: { model.setManualPitch($0) })
            : Binding(get: { model.draft.baselineYaw }, set: { model.setManualBaseline(min(90, max(-90, $0))) })
        let live = vertical ? model.pitch : model.yaw
        let relative = live.map { AttentionPolicy.difference($0, baseline.wrappedValue) }
        return VStack(alignment: .leading, spacing: 12) {
            Label(vertical ? "垂直方向" : "水平方向", systemImage: vertical ? "arrow.up.and.down" : "arrow.left.and.right")
                .font(.system(size: 14, weight: .semibold))
            Text(vertical ? "侧视 · 抬头 / 低头" : "俯视 · 向左 / 向右")
                .font(.caption).foregroundStyle(.secondary)
            AngleDial(value: baseline, live: live,
                      left: vertical ? model.draft.upLimit : model.draft.leftLimit,
                      right: vertical ? model.draft.downLimit : model.draft.rightLimit,
                      vertical: vertical)
                .frame(width: 150, height: 150).frame(maxWidth: .infinity)
            HStack(spacing: 5) {
                Text("基准").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                TextField("基准角度", value: baseline, format: .number.precision(.fractionLength(0)))
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.trailing).frame(width: 74)
                Text("°").font(.title3).foregroundStyle(.secondary)
            }
            HStack {
                Text("相对偏转").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(relative.map { String(format: "%+.0f°", $0) } ?? "—")
                    .font(.system(.callout, design: .monospaced))
            }
            Button(vertical ? "校准垂直方向" : "校准水平方向", systemImage: "scope") {
                model.calibrate(vertical ? .vertical : .horizontal)
            }.disabled(model.calibrating).frame(maxWidth: .infinity)
            Divider()
            Text("允许偏转").font(.caption).foregroundStyle(.secondary)
            sliderRow(vertical ? "抬头" : "左侧",
                      value: vertical ? $model.draft.upLimit : $model.draft.leftLimit,
                      range: 10...(vertical ? 60 : 70), suffix: "°", compact: true)
            sliderRow(vertical ? "低头" : "右侧",
                      value: vertical ? $model.draft.downLimit : $model.draft.rightLimit,
                      range: 10...(vertical ? 60 : 70), suffix: "°", compact: true)
            if vertical {
                Toggle("启用垂直保护", isOn: $model.draft.pitchEnabled).font(.caption)
                Text(model.draft.pitchEnabled ? "抬头或低头超限时触发。" : "当前仅预览，不触发保护。")
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                Label("水平保护始终启用", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.secondary)
                Text("以正常坐姿为判断基准。")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(14).frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
    }

    private var cameraPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.92))
            if let image = model.image {
                Image(decorative: image, scale: 1).resizable().scaledToFit()
                    .scaleEffect(x: -1, y: 1)
                GeometryReader { geometry in
                    if let box = model.faceBox {
                        let scale = min(geometry.size.width / CGFloat(image.width), geometry.size.height / CGFloat(image.height))
                        let width = CGFloat(image.width) * scale
                        let height = CGFloat(image.height) * scale
                        RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.85), lineWidth: 2)
                            .frame(width: box.width * width, height: box.height * height)
                            .position(x: (geometry.size.width - width) / 2 + (1 - box.midX) * width,
                                      y: (geometry.size.height - height) / 2 + (1 - box.midY) * height)
                    }
                }
                VStack { Spacer(); HStack {
                    Label("\(model.faceCount) 张人脸", systemImage: "person.crop.rectangle")
                        .font(.caption).padding(7).background(.black.opacity(0.5), in: Capsule())
                    Spacer()
                }.foregroundStyle(.white).padding(12) }
            } else {
                VStack(spacing: 14) {
                    Image(systemName: model.permissionDenied ? "video.slash" : "video").font(.system(size: 30))
                    Text(model.permissionDenied ? "需要摄像头权限" : model.cameraError ?? "正在连接摄像头…")
                        .font(.callout).multilineTextAlignment(.center)
                    if model.permissionDenied {
                        Button("打开系统设置") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
                        }
                    }
                }.foregroundStyle(.white.opacity(0.8)).padding()
            }
        }.frame(height: 263).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 16, weight: .semibold))
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func readout(_ label: String, value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value.map { String(format: "%+.0f°", $0) } ?? "—")
                .font(.system(size: 20, weight: .medium, design: .rounded)).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String, decimals: Int = 0, compact: Bool = false) -> some View {
        HStack(spacing: compact ? 6 : 10) {
            Text(title).font(.callout).frame(width: compact ? 28 : 60, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: "%.*f%@", decimals, value.wrappedValue, suffix))
                .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary).frame(width: compact ? 31 : 48, alignment: .trailing)
        }
    }
}

struct AngleDial: View {
    @Binding var value: Double
    var live: Double?
    var left: Double
    var right: Double
    var vertical = false
    private var zeroDirection: Double { vertical ? 0 : -90 }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size * 0.41
            Canvas { context, _ in
                let circle = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.stroke(Path(ellipseIn: circle), with: .color(.secondary.opacity(0.15)), lineWidth: 13)
                var allowed = Path()
                allowed.addArc(center: center, radius: radius, startAngle: .degrees(value - left + zeroDirection), endAngle: .degrees(value + right + zeroDirection), clockwise: false)
                context.stroke(allowed, with: .color(accent.opacity(0.22)), style: StrokeStyle(lineWidth: 13, lineCap: .round))
                for angle in stride(from: -180.0, through: 170.0, by: 10) {
                    let a = (angle + zeroDirection) * .pi / 180
                    let outer = radius + (Int(angle) % 30 == 0 ? 12 : 9)
                    var tick = Path()
                    tick.move(to: CGPoint(x: center.x + cos(a) * (radius + 5), y: center.y + sin(a) * (radius + 5)))
                    tick.addLine(to: CGPoint(x: center.x + cos(a) * outer, y: center.y + sin(a) * outer))
                    context.stroke(tick, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                }
                func pointer(_ angle: Double, color: Color, width: CGFloat, length: Double) {
                    let a = (angle + zeroDirection) * .pi / 180
                    var line = Path()
                    line.move(to: center)
                    line.addLine(to: CGPoint(x: center.x + cos(a) * radius * length, y: center.y + sin(a) * radius * length))
                    context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
                }
                if let live { pointer(live, color: .green, width: 2.5, length: 0.78) }
                pointer(value, color: accent, width: 4, length: 1)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)), with: .color(accent))
            }
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let dx = gesture.location.x - center.x
                let dy = gesture.location.y - center.y
                guard hypot(dx, dy) > 15 else { return }
                var angle = atan2(Double(dy), Double(dx)) * 180 / Double.pi - zeroDirection
                if angle > 180 { angle -= 360 }
                value = min(90, max(-90, angle)).rounded()
            })
            .accessibilityElement().accessibilityLabel(vertical ? "垂直方向转轮" : "水平方向转轮")
            .accessibilityValue("\(Int(value)) 度")
            .accessibilityAdjustableAction { direction in
                if direction == .increment { value = min(90, value + 1) }
                else if direction == .decrement { value = max(-90, value - 1) }
            }
        }
    }
}
