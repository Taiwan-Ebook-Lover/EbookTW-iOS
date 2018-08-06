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

        backgroundColor = .white
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive

        label.numberOfLines = 0
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .gray
        label.textAlignment = .center
        label.text = """
        Readmoo
        Kobo
        TAAZE
        博客來
        BookWalker
        Google Play 圖書
        Pubu
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
