import SwiftUI

@main
struct DreamNotesApp: App {
    @State private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appVM.showOnboarding {
                    WelcomeSetupView(appVM: appVM)
                } else {
                    ContentView(appVM: appVM)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
