import Foundation
import WordPressKit

struct PluginDirectoryService {
    static let iconAvailableNotification = Foundation.Notification.Name(rawValue: "PluginDirectoryServiceIconAvailable")
    static let iconCache = NSCache<NSString, NSURL>()
    static var requestsInProgress = Set<String>()

    let remote: PluginDirectoryServiceRemote

    func getPluginIcon(slug: String, download: Bool) -> URL? {
        if let cachedInfo = PluginDirectoryService.iconCache.object(forKey: slug as NSString) {
            return cachedInfo as URL
        }

        if download && !PluginDirectoryService.requestsInProgress.contains(slug) {
            fetchPluginIcon(slug: slug)
        }

        return nil
    }
}

private extension PluginDirectoryService {
    func fetchPluginIcon(slug: String) {
        PluginDirectoryService.requestsInProgress.insert(slug)
        remote.fetchPluginInfo(slug: slug, success: { (pluginInfo) in
            guard let icon = pluginInfo.icon else {
                return
            }
            PluginDirectoryService.iconCache.setObject(icon as NSURL, forKey: slug as NSString)
            NotificationCenter.default.post(name: PluginDirectoryService.iconAvailableNotification, object: slug)
            PluginDirectoryService.requestsInProgress.remove(slug)
        }, failure: { (error) in
            DDLogWarn("Could not fetch plugin info for \(slug): \(error)")
            PluginDirectoryService.requestsInProgress.remove(slug)
        })
    }
}
