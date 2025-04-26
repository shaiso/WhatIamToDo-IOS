//
//  AddGoalViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 19.03.2025.
//

import UIKit

class AddGoalViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let whatGoalLabel: UILabel = {
        let label = UILabel()
        label.text = "What goal do you want to add?"
        label.font = UIFont(name: "Poppins-Medium", size: 22)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.text = "Describe in as much detail as possible."
        label.font = UIFont(name: "Poppins-Regular", size: 16)
        label.textColor = UIColor.black.withAlphaComponent(0.55)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textViewShadowContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont(name: "Poppins-Regular", size: 16)
        tv.textColor = .black
        tv.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        tv.layer.cornerRadius = 20
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.autocorrectionType = .no
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return tv
    }()
    
    
    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .gray
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1.0)
        
        view.addSubview(whatGoalLabel)
        view.addSubview(detailLabel)
        view.addSubview(textViewShadowContainer)
        textViewShadowContainer.addSubview(textView)
        
        view.addSubview(activityIndicator)
        
        configureKeyboardToolbar()
        setupConstraints()
    }
    
    // MARK: - Layout
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Заголовок
            whatGoalLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            whatGoalLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Подзаголовок
            detailLabel.topAnchor.constraint(equalTo: whatGoalLabel.bottomAnchor, constant: 1),
            detailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Теневой контейнер
            textViewShadowContainer.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 12),
            textViewShadowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textViewShadowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textViewShadowContainer.heightAnchor.constraint(equalToConstant: 235),
            textViewShadowContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            
            // Текстовое поле
            textView.topAnchor.constraint(equalTo: textViewShadowContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textViewShadowContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textViewShadowContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewShadowContainer.bottomAnchor),
            
            // Индикатор загрузки
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func configureKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil,
                                            action: nil)
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(dismissKeyboardAndConfirm))
        
        toolbar.items = [flexibleSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }
    
    // MARK: - Actions
    
    @objc private func dismissKeyboardAndConfirm() {
        textView.resignFirstResponder()
        
        let alert = UIAlertController(title: "Add new goal?", message: nil, preferredStyle: .alert)
        
        let stayAction = UIAlertAction(title: "Stay", style: .cancel) { _ in
            self.textView.becomeFirstResponder()
        }
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            self.createGoalViaAI()
        }
        alert.addAction(stayAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Networking
    
    /// 1) generateGoalAI => goal_id
    /// 2) getGoalDetail => Goal
    /// 3) Закрываем экран при успехе
    private func createGoalViaAI() {
        let userPrompt = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userPrompt.isEmpty else {
            showUnexpectedErrorAlert()
            return
        }
        
        guard let accessToken = KeychainManager.loadString(key: "accessToken") else {
            showUnexpectedErrorAlert()
            return
        }
        
        activityIndicator.startAnimating()
        
        generateGoalAI(token: accessToken, userPrompt: userPrompt) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let newGoalId):
                    self.fetchGoalDetail(goalId: newGoalId, token: accessToken)
                    
                case .failure(let error):
                    if "\(error)".contains("expired") {
                        self.showTokenExpiredAlert()
                    } else {
                        self.showUnexpectedErrorAlert()
                    }
                }
            }
        }
    }
    
    private func fetchGoalDetail(goalId: Int, token: String) {
        activityIndicator.startAnimating()
        
        getGoalDetail(token: token, goalId: goalId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let newGoal):
                    NotificationCenter.default.post(name: Notification.Name("NewGoalCreated"),
                                                    object: newGoal)
                    self.dismiss(animated: true)
                    
                case .failure(let error):
                    if "\(error)".contains("expired") {
                        self.showTokenExpiredAlert()
                    } else {
                        self.showUnexpectedErrorAlert()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Показываем Alert с универсальным сообщением об ошибке
    private func showUnexpectedErrorAlert() {
        let alert = UIAlertController(title: "Error",
                                      message: "An unexpected error occurred. Please try again later.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
