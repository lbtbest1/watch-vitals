// iPhone 宿主壳:M0 仅用于满足双包结构与 HermesFixGui 兼容,M3 起放趋势页
import SwiftUI

@main
struct VitalsApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Vitals 宿主 · M0")
                .font(.headline)
        }
    }
}
