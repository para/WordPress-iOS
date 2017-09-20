import Foundation
import WordPressKit

@objc public protocol WPStatsContributionGraphDelegate2 {
    /// Called when a specific date is tapped within the graph.
    ///
    /// - Parameter dict: A Dictionary that contains the date and number of posts on that day.
    ///
    @objc func dateTapped(date: Date, contributions: Int)
}

/// Custom view subclass that displays contribution activity over a
/// specified month.
///
@objc open class WPStatsContributionGraph2: UIView {

    // MARK: - Private Properties

    fileprivate struct Constants {
        static let defaultGradeCount = 5
        static let defaultGradeMinimumCutoff: [Int] = [0, 1, 3, 6, 8]
        static let defaultCellSize = CGFloat(12.0)
        static let defaultCellSpacing = CGFloat(3.0)
        static let clearPostActivityDateNotification = "ClearPostActivityDate"
    }

    // MARK: - Public Properties

    open var delegate: WPStatsContributionGraphDelegate2? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Height and width of each cell.
    ///
    open var cellSize = Constants.defaultCellSize {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Horizontal and vertical spacing between each cell.
    ///
    open var cellSpacing = Constants.defaultCellSpacing {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Date containing the month that should be displayed.
    ///
    open var monthForGraph: Date = Date() {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Values used to populate this graph.
    ///
    open var graphData: StatsStreak? {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Private Properties

    fileprivate var gradeCount = Constants.defaultGradeCount
    fileprivate var gradeMinimumCutoff: [Int] = Constants.defaultGradeMinimumCutoff
    fileprivate var colors: [UIColor] = []
    fileprivate var dateButtons: [DateCellButton] = []

    // MARK: - Initializers

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    deinit {
        stopListeningToNotifications()
    }

    // MARK: - Setup Helpers

    fileprivate func startListeningToNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(Constants.clearPostActivityDateNotification),
                                               object: nil,
                                               queue: OperationQueue.main) { (notification) in
                                                self.clearAllButtons()
        }
    }

    fileprivate func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func setupView() {
        startListeningToNotifications()
        setupGraphColors()

        // Make sure this is re-drawn on rotation events
        layer.needsDisplayOnBoundsChange = true
    }

    fileprivate func setupGraphColors() {
        self.isOpaque = false

        colors.append(WPStyleGuide.statsPostActivityLevel1CellBackground())
        colors.append(WPStyleGuide.statsPostActivityLevel2CellBackground())
        colors.append(WPStyleGuide.statsPostActivityLevel3CellBackground())
        colors.append(WPStyleGuide.statsPostActivityLevel4CellBackground())
        colors.append(WPStyleGuide.statsPostActivityLevel5CellBackground())
    }

    // MARK: - View Methods

    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let graphData = graphData, graphData.items != nil else {
            return
        }

        // Cleanup & Setup
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        subviews.forEach({ $0.removeFromSuperview() })
        dateButtons.removeAll()
        var columnCount = 0
        
        var calendar = Calendar.init(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        let coreComponents = [.day, .month, .year] as Set<Calendar.Component>

        var monthComponents = calendar.dateComponents(coreComponents, from: monthForGraph)
        monthComponents.day = 1
        let firstDayThisMonth = calendar.date(from: monthComponents)!
        let firstDayNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: firstDayThisMonth)!
        var currentDate = firstDayThisMonth

        while currentDate < firstDayNextMonth {
            var grade = 0
            var contributions = 0
            dateButtons.removeAll()

            // These two calls will ensure the proper values for weekday & week of month are returned
            // since we are starting the week on a Monday instead of a Sunday
            let weekday = calendar.ordinality(of: .weekday, in: .weekOfMonth, for: currentDate)!
            let weekOfMonth = calendar.ordinality(of: .weekOfMonth, in: .month, for: currentDate)!

            // Tally up the contributions for this day
            for item in graphData.items {
                if item.date != nil {
                    let gregorian = Calendar.init(identifier: .gregorian)
                    let components1 = [.day, .month, .year] as Set<Calendar.Component>
                    let tempComps1 = gregorian.dateComponents(components1, from: item.date)
                    let tempComps2 = gregorian.dateComponents(components1, from: currentDate)

                    if tempComps1 == tempComps2 {
                        contributions += 1
                    }
                }
            }

            // Get the grade from the minimum cutoffs array
            for i in 0..<gradeCount {
                if gradeMinimumCutoff[i] <= contributions {
                    grade = i
                }
            }

            colors[grade].setFill()

            let column = (CGFloat(weekOfMonth - 1)) * (self.cellSize + self.cellSpacing)
            let row = (CGFloat(weekday - 1)) * (self.cellSize + self.cellSpacing)
            let cellRect = CGRect(x: column, y: row, width: cellSize, height: cellSize)
            context.fill(cellRect)

            //Add a button
            let dateButton = DateCellButton(frame: cellRect)
            dateButton.highlightedTintColor = WPStyleGuide.statsLighterOrange()
            dateButton.selectedTintColor = WPStyleGuide.statsDarkerOrange()
            dateButton.normalTintColor = UIColor.clear
            dateButton.disabledTintColor = UIColor.clear
            dateButton.date = currentDate
            dateButton.contributions = contributions
            dateButton.addTarget(self, action: #selector(daySelected), for: .touchUpInside)
            self.addSubview(dateButton)
            dateButtons.append(dateButton)

            // Prepare for next graph cell
            columnCount = (columnCount < weekOfMonth) ? weekOfMonth : columnCount
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Draw the abbreviated month name below the graph
        let x_value = (((cellSize * CGFloat(columnCount)) / 2.0) - (cellSize / 1.1))
        let y_value = cellSize * 9.0
        let monthLabelRect = CGRect(x: x_value, y: y_value, width: (cellSize * 3.0), height: (cellSize * 1.2))
        let textColor = WPStyleGuide.statsDarkGray()

        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMM")
        let monthName = df.string(from: monthForGraph)

        let ps: NSMutableParagraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        ps.lineBreakMode = .byClipping
        ps.alignment = .center

        let attrs: [String: Any] = [NSFontAttributeName: WPFontManager.systemRegularFont(ofSize:14.0),
                                    NSForegroundColorAttributeName: textColor ?? UIColor.darkGray,
                                    NSParagraphStyleAttributeName: ps]
        monthName.uppercased().draw(in: monthLabelRect, withAttributes: attrs)

        // Wrap Up
        context.restoreGState()
    }

    // MARK: - Private Helpers

    @objc fileprivate func daySelected(_ sender: DateCellButton) {
        NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Constants.clearPostActivityDateNotification), object: self)
        sender.isSelected = !sender.isSelected

        if let contributionDate = sender.date {
            delegate?.dateTapped(date: contributionDate, contributions: sender.contributions)
        }
    }

    fileprivate func clearAllButtons() {
        for button in dateButtons {
            button.isSelected = false
        }
    }
}

// MARK: - DateCellButton

/// UIButton used for individual date cells within the contribution graph
///
open class DateCellButton: UIButton {

    /// Date this button represents
    ///
    open var date: Date?

    /// Number of user contributions on this button's day
    ///
    open var contributions: Int = 0


    /// Tint Color to be applied whenever the button is selected
    ///
    var selectedTintColor: UIColor? {
        didSet {
            updateBackgroundColor()
        }
    }

    /// Tint Color to be applied whenever the button is disabled
    ///
    var disabledTintColor: UIColor? {
        didSet {
            updateBackgroundColor()
        }
    }

    /// Tint Color to be applied whenever the button is highlighted
    ///
    var highlightedTintColor: UIColor? {
        didSet {
            updateBackgroundColor()
        }
    }

    /// Tint Color to be applied to the "Normal" State
    ///
    var normalTintColor: UIColor? {
        didSet {
            updateBackgroundColor()
        }
    }


    /// Enabled Listener: Update Tint Colors, as needed
    ///
    open override var isEnabled: Bool {
        didSet {
            updateBackgroundColor()
        }
    }


    /// Highlight Listener: Update Tint Colors, as needed
    ///
    open override var isHighlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }


    /// Selection Listener: Update Tint Colors, as needed
    ///
    open override var isSelected: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    // MARK: - Lifecycle

    public convenience init() {
        let defaultFrame = CGRect(x: 0,
                                  y: 0,
                                  width: WPStatsContributionGraph2.Constants.defaultCellSize,
                                  height: WPStatsContributionGraph2.Constants.defaultCellSize)
        self.init(frame: defaultFrame)
    }

    open override var intrinsicContentSize: CGSize {
        return frame.size
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }


    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    fileprivate func updateBackgroundColor() {
        if state.contains(.disabled) {
            backgroundColor = disabledTintColor
            return
        }

        if state.contains(.highlighted) {
            backgroundColor = highlightedTintColor
            return
        }

        if state.contains(.selected) {
            backgroundColor = selectedTintColor
            return
        }

        backgroundColor = normalTintColor
    }
}
