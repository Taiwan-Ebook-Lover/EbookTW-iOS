//
//  ViewController.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Denken. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit
import EbookTWAPI

enum ViewControllerType {
    case initial
    case api(parameter: SearchParameter)
    case userScript(keyword: String)
}

struct StoreReview {
    static let kSearchCount = "searchCount"

    private static let idleTime : TimeInterval = 10.0
    private static let requestCondition : Int = 20  // every 20 times of search counts will do requestReview()
    static var didReachRequestReviewCondition : Bool {
        let searchCount = UserDefaults.standard.integer(forKey: StoreReview.kSearchCount)
        if searchCount > 0 && searchCount % requestCondition == 0 {
            return true
        }
        return false
    }

    private static var idleTimer : Timer? = nil

    static func setTimer() {
        if #available(iOS 10.3, *) {
            idleTimer = Timer.scheduledTimer(withTimeInterval: idleTime, repeats: false, block: { (timer) in
                if #available(iOS 14.0, *) {
                    // See: https://stackoverflow.com/q/63953891/3796488
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                } else {
                    SKStoreReviewController.requestReview()
                }
            })
        }
    }

    static func resetTimer() {
        if let idleTimer = idleTimer, idleTimer.isValid {
            idleTimer.invalidate()
            setTimer()
        }
    }
}

final class ViewController: UIViewController {

    private var viewType : ViewControllerType = .initial {
        didSet {
            navigationItem.rightBarButtonItem = nil
            switch viewType {
            case .initial:
                tableView.isHidden = true
                initialView.isHidden = false
            case .api(parameter: let parameter):
                tableView.isHidden = false
                initialView.isHidden = true
                tableView.dataSource = apiManager
                tableView.delegate = apiManager
                apiManager.searchEbook(parameter: parameter, completionHandler: { result in
                    switch result {
                    case .success(let response):
                        DispatchQueue.main.async {
                            self.searchBar.text = response.keywords
                            self.searchedKeyword = response.keywords
                        }
                    case .failure(let error):
                        var errorMessage = "您是否要重試？"
                        var actions = [UIAlertAction]()
                        switch parameter {
                        case .keyword(let keyword):
                            let switchAction = UIAlertAction(title: "改用舊版模式", style: .default, handler: { (alertAction) in
                                self.viewType = .userScript(keyword: keyword)
                            })
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                errorMessage = "您是否要暫時改用舊版模式？"
                                actions.append(switchAction)
                            }
                        default:
                            break
                        }
                        let alert = UIAlertController(title: error.message, message: errorMessage, preferredStyle: .alert)
                        let retryAction = UIAlertAction(title: "重試", style: .default, handler: { (alertAction) in
                            self.viewType = .api(parameter: parameter)
                        })
                        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: { (alertAction) in
                            self.viewType = .initial
                        })
                        actions += [retryAction, cancelAction]
                        for action in actions {
                            alert.addAction(action)
                        }
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                })
            case .userScript(keyword: let keyword):
                tableView.isHidden = false
                initialView.isHidden = true
                tableView.dataSource = userScriptManager
                tableView.delegate = userScriptManager
                tableView.rowHeight = 200.0
                userScriptManager.searchEbook(keyword: keyword)
            }
        }
    }
    private let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    private let initialView = InitialView()
    private lazy var userScriptManager : UserScriptManager = {
        return UserScriptManager()
    }()
    private lazy var apiManager : APIManager = {
       return APIManager(tableView: tableView)
    }()
    private lazy var searchHistoryManager : SearchHistoryManager = {
        return SearchHistoryManager(vc: self)
    }()
    var showSearchHistory : Bool = false {
        didSet {
            switch showSearchHistory {
            case true:
                searchHistoryManager.tableView.isHidden = false
            case false:
                searchHistoryManager.tableView.isHidden = true
            }
        }
    }

    fileprivate var searchedKeyword = String()  // for recovering
    private let searchBar = UISearchBar()
    private lazy var shareItem : UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewType = .initial
        showSearchHistory = false

        view.etw_add(subViews: [initialView, tableView, searchHistoryManager.tableView])
        let viewsDict = ["initialView": initialView, "tableView": tableView, "shTableView": searchHistoryManager.tableView]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[initialView]|", options: [], metrics: nil, views: viewsDict) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[initialView]|", options: [], metrics: nil, views: viewsDict)
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: viewsDict) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: viewsDict) +
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[shTableView]|", options: [], metrics: nil, views: viewsDict) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[shTableView]|", options: [], metrics: nil, views: viewsDict)
        )

        // A hacky fix for weird top padding. Take 18.0 to be consistent with other section headers.
        // See: https://stackoverflow.com/a/22185534/3796488
        if #available(iOS 11.0, *) {
            let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 18.0))
            tableView.tableHeaderView = tableHeaderView
        }

        tableView.sectionHeaderHeight = 30.0
        // Starting in iOS 12 the default is now false.
        // See: https://useyourloaf.com/blog/readable-width-table-views-with-ios-12/
        tableView.cellLayoutMarginsFollowReadableWidth = true

        tableView.keyboardDismissMode = .interactive

        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = .systemBackground
        }
        searchBar.placeholder = "輸入書名 / ISBN"
        searchBar.autocorrectionType = .yes
        searchBar.delegate = self

        /*
        let barcodeButton = UIButton(type: .system)
        barcodeButton.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 46.0)
        barcodeButton.etw_setBackgroundColor(.etw_tintColor, for: .normal)
        barcodeButton.setTitle("掃描條碼", for: .normal)
        barcodeButton.setTitleColor(.white, for: .normal)
        barcodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
        barcodeButton.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
        searchBar.inputAccessoryView = barcodeButton
         */

        navigationItem.titleView = searchBar
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // like clearsSelectionOnViewWillAppear
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
            StoreReview.resetTimer()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func search(parameter: SearchParameter) {
        switch parameter {
        case .keyword(let keyword):
            searchBar.text = keyword
            searchedKeyword = keyword
            let isUserScriptMode = UserDefaults.standard.bool(forKey: SettingsKey.isUserScriptMode)
            switch isUserScriptMode {
            case false:
                viewType = .api(parameter: .keyword(keyword))
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            case true:
                viewType = .userScript(keyword: keyword)
            }
            searchHistoryManager.add(keyword: keyword)
        case .resultID(let resultID):
            viewType = .api(parameter: .resultID(resultID))
        }
        searchBar.resignFirstResponder()
        switch viewType {
        case .api:
            navigationItem.rightBarButtonItem = shareItem   // must do after searchBar.resignFirstResponder()
        default:
            break
        }

        let oldSearchCount = UserDefaults.standard.integer(forKey: StoreReview.kSearchCount)
        let newSearchCount = oldSearchCount + 1
        UserDefaults.standard.set(newSearchCount, forKey: StoreReview.kSearchCount)

        if StoreReview.didReachRequestReviewCondition {
            // No longer on the App Store; stop requesting review.
//            StoreReview.setTimer()
        }
    }

    private func didTapSearchButton() {
        if let keyword = searchBar.text {
            search(parameter: .keyword(keyword))
        }
    }

    @objc private func share() {
        switch viewType {
        case .api(parameter: let parameter):
            var url: URL? = nil
            switch parameter {
            case .keyword(let keyword):
                if let searchResultID = apiManager.currentSearchResultID {
                    url = URL(string: "https://taiwan-ebook-lover.github.io/searches/\(searchResultID)")
                } else if let keywordEncoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let searchBookURL = URL(string: "https://taiwan-ebook-lover.github.io/searches?q=\(keywordEncoded)") {
                    url = searchBookURL
                }
            case .resultID(let resultID):
                url = URL(string: "https://taiwan-ebook-lover.github.io/searches/\(resultID)")
            }
            guard let url = url else { return }
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            present(activityViewController, animated: true, completion: nil)
        default:
            break
        }
    }
}

// MARK: - UISearchBarDelegate

extension ViewController : UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        showSearchHistory = true
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchHistoryManager.searchText = searchText
    }

    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        showSearchHistory = false
        if searchBar.text == "" {
            viewType = .initial
            // searchBar.text (User) -> searchBarKeyword (Cache) -> searchHistoryManager.searchText (TableView)
            searchedKeyword = ""
        } else {
            // searchBar.text (User) <- searchBarKeyword (Cache) -> searchHistoryManager.searchText (TableView)
            searchBar.text = searchedKeyword
        }
        searchHistoryManager.searchText = searchedKeyword  // reset
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        didTapSearchButton()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // searchBar.text (User) <- searchBarKeyword (Cache)
        searchBar.text = searchedKeyword  // Cancel any modification
        searchBar.resignFirstResponder()
    }
}

// MARK: - Utility

extension UIView {

    /// Convenience method for Auto Layout
    public func etw_add(subViews: [UIView]) {
        for subView : UIView in subViews {
            subView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subView)
        }
    }
}

// See: https://stackoverflow.com/a/27095410

extension UIButton {

    private func etw_imageWithColor(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    func etw_setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        self.setBackgroundImage(etw_imageWithColor(color: color), for: state)
    }
}
