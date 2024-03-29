//
//  UserScriptManager.swift
//  EbookTW
//
//  Created by denkeni on 28/11/2017.
//  Copyright © 2017 Denken. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

enum EbookProvider : Int, CaseIterable {
    case readmoo, kobo, taaze, books, bookwalker, googleplay, pubu, hyread
}

final class UserScriptManager : NSObject {

    private var urls = [URL]()
    private var cells = [UITableViewCell]()
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
            zoom = 420
            width = 420
        }
        /* v1 for TAAZE
        let userScriptString1 = """
          var styleElement = document.createElement('style');
          document.documentElement.appendChild(styleElement);
          styleElement.textContent = 'div#newHeaderV001, div#top_banner, div#searchresult_tool, div.searchresult_catalg_list, div.searchresult_page_list, div#feedbackSelect, div#newFooter {display: none !important; height: 0 !important;} div#div#searchresult_tool { width: 100% !important;} body {zoom: \(zoom)% !important;} div.one {margin-left: -180px !important;} div.two {float: left !important; width: \(width)px !important;}';
        """
        let userScriptString2 = """
          var element1 = document.getElementById('searchresult_tool');
          element1.parentElement.style.float = 'none';
          element1.parentElement.style.marginTop = '-30px';
          element1.parentElement.parentElement.style.margin = '0';
          element1.parentElement.parentElement.style.padding = '0';
          element1.nextElementSibling.style.display = 'none';
          var element2 = document.getElementById('searchresult_catalg_list');
          element1.parentElement.style.width = '0';
        """
         */
        let userScriptString = """
            var styleElement = document.createElement('style');
            document.documentElement.appendChild(styleElement);
            styleElement.textContent = 'div.container-fluid, div.hidden-sm, div.hidden-md, div.hidden-xs, div.visible-xs-block, div.visible-sm-block, div#mobileHeader {display: none !important; height: 0 !important; width: 0 !important;} div.md_top {margin-top: 0} div#listView > div:not(:first-of-type) {display: none !important;}';
        """
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()
    private var webTaazeProgressObservation : NSKeyValueObservation!

    private let webviewReadmoo : WKWebView = {
        let userScriptString1 = """
            var styleElement = document.createElement('style');
            document.documentElement.appendChild(styleElement);
            styleElement.textContent = 'header, div.top-nav-container, div.rm-breadcrumb, div.rm-ct-quickBar, div.special-banner, div#leftMenu, div#pagination, footer {display: none !important; height: 0 !important; width: 0 !important;} ul#main_items li:not(:first-child) {display: none !important;} ul.quickBar-sort {display:none}';
        """
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
    private var webReadmooProgressObservation : NSKeyValueObservation!

    private let webviewBooks : WKWebView = {
        let userScriptString = """
          var styleElement = document.createElement('style');
          document.documentElement.appendChild(styleElement);
          styleElement.textContent = 'div#header, div#catbtn, div.tbar, h4.keywordlist, div.mm_031, div#footer, div.color_basic, div.bc, div.pull_20, blockquote, div.search-mod-03, div.cntlisearch07, div.cntlisearch09, div.cntlisearch10, div.cntlisearch11, div.search-mod-01, div.search-mod-04, div.type04_footer {display: none !important; height: 0 !important;} div#content {padding: 0 !important;} ul.bd li:not(:first-child), ul.searchbook li:not(:first-child) {display: none !important;} div#app_banner {display: none}';
        """
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()
    private var webBooksProgressObservation : NSKeyValueObservation!

    private let webviewKobo : WKWebView = {
        let userScriptString = """
          var styleElement = document.createElement('style');
          document.documentElement.appendChild(styleElement);
          styleElement.textContent = 'header, div.rich-header-spacer, div.full-top, div.content-top, aside, button.add-to-cart, div.pagination, footer {display: none !important; height: 0 !important; width: 0 !important} ul.result-items li:not(:first-child) {display: none !important;}';
        """
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.isUserInteractionEnabled = false
        return webview
    }()
    private var webKoboProgressObservation : NSKeyValueObservation!

    override init() {
        for index in 0...(EbookProvider.allCases.count - 1) {
            var webView : WKWebView
            let webProgressView = UIProgressView(progressViewStyle: .bar)
            let webProgressChangeHandler : (WKWebView, NSKeyValueObservedChange<Double>) -> Void = {
                (observed : WKWebView, change : NSKeyValueObservedChange) -> Void in
                guard let progress = change.newValue else { return }
                switch progress {
                case 1.0:
                    webProgressView.setProgress(Float(progress), animated: false)
                    UIView.animate(withDuration: 0.2, delay: 0.3, options: .curveEaseIn, animations: {
                        webProgressView.alpha = 0
                    }) { (isFinished) in
                        webProgressView.setProgress(0, animated: false)
                    }
                default:
                    webProgressView.setProgress(Float(progress), animated: true)
                    webProgressView.alpha = 1.0
                }
            }
            if let ebookProvider = EbookProvider(rawValue: index) {
                switch ebookProvider {
                case .taaze:
                    webView = webviewTaaze
                    webTaazeProgressObservation = webView.observe(\.estimatedProgress, options: [.new], changeHandler: webProgressChangeHandler)
                case .readmoo:
                    webView = webviewReadmoo
                    webReadmooProgressObservation = webView.observe(\.estimatedProgress, options: [.new], changeHandler: webProgressChangeHandler)
                case .books:
                    webView = webviewBooks
                    webBooksProgressObservation = webView.observe(\.estimatedProgress, options: [.new], changeHandler: webProgressChangeHandler)
                case .kobo:
                    webView = webviewKobo
                    webKoboProgressObservation = webView.observe(\.estimatedProgress, options: [.new], changeHandler: webProgressChangeHandler)
                default:
                    continue    // legacy mode doesn't support other ebook stores
                }
            } else {
                assertionFailure()
                webView = WKWebView()
            }
            webProgressView.progressTintColor = UIColor.etw_tintColor
            // Add subviews
            let cell = UITableViewCell()
            cell.contentView.etw_add(subViews: [webView])
            webView.etw_add(subViews: [webProgressView])
            var constraints = [NSLayoutConstraint]()
            let viewsDict = ["webview": webView, "webProgressView": webProgressView]
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[webview]|", options: [], metrics: nil, views: viewsDict)
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[webview]|", options: [], metrics: nil, views: viewsDict)
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webProgressView]-0-|", options: [], metrics: nil, views: viewsDict)
            constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webProgressView(2)]", options: [], metrics: nil, views: viewsDict)
            NSLayoutConstraint.activate(constraints)
            cell.selectionStyle = .none
            self.cells.append(cell)
        }
    }

    func searchEbook(keyword: String) {
        // intensionally forced unwrapping below
        // to crash at build time if error
        guard let keywordEncoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            assertionFailure()
            return
        }
        let urlTaaze = URL(string: "https://www.taaze.tw/rwd_searchResult.html?keyword%5B%5D=" + keywordEncoded + "&keyType%5B%5D=1&prodKind=4")!
        let urlReadmoo = URL(string: "https://readmoo.com/search/keyword?q=" + keywordEncoded)!
        let urlBooks = URL(string: "https://search.books.com.tw/search/query/key/" + keywordEncoded + "/cat/EBA/")!
        let urlKobo = URL(string: "https://www.kobo.com/tw/zh/search?Query=" + keywordEncoded)!

        urls.removeAll()
        for index in 0...(EbookProvider.allCases.count - 1) {
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
                default:
                    continue
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
}


// MARK: - UITableViewDataSource

extension UserScriptManager : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
            default:
                break
            }
        }
        assertionFailure()
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Notice: we're not reusing UITableViewCell because WKWebView is not reusable
        if indexPath.section < cells.count {
            return cells[indexPath.section]
        }
        assertionFailure()
        return UITableViewCell()
    }
}

// MARK: - UITableViewDelegate

extension UserScriptManager : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < urls.count {
            let safariVC = SFSafariViewController(url: urls[indexPath.section])
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let rootVc = appDelegate.window?.rootViewController {
                rootVc.present(safariVC, animated: true, completion: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        if let header = view as? UITableViewHeaderFooterView {
            if #available(iOS 13.0, *) {
                header.textLabel?.textColor = .label
            } else {
                header.textLabel?.textColor = .black
            }
        }
    }
}
