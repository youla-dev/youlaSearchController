//
//  YoulaSearchResultsPresentable.swift
//  Youla
//
//  Created by i.zarubin on 30/11/2018.
//  Copyright © 2018 allgoritm. All rights reserved.
//

import UIKit

typealias YoulaSearchResultsController = UIViewController & YoulaSearchResultsPresentable

protocol YoulaSearchResultsPresentable {
    var mainView: UIView { get }
    var fadingView: UIView { get }
}
