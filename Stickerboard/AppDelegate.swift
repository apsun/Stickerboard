import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        do {
            try StickerFileManager.main.ensureReadmeFileExists()
        } catch {
            // Nothing can be done about this; since this isn't technically critical,
            // just swallow the error and move on.
        }
        return true
    }
}
