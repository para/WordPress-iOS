import Foundation
import XCTest
@testable import WordPressKit

class ActivityServiceRemoteTests: RemoteTestCase, RESTTestable {

    /// MARK: - Constants

    let siteID   = 321

    let getActivitySuccessMockFilename = "activity-log-success.json"
    let getActivityBadJsonFailureMockFilename = "activity-log-bad-json-failure.json"
    let getActivityAuthFailureMockFilename = "activity-log-auth-failure.json"

    /// MARK: - Properties

    var siteActivityEndpoint: String { return "sites/\(siteID)/activity" }
    var remote: ActivityServiceRemote!

    /// MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = ActivityServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    /// MARK: - Get Activity Tests

    func testGetActivitySucceeds() {
        let expect = expectation(description: "Get activity for site success")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivitySuccessMockFilename, contentType: .ApplicationJSON)
        remote.getActivityForSite(siteID, success: { activities in
            XCTAssertEqual(activities.count, 20, "The activity count should be 20")
            expect.fulfill()
        }) { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithBadAuthFails() {
        let expect = expectation(description: "Get plans with bad auth failure")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivityAuthFailureMockFilename, contentType: .ApplicationJSON, status: 403)
        remote.getActivityForSite(siteID, success: { activities in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            let error = error as NSError
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.authorizationRequired.rawValue, "The error code should be 2 - authorization_required")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetActivityWithBadJsonFails() {
        let expect = expectation(description: "Get plans with invalid json response failure")

        stubRemoteResponse(siteActivityEndpoint, filename: getActivityBadJsonFailureMockFilename, contentType: .ApplicationJSON, status: 200)
        remote.getActivityForSite(siteID, success: { sitePlans in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        }, failure: { error in
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
