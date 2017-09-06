//
//  ViewController.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

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
        "styleElement.textContent = 'div#header, div#catbtn, div.tbar, h4.keywordlist {display: none !important; height: 0 !important;} div#content {padding: 0 !important;}'"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.customUserAgent = userAgentString
        webview.load(URLRequest(url: url))
        return webview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white.withAlphaComponent(0.9)

        let labelBooks = UILabel()
        labelBooks.font = UIFont.preferredFont(forTextStyle: .headline)
        labelBooks.text = "博客來"

        view.etw_addSubViews(subViews: [labelBooks, webviewBooks])
        let viewsDict = ["labelBooks": labelBooks, "webviewBooks": webviewBooks]
        var constraints = [NSLayoutConstraint]()
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[labelBooks]-|", options: [], metrics: nil, views: viewsDict)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[webviewBooks]|", options: [], metrics: nil, views: viewsDict)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[labelBooks][webviewBooks(200)]", options: [], metrics: nil, views: viewsDict)
        NSLayoutConstraint.activate(constraints)

        title = "Ebook"
        navigationController?.navigationBar.isTranslucent = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension UIView {

    /// Convenience method for Auto Layout
    public func etw_addSubViews(subViews: [UIView]) {
        for subView : UIView in subViews {
            subView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subView)
        }
    }
}
