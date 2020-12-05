import UIKit

class TutorialViewController: UINavigationController {
    override func viewDidLoad() {
        self.setViewControllers([TutorialViewControllerImpl()], animated: false)
    }
}

class TutorialViewControllerImpl: UIViewController {
    private var textView: UITextView!

    override func loadView() {
        self.view = UIScrollView()
    }

    override func viewDidLoad() {
        self.title = "Tutorial"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
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
            <h1>Welcome to Stickerboard!</h1>
            <p>
            Before we get started, there's a few steps you'll need to take in order to use
            Stickerboard:
            </p>
            </section>

            <section>
            <br><h1>Enable the keyboard</h1>
            <p>
            Please enable Stickerboard by heading to:
            </p>
            <ol>
                <li>Settings</li>
                <li>Stickerboard</li>
                <li>Keyboards</li>
            </ol>
            <br><p><a href="app-settings:">Click here to open the Stickerboard settings menu</a></p>
            </section>

            <section>
            <br><h1>Allow full access</h1>
            <p>
            Stickerboard requires full access to function. Don't worry, we aren't uploading
            your stickers anywhere! All of your data stays on your device. Stickerboard only
            needs full access to copy stickers to your clipboard.
            </p>
            <p>
            To enable full access, open the Stickerboard settings (in the same place you enabled
            the keyboard, see section above), and toggle the switch labeled "Allow Full Access".
            </p>
            </section>

            <section>
            <br><h1>Add some stickers</h1>
            <p>
            You might have noticed that Stickerboard does not come with any stickers. That's
            because <i>you</i> provide them! Stickerboard allows you to send any image you want
            as a sticker. Once you've added the images, just hit the import button within the app
            and they will magically appear in the keyboard.
            </p>
            <p>
            So how do you add images to Stickerboard? There are three ways to do this:
            </p>
            </section>

            <section>
            <br><h1>1. Share menu</h1>
            <p>
            Have some images on your device you would like to use? Hit share, then select
            the "Save to Files" option. When given the option, choose Stickerboard under "On
            My iPhone".
            </p>
            </section>

            <section>
            <br><h1>2. iTunes File Sharing</h1>
            <p>
            Want to copy stickers from your computer? You can use iTunes File Sharing to
            drag and drop the images from your computer directly into the Stickerboard app.
            </p>
            </section>

            <section>
            <br><h1>3. Files app</h1>
            <p>
            You can use the built-in Files app to manage your stickers. Just copy the images
            you want to add to the Stickerboard folder under "On My iPhone".
            </p>
            </section>

            <section>
            <br><h1>Sticker packs</h1>
            <p>
            Too many stickers to handle? Create new sticker packs by organizing your images
            into folders under the Stickerboard directory. Each folder will turn into a new
            sticker pack.
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
