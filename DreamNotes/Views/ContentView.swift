import SwiftUI

struct ContentView: View {
    @State private var appVM: AppViewModel
    @State private var archiveVM = ArchiveViewModel()
    @State private var selectedTab = 0

    init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView(appVM: appVM)
                    .tabItem {
                        Label("今日", systemImage: "moon.stars.fill")
                    }
                    .tag(0)

                ArchiveView(appVM: appVM, archiveVM: archiveVM)
                    .tabItem {
                        Label("梦境档案", systemImage: "books.vertical.fill")
                    }
                    .tag(1)

                SettingsView(appVM: appVM)
                    .tabItem {
                        Label("设置", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .tint(Color(red: 0.6, green: 0.4, blue: 1.0))  // 淡紫色
            .sheet(isPresented: $appVM.showRecordingSheet) {
                RecordingView(appVM: appVM)
            }
        }
        .onAppear {
            appVM.checkMorningPrompt()
        }
        .alert("记录昨夜梦境？", isPresented: $appVM.showMorningPrompt) {
            Button("开始记录") {
                appVM.showRecordingSheet = true
            }
            Button("忽略", role: .cancel) {
                appVM.dismissMorningPrompt()
            }
        } message: {
            Text("你好像刚醒来，要不要把昨晚的梦记下来？")
        }
    }
}
