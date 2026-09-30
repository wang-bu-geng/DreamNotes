import Foundation
import SwiftUI

@Observable
final class RecordingViewModel {
    enum RecordingPhase: Equatable {
        case idle
        case recording
        case transcribing
        case processingAI
        case complete
        case failed(String)
    }

    var phase: RecordingPhase = .idle
    var rawText: String = ""
    var aiStory: String = ""
    var audioDuration: TimeInterval = 0

    let audioService = AudioRecorderService()
    let sttService = SpeechToTextService()
    let aiService = AIDreamService()

    /// 开始录音
    func startRecording() async {
        let granted = await AudioRecorderService.requestMicrophonePermission()
        guard granted else {
            phase = .failed("需要麦克风权限才能录梦")
            return
        }

        phase = .recording
        audioService.startRecording()
    }

    /// 停止录音 → 自动转写 → AI 梳理
    func stopAndProcess() async {
        audioService.stopRecording()
        audioDuration = audioService.currentTime

        phase = .transcribing

        guard let audioURL = audioService.getRecordedFileURL() else {
            phase = .failed("录音文件获取失败")
            return
        }

        // 转写
        do {
            rawText = try await sttService.transcribe(audioURL: audioURL)
        } catch {
            phase = .failed("语音转写失败: \(error.localizedDescription)")
            return
        }

        // AI 梳理
        phase = .processingAI
        do {
            aiStory = try await aiService.processDream(rawText: rawText)
        } catch {
            // 即使 AI 失败，也保留转写文本
            aiStory = "AI 梳理暂时不可用，请稍后再试。\n\n原始口述：\n\(rawText)"
        }

        phase = .complete
    }

    /// 重新录制
    func restartRecording() {
        audioService.cleanup()
        phase = .idle
        rawText = ""
        aiStory = ""
        audioDuration = 0
    }

    /// 取消
    func cancelRecording() {
        if case .recording = phase {
            audioService.cancelRecording()
        }
        audioService.cleanup()
        phase = .idle
        rawText = ""
        aiStory = ""
        audioDuration = 0
    }

    func makeEntry() -> DreamEntry {
        DreamEntry(
            duration: audioDuration,
            rawTranscription: rawText.isEmpty ? nil : rawText,
            aiStory: aiStory,
            audioFileName: audioService.getRecordedFileURL()?.lastPathComponent
        )
    }
}
