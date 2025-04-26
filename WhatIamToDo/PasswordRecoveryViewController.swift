//
//  PasswordRecoveryViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 31.01.2025.
//

import UIKit

class PasswordRecoveryViewController: UIViewController {
    
    // MARK: - Check State
    enum CheckState {
        case idle    // изначальное состояние
        case success // успешная проверка (галочка)
        case fail    // неудачная проверка (крест)
    }
    
    // Состояния для проверки email и одноразового кода
    private var emailCheckState: CheckState = .idle
    private var tokenCheckState: CheckState = .idle
    
    // MARK: - UI Elements
    
    private let backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Back"
        config.image = UIImage(named: "back_arrow")?.withRenderingMode(.alwaysOriginal)
        config.imagePlacement = .leading
        config.imagePadding = -12
        config.baseForegroundColor = .black
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont(name: "Poppins-Medium", size: 20) ?? .systemFont(ofSize: 20)
            return outgoing
        }
        let button = UIButton(configuration: config, primaryAction: nil)
        button.configurationUpdateHandler = { btn in
            guard var newConfig = btn.configuration else { return }
            newConfig.baseForegroundColor = btn.isHighlighted ? UIColor(white: 0.0, alpha: 0.6) : .black
            btn.configuration = newConfig
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Password recovery"
        label.font = UIFont(name: "Poppins-Regular", size: 24)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Please fill in the form to continue"
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        label.textColor = UIColor.black.withAlphaComponent(0.55)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Email field
    private let emailTextFieldContainer: UIView = {
        let container = UIView()
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 6
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont(name: "Poppins-Regular", size: 16)
        tf.textColor = UIColor(white: 0, alpha: 0.7)
        tf.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1)
        tf.layer.cornerRadius = 17
        tf.layer.masksToBounds = true
        tf.setLeftPaddingPoints(24)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0, alpha: 0.45),
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        ]
        tf.attributedPlaceholder = NSAttributedString(string: "Email", attributes: placeholderAttributes)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private lazy var emailCheckButton: UIButton = {
        let btn = UIButton(type: .system)
        if let arrowCircle = UIImage(named: "arrow_in_circle")?.withRenderingMode(.alwaysOriginal) {
            btn.setImage(arrowCircle, for: .normal)
        }
        btn.layer.cornerRadius = 14
        btn.clipsToBounds = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // One-time code field
    private let oneTimeKeyTextFieldContainer: UIView = {
        let container = UIView()
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 6
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let oneTimeKeyTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont(name: "Poppins-Regular", size: 16)
        tf.textColor = UIColor(white: 0, alpha: 0.7)
        tf.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1)
        tf.layer.cornerRadius = 17
        tf.layer.masksToBounds = true
        tf.setLeftPaddingPoints(24)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.rightViewMode = .never
        tf.translatesAutoresizingMaskIntoConstraints = false
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0, alpha: 0.45),
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        ]
        tf.attributedPlaceholder = NSAttributedString(string: "One-time key", attributes: placeholderAttributes)
        return tf
    }()
    
    // New password field
    private let newPasswordTextFieldContainer: UIView = {
        let container = UIView()
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 6
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let newPasswordTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont(name: "Poppins-Regular", size: 16)
        tf.textColor = UIColor(white: 0, alpha: 0.7)
        tf.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1)
        tf.layer.cornerRadius = 17
        tf.layer.masksToBounds = true
        tf.setLeftPaddingPoints(24)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 0, alpha: 0.45),
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        ]
        tf.attributedPlaceholder = NSAttributedString(string: "New password", attributes: placeholderAttributes)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // Resend label ("Resend one-time key? Click here")
    private lazy var resendLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        let fullString = "Resend one-time key? Click here"
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        ]
        let highlightAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 245/255, green: 123/255, blue: 93/255, alpha: 1),
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        ]
        let attributed = NSMutableAttributedString(string: fullString, attributes: normalAttrs)
        let rangeOfHere = (fullString as NSString).range(of: "here")
        if rangeOfHere.location != NSNotFound {
            attributed.setAttributes(highlightAttrs, range: rangeOfHere)
        }
        label.attributedText = attributed
        label.textAlignment = .center
        return label
    }()
    
    // Change Password button
    private let changePasswordButtonContainer: UIView = {
        let container = UIView()
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 6
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private let changePasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Change Password", for: .normal)
        btn.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 16)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 245/255, green: 123/255, blue: 93/255, alpha: 1.0)
        btn.layer.cornerRadius = 17
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        
        // Добавляем UI элементы
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailTextFieldContainer)
        emailTextFieldContainer.addSubview(emailTextField)
        emailTextFieldContainer.addSubview(emailCheckButton)
        view.addSubview(oneTimeKeyTextFieldContainer)
        oneTimeKeyTextFieldContainer.addSubview(oneTimeKeyTextField)
        view.addSubview(newPasswordTextFieldContainer)
        newPasswordTextFieldContainer.addSubview(newPasswordTextField)
        view.addSubview(resendLabel)
        view.addSubview(changePasswordButtonContainer)
        changePasswordButtonContainer.addSubview(changePasswordButton)
        
        setupConstraints()
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        changePasswordButton.addTarget(self, action: #selector(changePasswordTapped), for: .touchUpInside)
        emailCheckButton.addTarget(self, action: #selector(emailCheckButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(handleTapOnResendLabel(_:)))
        resendLabel.addGestureRecognizer(labelTap)
    }
    
    // MARK: - Actions
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // Изменённая логика: если состояние уже успешно – больше не трогаем (галочка остаётся),
    // а если ранее был крест (fail), то сбрасываем в idle и запускаем проверку
    @objc private func emailCheckButtonTapped() {
        dismissKeyboard()
        if emailCheckState == .success { return }
        if emailCheckState == .fail {
            revertToEmailIdleState()
        }
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showEmailFail()
            showAlert(withTitle: "Error", message: "Email is required.") {
                self.revertToEmailIdleState()
            }
            return
        }
        
        // Используем функцию recoverPassword из Routes.swift
        recoverPassword(email: email) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.showEmailSuccess()  // Галочка появляется и закрепляется
                    self?.showAlert(withTitle: "Success", message: message)
                case .failure(let error):
                    self?.showEmailFail()
                    let detailedMessage = self?.interpretRecoverPasswordError(error) ?? error.localizedDescription
                    self?.showAlert(withTitle: "Error", message: detailedMessage) {
                        self?.revertToEmailIdleState()
                    }
                }
            }
        }
    }
    
    @objc private func handleTapOnResendLabel(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = resendLabel.attributedText else { return }
        let fullString = attributedText.string
        let rangeOfHere = (fullString as NSString).range(of: "here")
        if rangeOfHere.location == NSNotFound { return }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: resendLabel.bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = resendLabel.lineBreakMode
        textContainer.maximumNumberOfLines = resendLabel.numberOfLines
        
        let locationOfTouch = gesture.location(in: resendLabel)
        var offset = CGPoint.zero
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        if usedRect.size.width < resendLabel.bounds.width {
            offset.x = (resendLabel.bounds.width - usedRect.size.width) / 2.0
        }
        let locationInTextContainer = CGPoint(x: locationOfTouch.x - offset.x, y: locationOfTouch.y - offset.y)
        let index = layoutManager.characterIndex(for: locationInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if NSLocationInRange(index, rangeOfHere) {
            handleClickOnHere()
        }
    }
    
    private func handleClickOnHere() {
        guard emailCheckState == .success, let email = emailTextField.text, !email.isEmpty else {
            showAlert(withTitle: "Warning", message: "Please enter and verify your email first!")
            return
        }
        recoverPassword(email: email) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.showAlert(withTitle: "Success", message: message)
                case .failure(let error):
                    let detailedMessage = self?.interpretRecoverPasswordError(error) ?? error.localizedDescription
                    self?.showAlert(withTitle: "Error", message: detailedMessage)
                }
            }
        }
    }
    
    @objc private func changePasswordTapped() {
        dismissKeyboard()
        guard let token = oneTimeKeyTextField.text, !token.isEmpty,
              let newPassword = newPasswordTextField.text, !newPassword.isEmpty else {
            showTokenFail()
            showAlert(withTitle: "Error", message: "One-time code and new password are required.") {
                self.revertToTokenIdleState()
            }
            return
        }
        
        // Используем функцию resetPassword из Routes.swift
        resetPassword(token: token, newPassword: newPassword) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    self?.showTokenSuccess()
                    self?.showAlert(withTitle: "Success", message: message) {
                        self?.navigateToSignInScreen()
                    }
                case .failure(let error):
                    // Получаем детальное сообщение об ошибке
                    let detailedMessage = self?.interpretResetPasswordError(error) ?? error.localizedDescription
                    // Если ошибка связана с требованиями к паролю или с неверным одноразовым кодом – не сбрасываем состояние галочки
                    if detailedMessage.contains("Password must") || detailedMessage.contains("The one-time key you entered is invalid. Please check your email and try again."){
                        self?.showAlert(withTitle: "Error", message: detailedMessage)
                    } else {
                        self?.showTokenFail()
                        self?.showAlert(withTitle: "Error", message: detailedMessage) {
                            self?.revertToTokenIdleState()
                        }
                    }
                }
            }
        }
    }

    
    // MARK: - Error Interpretation for Reset Password
    private func interpretResetPasswordError(_ error: Error) -> String {
        let errorMsg = error.localizedDescription
        if errorMsg.contains("Invalid one-time key") {
            return "The one-time key you entered is invalid. Please check your email and try again."
        } else if errorMsg.contains("one-time key has expired") {
            return "Your one-time key has expired. Please request a new one by tapping 'Resend one-time key'."
        }
        return errorMsg
    }
    
    // MARK: - Error Interpretation for Recover Password
    private func interpretRecoverPasswordError(_ error: Error) -> String {
        let errorMsg = error.localizedDescription
        if errorMsg.contains("User not found") {
            return "User not found. Please check your email address and try again."
        }
        return errorMsg
    }
    
    // MARK: - State Animations
    private func animateStatus(button: UIButton, withImage image: UIImage) {
        UIView.animate(withDuration: 0.2, animations: {
            button.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: { _ in
            button.setImage(image, for: .normal)
            button.backgroundColor = .clear
            UIView.animate(withDuration: 0.15) {
                button.transform = .identity
            }
        })
    }
    
    // MARK: - Token & Email State Helpers
    private func showTokenSuccess() {
        tokenCheckState = .success
    }
    
    private func showTokenFail() {
        tokenCheckState = .fail
    }
    
    private func revertToTokenIdleState() {
        tokenCheckState = .idle
        if let arrowCircle = UIImage(named: "arrow_in_circle")?.withRenderingMode(.alwaysOriginal) {
            animateStatus(button: emailCheckButton, withImage: arrowCircle)
        }
    }
    
    private func showEmailSuccess() {
        emailCheckState = .success  // Галочка – финальное состояние; дальше не меняется
        if let checkmarkImage = UIImage(named: "checkmark")?.withRenderingMode(.alwaysOriginal) {
            animateStatus(button: emailCheckButton, withImage: checkmarkImage)
        }
    }
    
    private func showEmailFail() {
        emailCheckState = .fail
        if let crossImage = UIImage(named: "cross")?.withRenderingMode(.alwaysOriginal) {
            animateStatus(button: emailCheckButton, withImage: crossImage)
        }
    }
    
    private func revertToEmailIdleState() {
        emailCheckState = .idle
        if let arrowCircle = UIImage(named: "arrow_in_circle")?.withRenderingMode(.alwaysOriginal) {
            animateStatus(button: emailCheckButton, withImage: arrowCircle)
        }
    }
    
    // MARK: - Navigation
    private func navigateToSignInScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Alert Helper
    private func showAlert(withTitle title: String, message: String, onOkAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            onOkAction?()
        }
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 61),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            emailTextFieldContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 66),
            emailTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            emailTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            emailTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            emailTextField.topAnchor.constraint(equalTo: emailTextFieldContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailTextFieldContainer.bottomAnchor),
            emailTextField.leadingAnchor.constraint(equalTo: emailTextFieldContainer.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: emailTextFieldContainer.trailingAnchor),
            
            emailCheckButton.centerYAnchor.constraint(equalTo: emailTextFieldContainer.centerYAnchor),
            emailCheckButton.trailingAnchor.constraint(equalTo: emailTextFieldContainer.trailingAnchor, constant: -10),
            emailCheckButton.widthAnchor.constraint(equalToConstant: 28),
            emailCheckButton.heightAnchor.constraint(equalToConstant: 28),
            
            oneTimeKeyTextFieldContainer.topAnchor.constraint(equalTo: emailTextFieldContainer.bottomAnchor, constant: 10),
            oneTimeKeyTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            oneTimeKeyTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            oneTimeKeyTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            oneTimeKeyTextField.topAnchor.constraint(equalTo: oneTimeKeyTextFieldContainer.topAnchor),
            oneTimeKeyTextField.bottomAnchor.constraint(equalTo: oneTimeKeyTextFieldContainer.bottomAnchor),
            oneTimeKeyTextField.leadingAnchor.constraint(equalTo: oneTimeKeyTextFieldContainer.leadingAnchor),
            oneTimeKeyTextField.trailingAnchor.constraint(equalTo: oneTimeKeyTextFieldContainer.trailingAnchor),
            
            newPasswordTextFieldContainer.topAnchor.constraint(equalTo: oneTimeKeyTextFieldContainer.bottomAnchor, constant: 10),
            newPasswordTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            newPasswordTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            newPasswordTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            newPasswordTextField.topAnchor.constraint(equalTo: newPasswordTextFieldContainer.topAnchor),
            newPasswordTextField.bottomAnchor.constraint(equalTo: newPasswordTextFieldContainer.bottomAnchor),
            newPasswordTextField.leadingAnchor.constraint(equalTo: newPasswordTextFieldContainer.leadingAnchor),
            newPasswordTextField.trailingAnchor.constraint(equalTo: newPasswordTextFieldContainer.trailingAnchor),
            
            resendLabel.topAnchor.constraint(equalTo: newPasswordTextFieldContainer.bottomAnchor, constant: 14),
            resendLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            changePasswordButtonContainer.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 116),
            changePasswordButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            changePasswordButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            changePasswordButtonContainer.heightAnchor.constraint(equalToConstant: 65),
            
            changePasswordButton.topAnchor.constraint(equalTo: changePasswordButtonContainer.topAnchor),
            changePasswordButton.bottomAnchor.constraint(equalTo: changePasswordButtonContainer.bottomAnchor),
            changePasswordButton.leadingAnchor.constraint(equalTo: changePasswordButtonContainer.leadingAnchor),
            changePasswordButton.trailingAnchor.constraint(equalTo: changePasswordButtonContainer.trailingAnchor),
        ])
    }
}
