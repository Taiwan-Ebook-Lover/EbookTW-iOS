//
//  SettingsViewController.swift
//  EbookTW
//
//  Created by denkeni on 2019/2/18.
//  Copyright © 2019 Nandalu. All rights reserved.
//

import UIKit
import SafariServices

/// get value from UserDefaults.standard
struct SettingsKey {

    static let isOnICloud = "isSearchHistoryOnICloud"
    static let isDataSaving = "isDataSavingMode"
    static let isUserScriptMode = "isUserScriptMode"
}

class SettingsViewController : UITableViewController {

    private enum SettingsSection : Int, CaseIterable {
        case searchHistory, advanced, about
    }
    private enum SettingsRowSearchHistory : Int, CaseIterable {
        case iCloud, export
    }
    private enum SettingsRowAdvanced : Int, CaseIterable {
        case davaSaving, userScriptMode
    }
    private enum SettingsRowAbout : Int, CaseIterable {
        case privacyPolicy, version, website, twitter
    }
    private let cellReuseIdentifier = "SettingsCellReuseIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "設定"
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.register(SettingsCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // like clearsSelectionOnViewWillAppear
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    @objc private func done() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func switchICloud(sender: UISwitch) {
        let message : String
        let confirmText : String
        switch sender.isOn {
        case true:
            message = "將會把本地端的搜尋記錄上傳到 iCloud，但若 iCloud 上已有搜尋記錄將被覆蓋！確定要啟用 iCloud 同步？"
            confirmText = "確定啟用"
        case false:
            message = "搜尋記錄將會移至本地端，但 iCloud 上的搜尋記錄將會刪除！確定要關閉 iCloud 同步？"
            confirmText = "確定關閉"
        }
        let alert = UIAlertController(title: "警告", message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: confirmText, style: .destructive) { (action) in
            switch sender.isOn {
            case true:
                SearchHistoryManager.moveTo(destiniation: .iCloud)
            case false:
                SearchHistoryManager.moveTo(destiniation: .local)
            }
            UserDefaults.standard.set(sender.isOn, forKey: SettingsKey.isOnICloud)
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
            sender.setOn(!sender.isOn, animated: true)  // restore
        }
        alert.addAction(confirm)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }

    @objc private func switchDataSaving(sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: SettingsKey.isDataSaving)
    }

    @objc private func switchUserScriptMode(sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: SettingsKey.isUserScriptMode)
        tableView.reloadData()  // update availability for data saving mode
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sectionType = SettingsSection(rawValue: section) {
            switch sectionType {
            case .searchHistory:
                return "搜尋記錄"
            case .advanced:
                return "進階"
            case .about:
                return "關於本軟體"
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionType = SettingsSection(rawValue: section) {
            switch sectionType {
            case .searchHistory:
                return SettingsRowSearchHistory.allCases.count
            case .advanced:
                return SettingsRowAdvanced.allCases.count
            case .about:
                return SettingsRowAbout.allCases.count
            }
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        cell.textLabel?.textColor = .black
        cell.detailTextLabel?.textColor = .black
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        cell.accessoryView = nil
        cell.selectionStyle = .none
        if let sectionType = SettingsSection(rawValue: indexPath.section) {
            switch sectionType {
            case .searchHistory:
                if let rowType = SettingsRowSearchHistory(rawValue: indexPath.row) {
                    switch rowType {
                    case .iCloud:
                        cell.textLabel?.text = "iCloud 同步"
                        let iCloudSwitch = UISwitch()
                        iCloudSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.isOnICloud)
                        iCloudSwitch.addTarget(self, action: #selector(switchICloud), for: .valueChanged)
                        cell.accessoryView = iCloudSwitch
                    case .export:
                        cell.textLabel?.textColor = .etw_tintColor
                        cell.textLabel?.text = "匯出記錄"
                        cell.selectionStyle = .default
                    }
                }
            case .advanced:
                if let rowType = SettingsRowAdvanced(rawValue: indexPath.row) {
                    switch rowType {
                    case .davaSaving:
                        cell.textLabel?.text = "節省網路流量"
                        cell.detailTextLabel?.text = "圖片將不會載入"
                        let dataSavingSwitch = UISwitch()
                        dataSavingSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.isDataSaving)
                        dataSavingSwitch.addTarget(self, action: #selector(switchDataSaving), for: .valueChanged)
                        cell.accessoryView = dataSavingSwitch
                        if UserDefaults.standard.bool(forKey: SettingsKey.isUserScriptMode) == true {
                            cell.textLabel?.textColor = .lightGray
                            cell.detailTextLabel?.textColor = .lightGray
                            dataSavingSwitch.isEnabled = false
                        }
                    case .userScriptMode:
                        cell.textLabel?.text = "舊版模式"
                        cell.detailTextLabel?.text = "僅支援 4 家電子書店"
                        let userScriptModeSwitch = UISwitch()
                        userScriptModeSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.isUserScriptMode)
                        userScriptModeSwitch.addTarget(self, action: #selector(switchUserScriptMode), for: .valueChanged)
                        cell.accessoryView = userScriptModeSwitch
                    }
                }
            case .about:
                if let rowType = SettingsRowAbout(rawValue: indexPath.row) {
                    switch rowType {
                    case .website:
                        cell.textLabel?.text = "官方網站"
                        cell.detailTextLabel?.text = "https://taiwan-ebook-lover.github.io"
                        cell.selectionStyle = .default
                        cell.accessoryType = .disclosureIndicator
                    case .twitter:
                        cell.textLabel?.text = "官方推特"
                        cell.detailTextLabel?.text = "@TaiwanEBook"
                        cell.selectionStyle = .default
                        cell.accessoryType = .disclosureIndicator
                    case .privacyPolicy:
                        cell.textLabel?.text = "隱私權政策"
                        cell.selectionStyle = .default
                        cell.accessoryType = .disclosureIndicator
                    case .version:
                        if let bundle = Bundle.main.infoDictionary, let version = bundle["CFBundleShortVersionString"] as? String, let build = bundle["CFBundleVersion"] as? String {
                            cell.textLabel?.text = "版本 \(version) (\(build))"
                        }
                    }
                }
            }
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let sectionType = SettingsSection(rawValue: indexPath.section) {
            switch sectionType {
            case .searchHistory:
                if let rowType = SettingsRowSearchHistory(rawValue: indexPath.row) {
                    switch rowType {
                    case .export:
                        tableView.deselectRow(at: indexPath, animated: true)
                        guard let textLabel = tableView.cellForRow(at: indexPath)?.textLabel else {
                            return
                        }
                        let activityViewController = UIActivityViewController(activityItems: [SearchHistoryManager.historyText], applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = textLabel
                        activityViewController.popoverPresentationController?.sourceRect = textLabel.frame
                        present(activityViewController, animated: true, completion: nil)
                    default:
                        break
                    }
                }
            case .about:
                if let rowType = SettingsRowAbout(rawValue: indexPath.row) {
                    switch rowType {
                    case .website:
                        if let url = URL(string: "https://taiwan-ebook-lover.github.io") {
                            let safari = SFSafariViewController(url: url)
                            safari.preferredBarTintColor = .etw_tintColor
                            safari.preferredControlTintColor = .white
                            present(safari, animated: true, completion: nil)
                        }
                    case .twitter:
                        if let url = URL(string: "https://twitter.com/TaiwanEBook") {
                            let safari = SFSafariViewController(url: url)
                            safari.preferredBarTintColor = .etw_tintColor
                            safari.preferredControlTintColor = .white
                            present(safari, animated: true, completion: nil)
                        }
                    case .privacyPolicy:
                        if let url = URL(string: "https://denkeni.org/ebook-tw-privacy-policy.html") {
                            let safari = SFSafariViewController(url: url)
                            safari.preferredBarTintColor = .etw_tintColor
                            safari.preferredControlTintColor = .white
                            present(safari, animated: true, completion: nil)
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
    }
}

private class SettingsCell : UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
