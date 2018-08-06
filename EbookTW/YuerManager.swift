//
//  YuerManager.swift
//  EbookTW
//
//  Created by denkeni on 28/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import SafariServices

private struct YuerEbookResult : Codable {

    let booksCompany : [Book]
    let readmoo : [Book]
    let kobo : [Book]
    let taaze : [Book]
    let bookWalker : [Book]
    let playStore : [Book]
    let pubu : [Book]
    let hyread : [Book]

    struct Book : Codable {
        let thumbnail : String
        let title : String
        let link : String
        let priceCurrency : String
        let price : Float
    }

    func count(of ebookProvider: EbookProvider) -> Int {
        let count : Int
        switch ebookProvider {
        case .taaze:
            count = taaze.count
        case .readmoo:
            count = readmoo.count
        case .books:
            count = booksCompany.count
        case .kobo:
            count = kobo.count
        case .googleplay:
            count = playStore.count
        case .bookwalker:
            count = bookWalker.count
        case .pubu:
            count = pubu.count
        case .hyread:
            count = hyread.count
        }
        return count
    }
}

private struct YuerEbookResultError : Codable {

    let message : String
}

private enum EbookProviderViewState {
    case loading, collapsed, expanded, oneResult, noResult
}

enum YuerEbookTableViewCellType {
    case book, loading, expand, collapse, noResult
}

final class YuerEbookTableViewCell : UITableViewCell {

    static let cellReuseIdentifier = "YuerEbookTableViewCell"
    var type : YuerEbookTableViewCellType = .book {
        didSet {
            switch type {
            case .book:
                break
            case .loading:
                centerTextLabel.textColor = .black
                centerTextLabel.text = "搜尋中..."
            case .expand:
                centerTextLabel.textColor = .etw_tintColor
                centerTextLabel.text = "顯示更多"
            case .collapse:
                centerTextLabel.textColor = .etw_tintColor
                centerTextLabel.text = "收合結果"
            case .noResult:
                centerTextLabel.textColor = .black
                centerTextLabel.text = "無搜尋結果"
            }
        }
    }
    let bookTitleLabel = UILabel()
    let bookPriceLabel = UILabel()
    let bookThumbImageView = UIImageView()
    var bookThumbImageLink : String?
    private let centerTextLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        bookTitleLabel.numberOfLines = 2
        bookTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        bookPriceLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bookThumbImageView.contentMode = .scaleAspectFit
        centerTextLabel.textAlignment = .center
        centerTextLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        contentView.etw_add(subViews: [bookTitleLabel, bookPriceLabel, bookThumbImageView, centerTextLabel])
        let viewsDict : [String: UIView] = ["bookTitleLabel": bookTitleLabel, "bookPriceLabel": bookPriceLabel, "bookThumbImageView": bookThumbImageView]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[bookThumbImageView]|", options: [], metrics: nil, views: viewsDict) +
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-[bookTitleLabel]-[bookPriceLabel]-|", options: .alignAllTrailing, metrics: nil, views: viewsDict) +
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-[bookThumbImageView(90)]-[bookTitleLabel]-|", options: [], metrics: nil, views: viewsDict) +
            [
            centerTextLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            centerTextLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookTitleLabel.text = nil
        bookPriceLabel.text = nil
        bookThumbImageView.image = nil
        bookThumbImageLink = nil
        centerTextLabel.text = nil
    }
}

// MARK: - YuerManager

final class YuerManager : NSObject {

    private weak var tableView : UITableView?
    private var result : YuerEbookResult? = nil
    private var resultStates = [EbookProvider: EbookProviderViewState]()

    private static let session : URLSession = {
        let config = URLSessionConfiguration.default
        let device : String
        if UIDevice.current.userInterfaceIdiom == .pad {
            device = "iPad"
        } else {
            device = "iPhone"
        }
        var version = UIDevice.current.systemVersion
        version = version.replacingOccurrences(of: ".", with: "_")
        // See: ua-parser-js http://faisalman.github.io/ua-parser-js/
        config.httpAdditionalHeaders = ["User-Agent": "(\(device); iPhone OS \(version) like Mac OS X)"]
        let session = URLSession(configuration: config)
        return session
    }()

    init(tableView: UITableView) {
        super.init()
        self.tableView = tableView
    }

    func searchEbook(keyword: String, errorHandler: @escaping (String) -> Void) {
        guard let keywordEncoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://ebook.yuer.tw/search?q=" + keywordEncoded) else {
            assertionFailure()
            return
        }
        self.result = nil
        self.resultStates = [EbookProvider: EbookProviderViewState]()
        self.tableView?.reloadData()
        let task = YuerManager.session.dataTask(with: url) { (data, urlResponse, error) in
            if let error = error {
                errorHandler(error.localizedDescription)
                return
            }
            guard let data = data else {
                return
            }
            let jsonDecoder = JSONDecoder()
            var yuerEbookResult : YuerEbookResult? = nil
            do {
                yuerEbookResult = try jsonDecoder.decode(YuerEbookResult.self, from: data)
            } catch let error {
                print(error)
                if let ebookResultError = try? jsonDecoder.decode(YuerEbookResultError.self, from: data) {
                    errorHandler(ebookResultError.message)
                    return
                }
            }
            guard let ebookResult = yuerEbookResult else {
                errorHandler("搜尋『\(keyword)』時出現未知的錯誤。麻煩回報給開發者，謝謝！")
                return
            }
            self.result = ebookResult
            for index in 0...(EbookProvider.count - 1) {
                if let ebookProvider = EbookProvider(rawValue: index) {
                    let count = ebookResult.count(of: ebookProvider)
                    switch count {
                    case 0:
                        self.resultStates[ebookProvider] = .noResult
                    case 1:
                        self.resultStates[ebookProvider] = .oneResult
                    default:
                        self.resultStates[ebookProvider] = .collapsed
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
        task.resume()
    }
}

// MARK: - UITableViewDataSource

extension YuerManager : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return EbookProvider.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let result = result, let ebookProvider = EbookProvider(rawValue: section) else {
            return 1
        }
        let count = result.count(of: ebookProvider)
        if let resultState = resultStates[ebookProvider] {
            switch resultState {
            case .collapsed:
                return 2
            case .expanded:
                return count + 1
            default:
                return 1
            }
        }
        assertionFailure()
        return 0
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
            case .bookwalker:
                return "BookWalker"
            case .googleplay:
                return "Google Play 圖書"
            case .pubu:
                return "Pubu"
            case .hyread:
                return "HyRead"
            }
        }
        assertionFailure()
        return String()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: YuerEbookTableViewCell.cellReuseIdentifier, for: indexPath) as! YuerEbookTableViewCell
        guard let ebookProvider = EbookProvider(rawValue: indexPath.section) else {
            assertionFailure()
            return cell
        }
        guard let result = result else {
            cell.type = .loading
            return cell
        }
        let row = indexPath.row
        if let viewState = resultStates[ebookProvider] {
            switch viewState {
            case .collapsed:
                if row == 1 {
                    cell.type = .expand
                    return cell
                }
            case .expanded:
                if row == result.count(of: ebookProvider) {
                    cell.type = .collapse
                    return cell
                }
            case .noResult:
                cell.type = .noResult
                return cell
            default:
                cell.type = .book   // continue to show book details below
            }
        }
        if !(row < result.count(of: ebookProvider)) {
            assertionFailure()
            return cell
        }
        let book : YuerEbookResult.Book
        switch ebookProvider {
        case .taaze:
            book = result.taaze[row]
        case .readmoo:
            book = result.readmoo[row]
        case .books:
            book = result.booksCompany[row]
        case .kobo:
            book = result.kobo[row]
        case .bookwalker:
            book = result.bookWalker[row]
        case .googleplay:
            book = result.playStore[row]
        case .pubu:
            book = result.pubu[row]
        case .hyread:
            book = result.hyread[row]
        }
        cell.bookTitleLabel.text = book.title
        cell.bookPriceLabel.text = String(format: "%.0f %@", book.price, book.priceCurrency)
        cell.bookThumbImageLink = book.thumbnail
        if let url = URL(string: book.thumbnail) {
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, urlResponse, error) in
                if let error = error {
                    print(error)
                    return
                }
                guard let data = data else {
                    return
                }
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    if let bookThumbImageLink = cell.bookThumbImageLink {
                        if bookThumbImageLink == book.thumbnail {
                            cell.bookThumbImageView.image = image
                        }
                    }
                }
            })
            task.resume()
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension YuerManager : UITableViewDelegate {

    // Note: we don't use estimatedHeightForRowAt
    // because we can't unify image size of different EbookProvider
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let ebookProvider = EbookProvider(rawValue: indexPath.section) else {
            assertionFailure()
            return 0
        }
        let row = indexPath.row
        if let viewState = resultStates[ebookProvider] {
            switch viewState {
            case .collapsed:
                if row == 1 {
                    return 44.0
                }
            case .expanded:
                guard let result = result else {
                    assertionFailure()
                    return 0
                }
                if row == result.count(of: ebookProvider) {
                    return 44.0
                }
            default:
                break
            }
        }
        return 100.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = indexPath.section
        let row = indexPath.row
        guard let result = result, let ebookProvider = EbookProvider(rawValue: indexPath.section) else {
            return
        }
        if let viewState = resultStates[ebookProvider] {
            switch viewState {
            case .noResult:
                return
            case .collapsed:
                if row == 1 {
                    resultStates[ebookProvider] = .expanded
                    var insertIndexPaths = [IndexPath]()
                    for rowIndex in 1...result.count(of: ebookProvider) {
                        insertIndexPaths.append(IndexPath(row: rowIndex, section: section))
                    }
                    // expanding
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [IndexPath(row: 1, section: section)], with: .fade)
                    tableView.insertRows(at: insertIndexPaths, with: .fade)
                    tableView.endUpdates()
                    return
                }
            case .expanded:
                if row == result.count(of: ebookProvider) {
                    self.resultStates[ebookProvider] = .collapsed
                    var deleteIndexPaths = [IndexPath]()
                    for rowIndex in 1...result.count(of: ebookProvider) {
                        deleteIndexPaths.append(IndexPath(row: rowIndex, section: section))
                    }
                    // collapsing
                    var willScrollToRow = false
                    if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
                        if !(indexPathsForVisibleRows.contains(IndexPath(row: 0, section: section))) {
                            willScrollToRow = true
                        }
                    }
                    tableView.beginUpdates()
                    tableView.deleteRows(at: deleteIndexPaths, with: .fade)
                    tableView.insertRows(at: [IndexPath(row: 1, section: section)], with: .fade)
                    tableView.endUpdates()
                    if willScrollToRow {
                        tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: false)
                    }
                    return
                }
            default:
                break   // continue to show book link below
            }
        }
        if !(row < result.count(of: ebookProvider)) {
            assertionFailure()
        }
        let book : YuerEbookResult.Book
        switch ebookProvider {
        case .taaze:
            book = result.taaze[row]
        case .readmoo:
            book = result.readmoo[row]
        case .books:
            book = result.booksCompany[row]
        case .kobo:
            book = result.kobo[row]
        case .bookwalker:
            book = result.bookWalker[row]
        case .googleplay:
            book = result.playStore[row]
        case .pubu:
            book = result.pubu[row]
        case .hyread:
            book = result.hyread[row]
        }
        guard let url = URL(string: book.link) else {
            return
        }
        let safariVC = SFSafariViewController(url: url)
        if #available(iOS 10.0, *) {
            safariVC.preferredControlTintColor = UIColor.etw_tintColor
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let rootVc = appDelegate.window?.rootViewController {
            rootVc.present(safariVC, animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor(red:0.63, green:0.84, blue:0.81, alpha:1.0)   // #A0D5CE
    }
}
