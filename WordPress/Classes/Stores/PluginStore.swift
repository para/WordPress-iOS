import Foundation

enum PluginAction: FluxAction {
    case activate(id: String, site: SiteRef)
    case deactivate(id: String, site: SiteRef)
    case enableAutoupdates(id: String, site: SiteRef)
    case disableAutoupdates(id: String, site: SiteRef)
    case remove(id: String, site: SiteRef)
    case receivePlugins(site: SiteRef, plugins: SitePlugins)
    case receivePluginsFailed(site: SiteRef, error: Error)
}

class PluginStore: FluxStore {
    fileprivate var plugins = [SiteRef: SitePlugins]() {
        didSet {
            emitChange()
        }
    }
    fileprivate var fetching = [SiteRef: Bool]()
    fileprivate let accounts = AccountDatabase(context: ContextManager.sharedInstance().mainContext)
    var accountsListener: FluxListener?

    override init(dispatcher: FluxDispatcher = .global) {
        super.init(dispatcher: dispatcher)
        accountsListener = accounts.onChange { [weak self] in
            self?.invalidatePluginsForMissingAccounts()
        }
    }

    func removeListener(_ listener: FluxListener) {
        super.removeListener(listener)
        if listenerCount == 0 {
            // Remove plugins from memory if nothing is listening for changes
            plugins = [:]
        }
    }

    func getPlugins(site: SiteRef) -> SitePlugins? {
        if let sitePlugins = plugins[site] {
            return sitePlugins
        }
        fetchPlugins(site: site)
        return nil
    }

    func getPlugin(id: String, site: SiteRef) -> PluginState? {
        guard let sitePlugins = getPlugins(site: site) else {
            return nil
        }
        return sitePlugins.plugins.first(where: { $0.id == id })
    }

    override func onDispatch(_ action: FluxAction) {
        guard let pluginAction = action as? PluginAction else {
            return
        }
        switch pluginAction {
        case .activate(let pluginID, let site):
            activatePlugin(pluginID: pluginID, site: site)
        case .deactivate(let pluginID, let site):
            deactivatePlugin(pluginID: pluginID, site: site)
        case .enableAutoupdates(let pluginID, let site):
            enableAutoupdatesPlugin(pluginID: pluginID, site: site)
        case .disableAutoupdates(let pluginID, let site):
            disableAutoupdatesPlugin(pluginID: pluginID, site: site)
        case .remove(let pluginID, let site):
            removePlugin(pluginID: pluginID, site: site)
        case .receivePlugins(let site, let plugins):
            receivePlugins(site: site, plugins: plugins)
        case .receivePluginsFailed(let site, _):
            fetching[site] = false
        }
    }
}

private extension PluginStore {
    func activatePlugin(pluginID: String, site: SiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = true
        }
        remote(site: site)?.activatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = false
                })
        })
    }

    func deactivatePlugin(pluginID: String, site: SiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.active = false
        }
        remote(site: site)?.deactivatePlugin(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.active = true
                })
        })
    }

    func enableAutoupdatesPlugin(pluginID: String, site: SiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = true
        }
        remote(site: site)?.enableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = false
                })
        })
    }

    func disableAutoupdatesPlugin(pluginID: String, site: SiteRef) {
        modifyPlugin(id: pluginID, site: site) { (plugin) in
            plugin.autoupdate = false
        }
        remote(site: site)?.disableAutoupdates(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                self?.modifyPlugin(id: pluginID, site: site, change: { (plugin) in
                    plugin.autoupdate = true
                })
        })
    }

    func removePlugin(pluginID: String, site: SiteRef) {
        guard let sitePlugins = plugins[site],
            let index = sitePlugins.plugins.index(where: { $0.id == pluginID }) else {
                return
        }
        plugins[site]?.plugins.remove(at: index)
        emitChange()
        remote(site: site)?.remove(
            pluginID: pluginID,
            siteID: site.siteID,
            success: {},
            failure: { [weak self] _ in
                _ = self?.getPlugins(site: site)
        })
    }

    func modifyPlugin(id: String, site: SiteRef, change: (inout PluginState) -> Void) {
        guard let sitePlugins = plugins[site],
            let index = sitePlugins.plugins.index(where: { $0.id == id }) else {
                return
        }
        var plugin = sitePlugins.plugins[index]
        change(&plugin)
        plugins[site]?.plugins[index] = plugin
        emitChange()
    }

    func fetchPlugins(site: SiteRef) {
        guard !fetching[site, default: false],
            let remote = remote(site: site) else {
                return
        }
        fetching[site] = true
        remote.getPlugins(
            siteID: site.siteID,
            success: { [globalDispatcher] (plugins) in
                globalDispatcher.dispatch(PluginAction.receivePlugins(site: site, plugins: plugins))
            },
            failure: { [globalDispatcher] (error) in
                globalDispatcher.dispatch(PluginAction.receivePluginsFailed(site: site, error: error))
        })
    }

    func receivePlugins(site: SiteRef, plugins: SitePlugins) {
        self.plugins[site] = plugins
        fetching[site] = false
    }

    func receivePluginsFailed(site: SiteRef) {
        fetching[site] = false
    }

    func remote(site: SiteRef) -> PluginServiceRemote? {
        guard let token = accounts.account(id: site.accountID)?.token else {
            return nil
        }
        let api = WordPressComRestApi(oAuthToken: token, userAgent: WPUserAgent.wordPress())
        return PluginServiceRemote(wordPressComRestApi: api)
    }

    func invalidatePluginsForMissingAccounts() {
        let accountIDs = Set(accounts.all().map({ $0.id }))
        plugins
            .keys
            .filter({ !accountIDs.contains($0.accountID) })
            .forEach { (site) in
                plugins.removeValue(forKey: site)
            }
        fetching
            .keys
            .filter({ !accountIDs.contains($0.accountID) })
            .forEach { (site) in
                fetching.removeValue(forKey: site)
            }
    }
}
