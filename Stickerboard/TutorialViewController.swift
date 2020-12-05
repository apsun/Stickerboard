import UIKit

class TutorialViewController: UINavigationController {
    override func viewDidLoad() {
        self.setViewControllers([TutorialViewControllerImpl()], animated: false)
    }
}

class TutorialViewControllerImpl: TextViewController {
    required init?(coder: NSCoder) {
        abort()
    }

    init() {
        super.init(
            contentHtml: L("tutorial_html"),
            titleText: L("tutorial"),
            backButtonText: L("close")
        )
    }
}
