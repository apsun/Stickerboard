import UIKit
import Common

class ChangelogViewController: UINavigationController {
    override func viewDidLoad() {
        self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance
        self.setViewControllers([ChangelogViewControllerImpl()], animated: false)
    }
}

fileprivate class ChangelogViewControllerImpl: HTMLViewController {
    required init?(coder: NSCoder) {
        abort()
    }

    init() {
        super.init(
            contentHtml: L("changelog_html"),
            titleText: L("changelog"),
            backButtonText: L("close")
        )
    }
}
