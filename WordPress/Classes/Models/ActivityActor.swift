import Foundation

/// ActivityActor
///
open class ActivityActor: NSManagedObject {

    /// Properties
    ///
    @NSManaged open var displayName: String
    @NSManaged open var avatarURL: String
    @NSManaged open var userRole: String

    /// Relations
    ///
    @NSManaged open var activity: Activity

    func updateWithRemoteActor(_ remoteActor: RemoteActivityActor) {
        displayName = remoteActor.displayName ?? ""
        avatarURL = remoteActor.avatarURL ?? ""
        userRole = remoteActor.userRole ?? ""
    }
}
