//
//  ViewController.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit

enum EbookProvider : Int {
    case readmoo, kobo, taaze, books, bookwalker, googleplay, pubu, hyread
    static let count = 8    // TODO: Swift 4.2 has .allCases.count
}

enum ViewControllerType {
    case initial
    case yuer(keyword: String)
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
                SKStoreReviewController.requestReview()
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

    private var viewTypeIsDefaultYuer = true
    private var viewType : ViewControllerType = .initial {
        didSet {
            switch viewType {
            case .initial:
                tableView.isHidden = true
                view.etw_add(subViews: [initialView])
                NSLayoutConstraint.activate(
                    NSLayoutConstraint.constraints(withVisualFormat: "H:|[initialView]|", options: [], metrics: nil, views: ["initialView": initialView]) +
                    NSLayoutConstraint.constraints(withVisualFormat: "V:|[initialView]|", options: [], metrics: nil, views: ["initialView": initialView])
                )
            case .yuer(keyword: let keyword):
                tableView.isHidden = false
                if initialView.superview != nil {
                    initialView.removeFromSuperview()
                }
                tableView.dataSource = yuerManager
                tableView.delegate = yuerManager
                yuerManager.searchEbook(keyword: keyword, errorHandler: { (errorString) in
                    let errorMessage : String = {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            return "您是否要暫時改用舊版模式？"
                        } else {
                            return "您是否要重試？"
                        }
                    }()
                    let alert = UIAlertController(title: errorString, message: errorMessage, preferredStyle: .alert)
                    let switchAction = UIAlertAction(title: "改用舊版模式", style: .default, handler: { (alertAction) in
                        self.viewTypeIsDefaultYuer = false
                        self.viewType = .userScript(keyword: keyword)
                    })
                    let retryAction = UIAlertAction(title: "重試", style: .default, handler: { (alertAction) in
                        self.viewType = .yuer(keyword: keyword)
                    })
                    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: { (alertAction) in
                        self.viewType = .initial
                    })
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        alert.addAction(switchAction)
                    } else {
                        alert.addAction(retryAction)
                    }
                    alert.addAction(cancelAction)
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            case .userScript(keyword: let keyword):
                tableView.isHidden = false
                if initialView.superview != nil {
                    initialView.removeFromSuperview()
                }
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
    private lazy var yuerManager : YuerManager = {
       return YuerManager(tableView: tableView)
    }()

    fileprivate var searchBarKeyword = String()  // for recovering when pressing cancel button
    private let searchBar = UISearchBar()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewType = .initial
        view.etw_add(subViews: [tableView])
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: ["tableView": tableView]) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: ["tableView": tableView])
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
        tableView.register(YuerEbookTableViewCell.self, forCellReuseIdentifier: YuerEbookTableViewCell.cellReuseIdentifier)

        searchBar.placeholder = "輸入書名 / ISBN"
        searchBar.autocorrectionType = .yes
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

    func didTapSearchButton() {
        if let keyword = searchBar.text {
            self.searchBarKeyword = keyword
            if viewTypeIsDefaultYuer {
                viewType = .yuer(keyword: keyword)
            } else {
                viewType = .userScript(keyword: keyword)
            }
        }
        searchBar.resignFirstResponder()    // must do after self.keyword is set

        let oldSearchCount = UserDefaults.standard.integer(forKey: StoreReview.kSearchCount)
        let newSearchCount = oldSearchCount + 1
        UserDefaults.standard.set(newSearchCount, forKey: StoreReview.kSearchCount)

        if StoreReview.didReachRequestReviewCondition {
            StoreReview.setTimer()
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
        searchBar.text = self.searchBarKeyword
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
