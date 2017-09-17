import Foundation

@objc open class InsightsPostingActivityCollectionViewCell: UICollectionViewCell {

    // MARK: - Constants

    open static let didTouchPostActivityDateNotification = "DidTouchPostActivityDate"
    open static let reuseIdentifier = "PostActivityCollectionViewCell"

    // MARK: - Outlets

    @IBOutlet open weak var contributionGraph: WPStatsContributionGraph!

    // MARK: - Lifecycle Methods

    override open func awakeFromNib() {
        super.awakeFromNib()

        contributionGraph.delegate = self
    }
}

// MARK: - WPStatsContributionGraphDelegate methods

extension InsightsPostingActivityCollectionViewCell : WPStatsContributionGraphDelegate {
    public func numberOfGrades() -> UInt {
        return 5
    }

    public func color(forGrade grade: UInt) -> UIColor! {
        switch grade {
        case 0:
            return WPStyleGuide.statsPostActivityLevel1CellBackground()
        case 1:
            return WPStyleGuide.statsPostActivityLevel2CellBackground()
        case 2:
            return WPStyleGuide.statsPostActivityLevel3CellBackground()
        case 3:
            return WPStyleGuide.statsPostActivityLevel4CellBackground()
        case 4:
            return WPStyleGuide.statsPostActivityLevel5CellBackground()
        default:
            return WPStyleGuide.statsPostActivityLevel1CellBackground()
        }
    }

    public func dateTapped(_ dict: [AnyHashable : Any]!) {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: InsightsPostingActivityCollectionViewCell.didTouchPostActivityDateNotification),
                                        object: self,
                                        userInfo: dict)
    }
}
