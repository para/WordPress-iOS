import Gridicons

struct PluginListRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(WPTableViewCellSubtitle.self)
    static let customHeight: Float? = 64

    let name: String
    let state: String
    let iconURL: URL?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        WPStyleGuide.configureTableViewSmallSubtitleCell(cell)
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = state
        cell.selectionStyle = .none
        let placeholderIcon = Gridicon.iconOfType(.plugins)
        if let iconURL = iconURL {
            cell.imageView?.setImageWith(iconURL, placeholderImage: placeholderIcon)
        } else {
            cell.imageView?.image = placeholderIcon
        }
    }
}
