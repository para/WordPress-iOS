import Foundation
import WordPressShared

/// This class groups all of the styles used by all of the ActivityListViewController.
///
extension WPStyleGuide {
    public struct Activity {

        /// MARK: - Public Properties

        public static func gravatarPlaceholderImage() -> UIImage {
            return gravatar
        }

        public static func separatorsColor() -> UIColor {
            return WPStyleGuide.readGrey()
        }

        public static func detailsRegularStyle() -> [String : AnyObject] {
            return  [NSParagraphStyleAttributeName: titleParagraph,
                     NSFontAttributeName: titleRegularFont,
                     NSForegroundColorAttributeName: WPStyleGuide.littleEddieGrey()]
        }

        public static func detailsItalicsStyle() -> [String : AnyObject] {
            return [NSParagraphStyleAttributeName: titleParagraph,
                    NSFontAttributeName: titleItalicsFont,
                    NSForegroundColorAttributeName: WPStyleGuide.littleEddieGrey()]
        }

        public static func detailsBoldStyle() -> [String : AnyObject] {
            return [NSParagraphStyleAttributeName: titleParagraph,
                    NSFontAttributeName: titleBoldFont,
                    NSForegroundColorAttributeName: WPStyleGuide.littleEddieGrey()]
        }

        public static func timestampStyle() -> [String: AnyObject] {
            return  [NSFontAttributeName: timestampFont,
                     NSForegroundColorAttributeName: WPStyleGuide.allTAllShadeGrey()]
        }

        public static func backgroundColor() -> UIColor {
            return UIColor.white
        }

        // MARK: - Private Properties
        //
        fileprivate static let gravatar = UIImage(named: "gravatar")!

        private static var timestampFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.caption1)
        }

        private static var titleRegularFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote)
        }

        private static var titleBoldFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, fontWeight: UIFontWeightSemibold)
        }

        private static var titleItalicsFont: UIFont {
            return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitItalic)
        }

        private static var titleLineSize: CGFloat {
            return WPStyleGuide.fontSizeForTextStyle(.footnote) * 1.3
        }

        private static var titleParagraph: NSMutableParagraphStyle {
            return NSMutableParagraphStyle(minLineHeight: titleLineSize,
                                           maxLineHeight: titleLineSize,
                                           lineBreakMode: .byTruncatingTail,
                                           alignment: .natural)
        }
    }
}
