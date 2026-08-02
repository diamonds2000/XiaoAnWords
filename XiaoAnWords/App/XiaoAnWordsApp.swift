import SwiftUI
import SwiftData

@main
struct XiaoAnWordsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: WordStats.self)
    }
}
