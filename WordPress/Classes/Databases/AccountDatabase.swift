import Foundation

struct Account {
    var id: Int
    var uuid: String
    var username: String
    var token: String

    init(managed: WPAccount) {
        self.id = managed.userID as! Int
        self.uuid = managed.uuid
        self.username = managed.username
        self.token = managed.authToken
    }
}

private let currentAccountUUIDKey = "AccountDefaultDotcomUUID"
extension UserDefaults {
    @objc dynamic fileprivate var currentAccountUUID: String? {
        get {
            return string(forKey: currentAccountUUIDKey)
        }
        set {
            set(newValue, forKey: currentAccountUUIDKey)
        }
    }
}

class AccountDatabase: NSObject, FluxEmitter {
    fileprivate struct State {
        var current: Account?
        var secondary: [Account]
    }
    fileprivate var state: State {
        didSet {
            emitChange()
        }
    }

    fileprivate let context: NSManagedObjectContext
    fileprivate let defaults: UserDefaults
    fileprivate let controller: NSFetchedResultsController<WPAccount>
    let dispatcher = Dispatcher<Void>()

    deinit {
        defaults.removeObserver(self, forKeyPath: currentAccountUUIDKey)
    }

    init(context: NSManagedObjectContext, defaults: UserDefaults = .standard) {
        self.context = context
        self.defaults = defaults
        let request = NSFetchRequest<WPAccount>()
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        state = State(current: nil, secondary: [])
        super.init()

        defaults.addObserver(self, forKeyPath: currentAccountUUIDKey, options: [], context: nil)
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch {
            DDLogError("Error fetching accounts: \(error)")
        }
    }

    var current: Account? {
        return state.current
    }

    func account(id: Int) -> Account? {
        if current?.id == id {
            return current
        }
        return state.secondary.first(where: { $0.id == id })
    }

    func all() -> [Account] {
        return state.current.map({ [$0] }) ?? []
            + state.secondary
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let observedDefaults = object as? UserDefaults,
            observedDefaults == defaults,
            keyPath == currentAccountUUIDKey else {
                return
        }
        refreshModel()
    }

}

extension AccountDatabase: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshModel()
    }
}

private extension AccountDatabase {
    func refreshModel() {
        let accounts = controller.fetchedObjects
        let current = defaults.currentAccountUUID.flatMap({ (uuid) in
            return accounts?.first(where: { $0.uuid == uuid })
        })
        let secondary = accounts?.filter({ $0 != current }) ?? []
        state = State(current: current.map(Account.init(managed:)), secondary: secondary.map(Account.init(managed:)))
    }
}
