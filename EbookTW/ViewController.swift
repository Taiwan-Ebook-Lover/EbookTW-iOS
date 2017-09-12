//
//  ViewController.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class ViewController: UITableViewController {

    fileprivate var keyword = String()  // for recovering when pressing cancel button
    private var urls = [URL]()
    private var cells = [UITableViewCell]()
    private let searchBar = UISearchBar()

    private let webviewTaaze : WKWebView = {
        let zoom : Int
        let width : CGFloat
        switch UIScreen.main.bounds.width {  // fixed to portrait
        case 320..<375: // iPhone 5
            zoom = 300
            width = 230
        case 375..<414: // iPhone 6
            zoom = 330
            width = 260
        case 414..<768: // iPhone 6 Plus
            zoom = 330
            width = 300
        default:
            assertionFailure()
            zoom = 0
            width = 0
        }
        let userScriptString1 = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
            "styleElement.textContent = 'div#newHeaderV001, div#top_banner, div#searchresult_tool, div.searchresult_catalg_list, div.searchresult_page_list, div#feedbackSelect, div#newFooter {display: none !important; height: 0 !important;} div#div#searchresult_tool { width: 100% !important;} body {zoom: \(zoom)% !important;} div.one {margin-left: -180px !important;} div.two {float: left !important; width: \(width)px !important;}'"
        let userScriptString2 = "var element1 = document.getElementById('searchresult_tool');" +
            "element1.parentElement.style.float = 'none';" +
            "element1.parentElement.style.marginTop = '-30px';" +
            "element1.parentElement.parentElement.style.margin = '0';" +
            "element1.parentElement.parentElement.style.padding = '0';" +
            "element1.nextElementSibling.style.display = 'none';" +
            "var element2 = document.getElementById('searchresult_catalg_list');" +
            "element1.parentElement.style.width = '0';"
        let userScript1 = WKUserScript(source: userScriptString1, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let userScript2 = WKUserScript(source: userScriptString2, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript1)
        config.userContentController.addUserScript(userScript2)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewReadmoo : WKWebView = {
        let userScriptString1 = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'header, div.top-nav-container, div.rm-breadcrumb, div.rm-ct-quickBar, div#pagination, footer {display: none !important; height: 0 !important;} ul#main_items li:not(:first-child) {display: none !important;}'"
        // only keep div.rm-search-summary for no search result
        let userScriptString2 = "if (document.getElementById('chalkboard').clientHeight != 0) {" +
        "document.getElementsByClassName('rm-search-summary')[0].style.display = 'none' }"
        let userScript1 = WKUserScript(source: userScriptString1, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let userScript2 = WKUserScript(source: userScriptString2, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript1)
        config.userContentController.addUserScript(userScript2)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewBooks : WKWebView = {
        // TODO: Swift 4 includes support for multi-line string literals.
        // https://stackoverflow.com/a/24091332/3796488
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'div#header, div#catbtn, div.tbar, h4.keywordlist, div.mm_031, div#footer {display: none !important; height: 0 !important;} div#content {padding: 0 !important;} ul.bd li:not(:first-child) {display: none !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewKobo : WKWebView = {
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'header, div.rich-header-spacer, div.full-top, div.content-top, aside, button.add-to-cart, div.pagination, footer {display: none !important; height: 0 !important; width: 0 !important} ul.result-items li:not(:first-child) {display: none !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Ebook"
        view.backgroundColor = UIColor.etw_tintColor.withAlphaComponent(0.95)
        tableView.rowHeight = 200.0

        for index in 0...(EbookProvider.count - 1) {
            // TODO: add UIProgressView with iOS 11 block-based key value observing
            var webview : WKWebView
            if let ebookProvider = EbookProvider(rawValue: index) {
                switch ebookProvider {
                case .taaze:
                    webview = webviewTaaze
                case .readmoo:
                    webview = webviewReadmoo
                case .books:
                    webview = webviewBooks
                case .kobo:
                    webview = webviewKobo
                }
            } else {
                assertionFailure()
                webview = WKWebView()
            }
            let cell = UITableViewCell()
            cell.contentView.etw_add(subViews: [webview])
            var constraints = [NSLayoutConstraint]()
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[webview]|", options: [], metrics: nil, views: ["webview": webview])
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[webview]|", options: [], metrics: nil, views: ["webview": webview])
            NSLayoutConstraint.activate(constraints)
            cell.selectionStyle = .none
            self.cells.append(cell)
        }

        searchBar.placeholder = "輸入 書名 / ISBN"
        searchBar.delegate = self
//        let qrCodeButton = UIButton(type: .system)
//        qrCodeButton.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 46.0)
//        qrCodeButton.backgroundColor = .brown
//        qrCodeButton.setTitle("QR Code", for: .normal)
//        qrCodeButton.setTitleColor(.white, for: .normal)
//        qrCodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
//        qrCodeButton.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
//        searchBar.inputAccessoryView = qrCodeButton
        navigationItem.titleView = searchBar
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func didTapSearchButton() {
        if let keyword = searchBar.text {
            self.keyword = keyword
            searchEbook(keyword: keyword)
        }
        searchBar.resignFirstResponder()    // must do after self.keyword is set
    }

    private func searchEbook(keyword: String) {
        // intensionally forced unwrapping below
        // to crash at build time if error
        guard let keywordEncoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            assertionFailure()
            return
        }
        let urlTaaze = URL(string: "https://www.taaze.tw/search_go.html?keyword%5B%5D=" + keywordEncoded + "&keyType%5B%5D=0&prodKind=4&prodCatId=141")!
        let urlReadmoo = URL(string: "https://readmoo.com/search/keyword?q=" + keywordEncoded)!
        let urlBooks = URL(string: "http://search.books.com.tw/search/query/key/" + keywordEncoded + "/cat/EBA/")!
        let urlKobo = URL(string: "https://www.kobo.com/tw/zh/search?Query=" + keywordEncoded)!

        urls.removeAll()
        for index in 0...2 {
            if let ebookProvider = EbookProvider(rawValue: index) {
                let url : URL
                switch ebookProvider {
                case .taaze:
                    url = urlTaaze
                case .readmoo:
                    url = urlReadmoo
                case .books:
                    url = urlBooks
                case .kobo:
                    url = urlKobo
                }
                urls.append(url)
            } else {
                assertionFailure()
            }
        }

        webviewTaaze.load(URLRequest(url: urlTaaze))
        webviewReadmoo.load(URLRequest(url: urlReadmoo))
        webviewBooks.load(URLRequest(url: urlBooks))
        webviewKobo.load(URLRequest(url: urlKobo))
    }

    // MARK: - UITableViewDataSource

    enum EbookProvider : Int {
        case taaze, readmoo, kobo, books
        static let count = 4
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return EbookProvider.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let ebookProvider = EbookProvider(rawValue: section) {
            switch ebookProvider {
            case .taaze:
                return "TAAZE"
            case .readmoo:
                return "Readmoo"
            case .books:
                return "博客來"
            case .kobo:
                return "Kobo"
            }
        }
        assertionFailure()
        return String()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Notice: we're not reusing UITableViewCell because WKWebView is not reusable
        if indexPath.section < cells.count {
            return cells[indexPath.section]
        }
        assertionFailure()
        return UITableViewCell()
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < urls.count {
            let safariVC = SFSafariViewController(url: urls[indexPath.section])
            if #available(iOS 10.0, *) {
                safariVC.preferredControlTintColor = UIColor(red:0.34, green:0.62, blue:0.56, alpha:1.0)
            }
            self.present(safariVC, animated: true, completion: nil)
        }
    }
}

// MARK: - UISearchBarDelegate

extension ViewController : UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = self.keyword
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        didTapSearchButton()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension UIView {

    /// Convenience method for Auto Layout
    public func etw_add(subViews: [UIView]) {
        for subView : UIView in subViews {
            subView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subView)
        }
    }
}
