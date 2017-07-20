import Foundation
import WordPressShared
import CocoaLumberjack

public class ActivityServiceRemote: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    public func getActivityForSite(_ siteID: Int, success: @escaping ([RemoteActivity]) -> Void, failure: @escaping (Error) -> Void) {
        let endpoint = "sites/\(siteID)/activity"
        let path = self.path(forEndpoint: endpoint, with: .version_1_1)
        let locale = WordPressComLanguageDatabase().deviceLanguage.slug
        let parameters = ["locale": locale, "number": "1000"]

        wordPressComRestApi.GET(path!,
                                parameters: parameters as [String : AnyObject]?,
                                success: {
                                    response, _ in
                                    do {
                                        try success(mapActivitiesResponse(response))
                                    } catch {
                                        DDLogError("Error parsing activity response for site \(siteID)")
                                        DDLogError("\(error)")
                                        DDLogDebug("Full response: \(response)")
                                        failure(error)
                                    }
        }, failure: {
            error, _ in
            failure(error)
        })
    }

}

private func mapActivitiesResponse(_ response: AnyObject) throws -> ([RemoteActivity]) {

    guard let json = response as? [String: AnyObject],
        let activitiesJson = json["activities"] as? [[String: AnyObject]] else {
            throw ActivityServiceRemote.ResponseError.decodingFailure
    }

    let activities = activitiesJson.map { activityJson -> RemoteActivity in
        return RemoteActivity(dictionary: activityJson as NSDictionary)
    }
    
    return activities
}

