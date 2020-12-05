import UIKit

class ChangelogViewController: UINavigationController {
    override func viewDidLoad() {
        self.setViewControllers([ChangelogViewControllerImpl()], animated: false)
    }
}

class ChangelogViewControllerImpl: TextViewController {
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
