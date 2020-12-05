import UIKit

/**
 * A view controller containing a scrollable HTML text view.
 */
class TextViewController: UIViewController {
    private let contentHtml: String
    private let titleText: String
    private let backButtonText: String
    private var textView: UITextView!

    required init?(coder: NSCoder) {
        abort()
    }

    init(contentHtml: String, titleText: String, backButtonText: String) {
        self.contentHtml = contentHtml
        self.titleText = titleText
        self.backButtonText = backButtonText
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        self.view = UIScrollView()
    }

    override func viewDidLoad() {
        self.title = self.titleText
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: self.backButtonText,
            style: .done,
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

        self.textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        self.textView.isScrollEnabled = false
        self.textView.isEditable = false

        // Creating NSAttributedString from HTML is extremely slow,
        // so load it off the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            let style = """
                <style>
                    body {
                        font-family: -apple-system, sans-serif;
                        font: -apple-system-body;
                    }
                    h1 { font: -apple-system-headline; }
                    h2 { font: -apple-system-subheadline; }
                </style>
                """

            let html = style + self.contentHtml

            let attrString = try! NSMutableAttributedString(
                data: Data(html.utf8),
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
            attrString.addAttributes(
                [.foregroundColor: UIColor.label],
                range: NSMakeRange(0, attrString.length)
            )
            DispatchQueue.main.async {
                self.textView.attributedText = attrString
            }
        }
    }

    @objc
    private func close() {
        self.dismiss(animated: true)
    }
}
