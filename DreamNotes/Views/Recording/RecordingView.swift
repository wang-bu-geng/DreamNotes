import SwiftUI

struct RecordingView: View {
    @State var appVM: AppViewModel
    @State private var recordingVM = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                // 标题
                Text("记录梦境")
                    .font(.title2.bold())
                    .padding(.top, 20)

                Spacer()

                switch recordingVM.phase {
                case .idle:
                    idleView

                case .recording:
                    recordingView

                case .transcribing:
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color(red: 0.6, green: 0.4, blue: 1.0))
                            .scaleEffect(1.5)
                        Text("正在转写语音...")
                            .foregroundStyle(.secondary)
                    }

                case .processingAI:
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Color(red: 0.6, green: 0.4, blue: 1.0))
                            .scaleEffect(1.5)
                        Text("AI 正在梳理你的梦境...")
                            .foregroundStyle(.secondary)
                        Text("保留原始口述，生成专属梦境故事")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                case .complete:
                    completeView

                case .failed(let error):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重新录制") {
                            recordingVM.restartRecording()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .interactiveDismissDisabled(recordingVM.phase != .idle && recordingVM.phase != .complete)
    }

    // MARK: - 空闲状态

    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

            Text("点击下方按钮开始录音")
                .foregroundStyle(.secondary)

            Button {
                Task { await recordingVM.startRecording() }
            } label: {
                Image(systemName: "record.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 录制中

    private var recordingView: some View {
        VStack(spacing: 24) {
            // 音频波形
            WaveformView(power: recordingVM.audioService.averagePower, isActive: recordingVM.phase == .recording)
                .frame(height: 120)

            // 计时
            Text(formatTime(recordingVM.audioService.currentTime))
                .font(.system(size: 48, design: .monospaced))
                .fontWeight(.light)
                .foregroundStyle(recordingVM.phase == .recording ? .white : .secondary)

            Text(recordingVM.phase == .recording ? "录音中..." : "已暂停")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 控制按钮
            HStack(spacing: 40) {
                // 删除
                Button {
                    recordingVM.cancelRecording()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)

                // 暂停/继续
                if recordingVM.phase == .recording {
                    Button {
                        recordingVM.audioService.pauseRecording()
                    } label: {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.3))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        recordingVM.audioService.resumeRecording()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                // 停止
                Button {
                    Task { await recordingVM.stopAndProcess() }
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 完成状态

    private var completeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)

                Text("梦境记录完成！")
                    .font(.title2.bold())

                // 原始口述
                if !recordingVM.rawText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundStyle(.secondary)
                            Text("原始口述")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        Text(recordingVM.rawText)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // AI 故事
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles.rectangle.stack")
                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        Text("梦境故事")
                            .font(.headline)
                    }
                    Text(recordingVM.aiStory)
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 操作按钮
                HStack(spacing: 16) {
                    Button("重新录制") {
                        recordingVM.restartRecording()
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)

                    Button("保存梦境") {
                        let entry = recordingVM.makeEntry()
                        appVM.addEntry(entry)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.6, green: 0.4, blue: 1.0))
                }
                .padding(.top, 8)
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - 波形视图

private struct WaveformView: View {
    let power: Float
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let count = 40
            let spacing: CGFloat = 4
            let barWidth = (geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count)

            HStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { i in
                    let normalized = max(0, CGFloat(power + 60) / 60)  // -60~0 dB → 0~1
                    let height = isActive ? max(3, normalized * geo.size.height * 0.8) : 3
                    let randomFactor = sin(Double(i) * 1.5 + Date().timeIntervalSince1970 * 4)
                    let finalHeight = isActive ? height * CGFloat(0.5 + randomFactor * 0.5) : height

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(isActive ? 0.7 : 0.3))
                        .frame(width: barWidth, height: max(3, CGFloat(finalHeight)))
                        .animation(.easeInOut(duration: 0.15), value: finalHeight)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}
