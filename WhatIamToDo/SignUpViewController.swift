//
//  SignUpViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 29.12.2024.
//

import UIKit

final class SignUpViewController: UIViewController {
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(
            red: 224/255,
            green: 224/255,
            blue: 224/255,
            alpha: 1.0
        )
        
        setupSubviews()
        setupConstraints()
        
        signUpButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        
        let signInTapGesture = UITapGestureRecognizer(target: self, action: #selector(signInTapped))
        signInLabel.addGestureRecognizer(signInTapGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func signUpButtonTapped() {
        dismissKeyboard()
        
        guard let fullName = fullNameTextField.text, !fullName.isEmpty,
              let email = emailAddressTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(withTitle: "Error", message: "Please fill in all required fields.")
            return
        }
        
        registerUser(email: email, password: password, name: fullName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    // Успешная регистрация – после нажатия OK на alert переходим на экран входа
                    print("Server message: \(message)")
                    self?.showAlert(withTitle: "Success", message: message) {
                        self?.navigateToSignInScreen()
                    }
                case .failure(let error):
                    // Показать детальный Alert
                    let (alertTitle, alertMessage) = self?.interpretSignUpError(error) ?? ("Sign Up Error", error.localizedDescription)
                    self?.showAlert(withTitle: alertTitle, message: alertMessage)
                }
            }
        }
    }
    
    @objc private func signInTapped() {
        print("Sign In tapped")
        navigateToSignInScreen()
    }
    
    private func navigateToSignInScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Error Handling
    
    private func interpretSignUpError(_ error: Error) -> (String, String) {
        if let netErr = error as? NetworkError {
            switch netErr {
            case .invalidURL:
                return ("Sign Up Error", "Invalid URL. Please contact support.")
            case .noData:
                return ("Server Error", "No data received from server. Possibly offline?")
            case .invalidResponse:
                return ("Sign Up Error", "Invalid response from server.")
            case .serverError(let msg):
                return ("Sign Up Error", msg)
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return ("Network Error", "No Internet connection. Please try again.")
            default:
                return ("Network Error", urlError.localizedDescription)
            }
        }
        return ("Sign Up Error", error.localizedDescription)
    }
    
    // MARK: - UI Helpers
    
    private func showAlert(withTitle title: String, message: String, onOkAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK",
                                     style: .default) { _ in
            onOkAction?()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // MARK: - Subviews Setup
    
    private func setupSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        
        view.addSubview(fullNameTextFieldContainer)
        fullNameTextFieldContainer.addSubview(fullNameTextField)
        
        view.addSubview(emailAddressTextFieldContainer)
        emailAddressTextFieldContainer.addSubview(emailAddressTextField)
        
        view.addSubview(passwordTextFieldContainer)
        passwordTextFieldContainer.addSubview(passwordTextField)
        
        view.addSubview(signUpButtonContainer)
        signUpButtonContainer.addSubview(signUpButton)
        
        view.addSubview(signInLabel)
    }
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create new account"
        label.font = UIFont(name: "Poppins-Regular", size: 24)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Please fill in the form to continue"
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        label.textColor = UIColor.black.withAlphaComponent(0.55)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let fullNameTextFieldContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    private let fullNameTextField: UITextField = {
        let textField = UITextField()
        let placeholderText = "Full Name"
        let placeholderColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.45)
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: placeholderAttrs)
        textField.font = UIFont(name: "Poppins-Regular", size: 16)
        textField.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.7)
        textField.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        textField.layer.cornerRadius = 17
        textField.layer.masksToBounds = true
        textField.setLeftPaddingPoints(24)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let emailAddressTextFieldContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    private let emailAddressTextField: UITextField = {
        let textField = UITextField()
        let placeholderText = "Email Address"
        let placeholderColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.45)
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attrs)
        textField.font = UIFont(name: "Poppins-Regular", size: 16)
        textField.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.7)
        textField.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        textField.layer.cornerRadius = 17
        textField.layer.masksToBounds = true
        textField.setLeftPaddingPoints(24)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextFieldContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        let placeholderText = "Password"
        let placeholderColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.45)
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attrs)
        textField.font = UIFont(name: "Poppins-Regular", size: 16)
        textField.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.7)
        textField.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        textField.layer.cornerRadius = 17
        textField.layer.masksToBounds = true
        textField.setLeftPaddingPoints(24)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        
        let eyeButton = UIButton(type: .custom)
        eyeButton.setImage(UIImage(named: "eyeSlashIcon"), for: .normal)
        eyeButton.tintColor = UIColor.black.withAlphaComponent(0.45)
        eyeButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 65, height: 65))
        eyeButton.center = paddingView.center
        paddingView.addSubview(eyeButton)
        textField.rightView = paddingView
        textField.rightViewMode = .always
        
        eyeButton.addTarget(nil, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        if let paddingView = passwordTextField.rightView as? UIView,
           let button = paddingView.subviews.first as? UIButton {
            let imageName = passwordTextField.isSecureTextEntry ? "eyeSlashIcon" : "eyeIcon"
            button.setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    private let signUpButtonContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(
            red: 245/255,
            green: 123/255,
            blue: 93/255,
            alpha: 1.0
        )
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let signInLabel: UILabel = {
        let label = UILabel()
        let text = NSMutableAttributedString(
            string: "Have an Account? ",
            attributes: [
                .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
        )
        text.append(NSAttributedString(
            string: "Sign In",
            attributes: [
                .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(red: 245/255, green: 123/255, blue: 93/255, alpha: 1.0)
            ]
        ))
        label.attributedText = text
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Layout
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 61),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            instructionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Full Name
            fullNameTextFieldContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 66),
            fullNameTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            fullNameTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            fullNameTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            fullNameTextField.topAnchor.constraint(equalTo: fullNameTextFieldContainer.topAnchor),
            fullNameTextField.bottomAnchor.constraint(equalTo: fullNameTextFieldContainer.bottomAnchor),
            fullNameTextField.leadingAnchor.constraint(equalTo: fullNameTextFieldContainer.leadingAnchor),
            fullNameTextField.trailingAnchor.constraint(equalTo: fullNameTextFieldContainer.trailingAnchor),
            
            // Email
            emailAddressTextFieldContainer.topAnchor.constraint(equalTo: fullNameTextFieldContainer.bottomAnchor, constant: 10),
            emailAddressTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            emailAddressTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            emailAddressTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            emailAddressTextField.topAnchor.constraint(equalTo: emailAddressTextFieldContainer.topAnchor),
            emailAddressTextField.bottomAnchor.constraint(equalTo: emailAddressTextFieldContainer.bottomAnchor),
            emailAddressTextField.leadingAnchor.constraint(equalTo: emailAddressTextFieldContainer.leadingAnchor),
            emailAddressTextField.trailingAnchor.constraint(equalTo: emailAddressTextFieldContainer.trailingAnchor),
            
            // Password
            passwordTextFieldContainer.topAnchor.constraint(equalTo: emailAddressTextFieldContainer.bottomAnchor, constant: 10),
            passwordTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            passwordTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            passwordTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            passwordTextField.topAnchor.constraint(equalTo: passwordTextFieldContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordTextFieldContainer.bottomAnchor),
            passwordTextField.leadingAnchor.constraint(equalTo: passwordTextFieldContainer.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordTextFieldContainer.trailingAnchor),
            
            // Sign Up
            signUpButtonContainer.topAnchor.constraint(equalTo: passwordTextFieldContainer.bottomAnchor, constant: 116),
            signUpButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            signUpButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            signUpButtonContainer.heightAnchor.constraint(equalToConstant: 65),
            
            signUpButton.topAnchor.constraint(equalTo: signUpButtonContainer.topAnchor),
            signUpButton.bottomAnchor.constraint(equalTo: signUpButtonContainer.bottomAnchor),
            signUpButton.leadingAnchor.constraint(equalTo: signUpButtonContainer.leadingAnchor),
            signUpButton.trailingAnchor.constraint(equalTo: signUpButtonContainer.trailingAnchor),
            
            // Label "Have an Account? Sign In"
            signInLabel.topAnchor.constraint(equalTo: signUpButtonContainer.bottomAnchor, constant: 14),
            signInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
