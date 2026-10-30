import UIKit
import WebKit

// CF FACEIT — приложение открывает сам сайт, поэтому все данные
// (аккаунт, матчи, лобби, сообщения) синхронизированы с сайтом в реальном времени.

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication, didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = WebController()
        window?.makeKeyAndVisible()
        return true
    }
}

final class WebController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var web: WKWebView!
    private let bg = UIColor(red: 10/255, green: 5/255, blue: 7/255, alpha: 1)
    private lazy var site: URL = URL(string: (Bundle.main.object(forInfoDictionaryKey: "CFSiteURL") as? String)
                                     ?? "https://cf-faceit-wcfgrade.msk1.amvera.tech")!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bg
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()          // вход сохраняется между запусками
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.applicationNameForUserAgent = "CFFaceitApp/iOS"

        web = WKWebView(frame: .zero, configuration: cfg)
        web.translatesAutoresizingMaskIntoConstraints = false
        web.isOpaque = false
        web.backgroundColor = bg
        web.scrollView.backgroundColor = bg
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsBackForwardNavigationGestures = true
        web.navigationDelegate = self
        web.uiDelegate = self
        view.addSubview(web)
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            web.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            web.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        let refresh = UIRefreshControl()
        refresh.tintColor = .white
        refresh.addTarget(self, action: #selector(reload(_:)), for: .valueChanged)
        web.scrollView.refreshControl = refresh
        load()
    }

    private func load() {
        var c = URLComponents(url: site, resolvingAgainstBaseURL: false)!
        c.path = "/"; c.queryItems = [URLQueryItem(name: "app", value: "ios")]
        web.load(URLRequest(url: c.url!))
    }

    @objc private func reload(_ s: UIRefreshControl) {
        if web.url?.host == site.host { web.reload() } else { load() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { s.endRefreshing() }
    }

    // Свой сайт — внутри приложения; Telegram, менеджер и прочее — снаружи.
    func webView(_ w: WKWebView, decidePolicyFor a: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = a.request.url else { return decisionHandler(.allow) }
        if a.targetFrame != nil && a.targetFrame?.isMainFrame == false { return decisionHandler(.allow) }
        if url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" || url.host == site.host {
            return decisionHandler(.allow)
        }
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
    }

    // target=_blank
    func webView(_ w: WKWebView, createWebViewWith c: WKWebViewConfiguration, for a: WKNavigationAction, windowFeatures f: WKWindowFeatures) -> WKWebView? {
        if let url = a.request.url {
            if url.host == site.host { w.load(a.request) } else { UIApplication.shared.open(url) }
        }
        return nil
    }

    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { offline() }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) {
        if (e as NSError).code != NSURLErrorCancelled { offline() }
    }

    private func offline() {
        let html = """
        <html><head><meta name=viewport content='width=device-width,initial-scale=1'><style>
        body{margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:#0A0507;color:#f3eaea;font-family:-apple-system;text-align:center}
        p{color:#a99}a{display:inline-block;background:#E5243B;color:#fff;border-radius:12px;padding:14px 26px;text-decoration:none;font-weight:700}
        </style></head><body><div><h2>Нет соединения</h2><p>Проверь интернет и потяни вниз.</p>
        <a href='\(site.absoluteString)/?app=ios'>Повторить</a></div></body></html>
        """
        web.loadHTMLString(html, baseURL: site)
    }

    // alert/confirm с сайта
    func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage m: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: m, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }
    func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage m: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = UIAlertController(title: nil, message: m, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in completionHandler(false) })
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(a, animated: true)
    }
}
