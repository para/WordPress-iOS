enum PluginListViewModel {
    case loading
    case ready([Item])
    case error(String)

    struct Item {
        let state: PluginState
        let icon: URL?

        func withIcon(_ icon: URL?) -> Item {
            return Item(state: state, icon: icon)
        }
    }

    var noResultsViewModel: WPNoResultsView.Model? {
        switch self {
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

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter?) -> ImmuTable {
        switch self {
        case .loading, .error:
            return .Empty
        case .ready(let items):
            let rows = items.map({ item in
                return PluginListRow(name: item.state.name, state: item.state.stateDescription, iconURL: item.icon)
            })
            return ImmuTable(sections: [
                ImmuTableSection(rows: rows)
                ])
        }
    }
}
