import Foundation

public struct RemoteActivity {
    public let activityID: NSNumber
    public let siteID: NSNumber
    public let type: String
    public let actionTrigger: String?
    public let jetpackVersion: String?
    public let action: String?
    public let group: String?
    public let name: String
    public let actor: RemoteActivityActor
    public let objects: [String: RemoteActivityObject]
    public let timestamp: Date

    init(dictionary: NSDictionary) {
        activityID = dictionary.number(forKey: "ts_utc")
        siteID = dictionary.number(forKey: "blog_id")
        type = dictionary.string(forKey: "type")
        actionTrigger = dictionary.string(forKey: "action_trigger")
        jetpackVersion = dictionary.string(forKey: "jetpack_version")
        action = dictionary.string(forKey: "action")
        group = dictionary.string(forKey: "group")
        name = dictionary.string(forKey: "name")
        if let actorData = dictionary.value(forKey: "actor") as? NSDictionary {
            actor = RemoteActivityActor.init(dictionary: actorData)
        } else {
            actor = RemoteActivityActor.init(dictionary: [:])
        }
        if let objectsData = dictionary.value(forKey: "object") as? [String: RemoteActivityObject] {
            objects = objectsData
        } else {
            objects = [:]
        }
        let milliseconds = dictionary.number(forKey: "ts_utc").intValue
        timestamp = Date.init(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

public struct RemoteActivityActor {
    public let displayName: String?
    public let avatarURL: String?
    public let userRole: String?

    init(dictionary: NSDictionary) {
        displayName = dictionary.string(forKey: "display_name")
        avatarURL = dictionary.string(forKey: "avatar_url")
        userRole = dictionary.string(forKey: "translated_role")
    }
}

public typealias RemoteActivityObject = [String: String]
