import Foundation

struct UserSettings: Codable {
    var wakeUpStartHour: Int
    var wakeUpStartMinute: Int
    var wakeUpEndHour: Int
    var wakeUpEndMinute: Int
    var isAutoWakeEnabled: Bool
    var hasCompletedOnboarding: Bool
    var privacyAccepted: Bool

    static let `default` = UserSettings(
        wakeUpStartHour: 7,
        wakeUpStartMinute: 0,
        wakeUpEndHour: 10,
        wakeUpEndMinute: 0,
        isAutoWakeEnabled: true,
        hasCompletedOnboarding: false,
        privacyAccepted: false
    )

    /// 当前时间是否在晨间唤醒时段内
    func isInWakeUpWindow(now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.hour, .minute], from: now)
        guard let hour = comp.hour, let minute = comp.minute else { return false }

        let nowMin = hour * 60 + minute
        let startMin = wakeUpStartHour * 60 + wakeUpStartMinute
        let endMin = wakeUpEndHour * 60 + wakeUpEndMinute

        if startMin <= endMin {
            return nowMin >= startMin && nowMin < endMin
        } else {
            // 跨天（如 22:00 - 02:00）
            return nowMin >= startMin || nowMin < endMin
        }
    }

    var wakeUpStartFormatted: String {
        String(format: "%02d:%02d", wakeUpStartHour, wakeUpStartMinute)
    }

    var wakeUpEndFormatted: String {
        String(format: "%02d:%02d", wakeUpEndHour, wakeUpEndMinute)
    }
}
