import UIKit
import Common

class TutorialViewController: UINavigationController {
    override func viewDidLoad() {
        self.navigationBar.scrollEdgeAppearance = self.navigationBar.standardAppearance
        self.setViewControllers([TutorialViewControllerImpl()], animated: false)
    }
}

fileprivate class TutorialViewControllerImpl: HTMLViewController {
    required init?(coder: NSCoder) {
        abort()
    }

    init() {
        super.init(
            contentHtml: L("tutorial_html"),
            titleText: L("tutorial"),
            doneButtonText: L("done")
        )
    }
}
