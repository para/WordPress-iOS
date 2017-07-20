import Foundation
import CocoaLumberjack
import WordPressKit

/// Service to sync and store a site's activities
///
open class ActivityService: LocalCoreDataService {

    /// Fetches the activities for a blog and stores them locally
    ///
    func syncActivitiesForBlog(_ blog: Blog, completion: @escaping (Bool) -> Void) {
        guard let remote = remoteForBlog(blog), let dotComID = blog.dotComID else {
            return
        }

        remote.getActivityForSite(Int(dotComID), success: { remoteActivities in
            self.mergeActivities(remoteActivities, forSite: dotComID, success: { activities in
                completion(true)
            }, failure: { error in
                completion(false)
            })
        }, failure: { error in
            completion(false)
        })
    }
}

/// Private methods
///
extension ActivityService {

    /// Merges the retrieved activities with the ones alraedy stored locally for the site
    ///
    fileprivate func mergeActivities(_ activities: [RemoteActivity], forSite siteID: NSNumber, success: @escaping ([Activity]) -> Void, failure: @escaping (Error) -> Void) {

        for remoteActivity in activities {
            if let existingActivity = activityForSite(siteID, activityID: remoteActivity.activityID) {
                updateActivity(existingActivity, withRemoteActivity: remoteActivity)
            } else {
                createActivityFromRemoteActivity(remoteActivity)
            }
        }
        ContextManager.sharedInstance().save(managedObjectContext)
    }

    /// Retrieves an Activity from Core Data, with the specified ID.
    ///
    func activityForSite(_ siteID: NSNumber, activityID: NSNumber) -> Activity? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Activity.entityName)
        request.predicate = NSPredicate(format: "siteID = %@ AND activityID = %@ ",
                                        siteID,
                                        activityID)
        request.fetchLimit = 1

        let results = (try? managedObjectContext.fetch(request) as! [Activity]) ?? []
        return results.first
    }

    /// Updates a CoreData activity with a remote one
    ///
    func updateActivity(_ activity: Activity, withRemoteActivity remoteActivity: RemoteActivity) {
        activity.updateWithRemoteActivity(remoteActivity)
    }

    /// Creates a new CoreData activity from a remote one
    ///
    func createActivityFromRemoteActivity(_ remoteActivity: RemoteActivity) {
        let activity = NSEntityDescription.insertNewObject(forEntityName: Activity.entityName,
                                                           into: managedObjectContext) as! Activity
        let actor = NSEntityDescription.insertNewObject(forEntityName: ActivityActor.entityName,
                                                        into: managedObjectContext) as! ActivityActor
        activity.actor = actor
        actor.activity = activity
        activity.updateWithRemoteActivity(remoteActivity)
    }

    /// Returns the remote to use with the service.
    ///
    fileprivate func remoteForBlog(_ blog: Blog) -> ActivityServiceRemote? {
        guard let api = blog.wordPressComRestApi() else {
            return nil
        }
        return ActivityServiceRemote(wordPressComRestApi: api)
    }
}
