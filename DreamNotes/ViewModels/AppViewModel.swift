import Foundation
import SwiftUI

@Observable
final class AppViewModel {
    var settings: UserSettings
    var entries: [DreamEntry]
    var showOnboarding: Bool
    var showRecordingSheet = false
    var showMorningPrompt = false

    private let storage = DreamStorage()

    init() {
        self.settings = .default
        self.entries = []
        self.showOnboarding = true
        loadAll()
    }

    // MARK: - 加载

    func loadAll() {
        settings = storageLoadSettings()
        entries = storageLoadEntries()
        showOnboarding = !settings.hasCompletedOnboarding || !settings.privacyAccepted
    }

    // MARK: - Settings

    func saveSettings(_ newSettings: UserSettings) {
        settings = newSettings
        Task { await storage.saveSettings(newSettings) }
    }

    func completeOnboarding() {
        var s = settings
        s.hasCompletedOnboarding = true
        s.privacyAccepted = true
        saveSettings(s)
        showOnboarding = false
    }

    // MARK: - Entries

    func addEntry(_ entry: DreamEntry) {
        entries.insert(entry, at: 0)
        Task { await storage.saveEntries(entries) }
    }

    func updateEntry(_ entry: DreamEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
            Task { await storage.saveEntries(entries) }
        }
    }

    func deleteEntry(_ entry: DreamEntry) {
        entries.removeAll { $0.id == entry.id }
        Task { await storage.saveEntries(entries) }
        // 同时删除录音文件
        if let fileName = entry.audioFileName {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("DreamRecordings/\(fileName)")
            try? FileManager.default.removeItem(at: url)
        }
    }

    func deleteAllEntries() {
        // 删除所有录音文件
        for entry in entries {
            if let fileName = entry.audioFileName {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("DreamRecordings/\(fileName)")
                try? FileManager.default.removeItem(at: url)
            }
        }
        entries.removeAll()
        Task { await storage.saveEntries([]) }
    }

    // MARK: - 早晨检查

    func checkMorningPrompt() {
        showMorningPrompt = settings.isAutoWakeEnabled &&
                            settings.isInWakeUpWindow() &&
                            !hasEntryForToday()
    }

    func dismissMorningPrompt() {
        showMorningPrompt = false
    }

    private func hasEntryForToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
    }

    func entriesForDate(_ date: Date) -> [DreamEntry] {
        entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - 存储空间

    func getStorageSize() async -> String {
        await storage.totalStorageSize()
    }

    // MARK: - Actor bridge

    private func storageLoadSettings() -> UserSettings {
        let semaphore = DispatchSemaphore(value: 0)
        var result = UserSettings.default
        Task {
            result = await storage.loadSettings()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    private func storageLoadEntries() -> [DreamEntry] {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [DreamEntry] = []
        Task {
            result = await storage.loadEntries()
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
}
