import Foundation

/// Encapsulates the authentication logic for a web view
///
class WebViewAuthenticator: NSObject {
    var dotComUsername: String?
    var dotComAuthToken: String?
    var siteLoginUrl: String?
    var siteUsername: String?
    var sitePassword: String?

    /// A request to wp-login that has been rewritten to authenticate automatically
    ///
    /// A UIWebViewDelegate should call this when a request is about to load,
    /// and load the resulting request instead, if one is returned.
    ///
    func rewrittenRequest(_ request: URLRequest) -> URLRequest? {
        guard request.value(forHTTPHeaderField: WebViewAuthenticator.headerName) == nil else {
            return nil
        }

        var newRequest = rewrittenDotComLoginRequest(request)
            ?? rewrittenDotComVisitRequest(request)
            ?? rewrittenSiteLoginRequest(request)

        newRequest?.setValue("1", forHTTPHeaderField: WebViewAuthenticator.headerName)
        return newRequest
    }
}

private extension WebViewAuthenticator {
    func rewrittenDotComLoginRequest(_ request: URLRequest) -> URLRequest? {
        guard isDotComLogin(request: request),
            let url = request.url,
            let username = dotComUsername,
            let authToken = dotComAuthToken else {
                return nil
        }

        let redirectTarget = extractRedirectTarget(url: url)
        guard let body = postBody(username: username, redirectTarget: redirectTarget) else {
            return nil
        }

        var request = request
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    func isDotComLogin(request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }

        return url.scheme == "https"
            && url.host == "wordpress.com"
            && url.path == "/wp-login.php"
            && request.httpMethod == "GET"
    }

    func rewrittenDotComVisitRequest(_ request: URLRequest) -> URLRequest? {
        guard let url = request.url,
            isDotComVisit(url: url),
            let username = dotComUsername,
            !WPCookie.hasCookie(for: url, andUsername: username),
            let authToken = dotComAuthToken else {
                return nil
        }

        guard let body = postBody(username: username, redirectTarget: request.url?.absoluteString) else {
            return nil
        }

        var request = request
        request.url = WebViewAuthenticator.wordPressComLoginUrl
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    func isDotComVisit(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        return host.hasSuffix(".wordpress.com")
            && host != "public-api.wordpress.com" // Don't authenticate API requests
    }

    func rewrittenSiteLoginRequest(_ request: URLRequest) -> URLRequest? {
        guard isSiteLogin(request: request),
            let url = request.url,
            let username = siteUsername,
            let password = sitePassword else {
                return nil
        }

        let redirectTarget = extractRedirectTarget(url: url)
        guard let body = postBody(username: username, password: password, redirectTarget: redirectTarget) else {
            return nil
        }

        var request = request
        request.httpMethod = "POST"
        request.httpBody = body
        return request
    }

    func isSiteLogin(request: URLRequest) -> Bool {
        guard let url = request.url,
            let siteLoginUrl = siteLoginUrl else {
            return false
        }

        return url.absoluteString.hasPrefix(siteLoginUrl)
    }

    func extractRedirectTarget(url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems else {
            return nil
        }
        return queryItems
            .first(where: { $0.name == "redirect_to" })?
            .value?
            .removingPercentEncoding
    }

    func postBody(username: String, password: String? = nil, redirectTarget: String?) -> Data? {
        guard let encodedUsername = (username as NSString).byUrlEncoding() else {
            return nil
        }
        var body = "log=\(encodedUsername)"
        if let password = password,
            let encodedPassword = (password as NSString).byUrlEncoding() {
            body += "&pwd=\(encodedPassword)"
        }
        if let redirectTarget = redirectTarget,
            let encodedRedirectTarget = (redirectTarget as NSString).byUrlEncoding() {
            body += "&redirect_to=\(encodedRedirectTarget)"
        }
        return body.data(using: .utf8)
    }

    static let headerName = "X-WPIOS-AUTH"
    static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
}
