import WordPressKit

protocol PluginPresenter: class {
    func present(plugin: PluginState, capabilities: SitePluginCapabilities)
}

class PluginListViewModel: FluxEmitter {
    enum State {
        case loading
        case ready(SitePlugins)
        case error(String)
    }

    let site: SiteRef
    let dispatcher = Dispatcher<Void>()
    private var state: State = .loading {
        didSet {
            dispatcher.dispatch()
        }
    }

    private let store: PluginStore
    private var listener: FluxListener?
    private var dispatchToken: FluxDispatcher.DispatchToken?

    init(site: SiteRef, store: PluginStore = StoreContainer.shared.plugin) {
        self.site = site
        self.store = store
        listener = store.onChange { [weak self] in
            self?.refreshPlugins()
        }
        dispatchToken = FluxDispatcher.global.register(callback: { [weak self] (action) in
            guard case PluginAction.receivePluginsFailed(let receivedSite, let error) = action,
                case receivedSite = site else {
                    return
            }
            self?.state = .error(error.localizedDescription)
        })
        refreshPlugins()
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        switch state {
        case .loading:
            return WPNoResultsView.Model(
                title: NSLocalizedString("Loading Plugins...", comment: "Text displayed while loading plugins for a site")
            )
        case .ready:
            return nil
        case .error:
            let appDelegate = WordPressAppDelegate.sharedInstance()
            if (appDelegate?.connectionAvailable)! {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("Oops", comment: ""),
                    message: NSLocalizedString("There was an error loading plugins", comment: ""),
                    buttonTitle: NSLocalizedString("Contact support", comment: "")
                )
            } else {
                return WPNoResultsView.Model(
                    title: NSLocalizedString("No connection", comment: ""),
                    message: NSLocalizedString("An active internet connection is required to view plugins", comment: "")
                )
            }
        }
    }

    func tableViewModel(presenter: PluginPresenter) -> ImmuTable {
        switch state {
        case .loading, .error:
            return .Empty
        case .ready(let sitePlugins):
            let rows = sitePlugins.plugins.map({ pluginState in
                return PluginListRow(
                    name: pluginState.name,
                    state: pluginState.stateDescription,
                    action: { [weak presenter] (row) in
                        presenter?.present(plugin: pluginState, capabilities: sitePlugins.capabilities)
                })
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }

    static var immutableRows: [ImmuTableRow.Type] {
        return [PluginListRow.self]
    }

    private func refreshPlugins() {
        guard let plugins = store.getPlugins(site: site) else {
            return
        }
        state = .ready(plugins)
    }
}
