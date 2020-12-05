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

    private func versionString() -> String {
        let versionString = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as! String
        let versionCode = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as! String
        return F("version_string", versionString, versionCode)
    }

    override func viewDidLoad() {
        self.title = L("stickerboard")

        self.preferenceViewController = PreferenceViewController(root: PreferenceRoot(sections: [
            PreferenceSection(
                header: L("actions"),
                footer: L("actions_footer"),
                preferences: [
                    Preference(
                        id: PreferenceKey.importStickers.rawValue,
                        type: .button(label: L("import_stickers"))
                    )
                ]
            ),
            PreferenceSection(
                header: L("playground"),
                footer: L("playground_footer"),
                preferences: [
                    Preference(
                        id: PreferenceKey.playground.rawValue,
                        type: .stickerTextView
                    )
                ]
            ),
            PreferenceSection(
                header: L("settings"),
                footer: L("settings_footer"),
                preferences: [
                    Preference(
                        id: PreferenceKey.signalMode.rawValue,
                        type: .switch(label: L("signal_mode"))
                    )
                ]
            ),
            PreferenceSection(
                header: L("about"),
                footer: F("about_footer", self.versionString()),
                preferences: [
                    Preference(
                        id: PreferenceKey.tutorial.rawValue,
                        type: .button(label: L("view_tutorial"))
                    ),
                    Preference(
                        id: PreferenceKey.github.rawValue,
                        type: .button(label: L("visit_github"))
                    ),
                    Preference(
                        id: PreferenceKey.changelog.rawValue,
                        type: .button(label: L("changelog"))
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
                        message = L("no_stickers_found")
                    } else if count == 1 {
                        message = L("imported_sticker")
                    } else {
                        message = F("imported_stickers", count)
                    }
                    self.bannerViewController.showBanner(
                        text: message,
                        style: .normal
                    )
                case .failure(let error):
                    logger.error("Failed to import stickers: \(error.localizedDescription)")
                    self.bannerViewController.showBanner(
                        text: L("failed_import_stickers"),
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
