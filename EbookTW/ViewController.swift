//
//  ViewController.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UITableViewController {

    private var urls = [URL]()
    private var webviews = [WKWebView]()
    private var cells = [UITableViewCell]()

    private let webviewTaaze : WKWebView = {
        guard let url = URL(string: "https://www.taaze.tw/search_go.html?keyword%5B%5D=9789861371955&keyType%5B%5D=0&prodKind=4&prodCatId=141") else {
            assertionFailure()
            return WKWebView()
        }
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'div#newHeaderV001, div#top_banner, div#searchresult_tool, div.searchresult_catalg_list, div.searchresult_page_list, div#feedbackSelect, div#newFooter {display: none !important; height: 0 !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.load(URLRequest(url: url))
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewReadmoo : WKWebView = {
        guard let url = URL(string: "https://readmoo.com/search/keyword?q=9789861371955") else {
            assertionFailure()
            return WKWebView()
        }
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'header, div.top-nav-container, div.rm-breadcrumb, div.rm-search-summary, div.rm-ct-quickBar, div#pagination, footer {display: none !important; height: 0 !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.load(URLRequest(url: url))
        webview.isUserInteractionEnabled = false
        return webview
    }()

    private let webviewBooks : WKWebView = {
        guard let url = URL(string: "http://search.books.com.tw/search/query/key/9789861371955/cat/EBA/") else {
            assertionFailure()
            return WKWebView()
        }
        
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
        webview.load(URLRequest(url: url))
        webview.isUserInteractionEnabled = false
        return webview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Ebook"
        view.backgroundColor = UIColor.brown.withAlphaComponent(0.9)
        tableView.rowHeight = 180.0

        for index in 0...2 {
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if let ebookProvider = EbookProvider(rawValue: indexPath.section) {
            switch ebookProvider {
            case .taaze:
                break
            case .readmoo:
                break
            case .books:
                break
            }
        }
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
