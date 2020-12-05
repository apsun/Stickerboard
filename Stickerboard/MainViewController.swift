import UIKit

class MainViewController
    : UIViewController
    , PreferenceDelegate
{
    private var preferenceViewController: PreferenceViewController!
    private var bannerViewController: BannerViewController!

    private static func versionString() -> String {
        let versionString = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as! String
        let versionCode = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as! String
        return "v\(versionString) (\(versionCode))"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Stickerboard"

        self.preferenceViewController = PreferenceViewController(root: PreferenceRoot(sections: [
            PreferenceSection(
                header: "Actions",
                footer: "Copies the stickers from the app's documents directory to the keyboard. Remember to re-import after adding or removing any stickers.",
                preferences: [
                    Preference(
                        id: PreferenceKey.importStickers.rawValue,
                        type: .button(label: "Import stickers")
                    )
                ]
            ),
            PreferenceSection(
                header: "Playground",
                footer: "Use this textbox to try out your stickers!",
                preferences: [
                    Preference(
                        id: PreferenceKey.playground.rawValue,
                        type: .stickerTextView
                    )
                ]
            ),
            PreferenceSection(
                header: "Settings",
                footer: "If enabled, this will shrink your stickers to 512x512 (or smaller, depending on the aspect ratio) and convert them to PNG. This lets you send them in Signal without the confirmation dialog. This does not affect GIFs.",
                preferences: [
                    Preference(
                        id: PreferenceKey.signalMode.rawValue,
                        type: .switch(label: "Signal compatibility mode")
                    )
                ]
            ),
            PreferenceSection(
                header: "About",
                footer: "Stickerboard \(MainViewController.versionString())",
                preferences: [
                    Preference(
                        id: PreferenceKey.help.rawValue,
                        type: .button(label: "Usage help")
                    ),
                    Preference(
                        id: PreferenceKey.github.rawValue,
                        type: .button(label: "Visit project on GitHub")
                    ),
                    Preference(
                        id: PreferenceKey.changelog.rawValue,
                        type: .button(label: "Changelog")
                    )
                ]
            )
        ]))
        self.addChild(self.preferenceViewController)
        self.preferenceViewController.view
            .autoLayoutInView(self.view)
            .fill(self.view)
            .activate()
        self.preferenceViewController.didMove(toParent: self)
        self.preferenceViewController.delegate = self

        self.bannerViewController = BannerViewController()
        self.addChild(self.bannerViewController)
        self.bannerViewController.view
            .autoLayoutInView(self.view, above: self.preferenceViewController.view)
            .fill(self.view.safeAreaLayoutGuide)
            .activate()
        self.bannerViewController.didMove(toParent: self)

        // Avoid putting content under the banner
        // let bannerHeight = self.bannerViewController.bannerHeight
        // self.preferenceViewController.additionalSafeAreaInsets.top = bannerHeight

        // Dismiss the keyboard when the user scrolls (indicating they
        // need more screen real estate)
        self.preferenceViewController.tableView.keyboardDismissMode = .onDrag
    }

    func preferenceView(initialSwitchValue id: String) -> Bool {
        switch id {
        case PreferenceKey.signalMode.rawValue:
            return PreferenceManager().signalMode()
        default:
            abort()
        }
    }

    func preferenceView(didClickButton id: String) {
        switch id {
        case PreferenceKey.importStickers.rawValue:
            self.importStickersButtonClicked()
        default:
            abort()
        }
    }

    func preferenceView(didSetSwitchValue id: String, newValue: Bool) {
        switch id {
        case PreferenceKey.signalMode.rawValue:
            PreferenceManager().setSignalMode(newValue)
        default:
            abort()
        }
    }

    private func importStickersButtonClicked() {
        // Dismiss the keyboard so it can refresh itself the next time it loads
        self.view.endEditing(false)

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try StickerFileManager.main.importFromDocuments() }
            DispatchQueue.main.async {
                switch result {
                case .success(let count):
                    self.bannerViewController.showBanner(
                        text: "Successfully imported \(count) sticker(s)",
                        style: .normal
                    )
                case .failure(_):
                    self.bannerViewController.showBanner(
                        text: "Failed to import stickers!",
                        style: .error
                    )
                }
            }
        }
    }
}
