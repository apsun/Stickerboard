import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let versionName = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as! String

        let versionCode = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as! String

        UserDefaults.standard.set(versionName, forKey: PreferenceKey.versionName.rawValue)
        UserDefaults.standard.set(versionCode, forKey: PreferenceKey.versionCode.rawValue)

        do {
            try StickerFileManager.main.ensureReadmeFileExists(content: L("readme_content"))
        } catch {
            logger.error("Failed to create readme file: \(error.localizedDescription)")
        }
        return true
    }
}
