import SwiftUI

struct DreamDetailView: View {
    @State var entry: DreamEntry
    @State var appVM: AppViewModel
    @State private var showEditSheet = false
    @State private var editedRawText: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 日期信息
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(entry.date, format: .dateTime.year().month().day())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(entry.date, style: .time)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if entry.duration > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text("录音 \(formatDuration(entry.duration))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Divider().overlay(.gray.opacity(0.3))

                    // 原始口述
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundStyle(.secondary)
                            Text("原始口述")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("编辑") {
                                editedRawText = entry.displayRawText
                                showEditSheet = true
                            }
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        }

                        Text(entry.displayRawText)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // AI 故事
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles.rectangle.stack")
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                            Text("梦境故事")
                                .font(.headline)
                        }

                        Text(entry.displayAIStory)
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // 删除
                    Button(role: .destructive) {
                        appVM.deleteEntry(entry)
                    } label: {
                        Label("删除这条梦境", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .navigationTitle("梦境详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            editSheet
        }
    }

    private var editSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("编辑原始口述")
                        .font(.headline)
                        .padding(.top)

                    TextEditor(text: $editedRawText)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showEditSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = entry
                        updated.editedRawText = editedRawText
                        entry = updated
                        appVM.updateEntry(updated)
                        showEditSheet = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
