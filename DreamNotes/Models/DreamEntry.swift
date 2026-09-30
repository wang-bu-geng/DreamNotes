import Foundation

struct DreamEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval       // 录音时长（秒）
    var rawTranscription: String?    // 语音转文字原始文本
    var aiStory: String?             // AI 梳理后的梦境故事
    var audioFileName: String?       // 录音文件名（本地存储）
    var createdAt: Date
    var editedRawText: String?       // 用户手动编辑后的原始文本
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval = 0,
        rawTranscription: String? = nil,
        aiStory: String? = nil,
        audioFileName: String? = nil,
        createdAt: Date = Date(),
        editedRawText: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.rawTranscription = rawTranscription
        self.aiStory = aiStory
        self.audioFileName = audioFileName
        self.createdAt = createdAt
        self.editedRawText = editedRawText
        self.isFavorite = isFavorite
    }

    /// 展示用的原始口述文本（优先取用户编辑版）
    var displayRawText: String {
        editedRawText ?? rawTranscription ?? "暂无口述记录"
    }

    /// 展示用的 AI 故事文本
    var displayAIStory: String {
        aiStory ?? "AI 整理中..."
    }
}
