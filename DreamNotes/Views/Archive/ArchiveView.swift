import SwiftUI

struct ArchiveView: View {
    @State var appVM: AppViewModel
    @State var archiveVM: ArchiveViewModel

    private var entriesForSelectedDate: [DreamEntry] {
        archiveVM.filteredEntries(from: appVM.entries)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 日历顶部
                    HStack {
                        Button { archiveVM.goToToday() } label: {
                            Text("今天")
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        }
                        Spacer()
                        Text(archiveVM.selectedDate, format: .dateTime.year())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    // 日历导航
                    HStack {
                        Button {
                            if let prev = Calendar.current.date(byAdding: .day, value: -1, to: archiveVM.selectedDate) {
                                withAnimation { archiveVM.navigateToDate(prev) }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        }

                        Spacer()

                        Text(archiveVM.selectedDate, format: .dateTime.month().day())
                            .font(.title3.bold())

                        Spacer()

                        Button {
                            if let next = Calendar.current.date(byAdding: .day, value: 1, to: archiveVM.selectedDate) {
                                withAnimation { archiveVM.navigateToDate(next) }
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    // 日期泡泡
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            let datesWithEntries = archiveVM.datesWithEntries(from: appVM.entries)
                            ForEach(-7...7, id: \.self) { offset in
                                if let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) {
                                    let isSelected = Calendar.current.isDate(date, inSameDayAs: archiveVM.selectedDate)
                                    let hasEntry = datesWithEntries.contains(
                                        Calendar.current.dateComponents([.year, .month, .day], from: date)
                                    )

                                    DayBubble(
                                        date: date,
                                        isSelected: isSelected,
                                        hasEntry: hasEntry)
                                        .onTapGesture {
                                            withAnimation { archiveVM.navigateToDate(date) }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // 搜索
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索梦境...", text: $archiveVM.searchText)
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    // 梦境列表
                    if entriesForSelectedDate.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "cloud.moon")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text("这天没有梦境记录")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(entriesForSelectedDate) { entry in
                                NavigationLink(destination: DreamDetailView(
                                    entry: entry,
                                    appVM: appVM
                                )) {
                                    ArchiveRow(entry: entry)
                                }
                                .listRowBackground(Color.white.opacity(0.03))
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                for idx in indexSet {
                                    let entry = entriesForSelectedDate[idx]
                                    appVM.deleteEntry(entry)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct DayBubble: View {
    let date: Date
    let isSelected: Bool
    let hasEntry: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(weekdaySymbol)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .fill(isSelected ? Color(red: 0.6, green: 0.4, blue: 1.0) : Color.clear)
                    .frame(width: 32, height: 32)

                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? .white : (hasEntry ? Color(red: 0.6, green: 0.4, blue: 1.0) : .secondary))
            }

            if hasEntry {
                Circle()
                    .fill(isSelected ? .white : Color(red: 0.6, green: 0.4, blue: 1.0))
                    .frame(width: 4, height: 4)
            } else {
                Color.clear.frame(width: 4, height: 4)
            }
        }
        .frame(width: 40)
    }

    private var weekdaySymbol: String {
        let idx = Calendar.current.component(.weekday, from: date) - 1
        return Calendar.current.veryShortWeekdaySymbols[safe: idx] ?? ""
    }
}

private struct ArchiveRow: View {
    let entry: DreamEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud.moon.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.displayAIStory.prefix(80) + (entry.displayAIStory.count > 80 ? "..." : ""))
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()

            if entry.duration > 0 {
                Text(formatDuration(entry.duration))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
