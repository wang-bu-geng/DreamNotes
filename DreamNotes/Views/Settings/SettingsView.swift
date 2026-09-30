import SwiftUI

struct SettingsView: View {
    @State var appVM: AppViewModel
    @State private var showPrivacySheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    // 晨间唤醒
                    Section {
                        Toggle("晨间自动唤醒提醒", isOn: Binding(
                            get: { appVM.settings.isAutoWakeEnabled },
                            set: { newVal in
                                var s = appVM.settings
                                s.isAutoWakeEnabled = newVal
                                appVM.saveSettings(s)
                            }
                        ))
                        .tint(Color(red: 0.6, green: 0.4, blue: 1.0))

                        HStack {
                            Text("唤醒时段")
                            Spacer()
                            Text("\(appVM.settings.wakeUpStartFormatted) — \(appVM.settings.wakeUpEndFormatted)")
                                .foregroundStyle(.secondary)
                        }

                        NavigationLink(destination: WakeTimePickerView(appVM: appVM)) {
                            Text("修改唤醒时段")
                        }
                    } header: {
                        Label("晨间唤醒", systemImage: "clock.badge.wakeup")
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // 数据
                    Section {
                        NavigationLink(destination: StorageInfoView(appVM: appVM)) {
                            Text("本地存储空间")
                        }

                        Button(role: .destructive) {
                            appVM.deleteAllEntries()
                        } label: {
                            Label("清空所有梦境记录", systemImage: "trash")
                        }
                    } header: {
                        Label("数据管理", systemImage: "internaldrive")
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // 隐私
                    Section {
                        Button {
                            showPrivacySheet = true
                        } label: {
                            Label("隐私说明", systemImage: "lock.shield")
                        }
                    } header: {
                        Label("隐私与安全", systemImage: "hand.raised")
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // 关于
                    Section {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("开发框架")
                            Spacer()
                            Text("SwiftUI")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Label("关于", systemImage: "info.circle")
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacySheetView()
        }
    }
}

// MARK: - 唤醒时段选择器

private struct WakeTimePickerView: View {
    @State var appVM: AppViewModel
    @State private var startHour: Int
    @State private var startMinute: Int
    @State private var endHour: Int
    @State private var endMinute: Int

    init(appVM: AppViewModel) {
        self.appVM = appVM
        self.startHour = appVM.settings.wakeUpStartHour
        self.startMinute = appVM.settings.wakeUpStartMinute
        self.endHour = appVM.settings.wakeUpEndHour
        self.endMinute = appVM.settings.wakeUpEndMinute
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Text("选择晨间唤醒时段")
                    .font(.title3.bold())
                    .padding(.top)

                Text("在你设定的时段内，拿起手机就会自动弹出记录提醒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("开始")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Picker("时", selection: $startHour) {
                                ForEach(0..<24) { h in Text(String(format: "%02d", h)).tag(h) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            Text(":")
                            Picker("分", selection: $startMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .padding(.top, 20)

                    Spacer()

                    VStack(spacing: 8) {
                        Text("结束")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Picker("时", selection: $endHour) {
                                ForEach(0..<24) { h in Text(String(format: "%02d", h)).tag(h) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            Text(":")
                            Picker("分", selection: $endMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("当前设置：\(String(format: "%02d:%02d", startHour, startMinute)) — \(String(format: "%02d:%02d", endHour, endMinute))")
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

                Button {
                    var s = appVM.settings
                    s.wakeUpStartHour = startHour
                    s.wakeUpStartMinute = startMinute
                    s.wakeUpEndHour = endHour
                    s.wakeUpEndMinute = endMinute
                    appVM.saveSettings(s)
                } label: {
                    Text("保存设置")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.6, green: 0.4, blue: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("唤醒时段")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 存储信息

private struct StorageInfoView: View {
    @State var appVM: AppViewModel
    @State private var storageSize = "计算中..."

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

                Text("本地存储")
                    .font(.title2.bold())

                HStack {
                    Text("录音文件占用")
                    Spacer()
                    Text(storageSize)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("所有梦境数据仅存储在您的设备上，不会上传至云端")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("存储空间")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            storageSize = await appVM.getStorageSize()
        }
    }
}

// MARK: - 隐私说明

private struct PrivacySheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)

                        Text("隐私承诺")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)

                        PrivacySection(
                            icon: "1.circle",
                            title: "数据本地化",
                            detail: "所有梦境录音、文字记录、AI 故事均仅存储在您的设备本地。我们无法访问您的任何梦境数据。"
                        )

                        PrivacySection(
                            icon: "2.circle",
                            title: "麦克风权限",
                            detail: "麦克风仅用于梦境录音，录音文件不会上传至任何服务器。您可以在系统设置中随时关闭此权限。"
                        )

                        PrivacySection(
                            icon: "3.circle",
                            title: "运动与姿态权限",
                            detail: "用于检测晨起抬手动作以触发记录提醒，数据仅用于本地判断，不会离开您的设备。"
                        )

                        PrivacySection(
                            icon: "4.circle",
                            title: "AI 处理",
                            detail: "AI 梳理梦境故事时需要临时网络请求，仅传输文本数据（不传输录音）。处理完成后不留存任何用户数据。"
                        )

                        PrivacySection(
                            icon: "5.circle",
                            title: "无多余权限",
                            detail: "本应用不获取定位、相册、通讯录、推送通知等无关权限。"
                        )
                    }
                    .padding(24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct PrivacySection: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
