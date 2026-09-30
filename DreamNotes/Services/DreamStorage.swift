import Foundation

/// 本地持久化助手
actor DreamStorage {
    private let defaults = UserDefaults.standard

    // MARK: - User Settings

    func saveSettings(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: "userSettings")
        }
    }

    func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: "userSettings"),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    // MARK: - Dream Entries

    func saveEntries(_ entries: [DreamEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: "dreamEntries")
        }
    }

    func loadEntries() -> [DreamEntry] {
        guard let data = defaults.data(forKey: "dreamEntries"),
              let entries = try? JSONDecoder().decode([DreamEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    // MARK: - Storage Info

    func totalStorageSize() -> String {
        let recordingDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DreamRecordings", isDirectory: true)

        guard let enumerator = FileManager.default.enumerator(
            at: recordingDir,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return "0 MB" }

        var totalBytes: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = attrs.fileSize {
                totalBytes += Int64(size)
            }
        }

        let mb = Double(totalBytes) / 1_048_576.0
        if mb < 1 {
            return String(format: "%.0f KB", Double(totalBytes) / 1024.0)
        }
        return String(format: "%.1f MB", mb)
    }
}
