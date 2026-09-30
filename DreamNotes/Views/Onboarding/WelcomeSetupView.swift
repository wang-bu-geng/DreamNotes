import SwiftUI

struct WelcomeSetupView: View {
    @State var appVM: AppViewModel
    @State private var startHour = 7
    @State private var startMinute = 0
    @State private var endHour = 10
    @State private var endMinute = 0
    @State private var showPrivacy = true

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 顶部图标
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))

                    Text("梦境手记")
                        .font(.largeTitle.bold())

                    Text("用语音记录你的每一个梦")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                // 唤醒时段设置
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "clock.badge.wakeup")
                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                        Text("设置晨间唤醒时段")
                            .font(.headline)
                    }

                    Text("在你设定的时段内，拿起手机就会自动询问是否记录梦境")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        // 开始时间
                        VStack(alignment: .leading, spacing: 4) {
                            Text("开始时间").font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Picker("时", selection: $startHour) {
                                    ForEach(0..<24) { h in
                                        Text(String(format: "%02d", h)).tag(h)
                                    }
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

                        // 结束时间
                        VStack(alignment: .leading, spacing: 4) {
                            Text("结束时间").font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Picker("时", selection: $endHour) {
                                    ForEach(0..<24) { h in
                                        Text(String(format: "%02d", h)).tag(h)
                                    }
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
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // 隐私说明
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        Text("隐私承诺")
                            .font(.headline)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        PrivacyRow(text: "所有梦境数据仅存储在您本地设备")
                        PrivacyRow(text: "录音文件不上传云端")
                        PrivacyRow(text: "不获取位置、通讯录、推送等无关权限")
                        PrivacyRow(text: "AI 处理仅临时网络请求，不留存原始音频")
                    }
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer(minLength: 20)

                // 开始按钮
                Button {
                    var s = appVM.settings
                    s.wakeUpStartHour = startHour
                    s.wakeUpStartMinute = startMinute
                    s.wakeUpEndHour = endHour
                    s.wakeUpEndMinute = endMinute
                    appVM.saveSettings(s)
                    appVM.completeOnboarding()
                } label: {
                    Text("开始记录梦境")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.6, green: 0.4, blue: 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.black)
        .onAppear {
            startHour = appVM.settings.wakeUpStartHour
            startMinute = appVM.settings.wakeUpStartMinute
            endHour = appVM.settings.wakeUpEndHour
            endMinute = appVM.settings.wakeUpEndMinute
        }
    }
}

private struct PrivacyRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
