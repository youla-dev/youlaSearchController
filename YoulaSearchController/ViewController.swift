//
//  ViewController.swift
//  YoulaSearchController
//
//  Created by i.zarubin on 23/05/2019.
//  Copyright © 2019 i.zarubin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var searchController: YoulaSearchController!
    private var searchResultsController: SearchResultsController!

    private lazy var searchItems: [String] = makeSearchItems()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsController = SearchResultsController(nibName: nil, bundle: nil)
        searchController = YoulaSearchController(mainViewController: self, searchResultsController: searchResultsController, hidesNavigationBarDuringPresentation: true)
        searchController.searchBar.delegate = self
        layout()
    }

    func layout() {
        let searchBar = searchController.searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        let topConstraint: NSLayoutConstraint
        if #available(iOS 11, *) {
            topConstraint = searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        } else {
            topConstraint = searchBar.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
        }
        let leadingConstraint = searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingConstraint = searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint])
    }
}

extension ViewController: YoulaSearchBarDelegate {
    func searchBarTextDidChange(text: String) {
        let results = searchItems.filter { (item) -> Bool in
            item.lowercased().hasPrefix(text.lowercased())
        }
        searchResultsController.suggestions = results
    }

    func searchBarTextDidBeginEditing(_ searchBar: YoulaSearchBar) {
        searchResultsController.suggestions = searchItems
    }
}

private extension ViewController {
    func makeSearchItems() -> [String] {
        return ["iPhone SE",
                "iPhone 8",
                "iPhone X",
                "iPhone XR",
                "iPhone XS",
                "iPad Air",
                "iPad Pro"]
    }
}

