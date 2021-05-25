//
//  APIManager.swift
//  EbookTW
//
//  Created by denkeni on 28/11/2017.
//  Copyright © 2017 Denken. All rights reserved.
//

import UIKit
import SafariServices

private struct EbookResponse : Codable {

    let results : [Result]

    /// Bookstores
    struct Result : Codable {
        let bookstore : Bookstore
        let books : [Book]
        let isOkay : Bool
        let status : String
    }

    struct Bookstore : Codable {
        let id : String
        let displayName : String
        let isOnline : Bool
    }

    struct Book : Codable {
        let thumbnail : String
        let title : String
        let link : String
        let priceCurrency : String
        let price : Float
    }
}

private struct EbookResultError : Codable {

    let message : String
}

private enum EbookProviderViewState {
    case loading, collapsed, expanded, noResult
    case notOnline  // developer turned off for crawler reason
    case notOkay    // crawler failed to parse
}

enum EbookTableViewCellType {
    case book
    case text(text: String)
    case action(text: String)
}

final class EbookTableViewCell : UITableViewCell {

    static let cellReuseIdentifier = "EbookTableViewCell"
    var type : EbookTableViewCellType = .book {
        didSet {
            switch type {
            case .book:
                centerTextLabel.text = nil
                selectionStyle = .default
            case let .text(text):
                if #available(iOS 13.0, *) {
                    centerTextLabel.textColor = .label
                } else {
                    centerTextLabel.textColor = .black
                }
                centerTextLabel.text = text
                selectionStyle = .none
            case let .action(text):
                centerTextLabel.textColor = .etw_tintColor
                centerTextLabel.text = text
                selectionStyle = .default
            }
        }
    }
    var showBookImageView : Bool = true {
        didSet {
            switch showBookImageView {
            case true:
                bookThumbImageViewWidthConstraint.constant = 90.0
            case false:
                bookThumbImageViewWidthConstraint.constant = 0
            }
        }
    }

    let bookTitleLabel = UILabel()
    let bookPriceLabel = UILabel()
    let bookThumbImageView = UIImageView()
    var bookThumbImageLink : String?
    private let centerTextLabel = UILabel()
    private var bookThumbImageViewWidthConstraint : NSLayoutConstraint

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        bookThumbImageViewWidthConstraint = bookThumbImageView.widthAnchor.constraint(equalToConstant: 90.0)
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
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-[bookThumbImageView]-[bookTitleLabel]-|", options: [], metrics: nil, views: viewsDict) +
            [
                bookTitleLabel.heightAnchor.constraint(equalTo: bookPriceLabel.heightAnchor, multiplier: 3.0),
                bookThumbImageViewWidthConstraint,
                centerTextLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                centerTextLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - APIManager

final class APIManager : NSObject {

    private weak var tableView : UITableView?
    private var response : EbookResponse? = nil
    private var resultStates = [String: EbookProviderViewState]()
    private var showBookImageView : Bool = true

    private static let session : URLSession = {
        let config = URLSessionConfiguration.default
        let device : String
        if UIDevice.current.userInterfaceIdiom == .pad {
            device = "iPad"
        } else {
            device = "iPhone"
        }
        var systemVersion = UIDevice.current.systemVersion
        systemVersion = systemVersion.replacingOccurrences(of: ".", with: "_")
        // See: ua-parser-js http://faisalman.github.io/ua-parser-js/
        if let infoDictionary = Bundle.main.infoDictionary, let version = infoDictionary["CFBundleShortVersionString"] {
            config.httpAdditionalHeaders = ["User-Agent": "EbookTW/\(version) (\(device); iPhone OS \(systemVersion) like Mac OS X)"]
        }
        let session = URLSession(configuration: config)
        return session
    }()

    init(tableView: UITableView) {
        super.init()
        self.tableView = tableView
    }

    func searchEbook(keyword: String, errorHandler: @escaping (String) -> Void) {
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = "ebook.yuer.tw"
        if AppConfig.isDevAPI {
            urlComponent.port = 8443
        }
        urlComponent.path = "/v1/searches"
        urlComponent.queryItems = [     // Percent encoding is automatically done with RFC 3986
            URLQueryItem(name: "q", value: keyword)
        ]
        guard let url = urlComponent.url else {
            assertionFailure()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST";
        self.response = nil
        self.resultStates = [String: EbookProviderViewState]()
        self.showBookImageView = !(UserDefaults.standard.bool(forKey: SettingsKey.isDataSaving))
        self.tableView?.reloadData()
        let task = APIManager.session.dataTask(with: request) { (data, urlResponse, error) in
            if let error = error {
                errorHandler(error.localizedDescription)
                return
            }
            let jsonDecoder = JSONDecoder()
            // From Settings.bundle
            let isDebugMode = UserDefaults.standard.bool(forKey: "debugMode")
            if isDebugMode {
                let successfulStatusCodes = 200..<300
                if let httpUrlResponse = urlResponse as? HTTPURLResponse, !successfulStatusCodes.contains(httpUrlResponse.statusCode) {
                    var errorMessage = "HTTP Error \(httpUrlResponse.statusCode)"
                    if let data = data {
                        if let ebookResultError = try? jsonDecoder.decode(EbookResultError.self, from: data) {
                            errorMessage += "\n\(ebookResultError.message)"
                        } else {
                            errorMessage += "\nNot error message"
                        }
                    } else {
                        errorMessage += "\nNo data"
                    }
                    errorHandler(errorMessage)
                    return
                }
            }
            guard let data = data else {
                errorHandler("No data")
                return
            }
            var ebookResponse : EbookResponse? = nil
            do {
                ebookResponse = try jsonDecoder.decode(EbookResponse.self, from: data)
            } catch let error as DecodingError {
                if let ebookResultError = try? jsonDecoder.decode(EbookResultError.self, from: data) {
                    errorHandler(ebookResultError.message)
                    return
                }
                // From Settings.bundle
                let isDebugMode = UserDefaults.standard.bool(forKey: "debugMode")
                if isDebugMode {
                    switch error {
                    case .dataCorrupted(let context):
                        errorHandler(context.debugDescription)
                    case .keyNotFound(_, let context):
                        errorHandler(context.debugDescription)
                    case .typeMismatch(_, let context):
                        errorHandler(context.debugDescription)
                    case .valueNotFound(_, let context):
                        errorHandler(context.debugDescription)
                    @unknown default:
                        errorHandler("unknown error")
                    }
                }
            } catch let error {
                print(error)
            }
            guard let ebookResponse = ebookResponse else {
                errorHandler("搜尋「\(keyword)」時出現錯誤。麻煩回報給開發者，謝謝！")
                return
            }
            self.response = ebookResponse
            for result in ebookResponse.results {
                let bookstoreID = result.bookstore.id
                let count = result.books.count
                switch count {
                case 0:
                    if !result.bookstore.isOnline {
                        self.resultStates[bookstoreID] = .notOnline
                    } else if !result.isOkay {
                        self.resultStates[bookstoreID] = .notOkay
                    } else {
                        self.resultStates[bookstoreID] = .noResult
                    }
                default:
                    self.resultStates[bookstoreID] = .collapsed
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

extension APIManager : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        guard let response = self.response else {
            return 1    // .loading
        }
        return response.results.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let result = self.response?.results[section] else {
            return 1    // .loading
        }
        let bookstoreID = result.bookstore.id
        let count = result.books.count
        if let resultState = self.resultStates[bookstoreID] {
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
        guard let result = self.response?.results[section] else {
            return nil
        }
        let bookstoreDisplayName = result.bookstore.displayName
        return bookstoreDisplayName
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EbookTableViewCell.cellReuseIdentifier, for: indexPath) as! EbookTableViewCell
        cell.bookTitleLabel.text = nil
        cell.bookPriceLabel.text = nil
        cell.bookThumbImageView.image = nil
        cell.bookThumbImageLink = nil
        cell.type = .book   // default value
        guard let response = self.response else {
            cell.type = .text(text: "搜尋中...")
            return cell
        }
        let result = response.results[indexPath.section]
        let bookstoreID = result.bookstore.id
        let row = indexPath.row
        if let viewState = resultStates[bookstoreID] {
            switch viewState {
            case .collapsed:
                if row == 1 {
                    cell.type = .action(text: "顯示更多")
                    return cell
                }
            case .expanded:
                if row == result.books.count {
                    cell.type = .action(text: "收合結果")
                    return cell
                }
            case .noResult:
                cell.type = .text(text: "無搜尋結果")
                return cell
            case .notOnline:
                cell.type = .text(text: "暫時停用")
                return cell
            case .notOkay:
                let status = result.status
                cell.type = .text(text: "搜尋失敗：\(status)")
                return cell
            default:
                break
            }
        }
        // .book: continue to show book details below
        if !(row < result.books.count) {
            assertionFailure()
            return cell
        }
        let book = result.books[row]
        cell.bookTitleLabel.text = book.title
        cell.bookPriceLabel.text = String(format: "%.0f %@", book.price, book.priceCurrency)
        cell.bookThumbImageLink = book.thumbnail
        if showBookImageView, let url = URL(string: book.thumbnail) {
            cell.showBookImageView = true
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
        } else {
            cell.showBookImageView = false
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension APIManager : UITableViewDelegate {

    // Note: we don't use estimatedHeightForRowAt
    // because we can't unify image size of different EbookProvider
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let result = self.response?.results[indexPath.section] else {
            return 44.0 // .loading
        }
        let bookstoreID = result.bookstore.id
        let row = indexPath.row
        if let viewState = resultStates[bookstoreID] {
            switch viewState {
            case .collapsed:
                if row == 1 {
                    return 44.0
                }
            case .expanded:
                if row == result.books.count {
                    return 44.0
                }
            default:
                break
            }
        }
        return 100.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StoreReview.resetTimer()
        let section = indexPath.section
        let row = indexPath.row
        guard let result = self.response?.results[section] else {
            return
        }
        let bookstoreID = result.bookstore.id
        if let viewState = resultStates[bookstoreID] {
            switch viewState {
            case .noResult, .notOnline, .notOkay:
                return
            case .collapsed:
                if row == 1 {
                    resultStates[bookstoreID] = .expanded
                    var insertIndexPaths = [IndexPath]()
                    for rowIndex in 1...result.books.count {
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
                if row == result.books.count {
                    self.resultStates[bookstoreID] = .collapsed
                    var deleteIndexPaths = [IndexPath]()
                    for rowIndex in 1...result.books.count {
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
        if !(row < result.books.count) {
            assertionFailure()
        }
        let book = result.books[row]
        guard let url = URL(string: book.link) else {
            return
        }
        let safariVC = SFSafariViewController(url: url)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let rootVc = appDelegate.window?.rootViewController {
            rootVc.present(safariVC, animated: true, completion: nil)
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

// MARK: - UIScrollViewDelegate

extension APIManager : UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        StoreReview.resetTimer()
    }
}
