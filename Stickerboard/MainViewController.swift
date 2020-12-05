import UIKit

class MainViewController: UINavigationController {
    override func viewDidLoad() {
        self.setViewControllers([MainViewControllerImpl()], animated: false)
    }
}

class MainViewControllerImpl
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
                footer: "If enabled, this will shrink your stickers to 512x512 (or smaller, depending on the aspect ratio). This lets you send them in Signal without the confirmation dialog. This does not affect GIFs. You can override this option at any time by long pressing on a sticker.",
                preferences: [
                    Preference(
                        id: PreferenceKey.signalMode.rawValue,
                        type: .switch(label: "Signal compatibility mode")
                    )
                ]
            ),
            PreferenceSection(
                header: "About",
                footer: "Stickerboard \(MainViewControllerImpl.versionString())",
                preferences: [
                    Preference(
                        id: PreferenceKey.tutorial.rawValue,
                        type: .button(label: "View tutorial")
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !KeyboardManager.main.isKeyboardEnabled() {
            self.showTutorial()
        }
    }

    func preferenceView(initialSwitchValue id: String) -> Bool {
        switch id {
        case PreferenceKey.signalMode.rawValue:
            return PreferenceManager.shared.signalMode()
        default:
            abort()
        }
    }

    func preferenceView(didClickButton id: String) {
        switch id {
        case PreferenceKey.importStickers.rawValue:
            self.importStickersButtonClicked()
        case PreferenceKey.tutorial.rawValue:
            self.showTutorial()
        case PreferenceKey.github.rawValue:
            self.openGitHub()
        case PreferenceKey.changelog.rawValue:
            self.showChangelog()
        default:
            abort()
        }
    }

    func preferenceView(didSetSwitchValue id: String, newValue: Bool) {
        switch id {
        case PreferenceKey.signalMode.rawValue:
            PreferenceManager.shared.setSignalMode(newValue)
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
                    let message: String
                    if count == 0 {
                        message = "Didn't find any stickers to import"
                    } else if count == 1 {
                        message = "Successfully imported 1 sticker"
                    } else {
                        message = "Successfully imported \(count) stickers"
                    }
                    self.bannerViewController.showBanner(
                        text: message,
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

    private func showTutorial() {
        self.present(TutorialViewController(), animated: true, completion: nil)
    }

    private func openGitHub() {
        let url = URL(string: "https://github.com/apsun/Stickerboard")!
        UIApplication.shared.open(url)
    }

    private func showChangelog() {
        self.present(ChangelogViewController(), animated: true, completion: nil)
    }
}
