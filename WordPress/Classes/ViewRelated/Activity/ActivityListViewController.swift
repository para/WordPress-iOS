import Foundation
import CocoaLumberjack
import WordPressShared

/// Based on the PagesViewController, this is a dummy implementation to fetch and display activities

class ActivityListViewController: AbstractPostListViewController, UIViewControllerRestoration {

    fileprivate static let activitySectionHeaderHeight = CGFloat(24.0)
    fileprivate static let activityCellEstimatedRowHeight = CGFloat(47.0)
    fileprivate static let activityViewControllerRestorationKey = "ActivityViewControllerRestorationKey"
    fileprivate static let activityCellIdentifier = "ActivityCellIdentifier"
    fileprivate static let activityCellNibName = "ActivityTableViewCell"

    fileprivate lazy var sectionFooterSeparatorView: UIView = {
        let footer = UIView()
        footer.backgroundColor = WPStyleGuide.greyLighten20()
        return footer
    }()

    /// MARK: - GUI

    fileprivate let animatedBox = WPAnimatedBox()


    /// MARK: - Convenience constructors

    class func controllerWithBlog(_ blog: Blog) -> ActivityListViewController {

        let storyBoard = UIStoryboard(name: "Activity", bundle: Bundle.main)
        let controller = storyBoard.instantiateViewController(withIdentifier: "ActivityListViewController") as! ActivityListViewController

        controller.blog = blog
        controller.restorationClass = self

        return controller
    }

    /// MARK: - UIViewControllerRestoration

    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {

        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: activityViewControllerRestorationKey) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = try? context.existingObject(with: objectID) as! Blog else {
                return nil
        }

        return self.controllerWithBlog(restoredBlog)
    }

    /// MARK: - UIStateRestoring

    override func encodeRestorableState(with coder: NSCoder) {
        let objectString = blog?.objectID.uriRepresentation().absoluteString
        coder.encode(objectString, forKey: type(of: self).activityViewControllerRestorationKey)
        super.encodeRestorableState(with: coder)
    }


    //// MARK: Overwrite methods from AbstractPostViewController

    override func syncHelper(_ syncHelper: WPContentSyncHelper, syncContentWithUserInteraction userInteraction: Bool, success: ((_ hasMore: Bool) -> ())?, failure: ((_ error: NSError) -> ())?) {

        let activityService = ActivityService(managedObjectContext: managedObjectContext())

        activityService.syncActivitiesForBlog(blog, completion: { (completed) in
            if (completed) {
                success?(true)
            } else {
                failure?(NSError())
            }
        })
    }

    override func syncHelper(_ syncHelper: WPContentSyncHelper, syncMoreWithSuccess success: ((_ hasMore: Bool) -> Void)?, failure: ((_ error: NSError) -> Void)?) {
    }

    /// MARK: - UIViewController

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.refreshNoResultsView = { [weak self] noResultsView in
            self?.handleRefreshNoResultsView(noResultsView)
        }
        super.tableViewController = (segue.destination as! UITableViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Activities", comment: "Tile of the screen showing the list of activities for a blog.")
    }

    /// MARK: - Configuration

    override func configureNavbar() {
    }

    override func configureTableView() {
        tableView.accessibilityIdentifier = "ActivityTable"
        tableView.isAccessibilityElement = true
        tableView.estimatedRowHeight = type(of: self).activityCellEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        let bundle = Bundle.main

        // Register the cells
        let activityCellNib = UINib(nibName: type(of: self).activityCellNibName, bundle: bundle)
        tableView.register(activityCellNib, forCellReuseIdentifier: type(of: self).activityCellIdentifier)

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    override func configureSearchController() {
        super.configureSearchController()
        // Noop
    }

    override func configureAuthorFilter() {
        // Noop
    }

    // MARK: - Model Interaction

    /// Retrieves the activity object at the specified index path.
    ///
    fileprivate func activityAtIndexPath(_ indexPath: IndexPath) -> Activity {
        guard let activity = tableViewHandler.resultsController.object(at: indexPath) as? Activity else {
            fatalError("Expected an Activity object.")
        }
        return activity
    }

    /// MARK: - TableView Handler Delegate Methods

    override func entityName() -> String {
        return String(describing: Activity.self)
    }

    override func predicateForFetchRequest() -> NSPredicate {
        if let dotComID = blog.dotComID {
            return NSPredicate(format: "siteID = %@", dotComID)
        }
        return NSPredicate()
    }

    override func sortDescriptorsForFetchRequest() -> [NSSortDescriptor] {
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        return [sortDescriptor]
    }

    override func updateAndPerformFetchRequest() {
        assert(Thread.isMainThread, "ActivityListViewController Error: NSFetchedResultsController accessed in BG")

        let predicate = predicateForFetchRequest()
        let sortDescriptors = sortDescriptorsForFetchRequest()
        let fetchRequest = tableViewHandler.resultsController.fetchRequest


        // If not filtering by the oldestPostDate or searching, set the fetchLimit to the default number of posts.
        fetchRequest.fetchLimit = 20
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            try tableViewHandler.resultsController.performFetch()
        } catch {
            DDLogError("Error fetching posts after updating the fetch request predicate: \(error)")
        }
    }


    // MARK: - Table View Handling

    func sectionNameKeyPath() -> String {
        //let sortField = filterSettings.currentPostListFilter().sortField
        //return Page.sectionIdentifier(dateKeyPath: sortField.keyPath)
        return NSStringFromSelector(#selector(Activity.sectionIdentifierWithTimestamp))
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return type(of: self).activitySectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 {
            return WPDeviceIdentification.isRetina() ? 0.5 : 1.0
        }
        return 0.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView! {
        let sectionInfo = tableViewHandler.resultsController.sections?[section]
        let nibName = String(describing: ActivityListSectionHeaderView.self)
        let headerView = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)![0] as! ActivityListSectionHeaderView

        if let sectionInfo = sectionInfo {
            headerView.title = sectionInfo.name
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView! {
        if section == tableView.numberOfSections - 1 {
            return sectionFooterSeparatorView
        }
        return UIView(frame: CGRect.zero)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        if let windowlessCell = dequeCellForWindowlessLoadingIfNeeded(tableView) {
            return windowlessCell
        }

        let identifier = type(of: self).activityCellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        configureCell(cell, at: indexPath)

        return cell
    }

    override func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {

        guard let cell = cell as? ActivityTableViewCell else {
            preconditionFailure("The cell should be of class \(String(describing: ActivityTableViewCell.self))")
        }

        cell.accessoryType = .none
        let activity = activityAtIndexPath(indexPath)
        cell.configureCell(activity)
    }


    // MARK: - Refreshing noResultsView

    func handleRefreshNoResultsView(_ noResultsView: WPNoResultsView) {
        noResultsView.titleText = noResultsTitle()
        noResultsView.messageText = noResultsMessage()
        noResultsView.accessoryView = noResultsAccessoryView()
    }

    // MARK: - NoResultsView Customizer helpers

    fileprivate func noResultsAccessoryView() -> UIView {
        if syncHelper.isSyncing {
            animatedBox.animate(afterDelay: 0.1)
            return animatedBox
        }

        return UIImageView(image: UIImage(named: "theme-empty-results"))
    }

    fileprivate func noResultsTitle() -> String {
        return NSLocalizedString("No Activity", comment: "")
    }

    fileprivate func noResultsMessage() -> String {
        return NSLocalizedString("We still haven't recorded any activity for your site", comment: "")
    }
}
