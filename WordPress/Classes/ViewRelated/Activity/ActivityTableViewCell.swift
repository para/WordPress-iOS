import Foundation
import WordPressShared.WPTableViewCell

open class ActivityTableViewCell: WPTableViewCell {

    /// MARK: - Overwritten Methods

    open override func awakeFromNib() {
        super.awakeFromNib()
        assert(gravatarImageView != nil)
        assert(detailsLabel != nil)
        assert(timestampLabel != nil)
    }

    /// MARK: - Public Methods

    open func configureCell(_ activity: Activity) {
        actor = activity.actor.displayName
        actorRole = activity.actor.userRole
        if let url = URL(string: activity.actor.avatarURL) {
            downloadGravatarWithURL(url)
        } else {
            gravatarImageView.image = placeholderImage
        }
        activityTitle = activity.type
        activityContent = activity.action
        timestamp = activity.timestamp.mediumStringWithTime()
        activityObjects = activity.objects
        refreshDetailsLabel()
        refreshTimestampLabel()
    }

    /// MARK: - Private Methods

    fileprivate func refreshDetailsLabel() {
        detailsLabel.attributedText = attributedDetailsText()
        layoutIfNeeded()
    }

    fileprivate func refreshTimestampLabel() {
        let style = Style.timestampStyle()
        let unwrappedTimestamp = timestamp ?? String()
        timestampLabel?.attributedText = NSAttributedString(string: unwrappedTimestamp, attributes: style)
    }


    // MARK: - Details Helpers
    fileprivate func attributedDetailsText() -> NSAttributedString {
        // Unwrap
        let unwrappedActor = actor ?? ""
        let unwrappedActorRole = actorRole ?? ""
        let unwrappedTitle = (activityTitle ?? NSLocalizedString("(No Title)", comment: "Empty Activity Title")).uppercased()
        let unwrappedContent = activityContent ?? ""
        let unwrappedObjects = activityObjects?.description ?? ""

        // Styles
        let detailsBoldStyle = Style.detailsBoldStyle()
        let detailsItalicsStyle = Style.detailsItalicsStyle()
        let detailsRegularStyle = Style.detailsRegularStyle()
        let detailsLightStyle = Style.timestampStyle()

        // Localize the format
        let details = NSLocalizedString("%1$@ (%2$@) - %3$@: %4$@ - %5$@", comment: "AUTHOR(authorRole) - ACTIVITY TITLE: ACTIVITY CONTENT - objects")

        // Arrange the Replacement Map
        let replacementMap  = [
            "%1$@": NSAttributedString(string: unwrappedActor, attributes: detailsBoldStyle),
            "%2$@": NSAttributedString(string: unwrappedActorRole, attributes: detailsRegularStyle),
            "%3$@": NSAttributedString(string: unwrappedTitle, attributes: detailsItalicsStyle),
            "%4$@": NSAttributedString(string: unwrappedContent, attributes: detailsRegularStyle),
            "%5$@": NSAttributedString(string: unwrappedObjects, attributes: detailsLightStyle)
        ]

        let attributedDetails = NSMutableAttributedString(string: details, attributes: detailsRegularStyle)

        for (key, attributedString) in replacementMap {
            let range = (attributedDetails.string as NSString).range(of: key)
            if range.location == NSNotFound {
                continue
            }

            attributedDetails.replaceCharacters(in: range, with: attributedString)
        }

        return attributedDetails
    }


    fileprivate func downloadGravatarWithURL(_ url: URL?) {
        if url == gravatarURL {
            return
        }

        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
    }

    /// Hijacking Comments style

    typealias Style = WPStyleGuide.Activity

    /// MARK: - Private Properties

    fileprivate var actor: String?
    fileprivate var actorRole: String?
    fileprivate var gravatarURL: URL?
    fileprivate var activityTitle: String?
    fileprivate var activityContent: String?
    fileprivate var activityObjects: [String: ActivityObject]?
    fileprivate var timestamp: String?

    /// MARK: - Private Calculated Properties

    fileprivate var placeholderImage: UIImage {
        return Style.gravatarPlaceholderImage()
    }

    /// MARK: - IBOutlets

    @IBOutlet fileprivate var gravatarImageView: CircularImageView!
    @IBOutlet fileprivate var detailsLabel: UILabel!
    @IBOutlet fileprivate var timestampLabel: UILabel!
}
