import Alamofire
import Foundation

public struct PluginDirectoryServiceRemote {
    let session = URLSession()

    public init() {}

    public struct ParseError: Error {}

    public func fetchPluginInfo(slug: String, success: @escaping (PluginInfo) -> Void, failure: @escaping (Error) -> Void) {
        guard let url = URL(string: "https://api.wordpress.org/plugins/info/1.0/\(slug).json") else {
            return
        }
        let parameters: Parameters = ["fields": "icons,-sections,-contributors,-tags"]
        Alamofire.request(url, parameters: parameters).responseJSON { (response) in
            guard let json = response.result.value as? [String: Any],
                let pluginInfo = self.pluginInfoFromResponse(json) else {
                    failure(ParseError())
                    return
            }
            success(pluginInfo)
        }

    }
}

private extension PluginDirectoryServiceRemote {
    func pluginInfoFromResponse(_ rawPlugin: [String: Any]) -> PluginInfo? {
        guard let name = rawPlugin["name"] as? String,
            let slug = rawPlugin["slug"] as? String else {
                return nil
        }
        var iconURL: URL? = nil
        if let icons = rawPlugin["icons"] as? [String: String] {
            iconURL = icons["1x"].flatMap(URL.init(string:))
        }
        return PluginInfo(slug: slug, name: name, icon: iconURL)
    }
}
