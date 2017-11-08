import XCTest
@testable import WordPress
@testable import WordPressKit

class MockPluginServiceRemote: PluginServiceRemote {
    var plugins: SitePlugins
    var error: Error?
    var getPluginsCalledCount = 0

    init(plugins: SitePlugins, error: Error?) {
        self.plugins = plugins
        self.error = error
        super.init()
    }

    override func getPlugins(siteID: Int, success: @escaping (SitePlugins) -> Void, failure: @escaping (Error) -> Void) {
        getPluginsCalledCount += 1
        if let error = error {
            failure(error)
        } else {
            success(plugins)
        }
    }

    override func activatePlugin(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let error = error {
            failure(error)
            return
        }
        let index = plugins.plugins.index(where: { $0.id == pluginID })!
        plugins.plugins[index].active = true
        success()
    }

    override func deactivatePlugin(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let error = error {
            failure(error)
            return
        }
        let index = plugins.plugins.index(where: { $0.id == pluginID })!
        plugins.plugins[index].active = false
        success()
    }

    override func enableAutoupdates(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let error = error {
            failure(error)
            return
        }
        let index = plugins.plugins.index(where: { $0.id == pluginID })!
        plugins.plugins[index].autoupdate = true
        success()
    }

    override func disableAutoupdates(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let error = error {
            failure(error)
            return
        }
        let index = plugins.plugins.index(where: { $0.id == pluginID })!
        plugins.plugins[index].autoupdate = false
        success()
    }

    override func remove(pluginID: String, siteID: Int, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        if let error = error {
            failure(error)
            return
        }
        let index = plugins.plugins.index(where: { $0.id == pluginID })!
        plugins.plugins.remove(at: index)
        success()
    }
}

class PluginStoreTests: XCTestCase {
    let testDispatcher = FluxDispatcher()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetPluginsTriggersFetch() {
        let siteID = 123
        let akismet = PluginState(id: "akismet/akismet", slug: "akismet", active: true, name: "Akismet Anti-Spam", version: "4.0", autoupdate: true, url: URL(string: "https://akismet.com/"))
        let plugins = SitePlugins(plugins: [akismet], capabilities: SitePluginCapabilities(modify: true, autoupdate: true))
        let remote = MockPluginServiceRemote(plugins: plugins, error: nil)
        let store = PluginStore(dispatcher: testDispatcher)
        let expectation = XCTestExpectation(description: "Store changed")
        let listener = store.onChange {
            expectation.fulfill()
        }
        store._testingRemote = remote
        var result = store.getPlugins(siteID: siteID)
        XCTAssertNil(result)
        XCTAssertEqual(remote.getPluginsCalledCount, 1)

        wait(for: [expectation], timeout: 4)
        listener.stopListening()

        result = store.getPlugins(siteID: siteID)
        XCTAssertNotNil(result)
        XCTAssertEqual(remote.getPluginsCalledCount, 1)

    }
}
