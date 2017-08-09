import UIKit
import WordPressKit

class PluginListLoader: NSObject {
    let directoryService: PluginDirectoryService
    let pluginServiceRemote: PluginServiceRemote
    let siteID: Int
    var model: PluginListViewModel {
        didSet {
            modelUpdated?(model)
        }
    }
    var modelUpdated: ((PluginListViewModel) -> Void)? = nil

    init(siteID: Int, pluginServiceRemote: PluginServiceRemote, model: PluginListViewModel) {
        let directoryRemote = PluginDirectoryServiceRemote()
        directoryService = PluginDirectoryService(remote: directoryRemote)
        self.pluginServiceRemote = pluginServiceRemote
        self.siteID = siteID
        self.model = model
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PluginListLoader.iconAvailable(notification:)),
                                               name: PluginDirectoryService.iconAvailableNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func loadPlugins() {
        pluginServiceRemote.getPlugins(siteID: siteID, success: { [weak self] plugins in
            self?.loadIcons(plugins: plugins)
        }, failure: { [weak self] error in
            self?.model = .error(String(describing: error))
        })
    }

    private func loadIcons(plugins: [PluginState]) {
        let items = plugins.map({ state -> PluginListViewModel.Item in
            let icon = directoryService.getPluginIcon(slug: state.slug, download: true)
            return PluginListViewModel.Item(state: state, icon: icon)
        })
        model = .ready(items)
    }

    @objc private func iconAvailable(notification: Foundation.Notification) {
        guard let slug = notification.object as? String else {
            return
        }
        guard case .ready(let items) = model else {
            return
        }

        self.model = .ready(items.map({ item in
            if item.state.slug == slug {
                let icon = directoryService.getPluginIcon(slug: slug, download: false)
                return item.withIcon(icon)
            }
            return item
        }))
    }
}

class PluginListViewController: UITableViewController, ImmuTablePresenter {
    let siteID: Int
    let loader: PluginListLoader

    fileprivate lazy var handler: ImmuTableViewHandler = {
        return ImmuTableViewHandler(takeOver: self)
    }()

    fileprivate var viewModel: PluginListViewModel = .loading {
        didSet {
            handler.viewModel = viewModel.tableViewModelWithPresenter(self)
            updateNoResults()
        }
    }

    fileprivate let noResultsView = WPNoResultsView()

    init(siteID: Int, service: PluginServiceRemote) {
        self.siteID = siteID
        loader = PluginListLoader(siteID: siteID, pluginServiceRemote: service, model: viewModel)
        super.init(style: .grouped)
        title = NSLocalizedString("Plugins", comment: "Title for the plugin manager")
        noResultsView.delegate = self
        loader.modelUpdated = { [weak self] model in
            self?.viewModel = model
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init?(blog: Blog) {
        precondition(blog.dotComID != nil)
        guard let api = blog.wordPressComRestApi(),
            let service = PluginServiceRemote(wordPressComRestApi: api) else {
                return nil
        }

        self.init(siteID: Int(blog.dotComID!), service: service)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows([PluginListRow.self], tableView: tableView)
        handler.viewModel = viewModel.tableViewModelWithPresenter(self)
        updateNoResults()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        loader.loadPlugins()
    }

    func updateNoResults() {
        if let noResultsViewModel = viewModel.noResultsViewModel {
            showNoResults(noResultsViewModel)
        } else {
            hideNoResults()
        }
    }

    func showNoResults(_ viewModel: WPNoResultsView.Model) {
        noResultsView.bindViewModel(viewModel)
        if noResultsView.isDescendant(of: tableView) {
            noResultsView.centerInSuperview()
        } else {
            tableView.addSubview(withFadeAnimation: noResultsView)
        }
    }

    func hideNoResults() {
        noResultsView.removeFromSuperview()
    }
}

// MARK: - WPNoResultsViewDelegate

extension PluginListViewController: WPNoResultsViewDelegate {
    func didTap(_ noResultsView: WPNoResultsView!) {
        let supportVC = SupportViewController()
        supportVC.showFromTabBar()
    }
}
