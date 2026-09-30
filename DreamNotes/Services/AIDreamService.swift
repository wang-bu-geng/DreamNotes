import Foundation

// MARK: - AI 服务配置
// ⚠️ 替换为你的 API Key（可选用 DeepSeek 官方或硅基流动）

enum AIConfig {
    /// API 地址（OpenAI 兼容格式）
    /// DeepSeek: https://api.deepseek.com/v1/chat/completions
    /// 硅基流动: https://api.siliconflow.cn/v1/chat/completions
    static let baseURL = "https://api.deepseek.com/v1/chat/completions"

    /// 你的 API Key
    static let apiKey = "YOUR_API_KEY"

    /// 模型名
    /// DeepSeek: deepseek-chat
    /// 硅基流动: deepseek-llm-67b-chat 或 Pro/deepseek-v3
    static let model = "deepseek-chat"
}

// MARK: - AI 梦境故事梳理服务

@Observable
final class AIDreamService {
    private(set) var isProcessing = false
    private(set) var statusMessage: String = ""

    /// 固定 Prompt（不可修改，来自产品文档）
    private let systemPrompt = """
    请将这段碎片化、逻辑跳跃、口语化的口述梦境，整理为一篇通顺、完整的短篇梦境小故事。
    硬性要求：
    1. 100%保留用户口述的所有人物、场景、细节、情绪、奇幻情节，禁止编造新增内容，禁止删减任何内容；
    2. 仅优化语序、衔接语句，保留梦境本身的错乱、虚幻、荒诞特质；
    3. 文风温柔有氛围感，贴合梦境专属质感，篇幅与原文匹配。
    """

    /// 将口述文本梳理为梦境小故事
    func processDream(rawText: String) async throws -> String {
        isProcessing = true
        statusMessage = "AI 正在梳理你的梦境..."

        defer {
            isProcessing = false
            statusMessage = ""
        }

        guard AIConfig.apiKey != "YOUR_API_KEY" else {
            throw AIError.notConfigured("请在 AIConfig 中填写你的 API Key")
        }

        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIError.invalidInput("口述文本为空")
        }

        statusMessage = "正在请求 AI..."

        // 构建请求
        let url = URL(string: AIConfig.baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        // 构建消息体
        let body: [String: Any] = [
            "model": AIConfig.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": rawText],
            ],
            "temperature": 0.7,
            "max_tokens": 4096,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("无效响应")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "无详情"
            throw AIError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        // 解析响应
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.parseError("响应格式错误")
        }

        if let errorObj = json["error"] as? [String: Any] {
            let msg = errorObj["message"] as? String ?? "未知错误"
            throw AIError.apiError(msg)
        }

        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty
        else {
            throw AIError.parseError("响应中未找到有效内容")
        }

        statusMessage = "梦境故事已生成！"
        return content
    }
}

// MARK: - 错误类型

enum AIError: LocalizedError {
    case notConfigured(String)
    case invalidInput(String)
    case networkError(String)
    case apiError(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let msg): return msg
        case .invalidInput(let msg): return msg
        case .networkError(let msg): return "网络错误: \(msg)"
        case .apiError(let msg): return "API 错误: \(msg)"
        case .parseError(let msg): return "解析错误: \(msg)"
        }
    }
}
