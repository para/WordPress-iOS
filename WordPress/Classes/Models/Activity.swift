import Foundation

/// Activity NSManagedObject
///
open class Activity: NSManagedObject {

    /// Properties
    ///
    @NSManaged open var activityID: NSNumber
    @NSManaged open var siteID: NSNumber
    @NSManaged open var type: String
    @NSManaged open var actionTrigger: String
    @NSManaged open var jetpackVersion: String
    @NSManaged open var action: String
    @NSManaged open var group: String
    @NSManaged open var name: String
    @NSManaged open var timestamp: Date

    /// Relations
    ///
    @NSManaged open var actor: ActivityActor
    @NSManaged open var objects: [String: ActivityObject]?

    func updateWithRemoteActivity(_ remoteActivity: RemoteActivity) {
        activityID = remoteActivity.activityID
        siteID = remoteActivity.siteID
        type = remoteActivity.type
        actionTrigger = remoteActivity.actionTrigger ?? ""
        jetpackVersion = remoteActivity.jetpackVersion ?? ""
        action = remoteActivity.action ?? ""
        group = remoteActivity.group ?? ""
        name = remoteActivity.name
        timestamp = remoteActivity.timestamp

        actor.updateWithRemoteActor(remoteActivity.actor)

        objects = remoteActivity.objects
    }

    func sectionIdentifierWithTimestamp() -> String {
        return timestamp.mediumString()
    }

}

public typealias ActivityObject = [String: String]
