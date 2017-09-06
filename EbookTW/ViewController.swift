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
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'div#newHeaderV001, div#top_banner, div#searchresult_tool, div.searchresult_catalg_list, div.searchresult_page_list, div#feedbackSelect, div#newFooter {display: none !important; height: 0 !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewReadmoo : WKWebView = {
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'header, div.top-nav-container, div.rm-breadcrumb, div.rm-search-summary, div.rm-ct-quickBar, div#pagination, footer {display: none !important; height: 0 !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewBooks : WKWebView = {
        let userAgentString = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_3 like Mac OS X) AppleWebKit/603.3.8 (KHTML, like Gecko) Version/10.0 Mobile/14G60 Safari/602.1"
        // Note: Swift 4 includes support for multi-line string literals.
        // https://stackoverflow.com/a/24091332/3796488
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'div#header, div#catbtn, div.tbar, h4.keywordlist, div#footer {display: none !important; height: 0 !important;} div#content {padding: 0 !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.customUserAgent = userAgentString
        webview.isUserInteractionEnabled = false
        return webview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Ebook"
        view.backgroundColor = UIColor.brown.withAlphaComponent(0.9)
        tableView.rowHeight = 180.0

        for index in 0...2 {
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
                }
                urls.append(url)
            } else {
                assertionFailure()
            }
        }

        webviewTaaze.load(URLRequest(url: urlTaaze))
        webviewReadmoo.load(URLRequest(url: urlReadmoo))
        webviewBooks.load(URLRequest(url: urlBooks))
    }

    // MARK: UITableViewDataSource

    enum EbookProvider : Int {
        case taaze, readmoo, books
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
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

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < urls.count {
            let safariVC = SFSafariViewController(url: urls[indexPath.section])
            safariVC.preferredControlTintColor = .brown
            self.present(safariVC, animated: true, completion: nil)
        }
    }
}

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
