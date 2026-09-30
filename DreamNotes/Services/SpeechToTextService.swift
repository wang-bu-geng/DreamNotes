import Foundation
import AVFoundation
import CryptoKit

// MARK: - 讯飞开放平台配置
// 需要你在 https://www.xfyun.cn 注册账号 → 创建应用 → 开通"语音听写"服务

enum IFlyTekConfig {
    // ⚠️ 替换为你的真实值
    static let appId = "YOUR_CREDENTIAL"
    static let apiKey = "YOUR_CREDENTIAL"
    static let apiSecret = "YOUR_CREDENTIAL"

    // REST API 地址（短语音听写，≤60秒）
    static let iatURL = "https://api.xfyun.cn/v1/service/v1/iat"
}

// MARK: - 语音转文字服务

@Observable
final class SpeechToTextService {
    private(set) var isTranscribing = false
    private(set) var progress: String = ""

    /// 转写录音文件（M4A → WAV 16kHz → 讯飞听写 API）
    func transcribe(audioURL: URL) async throws -> String {
        isTranscribing = true
        progress = "转换音频格式..."

        defer {
            isTranscribing = false
            progress = ""
        }

        // 1. 将 M4A 转为 WAV (PCM 16kHz, 16bit, mono)
        let wavURL = try await convertToWAV(source: audioURL)

        progress = "上传音频到讯飞..."

        // 2. 读取 WAV 数据
        let audioData = try Data(contentsOf: wavURL)

        // 3. 调用讯飞听写 API
        let text = try await callIFlyTek(audioData: audioData)

        // 4. 清理临时 WAV 文件
        try? FileManager.default.removeItem(at: wavURL)

        progress = "转写完成"
        return text
    }

    // MARK: - 音频格式转换 (M4A AAC → WAV PCM 16kHz/16bit/mono)

    private func convertToWAV(source: URL) async throws -> URL {
        let asset = AVAsset(url: source)

        guard let reader = try? AVAssetReader(asset: asset) else {
            throw STTError.conversionFailed("无法读取音频文件")
        }

        // 输出设置：Linear PCM, 16kHz, 16-bit, mono
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]

        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            throw STTError.conversionFailed("没有找到音频轨道")
        }

        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(output)
        reader.startReading()

        // 收集 PCM 数据
        var pcmData = Data()
        while let sampleBuffer = output.copyNextSampleBuffer() {
            if let blockBuffer = sampleBuffer.dataBuffer {
                let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                    var length: Int = 0
                    var dataPointer: UnsafeMutablePointer<CChar>?
                    let status = CMBlockBufferGetDataPointer(blockBuffer,
                                                              atOffset: 0,
                                                              lengthAtOffsetOut: nil,
                                                              totalLengthOut: &length,
                                                              dataPointerOut: &dataPointer)
                    if status == kCMBlockBufferNoErr, let ptr = dataPointer {
                        continuation.resume(returning: Data(bytes: ptr, count: length))
                    } else {
                        continuation.resume(throwing: STTError.conversionFailed("读取 PCM 数据失败"))
                    }
                }
                pcmData.append(data)
            }
        }

        guard reader.status == .completed || reader.status == .reading else {
            throw STTError.conversionFailed("音频读取未完成")
        }

        // 写入 WAV 文件
        let wavURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).wav")
        try writeWAV(data: pcmData, to: wavURL, sampleRate: 16000, channels: 1, bitsPerSample: 16)

        return wavURL
    }

    private func writeWAV(data: Data, to url: URL, sampleRate: Int, channels: Int, bitsPerSample: Int) throws {
        let byteRate = sampleRate * channels * (bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)
        let dataSize = data.count
        let fileSize = 36 + dataSize

        var wav = Data()

        // RIFF header
        wav.append(contentsOf: "RIFF".utf8)
        withUnsafeBytes(of: Int32(fileSize).littleEndian) { wav.append(contentsOf: $0) }
        wav.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        wav.append(contentsOf: "fmt ".utf8)
        withUnsafeBytes(of: Int32(16).littleEndian) { wav.append(contentsOf: $0) }       // chunk size
        withUnsafeBytes(of: Int16(1).littleEndian) { wav.append(contentsOf: $0) }         // PCM format
        withUnsafeBytes(of: Int16(channels).littleEndian) { wav.append(contentsOf: $0) }  // channels
        withUnsafeBytes(of: Int32(sampleRate).littleEndian) { wav.append(contentsOf: $0) } // sample rate
        withUnsafeBytes(of: Int32(byteRate).littleEndian) { wav.append(contentsOf: $0) }  // byte rate
        withUnsafeBytes(of: Int16(blockAlign).littleEndian) { wav.append(contentsOf: $0) } // block align
        withUnsafeBytes(of: Int16(bitsPerSample).littleEndian) { wav.append(contentsOf: $0) } // bits per sample

        // data chunk
        wav.append(contentsOf: "data".utf8)
        withUnsafeBytes(of: Int32(dataSize).littleEndian) { wav.append(contentsOf: $0) }
        wav.append(data)

        try wav.write(to: url)
    }

    // MARK: - 讯飞 REST API 调用

    private func callIFlyTek(audioData: Data) async throws -> String {
        let appId = IFlyTekConfig.appId
        guard appId != "YOUR_APPID" else {
            throw STTError.notConfigured("请在 IFlyTekConfig 中填写讯飞 APPID / APIKey / APISecret")
        }

        let curTime = "\(Int(Date().timeIntervalSince1970))"

        // X-Param: base64({"engine_type":"sms16k","aue":"raw"})
        let paramJSON = #"{"engine_type":"sms16k","aue":"raw"}"#
        let paramBase64 = paramJSON.data(using: .utf8)!.base64EncodedString()

        // Body MD5 (binary, then base64)
        let bodyMD5 = md5(audioData)

        // X-CheckSum: MD5(appId + curTime + paramBase64 + bodyMD5)
        let checkSumSource = appId + curTime + paramBase64 + bodyMD5
        let checkSum = md5(checkSumSource.data(using: .utf8)!)

        // 构造请求
        var request = URLRequest(url: URL(string: IFlyTekConfig.iatURL)!)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "X-Appid")
        request.setValue(curTime, forHTTPHeaderField: "X-CurTime")
        request.setValue(paramBase64, forHTTPHeaderField: "X-Param")
        request.setValue(checkSum, forHTTPHeaderField: "X-CheckSum")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw STTError.apiError("无效响应")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw STTError.apiError("响应格式错误")
        }

        let code = json["code"] as? String ?? "-1"
        let desc = json["desc"] as? String ?? ""

        guard code == "0" else {
            throw STTError.apiError("讯飞 API 错误 [\(code)]: \(desc)")
        }

        guard let resultData = json["data"] as? String else {
            throw STTError.apiError("响应中缺少 data 字段")
        }

        return resultData
    }

    // MARK: - MD5 辅助

    private func md5(_ data: Data) -> String {
        let hashed = Insecure.MD5.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - 错误类型

enum STTError: LocalizedError {
    case notConfigured(String)
    case conversionFailed(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let msg): return msg
        case .conversionFailed(let msg): return "音频转换失败: \(msg)"
        case .apiError(let msg): return "讯飞 API 错误: \(msg)"
        }
    }
}
