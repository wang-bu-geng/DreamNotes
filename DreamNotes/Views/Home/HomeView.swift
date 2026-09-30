import SwiftUI

struct HomeView: View {
    @State var appVM: AppViewModel
    @State private var showRecords = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 顶部问候
                        VStack(spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

                            Text("梦境手记")
                                .font(.title2.bold())

                            Text("今天想记录梦境吗？")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 32)

                        // 快速录梦按钮
                        Button {
                            appVM.showRecordingSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "waveform")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("录梦")
                                        .font(.headline)
                                    Text("口述你的梦境，AI 帮你整理成故事")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
                            .padding(20)
                            .background(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // 状态卡片
                        HStack(spacing: 12) {
                            StatusCard(
                                icon: "book.circle.fill",
                                label: "总记录",
                                value: "\(appVM.entries.count)",
                                color: Color(red: 0.6, green: 0.4, blue: 1.0)
                            )

                            StatusCard(
                                icon: "calendar.circle.fill",
                                label: "今日",
                                value: "\(appVM.entriesForDate(Date()).count)",
                                color: .orange
                            )
                        }

                        // 时段信息
                        HStack {
                            Image(systemName: "clock.badge.wakeup")
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("晨间唤醒时段")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(appVM.settings.wakeUpStartFormatted) — \(appVM.settings.wakeUpEndFormatted)")
                                    .font(.subheadline)
                            }
                            Spacer()
                            if appVM.settings.isAutoWakeEnabled {
                                Text("已开启")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("已关闭")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // 最近梦境
                        if !appVM.entries.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("最近梦境")
                                    .font(.headline)

                                ForEach(Array(appVM.entries.prefix(5))) { entry in
                                    NavigationLink(destination: DreamDetailView(
                                        entry: entry,
                                        appVM: appVM
                                    )) {
                                        RecentDreamRow(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct StatusCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RecentDreamRow: View {
    let entry: DreamEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud.moon.fill")
                .font(.title3)
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.displayAIStory.prefix(60) + (entry.displayAIStory.count > 60 ? "..." : ""))
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
