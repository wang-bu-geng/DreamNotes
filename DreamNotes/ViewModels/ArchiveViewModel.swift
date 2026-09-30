import Foundation
import SwiftUI

@Observable
final class ArchiveViewModel {
    var searchText = ""
    var selectedDate: Date

    init() {
        self.selectedDate = Date()
    }

    func filteredEntries(from allEntries: [DreamEntry]) -> [DreamEntry] {
        let entries = allEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }

        if searchText.isEmpty {
            return entries
        }
        return entries.filter {
            $0.displayRawText.localizedCaseInsensitiveContains(searchText) ||
            $0.displayAIStory.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// 获取有梦境记录的日期集合
    func datesWithEntries(from allEntries: [DreamEntry]) -> Set<DateComponents> {
        Set(allEntries.map {
            Calendar.current.dateComponents([.year, .month, .day], from: $0.date)
        })
    }

    /// 获取日历中每一天的梦境数
    func entryCount(for date: Date, from allEntries: [DreamEntry]) -> Int {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
    }

    /// 导航到指定日期
    func navigateToDate(_ date: Date) {
        selectedDate = date
    }

    /// 返回到今天
    func goToToday() {
        selectedDate = Date()
    }
}
