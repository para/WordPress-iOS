import Foundation

/// Information about a plugin coming from the WordPress.org plugin directory.
///
public struct PluginInfo {
    public let slug: String
    public let name: String
    public let icon: URL?
}
