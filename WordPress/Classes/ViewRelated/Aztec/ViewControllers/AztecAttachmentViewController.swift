import Foundation
import UIKit
import WordPressShared
import Aztec


class AztecAttachmentViewController: UITableViewController {

    @objc var attachment: ImageAttachment? {
        didSet {
            if let attachment = attachment {
                alignment = attachment.alignment
                linkURL = attachment.linkURL
                size = attachment.size
                alt = attachment.alt
            }
        }
    }

    var alignment = ImageAttachment.Alignment.none
    var linkURL: URL?
    var size = ImageAttachment.Size.full
    @objc var alt: String?

    var onUpdate: ((_ alignment: ImageAttachment.Alignment, _ size: ImageAttachment.Size, _ linkURL: URL?, _ altText: String?) -> Void)?
    @objc var onCancel: (() -> Void)?

    fileprivate var handler: ImmuTableViewHandler!


    // MARK: - Initialization

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Media Settings", comment: "Media Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            EditableTextRow.self,
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        handler.viewModel = tableViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(AztecAttachmentViewController.handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(AztecAttachmentViewController.handleDoneButtonTapped))
        navigationItem.rightBarButtonItem = doneButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.handler.viewModel = self.tableViewModel()
    }

    // MARK: - Model mapping

    func tableViewModel() -> ImmuTable {
        let displaySettingsHeader = NSLocalizedString("Web Display Settings", comment: "The title of the option group for editing an image's size, alignment, etc. on the image details screen.")

        let alignmentRow = EditableTextRow(
            title: NSLocalizedString("Alignment", comment: "Image alignment option title."),
            value: alignment.localizedString,
            action: displayAlignmentSelector)

        let linkToRow = EditableTextRow(
            title: NSLocalizedString("Link To", comment: "Image link option title."),
            value: linkURL?.absoluteString ?? "",
            action: displayLinkTextfield)

        let sizeRow = EditableTextRow(
            title: NSLocalizedString("Size", comment: "Image size option title."),
            value: size.localizedString,
            action: displaySizeSelector)

        let altRow = EditableTextRow(
            title: NSLocalizedString("Alt Text", comment: "Image alt attribute option title."),
            value: alt ?? "",
            action: displayAltTextfield)

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: displaySettingsHeader,
                rows: [
                    alignmentRow,
                    linkToRow,
                    sizeRow,
                    altRow
                ],
                footerText: nil)
            ])
    }


    // MARK: - Actions

    private func displayAltTextfield(row: ImmuTableRow) {
        let editableRow = row as! EditableTextRow
        let hint = NSLocalizedString("Image Alt", comment: "Hint for image alt on image settings.")
        self.pushSettingsController(for: editableRow, hint: hint, settingsTextMode: .text) { value in
            self.alt = value
            self.tableView.reloadData()
        }
    }

    private func displayLinkTextfield(row: ImmuTableRow) {
        let editableRow = row as! EditableTextRow
        let hint = NSLocalizedString("Image Link", comment: "Hint for image link on image settings.")
        self.pushSettingsController(for: editableRow, hint: hint, settingsTextMode: .URL) { value in
            self.linkURL = URL(string: value)
            self.tableView.reloadData()
        }
    }

    func displayAlignmentSelector(row: ImmuTableRow) {

        let values: [ImageAttachment.Alignment] = [.left, .center, .right, .none]

        let titles = values.map { (value) in
            return value.localizedString
        }

        let currentValue = alignment

        let dict: [String: Any] = [
            SettingsSelectionDefaultValueKey: alignment,
            SettingsSelectionTitleKey: NSLocalizedString("Alignment", comment: "Title of the screen for choosing an image's alignment."),
            SettingsSelectionTitlesKey: titles,
            SettingsSelectionValuesKey: values,
            SettingsSelectionCurrentValueKey: currentValue
        ]

        guard let vc = SettingsSelectionViewController(dictionary: dict) else {
            return
        }

        vc.onItemSelected = { (status: Any) in
            if let newAlignment = status as? ImageAttachment.Alignment {
                self.alignment = newAlignment
            }
            vc.dismiss()
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func displaySizeSelector(row: ImmuTableRow) {
        let values: [ImageAttachment.Size] = [.thumbnail, .medium, .large, .full]

        let titles = values.map { (value) in
            return value.localizedString
        }

        let currentValue = size

        let dict: [String: Any] = [
            SettingsSelectionDefaultValueKey: size,
            SettingsSelectionTitleKey: NSLocalizedString("Image Size", comment: "Title of the screen for choosing an image's size."),
            SettingsSelectionTitlesKey: titles,
            SettingsSelectionValuesKey: values,
            SettingsSelectionCurrentValueKey: currentValue
        ]

        guard let vc = SettingsSelectionViewController(dictionary: dict) else {
            return
        }
        vc.onItemSelected = { (status: Any) in
            // do interesting work here... like updating the value of image meta.
            if let newSize = status as? ImageAttachment.Size {
                self.size = newSize
            }
            vc.dismiss()
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Helper methods

    @objc func handleCancelButtonTapped(sender: UIBarButtonItem) {
        onCancel?()
        dismiss(animated: true, completion: nil)
    }

    @objc func handleDoneButtonTapped(sender: UIBarButtonItem) {
        let checkedAlt = alt == "" ? nil : alt
        onUpdate?(alignment, size, linkURL, checkedAlt)
        dismiss(animated: true, completion: nil)
    }

    private func pushSettingsController(for row: EditableTextRow,
                                        hint: String? = nil,
                                        settingsTextMode: SettingsTextModes,
                                        onValueChanged: @escaping SettingsTextChanged) {
        let title = row.title
        let value = row.value
        let controller = SettingsTextViewController(text: value, placeholder: "\(title)...", hint: hint)

        controller.title = title
        controller.mode = settingsTextMode
        controller.onValueChanged = onValueChanged

        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ImageAttachment.Alignment {

    var localizedString: String {
        switch self {
        case .left: return NSLocalizedString("Left", comment: "Left alignment for an image. Should be the same as in core WP.")
        case .center: return NSLocalizedString("Center", comment: "Center alignment for an image. Should be the same as in core WP.")
        case .right: return NSLocalizedString("Right", comment: "Right alignment for an image. Should be the same as in core WP.")
        case .none: return NSLocalizedString("None", comment: "No alignment for an image (default). Should be the same as in core WP.")
        }
    }
}

extension ImageAttachment.Size {

    var localizedString: String {
        switch self {
        case .thumbnail: return NSLocalizedString("Thumbnail", comment: "Thumbnail image size. Should be the same as in core WP.")
        case .medium: return NSLocalizedString("Medium", comment: "Medium image size. Should be the same as in core WP.")
        case .large: return NSLocalizedString("Large", comment: "Large image size. Should be the same as in core WP.")
        case .none, .full: return NSLocalizedString("Full Size", comment: "Full size image. (default). Should be the same as in core WP.")
        }
    }
}
