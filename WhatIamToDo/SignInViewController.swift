//
//  SignInViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 13.12.2024.
//

import UIKit


final class SignInViewController: UIViewController, UITextFieldDelegate {

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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let forgotPasswordTap = UITapGestureRecognizer(target: self, action: #selector(forgotPasswordTapped))
        forgotPasswordLabel.addGestureRecognizer(forgotPasswordTap)
        
        signInButton.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
        
        let signUpTapGesture = UITapGestureRecognizer(target: self, action: #selector(signUpTapped))
        signUpLabel.addGestureRecognizer(signUpTapGesture)
        
        emailTextField.textContentType = .emailAddress 
        passwordTextField.textContentType = .password

    }
    
    // MARK: - Actions
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func forgotPasswordTapped() {
        print("Forgot Password? tapped")
        let passwordRecoveryVC = PasswordRecoveryViewController()
        passwordRecoveryVC.modalPresentationStyle = .fullScreen
        present(passwordRecoveryVC, animated: true, completion: nil)
    }
    
       @objc private func signUpTapped() {
           print("Sign Up tapped")
           let signUpVC = SignUpViewController()
           signUpVC.modalPresentationStyle = .fullScreen
           present(signUpVC, animated: true, completion: nil)
       }
    
    @objc private func signInButtonTapped() {
        dismissKeyboard()
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(withTitle: "Error", message: "Email and password are required.")
            return
        }
        
        loginUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success((let message, let accessToken)):
                    // Успешный вход
                    print("Server message (user name): \(message)")
                    if let token = accessToken {
                        // Сохраняем access_token, логин, пароль и имя пользователя в Keychain
                        KeychainManager.saveString(key: "accessToken", value: token)
                        KeychainManager.saveString(key: "userLogin", value: email)
                        KeychainManager.saveString(key: "userPassword", value: password)
                        KeychainManager.saveString(key: "userName", value: message)
                        print("Credentials saved to Keychain")
                        // Загружаем цели с шагами и передаём данные на экран календаря
                        self?.loadGoalsAndProceed(token: token)
                    } else {
                        self?.navigateToMainScreen(preloadedGoalsWithSteps: nil)
                    }
                    
                case .failure(let error):
                    let (alertTitle, alertMessage) = self?.interpretSignInError(error) ?? ("Sign In Error", error.localizedDescription)
                    self?.showAlert(withTitle: alertTitle, message: alertMessage)
                }
            }
        }
    }
    
    /// Загружает цели с шагами с сервера и переходит на главный экран,
    /// передавая полученные данные для дальнейшей обработки на экране календаря.
    private func loadGoalsAndProceed(token: String) {
        getGoalsWithSteps(token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let goals):
                    print("Goals loaded successfully, count: \(goals.count)")
                    // Передаём данные напрямую, без преобразования.
                    self?.navigateToMainScreen(preloadedGoalsWithSteps: goals)
                case .failure(let error):
                    print("Failed to load goals: \(error.localizedDescription)")
                    self?.showAlert(withTitle: "Data Error", message: "Failed to load goals. Please try again later.")
                        self?.navigateToMainScreen(preloadedGoalsWithSteps: nil)
                    
                }
            }
        }
    }



    /// Переход на главный экран MainViewController.
    /// Передаются предзагруженные цели с шагами для построения календаря.
    private func navigateToMainScreen(preloadedGoalsWithSteps: [Goal]?) {
        let mainVC = MainViewController()
        mainVC.preloadedGoalsWithSteps = preloadedGoalsWithSteps
        mainVC.modalPresentationStyle = .fullScreen
        present(mainVC, animated: true, completion: nil)
    }
    
    /// Анализируем ошибку и формируем заголовок + сообщение для Alert
    private func interpretSignInError(_ error: Error) -> (String, String) {
        if let netErr = error as? NetworkError {
            switch netErr {
            case .invalidURL:
                return ("Sign In Error", "Invalid URL. Please contact support.")
            case .noData:
                return ("Server Error", "No data received from server. Possibly offline?")
            case .invalidResponse:
                return ("Sign In Error", "Invalid response from server.")
            case .serverError(let msg):
                return ("Sign In Error", msg)
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
        return ("Sign In Error", error.localizedDescription)
    }
    
    // MARK: - UI Helpers
    
    /// Отображает простой Alert
    private func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Subviews Setup
    
    private func setupSubviews() {
        view.addSubview(welcomeLabel)
        view.addSubview(signInPromptLabel)
        
        view.addSubview(emailTextFieldContainer)
        emailTextFieldContainer.addSubview(emailTextField)
        
        view.addSubview(passwordTextFieldContainer)
        passwordTextFieldContainer.addSubview(passwordTextField)
        
        view.addSubview(forgotPasswordLabel)
        
        view.addSubview(signInButtonContainer)
        signInButtonContainer.addSubview(signInButton)
        
        view.addSubview(signUpLabel)
    }
    
    // MARK: - UI Elements
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome Back!"
        label.font = UIFont(name: "Poppins-Regular", size: 24)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let signInPromptLabel: UILabel = {
        let label = UILabel()
        label.text = "Please sign in to your account"
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.55)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextFieldContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        let placeholderText = "Email"
        let placeholderColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.45)
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: placeholderAttributes)
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
        let placeholderColor = UIColor(
                red: 0/255,
                green: 0/255,
                blue: 0/255,
                alpha: 0.45
            )
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
            ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: placeholderAttributes)
        textField.font = UIFont(name: "Poppins-Regular", size: 16)
        textField.textColor = UIColor(
                red: 0/255,
                green: 0/255,
                blue: 0/255,
                alpha: 0.7
            )
        textField.backgroundColor = UIColor(
                red: 234/255,
                green: 234/255,
                blue: 234/255,
                alpha: 1.0
            )
        textField.layer.cornerRadius = 17
        textField.layer.masksToBounds = true
        textField.setLeftPaddingPoints(24)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
            
        // Кнопка для переключения видимости пароля
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "eyeSlashIcon"), for: .normal)
        button.tintColor = UIColor.black.withAlphaComponent(0.45)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 65, height: 65))
        button.center = paddingView.center
        paddingView.addSubview(button)
        textField.rightView = paddingView
        textField.rightViewMode = .always
        button.addTarget(nil, action: #selector(togglePasswordVisibility), for: .touchUpInside)
            
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
    
    private let forgotPasswordLabel: UILabel = {
        let label = UILabel()
        label.text = "Forgot Password?"
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.55)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let signInButtonContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 245/255, green: 123/255, blue: 93/255, alpha: 1.0)
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let signUpLabel: UILabel = {
        let label = UILabel()
        let text = NSMutableAttributedString(
            string: "Don't have an Account? ",
            attributes: [
                .font: UIFont(name: "Poppins-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.black
            ]
        )
        text.append(NSAttributedString(
            string: "Sign Up",
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
    
    // MARK: - Layout Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Welcome Label
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 61),
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // "Please sign in..."
            signInPromptLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 1),
            signInPromptLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Email container
            emailTextFieldContainer.topAnchor.constraint(equalTo: signInPromptLabel.bottomAnchor, constant: 66),
            emailTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            emailTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            emailTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            emailTextField.topAnchor.constraint(equalTo: emailTextFieldContainer.topAnchor),
            emailTextField.bottomAnchor.constraint(equalTo: emailTextFieldContainer.bottomAnchor),
            emailTextField.leadingAnchor.constraint(equalTo: emailTextFieldContainer.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: emailTextFieldContainer.trailingAnchor),
            
            // Password container
            passwordTextFieldContainer.topAnchor.constraint(equalTo: emailTextFieldContainer.bottomAnchor, constant: 10),
            passwordTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            passwordTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            passwordTextFieldContainer.heightAnchor.constraint(equalToConstant: 65),
            
            passwordTextField.topAnchor.constraint(equalTo: passwordTextFieldContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordTextFieldContainer.bottomAnchor),
            passwordTextField.leadingAnchor.constraint(equalTo: passwordTextFieldContainer.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordTextFieldContainer.trailingAnchor),
            
            // Forgot password label
            forgotPasswordLabel.topAnchor.constraint(equalTo: passwordTextFieldContainer.bottomAnchor, constant: 14),
            forgotPasswordLabel.trailingAnchor.constraint(equalTo: passwordTextFieldContainer.trailingAnchor),
            
            // Sign In button container
            signInButtonContainer.topAnchor.constraint(equalTo: passwordTextFieldContainer.bottomAnchor, constant: 116),
            signInButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            signInButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            signInButtonContainer.heightAnchor.constraint(equalToConstant: 65),
            
            signInButton.topAnchor.constraint(equalTo: signInButtonContainer.topAnchor),
            signInButton.bottomAnchor.constraint(equalTo: signInButtonContainer.bottomAnchor),
            signInButton.leadingAnchor.constraint(equalTo: signInButtonContainer.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: signInButtonContainer.trailingAnchor),
            
            // Sign Up label
            signUpLabel.topAnchor.constraint(equalTo: signInButtonContainer.bottomAnchor, constant: 14),
            signUpLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
