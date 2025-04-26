//
//  TellAiProblemsViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 18.03.2025.
//

import UIKit

class TellAiProblemsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let howHelpLabel: UILabel = {
        let label = UILabel()
        label.text = "How can I help you?"
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
        
        view.addSubview(howHelpLabel)
        view.addSubview(detailLabel)
        view.addSubview(textViewShadowContainer)
        textViewShadowContainer.addSubview(textView)
        
        view.addSubview(activityIndicator)
        
        configureKeyboardToolbar()
        setupConstraints()
    }
    
    // MARK: - UI Setup
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Лейбл "How can I help you?"
            howHelpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            howHelpLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Лейбл "Describe in as much detail as possible."
            detailLabel.topAnchor.constraint(equalTo: howHelpLabel.bottomAnchor, constant: 1),
            detailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Контейнер для текстового поля
            textViewShadowContainer.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 12),
            textViewShadowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textViewShadowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textViewShadowContainer.heightAnchor.constraint(equalToConstant: 235),
            textViewShadowContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            
            // Текстовое поле занимает весь контейнер
            textView.topAnchor.constraint(equalTo: textViewShadowContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textViewShadowContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textViewShadowContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewShadowContainer.bottomAnchor),
            
            // Индикатор загрузки
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    /// Настройка UIToolbar с кнопкой "Done" для клавиатуры
    private func configureKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil,
                                            action: nil)
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(doneButtonTapped))
        
        toolbar.items = [flexibleSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }
    
    // MARK: - Методы для Activity Indicator
    
    private func showLoadingIndicator() {
        view.isUserInteractionEnabled = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        view.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
    }
    
    // MARK: - Обработка нажатия на "Done"
    
    @objc private func doneButtonTapped() {
        textView.resignFirstResponder()
        
        let alert = UIAlertController(title: "Make changes?", message: nil, preferredStyle: .alert)
        
        let stayAction = UIAlertAction(title: "Stay", style: .cancel) { _ in
            // Продолжаем редактирование — снова показываем клавиатуру
            self.textView.becomeFirstResponder()
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            // При подтверждении отправляем данные на сервер
            self.submitProblem()
        }
        
        alert.addAction(stayAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - САМ ПРОЦЕСС "submitProblem"
    
    /// Метод для отправки описания проблемы на сервер (reschedule), а затем массового получения обновлённых шагов.
    private func submitProblem() {
        let trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            showAlert(title: "Error", message: "Please enter a problem description.")
            return
        }
        
        // 1) Достаём токен из Keychain
        guard let token = KeychainManager.loadString(key: "accessToken") else {
            showAlert(title: "Error", message: "Access token not found.")
            return
        }
        
        // 2) Включаем индикатор загрузки
        showLoadingIndicator()
        
        // 3) Запрашиваем /api/ai/reschedule
        rescheduleTasks(token: token, problemText: trimmedText) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Отключаем индикатор
                self.hideLoadingIndicator()
                
                switch result {
                case .failure(let error):
                    // Если токен просрочен
                    if "\(error)".contains("Token has expired") {
                        self.showTokenExpiredAlert()
                    } else {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                    
                case .success(let (serverMessage, updatedStepIds)):
                    print("Reschedule success. Server says: \(serverMessage)")
                    
                    // Если нет изменений
                    guard !updatedStepIds.isEmpty else {
                        self.showAlert(title: "Success",
                                       message: "No tasks were changed on the server.\nServer says: \(serverMessage)",
                                       onDismiss: {
                            self.dismiss(animated: true)
                        })
                        return
                    }
                    
                    // 4) Запускаем индикатор заново (новый запрос)
                    self.showLoadingIndicator()
                    
                    // 5) Запрашиваем у сервера свежие данные шагов (/api/steps/bulk)
                    getStepsBulk(token: token, stepIds: updatedStepIds) { bulkResult in
                        DispatchQueue.main.async {
                            // Снимаем индикатор
                            self.hideLoadingIndicator()
                            
                            switch bulkResult {
                            case .failure(let bulkError):
                                if "\(bulkError)".contains("Token has expired") {
                                    self.showTokenExpiredAlert()
                                } else {
                                    self.showAlert(title: "Error", message: bulkError.localizedDescription)
                                }
                            case .success(let fetchedSteps):
                                // Рассылаем уведомление, чтобы MainViewController мог обновить UI
                                NotificationCenter.default.post(name: Notification.Name("StepsRescheduled"),
                                                                object: fetchedSteps)
                                // Показываем успех и закрываем экран
                                self.showAlert(title: "Success",
                                               message: "Tasks updated successfully",
                                               onDismiss: {
                                    self.dismiss(animated: true, completion: nil)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String, onDismiss: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            onDismiss?()
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}
