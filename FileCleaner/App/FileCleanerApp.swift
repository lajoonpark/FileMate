import SwiftUI

@main
struct FileCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 560)
        }
        .windowResizability(.contentSize)
    }
}
