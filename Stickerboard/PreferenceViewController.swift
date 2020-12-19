import UIKit
import Common

/**
 * This is the public preference change protocol that listeners should
 * implement.
 */
@objc
protocol PreferenceDelegate: class {
    /**
     * Indicates a button preference was clicked.
     */
    @objc
    optional func preferenceView(didClickButton id: String)

    /**
     * Returns the initial value of the given switch preference.
     */
    @objc
    optional func preferenceView(initialSwitchValue id: String) -> Bool

    /**
     * Indicates a switch preference was toggled.
     */
    @objc
    optional func preferenceView(didSetSwitchValue id: String, newValue: Bool)
}

/**
 * Internal delegate for callbacks from the cell to the view controller.
 */
fileprivate protocol PreferenceCellDelegate: class {
    func preferenceCellDidUpdate(_ sender: PreferenceCell)
}

/**
 * Base class for all preference cells.
 */
fileprivate class PreferenceCell: UITableViewCell {
    var preferenceID: String?
    weak var delegate: PreferenceCellDelegate?
}

/**
 * Preference cell that acts as a button.
 */
fileprivate class ButtonCell: PreferenceCell {
    static let reuseIdentifier = NSStringFromClass(ButtonCell.self)

    required init?(coder: NSCoder) {
        abort()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .default
    }

    func setLabel(_ text: String) {
        var contentConfig = self.defaultContentConfiguration()
        contentConfig.text = text
        contentConfig.textProperties.color = .accent
        self.contentConfiguration = contentConfig
    }
}

/**
 * Preference cell that contains a switch.
 */
fileprivate class SwitchCell: PreferenceCell {
    static let reuseIdentifier = NSStringFromClass(SwitchCell.self)

    private var switchView: UISwitch {
        return self.accessoryView as! UISwitch
    }

    var isOn: Bool {
        get {
            return self.switchView.isOn
        }
        set {
            self.switchView.isOn = newValue
        }
    }

    required init?(coder: NSCoder) {
        abort()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryView = UISwitch()
        self.selectionStyle = .none
        self.switchView.addTarget(
            self,
            action: #selector(self.switchValueDidChange),
            for: .valueChanged
        )
    }

    func setLabel(_ text: String) {
        var contentConfig = self.defaultContentConfiguration()
        contentConfig.text = text
        self.contentConfiguration = contentConfig
    }

    @objc
    private func switchValueDidChange() {
        self.delegate?.preferenceCellDidUpdate(self)
    }
}

/**
 * Preference cell that contains a StickerTextView.
 */
fileprivate class StickerTextViewCell: PreferenceCell, UITextViewDelegate {
    static let reuseIdentifier = NSStringFromClass(StickerTextViewCell.self)

    private var textView: StickerTextView!

    required init?(coder: NSCoder) {
        abort()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none

        self.textView = StickerTextView()
        self.textView.backgroundColor = .clear
        self.textView
            .autoLayoutInView(self.contentView)
            .fill(self.contentView.layoutMarginsGuide)
            .activate()

        // By disabling scroll, we are letting the text view resize to
        // fit its contents, which in turn lets the cell resize to fit
        // the text view.
        self.textView.isScrollEnabled = false
        self.textView.delegate = self
    }

    func textViewDidChange(_ textView: UITextView) {
        // Resize newly inserted images to something more reasonable
        // so they don't take up the whole screen.
        textView.textStorage.enumerateAttribute(
            .attachment,
            in: NSMakeRange(0, textView.attributedText.length),
            options: []
        ) { (value, range, stop) in
            // Only consider image attachments
            guard let value = value as? NSTextAttachment else { return }
            guard let image = value.image else { return }

            // Only do this the first time we see an image
            guard value.bounds == .zero else { return }

            // Resize it to something reasonable
            let widthScale = min(1, 88 / image.size.width)
            var bounds = value.bounds
            bounds.size.height = image.size.height * widthScale
            bounds.size.width = image.size.width * widthScale
            value.bounds = bounds
        }

        self.delegate?.preferenceCellDidUpdate(self)
    }
}

/**
 * Provides a static UITableView that displays preferences, as defined
 * by a PreferenceRoot model object.
 */
class PreferenceViewController
    : UITableViewController
    , UITextViewDelegate
    , PreferenceCellDelegate
{
    private let root: PreferenceRoot

    /**
     * Receive preference actions and change callbacks via this delegate.
     */
    weak var delegate: PreferenceDelegate?

    required init?(coder: NSCoder) {
        abort()
    }

    init(root: PreferenceRoot) {
        self.root = root
        var style = UITableView.Style.grouped
        if UIDevice.current.userInterfaceIdiom == .pad {
            style = UITableView.Style.insetGrouped
        }
        super.init(style: style)
    }

    override func viewDidLoad() {
        self.tableView.register(
            ButtonCell.self,
            forCellReuseIdentifier: ButtonCell.reuseIdentifier
        )
        self.tableView.register(
            SwitchCell.self,
            forCellReuseIdentifier: SwitchCell.reuseIdentifier
        )
        self.tableView.register(
            StickerTextViewCell.self,
            forCellReuseIdentifier: StickerTextViewCell.reuseIdentifier
        )
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return root.sections.count
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return root.sections[section].preferences.count
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        return root.sections[section].header
    }

    override func tableView(
        _ tableView: UITableView,
        titleForFooterInSection section: Int
    ) -> String? {
        return root.sections[section].footer
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let pref = self.root.sections[indexPath.section].preferences[indexPath.row]
        switch pref.type {
        case .button(let label):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ButtonCell.reuseIdentifier,
                for: indexPath
            ) as! ButtonCell
            cell.preferenceID = pref.id
            cell.setLabel(label)
            cell.delegate = self
            return cell
        case .switch(let label):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SwitchCell.reuseIdentifier,
                for: indexPath
            ) as! SwitchCell
            cell.isOn = self.delegate!.preferenceView!(initialSwitchValue: pref.id)
            cell.preferenceID = pref.id
            cell.setLabel(label)
            cell.delegate = self
            return cell
        case .stickerTextView:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: StickerTextViewCell.reuseIdentifier,
                for: indexPath
            ) as! StickerTextViewCell
            cell.preferenceID = pref.id
            cell.delegate = self
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Remove cell highlight for buttons
        tableView.deselectRow(at: indexPath, animated: true)

        // If this is a button preference, trigger the callback
        if let buttonCell = tableView.cellForRow(at: indexPath) as? ButtonCell {
            self.delegate!.preferenceView!(didClickButton: buttonCell.preferenceID!)
        }
    }

    fileprivate func preferenceCellDidUpdate(_ sender: PreferenceCell) {
        switch sender {
        case is ButtonCell:
            // Button cells are kind of special in that they don't
            // handle their own clicks, but rather, the entire cell is
            // selected and handled by ourselves, so this is a no-op.
            break
        case let switchCell as SwitchCell:
            self.delegate!.preferenceView!(
                didSetSwitchValue: switchCell.preferenceID!,
                newValue: switchCell.isOn
            )
        case is StickerTextViewCell:
            // This resizes the cell to fit the text view
            UIView.setAnimationsEnabled(false)
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        default:
            abort()
        }
    }
}
