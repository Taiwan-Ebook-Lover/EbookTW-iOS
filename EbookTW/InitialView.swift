//
//  InitialView.swift
//  EbookTW
//
//  Created by denkeni on 28/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit

final class InitialView : UIScrollView {

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive

        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        if #available(iOS 13.0, *) {
            label.textColor = .systemGray
        } else {
            label.textColor = .gray
        }
        label.textAlignment = .center
        label.text = """
        Readmoo
        Kobo
        TAAZE
        博客來
        BookWalker
        Google Play 圖書
        Pubu
        HyRead
        """

        etw_add(subViews: [label])
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            label.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
