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

    struct Book : Codable {
        let thumbnail : String
        let title : String
        let link : String
        let priceCurrency : String
        let price : Float
    }
}

final class YuerEbookTableViewCell : UITableViewCell {

    static let cellReuseIdentifier = "YuerEbookTableViewCell"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 2
        imageView?.contentMode = .scaleAspectFit
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class YuerManager : NSObject {

    private weak var tableView : UITableView?
    private var result : YuerEbookResult? = nil

    init(tableView: UITableView) {
        super.init()
        self.tableView = tableView
    }

    func searchEbook(keyword: String) {
        guard let keywordEncoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://ebook.yuer.tw/search?q=" + keywordEncoded) else {
            assertionFailure()
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, urlResponse, error) in
            if let error = error {
                print(error)
                return
            }
            guard let data = data else {
                return
            }
            let jsonDecoder = JSONDecoder()
            guard let ebookResult = try? jsonDecoder.decode(YuerEbookResult.self, from: data) else {
                return
            }
            self.result = ebookResult
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
        task.resume()
    }
}

extension YuerManager : UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return EbookProvider.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let result = result, let ebookProvider = EbookProvider(rawValue: section) else {
            return 1
        }
        switch ebookProvider {
        case .taaze:
            let count = result.taaze.count
            return count
        case .readmoo:
            let count = result.readmoo.count
            return count
        case .books:
            let count = result.booksCompany.count
            return count
        case .kobo:
            let count = result.kobo.count
            return count
        }
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
            }
        }
        assertionFailure()
        return String()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: YuerEbookTableViewCell.cellReuseIdentifier, for: indexPath)
        guard let result = result, let ebookProvider = EbookProvider(rawValue: indexPath.section) else {
            return cell
        }
        let row = indexPath.row
        var book : YuerEbookResult.Book? = nil
        switch ebookProvider {
        case .taaze:
            if row < result.taaze.count {
                book = result.taaze[row]
            }
        case .readmoo:
            if row < result.readmoo.count {
                book = result.readmoo[row]
            }
        case .books:
            if row < result.booksCompany.count {
                book = result.booksCompany[row]
            }
        case .kobo:
            if row < result.kobo.count {
                book = result.kobo[row]
            }
        }
        if let book = book {
            cell.textLabel?.text = book.title
            cell.detailTextLabel?.text = String(format: "%.0f %@", book.price, book.priceCurrency)
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
                        cell.imageView?.image = image
                        cell.setNeedsLayout()
                    }
                })
                task.resume()
            }
        }
        return cell
    }
}

extension YuerManager : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let result = result, let ebookProvider = EbookProvider(rawValue: indexPath.section) else {
            return
        }
        let row = indexPath.row
        var book : YuerEbookResult.Book? = nil
        switch ebookProvider {
        case .taaze:
            if row < result.taaze.count {
                book = result.taaze[row]
            }
        case .readmoo:
            if row < result.readmoo.count {
                book = result.readmoo[row]
            }
        case .books:
            if row < result.booksCompany.count {
                book = result.booksCompany[row]
            }
        case .kobo:
            if row < result.kobo.count {
                book = result.kobo[row]
            }
        }
        guard let urlString = book?.link, let url = URL(string: urlString) else {
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
