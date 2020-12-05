import UIKit

class ChangelogViewController: UINavigationController {
    override func viewDidLoad() {
        self.setViewControllers([ChangelogViewControllerImpl()], animated: false)
    }
}

class ChangelogViewControllerImpl: UIViewController {
    private var textView: UITextView!

    override func loadView() {
        self.view = UIScrollView()
    }

    override func viewDidLoad() {
        self.title = "Changelog"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(self.close)
        )

        self.view.backgroundColor = .systemBackground

        self.textView = UITextView()
        self.textView
            .autoLayoutInView(self.view)
            .fillY(self.view)
            .fillX(self.view.safeAreaLayoutGuide)
            .activate()

        let text = """
        <style>
            body {
                font-family: -apple-system, sans-serif;
                font: -apple-system-body;
            }
            h1 { font: -apple-system-headline; }
            h2 { font: -apple-system-subheadline; }
        </style>
        <body>
            <section>
            <h1>v1.0 - Dec 4, 2020</h1>
            <p>
            This is the initial release! Thanks for being an early adopter. Come back in the
            future to see what new features we've added.
            </p>
            </section>
        </body>
        """
        self.textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        self.textView.isScrollEnabled = false
        self.textView.isEditable = false
        let attrString = try! NSMutableAttributedString(
            data: Data(text.utf8),
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        )
        attrString.addAttributes(
            [.foregroundColor: UIColor.label],
            range: NSMakeRange(0, attrString.length)
        )
        self.textView.attributedText = attrString
    }

    @objc
    private func close() {
        self.dismiss(animated: true)
    }
}
