//
//  YoulaSearchBar.swift
//  Youla
//
//  Created by i.zarubin on 20/11/2018.
//  Copyright © 2018 allgoritm. All rights reserved.
//

import UIKit

@objc
public protocol YoulaSearchBarActiveDelegate: AnyObject {
    @objc optional func willBecomeActive()
    @objc optional func willResignActive()
}

@objc
protocol YoulaSearchBarDelegate: AnyObject {
    @objc optional func searchBarTextDidBeginEditing(_ searchBar: YoulaSearchBar)
    @objc optional func searchBarCancelButtonClicked(_ searchBar: YoulaSearchBar)
    @objc optional func searchBarSearchButtonClicked(_ searchBar: YoulaSearchBar)
    @objc optional func searchBarTextDidEndEditing(_ searchBar: YoulaSearchBar)
    @objc optional func searchBarTextDidChange(text: String)
}

private final class YoulaSearchBarTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var bounds = super.textRect(forBounds: bounds)
        bounds.origin.y += 1
        return bounds
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var bounds = super.editingRect(forBounds: bounds)
        bounds.origin.y += 1
        return bounds
    }
}

@objcMembers
final class YoulaSearchBar: UIView {
    var shouldClearOnEndEditing: Bool = true
    var shouldReturnTextOnCancel: Bool = false

    var shouldShowSeparator: Bool = false {
        didSet {
            bottomSeparator.isHidden = !shouldShowSeparator
        }
    }

    var text: String? {
        set {
            textField.text = newValue
            setupClearButton(textFiled: self.textField)
        }
        get {
            return textField.text
        }
    }

    var textColor: UIColor = UIColor.textFieldTextColor {
        didSet {
            textField.textColor = textColor
        }
    }

    var textFieldBackgroundColor: UIColor = UIColor.textFieldBackgroundColor {
        didSet {
            textField.backgroundColor = textFieldBackgroundColor
        }
    }

    var isActive: Bool {
        return isActiveSearchBar
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        set {
            textField.autocapitalizationType = newValue
        }
        get {
            return textField.autocapitalizationType
        }
    }

    var isAlwaysShowCancelButton: Bool = false {
        didSet {
            if self.isAlwaysShowCancelButton || self.isActiveSearchBar {
                self.showCancelButton(animated: false)
            } else {
                self.hideCancelButton(animated: false)
            }
        }
    }

    var activatedPlaceholderColor: UIColor = UIColor.activatedPlaceholderColor {
        didSet {
            updatePlaceholderAppearence()
        }
    }

    var deactivatedPlaceholderColor: UIColor = UIColor.deactivatedPlaceholderColor {
        didSet {
            updatePlaceholderAppearence()
        }
    }

    var cancelButtonText: String = "Cancel" {
        didSet {
            setupCancelButton()
        }
    }

    var cancelButtonColor: UIColor = UIColor.cancelButtonColor {
        didSet {
            setupCancelButton()
        }
    }

    private var placeholderColor: UIColor {
        if isActiveSearchBar {
            return activatedPlaceholderColor
        } else {
            return deactivatedPlaceholderColor
        }
    }

    var placeholder: String = "Search..." {
        didSet {
            updatePlaceholderAppearence()
        }
    }

    weak var activeDelegate: YoulaSearchBarActiveDelegate?

    weak var delegate: YoulaSearchBarDelegate?

    private let defaultHeight: CGFloat = 44
    private let topOffset: CGFloat = 4
    private let textFieldHeight: CGFloat = 32
    private let sideViewSize: CGFloat = 24
    private let containerSearchImageWidth: CGFloat = 36
    private let cancelButtonOffset: CGFloat = 16
    private let textFieldLeftOffset: CGFloat = 8

    private let textFieldDefaultRightOffset: CGFloat = 8
    private var textFieldRightOffset: CGFloat = 8

    private var originalText: String?

    private var isActiveSearchBar: Bool = false

    private lazy var sideViewFrame: CGRect = {
        return CGRect(x: 6,
                      y: (self.textFieldHeight - self.sideViewSize) / 2,
                      width: self.sideViewSize,
                      height: self.sideViewSize)
    }()

    private lazy var containerViewFrame: CGRect = {
        return CGRect(x: 0,
                      y: 0,
                      width: self.containerSearchImageWidth,
                      height: self.textFieldHeight)
    }()

    private let bottomSeparator = CALayer()
    private let textField = YoulaSearchBarTextField()
    private let cancelButton = UIButton(type: .system)
    private let containerSearchImageView = UIView()
    private let containerClearButtonView = UIView()
    private let searchImageView = UIImageView(image: UIImage(named: "searchBarIcon"))
    private let clearButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: superview?.frame.width ?? 0, height: defaultHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    private func initialSetup() {
        backgroundColor = UIColor.white
        textField.returnKeyType = .search
        textField.delegate = self
        addSubview(textField)
        addSubview(cancelButton)
        layer.addSublayer(bottomSeparator)
        setupTextField()
        setupTextFieldSideViews()
        setupCancelButton()
        setupBottomSeparator()
        setNeedsLayout()
    }

    private func setupBottomSeparator() {
        bottomSeparator.backgroundColor = UIColor.separatorColor.cgColor
        bottomSeparator.isHidden = true
    }

    private func setupTextField() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = textFieldBackgroundColor
        textField.textColor = textColor
        textField.textAlignment = .left
        textField.rightViewMode = .never
        textField.layer.cornerRadius = 10
        textField.leftViewMode = .always
        textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        let attributedString = NSAttributedString(string: placeholder,
                                                  attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        textField.attributedPlaceholder = attributedString
        textField.leftView = containerSearchImageView
        textField.rightView = containerClearButtonView
        textField.isAccessibilityElement = true
    }

    private func setupTextFieldSideViews() {
        clearButton.frame = sideViewFrame
        clearButton.setImage(UIImage(named: "searchBarIconClear"), for: .normal)
        clearButton.addTarget(self, action: #selector(clearButtonTouch), for: .touchUpInside)

        searchImageView.frame = sideViewFrame

        containerSearchImageView.frame = containerViewFrame
        containerClearButtonView.frame = containerViewFrame
        containerSearchImageView.addSubview(searchImageView)
        containerClearButtonView.addSubview(clearButton)
    }

    private func setupCancelButton() {
        let attirbutedTitle = NSAttributedString(string: cancelButtonText,
                                                 attributes: [NSAttributedString.Key.foregroundColor: cancelButtonColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)])
        cancelButton.setAttributedTitle(attirbutedTitle, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTouch), for: .touchUpInside)
        cancelButton.isUserInteractionEnabled = false
        hideCancelButton(animated: false)
    }

    private func setupClearButton(textFiled: UITextField) {
        let isEmpty = textField.text?.isEmpty ?? true
        textField.rightViewMode = isEmpty ? .never : .always
    }

    private func layout() {
        textField.frame = CGRect(x: textFieldLeftOffset, y: topOffset, width: bounds.width - textFieldLeftOffset - textFieldRightOffset, height: textFieldHeight)
        cancelButton.sizeToFit()
        let cancelButtonY: CGFloat = textField.bounds.height / 2 + topOffset - cancelButton.bounds.height / 2
        cancelButton.frame.origin = CGPoint(x: textField.frame.maxX + cancelButtonOffset, y: cancelButtonY)
        bottomSeparator.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)
    }

    private func updatePlaceholderAppearence() {
        let attributedString = NSAttributedString(string: placeholder,
                                                  attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        textField.attributedPlaceholder = attributedString
    }
}

extension YoulaSearchBar {

    func activate() {
        guard !isActiveSearchBar else { return }
        isActiveSearchBar = true
        activeDelegate?.willBecomeActive?()
        if !isAlwaysShowCancelButton {
            showCancelButton()
        }
        updatePlaceholderAppearence()
    }

    func deactivate() {
        guard isActiveSearchBar else { return }
        isActiveSearchBar = false
        textField.resignFirstResponder()
        activeDelegate?.willResignActive?()
        if !isAlwaysShowCancelButton {
            hideCancelButton()
        }
        updatePlaceholderAppearence()
        textField.resignFirstResponder()
    }

    func hideCancelButton(animated: Bool = true, completionHandler: (() -> Void)? = nil) {
        cancelButton.isUserInteractionEnabled = false
        changeStateCancelButton(animated: animated,
                                offset: textFieldDefaultRightOffset) {
                                    self.cancelButton.isHidden = true
                                    completionHandler?()
        }
    }

    func showCancelButton(animated: Bool = true, completionHandler: (() -> Void)? = nil) {
        cancelButton.isHidden = false
        changeStateCancelButton(animated: animated,
                                offset: 2 * cancelButtonOffset + self.cancelButton.intrinsicContentSize.width) {
                                    self.cancelButton.isUserInteractionEnabled = true
                                    completionHandler?()
        }
    }

    private func changeStateCancelButton(animated: Bool, offset: CGFloat, completionHandler: (() -> Void)?) {
        textFieldRightOffset = offset
        if animated {
            UIView.animate(withDuration: 0.25, animations: ({
                self.layoutIfNeeded()
                self.layout()
            })) { _ in
                completionHandler?()
            }
        } else {
            layoutIfNeeded()
            completionHandler?()
        }
    }

    private func textFieldBeginEditing() {
        textField.becomeFirstResponder()
    }

    private func textFieldEndEditing() {
        textField.endEditing(true)
    }

    private func clearOrReturnTextIfNeeded() {
        if shouldClearOnEndEditing {
            text = ""
            delegate?.searchBarTextDidChange?(text: "")
        } else if shouldReturnTextOnCancel {
            text = originalText
            delegate?.searchBarTextDidChange?(text: originalText ?? "")
        }
    }
}

private extension YoulaSearchBar {

    @objc
    func clearButtonTouch() {
        if !textField.isEditing {
            textField.becomeFirstResponder()
        }
        textField.text = ""
        setupClearButton(textFiled: textField)
        delegate?.searchBarTextDidChange?(text: "")
    }

    @objc
    func cancelButtonTouch() {
        clearOrReturnTextIfNeeded()
        textFieldEndEditing()
        delegate?.searchBarCancelButtonClicked?(self)
        deactivate()
    }

    @objc
    func textFieldEditingChanged(sender: UITextField) {
        setupClearButton(textFiled: textField)
        delegate?.searchBarTextDidChange?(text: sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    @objc
    func textFieldDidBeginEditing(sender: UITextField) {
        delegate?.searchBarTextDidBeginEditing?(self)
    }

    @objc
    func textFieldDidEndEditing(sender: UITextField) {
        delegate?.searchBarTextDidEndEditing?(self)
        setupClearButton(textFiled: textField)
    }
}

extension YoulaSearchBar: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        originalText = textField.text
        activate()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.searchBarSearchButtonClicked?(self)
        let shouldReturn = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        if shouldReturn {
            deactivate()
            clearOrReturnTextIfNeeded()
        }
        return shouldReturn
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        setupClearButton(textFiled: textField)
        return true
    }
}

private extension UIColor {
    static let activatedPlaceholderColor = UIColor(white: 176 / 255, alpha: 1)
    static let deactivatedPlaceholderColor = UIColor(white: 133 / 255, alpha: 1)
    static let separatorColor = UIColor(white: 235 / 255, alpha: 1)
    static let textFieldBackgroundColor = UIColor(white: 242 / 255, alpha: 1)
    static let textFieldTextColor = UIColor(white: 51 / 255, alpha: 1)
    static let cancelButtonColor = UIColor(red: 68 / 255, green: 151 / 255, blue: 206 / 255, alpha: 1)
}
