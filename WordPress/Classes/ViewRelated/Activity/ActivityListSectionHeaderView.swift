import UIKit
import WordPressShared

class ActivityListSectionHeaderView: UIView {

    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        assert(titleLabel != nil)
        applyStyles()
    }

    fileprivate func applyStyles() {
        WPStyleGuide.applySectionHeaderTitleStyle(titleLabel)
        backgroundColor = titleLabel.backgroundColor
    }

    @IBOutlet fileprivate var titleLabel: UILabel!

}
