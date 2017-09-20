import Foundation

@objc open class InsightsPostingActivityCollectionViewCell: UICollectionViewCell {

    // MARK: - Constants

    open static let didTouchPostActivityDateNotification = "DidTouchPostActivityDate"
    open static let reuseIdentifier = "PostActivityCollectionViewCell"

    // MARK: - Outlets

    @IBOutlet open weak var contributionGraph: WPStatsContributionGraph2!

    // MARK: - Lifecycle Methods

    override open func awakeFromNib() {
        super.awakeFromNib()

        contributionGraph.delegate = self
    }
}

// MARK: - WPStatsContributionGraphDelegate methods

extension InsightsPostingActivityCollectionViewCell : WPStatsContributionGraphDelegate2 {
    public func dateTapped(date: Date, contributions: Int) {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: InsightsPostingActivityCollectionViewCell.didTouchPostActivityDateNotification),
                                        object: self,
                                        userInfo: ["date": date, "contributions": String(contributions)])
    }
}
