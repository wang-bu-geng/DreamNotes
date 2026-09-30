import Foundation
import AVFoundation

enum RecordingState: Equatable {
    case idle
    case recording
    case paused
    case finished(URL)
    case failed(String)
}

@Observable
final class AudioRecorderService: NSObject {
    private(set) var state: RecordingState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var averagePower: Float = -60  // dB

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var audioFileName: String?

    // MARK: - 路径

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DreamRecordings", isDirectory: true)
    }

    // MARK: - 权限申请

    static func requestMicrophonePermission() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
        return granted
    }

    // MARK: - 开始录制

    func startRecording() {
        guard case .idle = state else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            state = .failed("音频会话启动失败: \(error.localizedDescription)")
            return
        }

        let fileName = "dream_\(UUID().uuidString.prefix(8))_\(Int(Date().timeIntervalSince1970)).m4a"
        audioFileName = fileName

        // 确保目录存在
        try? FileManager.default.createDirectory(at: documentsDirectory,
                                                  withIntermediateDirectories: true)

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64000
        ]

        do {
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true

            guard recorder?.record() == true else {
                state = .failed("录音启动失败")
                return
            }

            state = .recording
            currentTime = 0
            startMetering()

        } catch {
            state = .failed("录音器初始化失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 暂停/继续

    func pauseRecording() {
        guard case .recording = state else { return }
        recorder?.pause()
        state = .paused
        stopMetering()
    }

    func resumeRecording() {
        guard case .paused = state else { return }
        recorder?.record()
        state = .recording
        startMetering()
    }

    // MARK: - 结束录制

    func stopRecording() {
        recorder?.stop()
        stopMetering()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - 取消录制（不保存）

    func cancelRecording() {
        recorder?.stop()
        recorder?.deleteRecording()
        stopMetering()
        try? AVAudioSession.sharedInstance().setActive(false)

        if let fileName = audioFileName {
            let url = documentsDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
        }

        audioFileName = nil
        currentTime = 0
        state = .idle
    }

    // MARK: - 获取录音文件 URL

    func getRecordedFileURL() -> URL? {
        guard let fileName = audioFileName else { return nil }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    // MARK: - 计量

    private func startMetering() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder, recorder.isRecording else { return }
            recorder.updateMeters()
            self.currentTime = recorder.currentTime
            self.averagePower = recorder.averagePower(forChannel: 0)
        }
    }

    private func stopMetering() {
        timer?.invalidate()
        timer = nil
    }

    func cleanup() {
        stopMetering()
        recorder = nil
        state = .idle
        currentTime = 0
        averagePower = -60
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            state = .finished(recorder.url)
        } else {
            state = .failed("录音保存失败")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        state = .failed("录音编码错误: \(error?.localizedDescription ?? "未知")")
    }
}
