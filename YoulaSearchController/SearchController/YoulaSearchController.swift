//
//  YoulaSearchController.swift
//  Youla
//
//  Created by i.zarubin on 20/11/2018.
//  Copyright © 2018 allgoritm. All rights reserved.
//

import UIKit

@objc
protocol YoulaSearchControllerDelegate: AnyObject {
    @objc optional func willPresentSearchController(_ searchController: YoulaSearchController)
    @objc optional func didPresentSearchController(_ searchController: YoulaSearchController)
    @objc optional func didDismissSearchController(_ searchController: YoulaSearchController)
    @objc optional func willDismissSearchController(_ searchController: YoulaSearchController)
}

@objcMembers
final class YoulaSearchController: UIViewController {
    private weak var parentNavigationViewController: UINavigationController?
    private var collapseAnimated: Bool = true

    var searchResultsController: YoulaSearchResultsController?
    var hidesNavigationBarDuringPresentation: Bool

    weak var delegate: YoulaSearchControllerDelegate?
    weak var mainViewController: UIViewController?

    lazy var searchBar = YoulaSearchBar()

    init(mainViewController: UIViewController?,
         searchResultsController: YoulaSearchResultsController? = nil,
         hidesNavigationBarDuringPresentation: Bool = true) {
        self.hidesNavigationBarDuringPresentation = hidesNavigationBarDuringPresentation
        super.init(nibName: nil, bundle: nil)
        self.mainViewController = mainViewController
        self.searchResultsController = searchResultsController
        self.searchBar.activeDelegate = self
    }

    override func loadView() {
        self.view = UIView()
        self.view.frame = CGRect.zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.parentNavigationViewController = mainViewController?.navigationController
        if let navigationController = self.parentNavigationViewController,
            !navigationController.isNavigationBarHidden,
            self.hidesNavigationBarDuringPresentation {
            navigationController.isNavigationBarHidden = true
        }
        self.delegate?.willPresentSearchController?(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationController = self.parentNavigationViewController,
            navigationController.isNavigationBarHidden,
            self.hidesNavigationBarDuringPresentation {
            navigationController.isNavigationBarHidden = false
        }
        self.delegate?.willDismissSearchController?(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate?.didPresentSearchController?(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.didDismissSearchController?(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = mainViewController?.view.bounds.size ?? .zero
        layoutSearchResultsController(with: size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        layoutSearchResultsController(with: size)
    }

    private func layoutSearchResultsController(with size: CGSize) {
        // swiftlint:disable identifier_name
        let y: CGFloat
        // swiftlint:enable identifier_name
        if searchBar.superview is UINavigationBar {
            if #available(iOS 11, *) {
                y = view.safeAreaInsets.top
            } else {
                y = topLayoutGuide.length
            }
        } else {
            y = searchBar.frame.maxY
        }
        searchResultsController?.mainView.frame = CGRect(x: 0, y: y, width: size.width, height: size.height - y)
    }

    func collapseWithoutAnimation() {
        collapseAnimated = false
        isActive = false
        collapseAnimated = true
    }

    var isActive: Bool {
        set {
            if newValue {
                self.searchBar.activate()
            } else {
                self.searchBar.deactivate()
            }
        }
        get {
            return self.searchBar.isActive
        }
    }
}

extension YoulaSearchController: YoulaSearchBarActiveDelegate {
    func willBecomeActive() {
        guard let mainViewController = self.mainViewController else {
            return
        }

        if let resultsViewController = self.searchResultsController {
            mainViewController.addChild(resultsViewController)

            let resultsView = resultsViewController.mainView
            resultsView.alpha = 0.0

            mainViewController.view.addSubview(resultsView)

            resultsViewController.fadingView.alpha = 0.0
            UIView.animate(withDuration: 0.25) {
                if self.hidesNavigationBarDuringPresentation {
                    mainViewController.navigationController?.setNavigationBarHidden(true, animated: true)
                }
                resultsViewController.fadingView.alpha = 1.0
                resultsView.alpha = 1.0
                mainViewController.view.layoutIfNeeded()
            }

            resultsViewController.didMove(toParent: mainViewController)
        }

        mainViewController.view.setNeedsLayout()
        mainViewController.view.layoutIfNeeded()

        mainViewController.addChild(self)
        mainViewController.view.addSubview(self.view)
        didMove(toParent: mainViewController)
        view.setNeedsLayout()
    }

    func willResignActive() {
        if hidesNavigationBarDuringPresentation {
            mainViewController?.navigationController?.setNavigationBarHidden(false, animated: collapseAnimated)
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        didMove(toParent: nil)

        if let resultsController = searchResultsController {
            resultsController.fadingView.alpha = 1

            UIView.animate(withDuration: collapseAnimated ? 0.25 : 0, animations: {
                resultsController.fadingView.alpha = 0
            }, completion: { _ in
                let resultsMainView = resultsController.mainView
                resultsController.willMove(toParent: nil)

                UIView.animate(withDuration: self.collapseAnimated ? 0.25 : 0.0,
                               animations: {
                                resultsMainView.alpha = 0.0
                }, completion: { _ in
                    resultsMainView.removeFromSuperview()
                    resultsController.removeFromParent()
                    resultsController.didMove(toParent: nil)
                })
            })
        }
    }
}
