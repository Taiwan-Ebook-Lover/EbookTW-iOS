//
//  SearchHistoryManager.swift
//  EbookTW
//
//  Created by denkeni on 2019/2/12.
//  Copyright © 2019 Nandalu. All rights reserved.
//

import UIKit

final class SearchHistoryManager : NSObject {

    private let cellReuseIdentifier = "SearchHistoryCellReuseIdentifier"
    private struct Key {
        static let isOnICloud = "isSearchHistoryOnICloud"
        static let searchHistory = "SearchHistory"
    }

    private weak var vc : ViewController?
    let tableView = UITableView(frame: .zero, style: .grouped)

    /// modify this when textDidChange
    var searchText = "" {
        didSet {
            tableView.reloadData()
        }
    }
    private var filteredArray : [String] {
        let isOnICloud = UserDefaults.standard.bool(forKey: Key.isOnICloud)
        var array : [String]? = nil
        switch isOnICloud {
        case true:
            array = NSUbiquitousKeyValueStore.default.array(forKey: Key.searchHistory) as? [String]
        case false:
            array = UserDefaults.standard.stringArray(forKey: Key.searchHistory)
        }
        guard let dataArray = array else {
            assertionFailure()
            return [String]()
        }
        if searchText != "" {
            let filtered = dataArray.filter {
                nil != $0.range(of: searchText, options: .caseInsensitive)
            }
            return filtered
        } else {
            return dataArray
        }
    }
    private var isEmptyState = false

    // Mark: - Public methods

    init(vc: ViewController) {
        self.vc = vc
        super.init()

        tableView.keyboardDismissMode = .interactive
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        if #available(iOS 11.0, *) {
        } else {
            tableView.estimatedSectionHeaderHeight = 44.0
        }

        UserDefaults.standard.register(defaults: [Key.isOnICloud: true])

        NotificationCenter.default.addObserver(self, selector: #selector(storeDidChange), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    func add(keyword: String) {
        let isOnICloud = UserDefaults.standard.bool(forKey: Key.isOnICloud)
        switch isOnICloud {
        case true:
            if var array = NSUbiquitousKeyValueStore.default.array(forKey: Key.searchHistory) as? [String] {
                array = array.filter { $0 != keyword }
                array.insert(keyword, at: 0)
                NSUbiquitousKeyValueStore.default.set(array, forKey: Key.searchHistory)
            } else {
                NSUbiquitousKeyValueStore.default.set([keyword], forKey: Key.searchHistory)
            }
        case false:
            if var array = UserDefaults.standard.stringArray(forKey: Key.searchHistory) {
                array = array.filter { $0 != keyword }
                array.insert(keyword, at: 0)
                UserDefaults.standard.setValue(array, forKey: Key.searchHistory)
            } else {
                UserDefaults.standard.setValue([keyword], forKey: Key.searchHistory)
            }
        }
    }

    // MARK: - Private methods

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardRectValue = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardRectValue.height
            if tableView.tableFooterView == nil {
                let quickTypeBarHeight : CGFloat = 23.0 // TODO: how to get this programmatically?
                let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: keyboardHeight + quickTypeBarHeight))
                tableView.tableFooterView = view   // keyboard offset
            }
        }
    }

    @objc private func openSettings() {
        // TODO:
    }

    @objc private func storeDidChange(notification: NSNotification) {
        if let value = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int {
            switch value {
            case NSUbiquitousKeyValueStoreQuotaViolationChange:
                let alert = UIAlertController(title: "警告", message: "歷史記錄已滿載；請刪除部分或全部記錄。", preferredStyle: .alert)
                let confirm = UIAlertAction(title: "確認", style: .default, handler: nil)
                alert.addAction(confirm)
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let rootVc = appDelegate.window?.rootViewController {
                    rootVc.present(alert, animated: true, completion: nil)
                }
            case NSUbiquitousKeyValueStoreServerChange,
                 NSUbiquitousKeyValueStoreInitialSyncChange,
                 NSUbiquitousKeyValueStoreAccountChange:
                tableView.reloadData()
            default:
                break
            }
        }
    }

    @objc private func clearHistory() {
        let alert = UIAlertController(title: "確定要清除所有搜尋記錄？", message: nil, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "確定清除", style: .destructive) { (action) in
            let isOnICloud = UserDefaults.standard.bool(forKey: Key.isOnICloud)
            switch isOnICloud {
            case true:
                NSUbiquitousKeyValueStore.default.set([String](), forKey: Key.searchHistory)
            case false:
                UserDefaults.standard.set(nil, forKey: Key.searchHistory)
            }
            self.tableView.reloadData()
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(confirm)
        alert.addAction(cancel)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let rootVc = appDelegate.window?.rootViewController {
            rootVc.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - UITableViewDataSource

extension SearchHistoryManager : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIToolbar()
        let titleLabel = UILabel()
        titleLabel.textColor = .darkGray
        titleLabel.text = "搜尋記錄"
        if #available(iOS 11.0, *) {
        } else {
            titleLabel.sizeToFit()
        }
        let title = UIBarButtonItem(customView: titleLabel)
        let settings = UIBarButtonItem(title: "設定", style: .plain, target: self, action: #selector(openSettings))
        let clear = UIBarButtonItem(title: "清除", style: .plain, target: self, action: #selector(clearHistory))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        header.items = [title, flexibleSpace, settings, clear]
        return header
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let number = filteredArray.count
        if number == 0 {
            isEmptyState = true
            return 1    // empty state
        } else {
            isEmptyState = false
            return number
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        if isEmptyState {
            let text : String
            if searchText != "" {
                text = "（沒有符合的記錄）"
            } else {
                text = "（沒有資料）"
            }
            cell.textLabel?.text = text
            cell.selectionStyle = .none
            return cell
        } else {
            cell.selectionStyle = .default
        }
        if indexPath.row < filteredArray.count {
            cell.textLabel?.text = filteredArray[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let isOnICloud = UserDefaults.standard.bool(forKey: Key.isOnICloud)
            switch isOnICloud {
            case true:
                var array = NSUbiquitousKeyValueStore.default.array(forKey: Key.searchHistory)
                array?.remove(at: indexPath.row)
                NSUbiquitousKeyValueStore.default.set(array, forKey: Key.searchHistory)
            case false:
                var array = UserDefaults.standard.array(forKey: Key.searchHistory)
                array?.remove(at: indexPath.row)
                UserDefaults.standard.set(array, forKey: Key.searchHistory)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - UITableViewDelegate

extension SearchHistoryManager : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let keyword = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            vc?.search(keyword: keyword)
        }
    }
}
