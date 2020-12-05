import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let versionString = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as! String

        let versionCode = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as! String

        UserDefaults.standard.set(versionString, forKey: "pref_version")
        UserDefaults.standard.set(versionCode, forKey: "pref_version_code")

        do {
            try StickerFileManager.main.ensureReadmeFileExists()
        } catch {
            // Nothing can be done about this; since this isn't technically critical,
            // just swallow the error and move on.
        }
        return true
    }
}
