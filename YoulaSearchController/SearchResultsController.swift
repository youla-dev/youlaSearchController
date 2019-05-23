//
//  SearchResultsController.swift
//  YoulaSearchController
//
//  Created by i.zarubin on 23/05/2019.
//  Copyright © 2019 i.zarubin. All rights reserved.
//

import UIKit

class SearchResultsController: UIViewController {

    private let tableView: UITableView = UITableView()
    var suggestions = [String]() {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([tableView.topAnchor.constraint(equalTo: view.topAnchor),
                                     tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                     tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
    }
}

extension SearchResultsController: YoulaSearchResultsPresentable {
    var mainView: UIView { return view }
    var fadingView: UIView { return tableView }
}

extension SearchResultsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell") // don't need reuse in the example :)
        cell.textLabel?.text = suggestions[indexPath.row]
        return cell
    }
}

extension SearchResultsController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
