import Foundation

class PortfolioListViewController: AbstractPostListViewController {

    private enum Constants {
        // Storyboard
        static let storyboardName = "Portfolio"
        static let controllerID = "PortfolioListViewController"
        // UIViewControllerRestoration
        static let restorationKey = "PortfolioListViewControllerRestorationKey"
        // Table View configuration
        static let tableAccessibilityID = "PortfolioTable"
        static let tableEstimatedRowHeight = CGFloat(60)
        static let tableSectionHeaderHeight = CGFloat(24)
        static let tableLastSectionFooterHeight = CGFloat(0.5)
        static let projectCellID = "ProjectCellIdentifier"
        static let projectCellNibName = "ProjectTableViewCell"
        static let restoreProjectCellID = "RestoreProjectCellIdentifier"
        static let restoreProjectCellNibName = "RestoreProjectTableViewCell"
    }

    // MARK: - Convenience constructors

    @objc class func controller(withBlog blog: Blog) -> PortfolioListViewController {
        let storyBoard = UIStoryboard(name: Constants.storyboardName, bundle: .main)
        let controller = storyBoard.instantiateViewController(withIdentifier: Constants.controllerID) as! PortfolioListViewController

        controller.blog = blog
        controller.restorationClass = self

        return controller
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Portfolio", comment: "Tile of the screen showing the list of portfolio projects for a blog.")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let embeddedTableVC = segue.destination as? UITableViewController {
            super.tableViewController = embeddedTableVC
        }
    }

    // MARK: - Configuration

    override func configureTableView() {
        // Configure table
        tableView.accessibilityIdentifier = Constants.tableAccessibilityID
        tableView.isAccessibilityElement = true
        tableView.estimatedRowHeight = Constants.tableEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        // Register cells
        let projectCellNib = UINib(nibName: Constants.projectCellNibName, bundle: .main)
        tableView.register(projectCellNib, forCellReuseIdentifier: Constants.projectCellID)

        let restoreProjectCellNib = UINib(nibName: Constants.restoreProjectCellNibName, bundle: .main)
        tableView.register(restoreProjectCellNib, forCellReuseIdentifier: Constants.restoreProjectCellID)
    }

    // MARK: - Sync Methods

    override func postTypeToSync() -> PostServiceType {
        return .portfolio
    }

    // MARK: - Model Interaction

    private func projectAtIndexPath(_ indexPath: IndexPath) -> PortfolioProject {
        guard let project = tableViewHandler.resultsController.object(at: indexPath) as? PortfolioProject else {
            fatalError("Expected a PortfolioProject object.")
        }

        return project
    }

    // MARK: - Table View Handler Delegate Methods

    override func entityName() -> String {
        return PortfolioProject.entityName()
    }

    override func predicateForFetchRequest() -> NSPredicate {
        var predicates = [NSPredicate]()

        if let blog = blog {
            let basePredicate = NSPredicate(format: "blog = %@ && revision = nil", blog)
            predicates.append(basePredicate)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    // MARK: - Table View Handling

    func sectionNameKeyPath() -> String {
        let sortField = filterSettings.currentPostListFilter().sortField
        return PortfolioProject.sectionIdentifier(dateKeyPath: sortField.keyPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableSectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 {
            return Constants.tableLastSectionFooterHeight
        }

        return 0.0
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let windowlessCell = dequeCellForWindowlessLoadingIfNeeded(tableView) {
            return windowlessCell
        }

        let project = projectAtIndexPath(indexPath)
        let cellID = cellIdentifier(forProject: project)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)

        configureCell(cell, at: indexPath)

        return cell
    }

    override func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // TODO: finish here
    }

    private func cellIdentifier(forProject project: PortfolioProject) -> String {
        if recentlyTrashedPostObjectIDs.contains(project.objectID) == true && filterSettings.currentPostListFilter().filterType != .trashed {
            return Constants.restoreProjectCellID
        } else {
            return Constants.projectCellID
        }
    }
}

// MARK: - UIViewControllerRestoration

extension PortfolioListViewController: UIViewControllerRestoration {
    class func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {

        let context = ContextManager.sharedInstance().mainContext

        guard let blogID = coder.decodeObject(forKey: Constants.restorationKey) as? String,
            let objectURL = URL(string: blogID),
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: objectURL),
            let restoredBlog = (try? context.existingObject(with: objectID)) as? Blog
        else {
            return nil
        }

        return controller(withBlog: restoredBlog)
    }

    override func encodeRestorableState(with coder: NSCoder) {
        let objectString = blog?.objectID.uriRepresentation().absoluteString
        coder.encode(objectString, forKey: Constants.restorationKey)
        super.encodeRestorableState(with: coder)
    }
}
