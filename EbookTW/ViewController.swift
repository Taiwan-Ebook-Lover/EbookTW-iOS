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

    private let webview : WKWebView = {
        guard let url = URL(string: "http://search.books.com.tw/search/query/key/%E8%A2%AB%E8%A8%8E%E5%8E%AD%E7%9A%84%E5%8B%87%E6%B0%A3/") else {
            assertionFailure()
            return WKWebView()
        }
        
        let userAgentString = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_3 like Mac OS X) AppleWebKit/603.3.8 (KHTML, like Gecko) Version/10.0 Mobile/14G60 Safari/602.1"
        // Note: Swift 4 includes support for multi-line string literals.
        // https://stackoverflow.com/a/24091332/3796488
        let userScriptString = "var styleElement = document.createElement('style');" +
            "document.documentElement.appendChild(styleElement);" +
        "styleElement.textContent = 'div#content {padding: 0 !important} div#header {display: none !important; height: 0 !important}';"
        let userScript = WKUserScript(source: userScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(userScript)
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.customUserAgent = userAgentString
        webview.load(URLRequest(url: url))
        return webview
    }()

    override func loadView() {
        view = webview
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

