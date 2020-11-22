import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentDir.appendingPathComponent("README.txt")
        let content = "Copy your files to this directory."
        try! content.write(to: filePath, atomically: true, encoding: .utf8)
        return true
    }
}
