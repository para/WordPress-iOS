import Foundation

/// Information about a plugin coming from the WordPress.org plugin directory.
///
struct PluginInfo {
    let slug: String
    let name: String
    let icon: URL?
}
