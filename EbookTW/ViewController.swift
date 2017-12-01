//
//  ViewController.swift
//  EbookTW
//
//  Created by denkeni on 05/09/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import SafariServices

enum EbookProvider : Int {
    case taaze, readmoo, kobo, books
    static let count = 4
}

enum ViewControllerType {
    case initial
    case yuer(keyword: String)
    case userScript(keyword: String)
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
                tableView.backgroundColor = UIColor.etw_tintColor.withAlphaComponent(0.95)
                yuerManager.searchEbook(keyword: keyword, errorHandler: { (errorString) in
                    let errorMessage : String = {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            return "\(errorString)\n您是否要暫時改用舊版模式？"
                        } else {
                            return "\(errorString)\n您是否要重試？"
                        }
                    }()
                    let alert = UIAlertController(title: nil, message: errorMessage, preferredStyle: .alert)
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
                    self.present(alert, animated: true, completion: nil)
                })
            case .userScript(keyword: let keyword):
                tableView.isHidden = false
                if initialView.superview != nil {
                    initialView.removeFromSuperview()
                }
                tableView.dataSource = userScriptManager
                tableView.delegate = userScriptManager
                tableView.backgroundColor = UIColor.etw_tintColor.withAlphaComponent(0.95)
                tableView.rowHeight = 200.0
                userScriptManager.searchEbook(keyword: keyword)
            }
        }
    }
    private let tableView = UITableView(frame: CGRect.zero, style: .plain)
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
