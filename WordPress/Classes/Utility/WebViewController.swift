import Foundation
import Gridicons
import UIKit
import WebKit

class WebViewController: UIViewController {
    let webView = WKWebView()
    let progressView = WebProgressView()
    let toolbar = UIToolbar()
    let titleView = NavigationTitleView()

    var backButton: UIBarButtonItem?
    var forwardButton: UIBarButtonItem?
    var shareButton: UIBarButtonItem?
    var safariButton: UIBarButtonItem?

    let url: URL
    var allowsSharing = true

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
    }

    override func loadView() {
        let stackView = UIStackView(arrangedSubviews: [
            progressView,
            webView,
            toolbar
            ])
        stackView.axis = .vertical
        view = stackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureToolbar()
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: [.new], context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: [], context: nil)

        let request = URLRequest(url: url)
        webView.load(request)
    }

    func configureNavigation() {
        let closeButton = UIBarButtonItem(image: Gridicon.iconOfType(.cross), style: .plain, target: self, action: #selector(WebViewController.close))
        closeButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Dismiss a view. Verb")
        navigationItem.leftBarButtonItem = closeButton

        titleView.titleLabel.text = NSLocalizedString("Loading...", comment: "Loading. Verb")
        navigationItem.titleView = titleView

        // Modal styling
        // Proceed only if this Modal, and it's the only view in the stack.
        // We're not changing the NavigationBar style, if we're sharing it with someone else!
        guard presentingViewController != nil && navigationController?.viewControllers.count == 1 else {
            return
        }

        let navigationBar = navigationController?.navigationBar
        navigationBar?.shadowImage = UIImage(color: WPStyleGuide.webViewModalNavigationBarShadow())
        navigationBar?.barStyle = .default
        navigationBar?.setBackgroundImage(UIImage(color: WPStyleGuide.webViewModalNavigationBarBackground()), for: .default)

        titleView.titleLabel.textColor = WPStyleGuide.darkGrey()
        titleView.subtitleLabel.textColor = WPStyleGuide.grey()
        closeButton.tintColor = WPStyleGuide.greyLighten10()
    }

    func configureToolbar() {
        toolbar.barTintColor = UIColor.white

        backButton = UIBarButtonItem(image: Gridicon.iconOfType(.chevronLeft).imageFlippedForRightToLeftLayoutDirection(),
                                     style: .plain,
                                     target: self,
                                     action: #selector(WebViewController.goBack))

        forwardButton = UIBarButtonItem(image: Gridicon.iconOfType(.chevronRight).imageFlippedForRightToLeftLayoutDirection(),
                                     style: .plain,
                                     target: self,
                                     action: #selector(WebViewController.goForward))

        shareButton = UIBarButtonItem(image: Gridicon.iconOfType(.shareIOS),
                                      style: .plain,
                                      target: self,
                                      action: #selector(WebViewController.share))

        safariButton = UIBarButtonItem(image: Gridicon.iconOfType(.globe),
                                      style: .plain,
                                      target: self,
                                      action: #selector(WebViewController.openInSafari))

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [
            backButton!,
            space,
            forwardButton!,
            space,
            shareButton!,
            space,
            safariButton!
        ]

        toolbar.items?.forEach({ (button) in
            button.tintColor = WPStyleGuide.greyLighten10()
        })
    }

    func close() {
        dismiss(animated: true, completion: nil)
    }

    func share() {
        guard let url = webView.url else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { (type, completed, _, _) in
            if completed, let type = type?.rawValue {
                WPActivityDefaults.trackActivityType(type)
            }
        }
        present(activityViewController, animated: true, completion: nil)

    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func openInSafari() {
        guard let url = webView.url else {
            return
        }
        UIApplication.shared.open(url)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let object = object as? WKWebView,
            object == webView,
            let keyPath = keyPath else {
                return
        }

        switch keyPath {
        case #keyPath(WKWebView.title):
            titleView.titleLabel.text = webView.title
        case #keyPath(WKWebView.url):
            titleView.subtitleLabel.text = webView.url?.host
        case #keyPath(WKWebView.estimatedProgress):
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress == 1
        case #keyPath(WKWebView.isLoading):
            backButton?.isEnabled = webView.canGoBack
            forwardButton?.isEnabled = webView.canGoForward
        default:
            assertionFailure("Observed change to web view that we are not handling")
        }
    }
}
