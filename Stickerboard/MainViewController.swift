import UIKit
import Common

class MainViewController: UINavigationController {
    private var bannerView: BannerView!

    override func viewDidLoad() {
        self.navigationBar.prefersLargeTitles = true
        self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance

        // Create the banner view in the navigation controller directly
        // rather than in the child view controller. This is because we
        // need to attach the banner to the bottom of the navigation bar,
        // and autolayout doesn't let us do that unless the two views
        // are in the same hierarchy.
        //
        // Attaching the banner view to the top of the child view doesn't
        // work either, because overscroll doesn't affect the safe area
        // insets for some reason.
        self.bannerView = BannerView()
        self.bannerView
            .autoLayoutInView(self.view)
            .top(self.navigationBar.bottomAnchor)
            .bottom(self.view.safeAreaLayoutGuide.bottomAnchor)
            .fillX(self.view.safeAreaLayoutGuide)
            .activate()

        self.setViewControllers([MainViewControllerImpl()], animated: false)
    }

    fileprivate func showBanner(text: String, style: BannerView.Style) {
        self.bannerView.show(text: text, style: style)
    }
}

fileprivate class MainViewControllerImpl
    : UIViewController
    , PreferenceDelegate
{
    private var preferenceViewController: PreferenceViewController!

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
                footer: L("resize_stickers_footer"),
                preferences: [
                    Preference(
                        id: PreferenceKey.resizeStickers.rawValue,
                        type: .switch(label: L("resize_stickers"))
                    )
                ]
            ),
            PreferenceSection(
                header: nil,
                footer: L("auto_switch_keyboard_footer"),
                preferences: [
                    Preference(
                        id: PreferenceKey.autoSwitchKeyboard.rawValue,
                        type: .switch(label: L("auto_switch_keyboard"))
                    )
                ]
            ),
            PreferenceSection(
                header: nil,
                footer: L("remember_selected_pack_footer"),
                preferences: [
                    Preference(
                        id: PreferenceKey.rememberSelectedPack.rawValue,
                        type: .switch(label: L("remember_selected_pack"))
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

        // Dismiss the keyboard when the user scrolls (indicating they
        // need more screen real estate)
        self.preferenceViewController.tableView.keyboardDismissMode = .onDrag
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !KeyboardManager.isKeyboardEnabled() {
            self.showTutorial()
        }
    }

    func preferenceView(didClickButton id: String) {
        switch id {
        case PreferenceKey.importStickers.rawValue:
            self.importStickers()
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

    func preferenceView(initialSwitchValue id: String) -> Bool {
        switch id {
        case PreferenceKey.resizeStickers.rawValue:
            return PreferenceManager.shared.resizeStickers()
        case PreferenceKey.autoSwitchKeyboard.rawValue:
            return PreferenceManager.shared.autoSwitchKeyboard()
        case PreferenceKey.rememberSelectedPack.rawValue:
            return PreferenceManager.shared.rememberSelectedPack()
        default:
            abort()
        }
    }

    func preferenceView(didSetSwitchValue id: String, newValue: Bool) {
        switch id {
        case PreferenceKey.resizeStickers.rawValue:
            PreferenceManager.shared.setResizeStickers(newValue)
        case PreferenceKey.autoSwitchKeyboard.rawValue:
            PreferenceManager.shared.setAutoSwitchKeyboard(newValue)
        case PreferenceKey.rememberSelectedPack.rawValue:
            PreferenceManager.shared.setRememberSelectedPack(newValue)
        default:
            abort()
        }
    }

    private func importStickers() {
        // Dismiss the keyboard so it can refresh itself the next time it loads
        self.view.endEditing(false)

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try StickerFileManager.main.importFromDocuments() }
            DispatchQueue.main.async {
                self.showStickerImportResult(result)
            }
        }
    }

    private func showStickerImportResult(_ result: Result<StickerLoadResult, Error>) {
        switch result {
        case .success(let result):
            let message: String
            if result.succeeded.count == 0 {
                message = L("no_stickers_found_banner")
            } else if result.succeeded.count == 1 {
                message = L("imported_sticker_banner")
            } else {
                message = F("imported_stickers_banner", result.succeeded.count)
            }
            self.showBanner(
                text: message,
                style: .normal
            )

            if !result.errors.isEmpty {
                let errors = result.errors.map { $0.localizedDescription }
                let maxLines = 3
                var truncatedErrors = errors
                if errors.count > maxLines {
                    truncatedErrors.removeSubrange(maxLines..<errors.count)
                    truncatedErrors.append(F("skipped_stickers_more", errors.count - maxLines))
                }

                let alert = UIAlertController(
                    title: L("skipped_stickers_title"),
                    message: F("skipped_stickers_body", truncatedErrors.joined(separator: "\n\n")),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: L("ok"), style: .default))
                alert.addAction(UIAlertAction(title: L("copy_error"), style: .default) { (_) in
                    UIPasteboard.general.string = errors.joined(separator: "\n\n")
                })
                self.present(alert, animated: true)
            }
        case .failure(let error):
            logger.error("Failed to import stickers: \(error.localizedDescription)")
            self.showBanner(
                text: L("failed_import_banner"),
                style: .error
            )

            let alert = UIAlertController(
                title: L("failed_import_dialog_title"),
                message: F("failed_import_dialog_body", error.localizedDescription),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L("ok"), style: .default))
            alert.addAction(UIAlertAction(title: L("copy_error"), style: .default) { (_) in
                UIPasteboard.general.string = error.localizedDescription
            })
            self.present(alert, animated: true)
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

    private func showBanner(text: String, style: BannerView.Style) {
        let parent = self.navigationController as! MainViewController
        parent.showBanner(text: text, style: style)
    }
}
