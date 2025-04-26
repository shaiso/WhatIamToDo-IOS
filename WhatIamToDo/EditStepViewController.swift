//
//  EditGoalViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 31.03.2025.
//

import UIKit

class EditGoalViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    // MARK: - Properties для передачи данных
    var initialStepText: String?   // Текст шага, полученный с карточки
    var initialDateText: String?   // Дата в формате "dd.MM.yyyy"
    var cardId: Int?
    var goalId: Int?
    
    // MARK: - UI Elements

    private let changeLabel: UILabel = {
        let label = UILabel()
        label.text = "Change what you want."
        label.font = UIFont(name: "Poppins-Medium", size: 22)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stepLabel: UILabel = {
        let label = UILabel()
        label.text = "Step"
        label.font = UIFont(name: "Poppins-Medium", size: 20)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stepTextViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stepTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont(name: "Poppins-Regular", size: 18)
        tv.textColor = .black
        tv.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        tv.layer.cornerRadius = 20
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.autocorrectionType = .no
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return tv
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "Due date"
        label.font = UIFont(name: "Poppins-Medium", size: 20)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateTextFieldContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let dateTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont(name: "Poppins-Regular", size: 18)
        tf.textColor = .black
        tf.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        tf.layer.cornerRadius = 20
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.keyboardType = .numberPad
        tf.autocorrectionType = .no
        tf.textAlignment = .center
        return tf
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1.0)
        setupUI()
        populateData()
        configureKeyboardToolbar()
        
        stepTextView.delegate = self
        dateTextField.delegate = self
        
        // жест для скрытия клавиатуры при нажатии вне полей
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFromTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(changeLabel)
        view.addSubview(stepLabel)
        view.addSubview(stepTextViewContainer)
        stepTextViewContainer.addSubview(stepTextView)
        view.addSubview(dateLabel)
        view.addSubview(dateTextFieldContainer)
        dateTextFieldContainer.addSubview(dateTextField)
        
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Change Label
            changeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            changeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            changeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Step Label
            stepLabel.topAnchor.constraint(equalTo: changeLabel.bottomAnchor, constant: 10),
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stepLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Step TextView Container
            stepTextViewContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 4),
            stepTextViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stepTextViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stepTextViewContainer.heightAnchor.constraint(equalToConstant: 150),
            
            // Step TextView
            stepTextView.topAnchor.constraint(equalTo: stepTextViewContainer.topAnchor),
            stepTextView.leadingAnchor.constraint(equalTo: stepTextViewContainer.leadingAnchor),
            stepTextView.trailingAnchor.constraint(equalTo: stepTextViewContainer.trailingAnchor),
            stepTextView.bottomAnchor.constraint(equalTo: stepTextViewContainer.bottomAnchor),
            
            // Date Label
            dateLabel.topAnchor.constraint(equalTo: stepTextViewContainer.bottomAnchor, constant: 5),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Date TextField Container
            dateTextFieldContainer.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            dateTextFieldContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateTextFieldContainer.widthAnchor.constraint(equalToConstant: 155),
            dateTextFieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Date TextField
            dateTextField.topAnchor.constraint(equalTo: dateTextFieldContainer.topAnchor),
            dateTextField.leadingAnchor.constraint(equalTo: dateTextFieldContainer.leadingAnchor),
            dateTextField.trailingAnchor.constraint(equalTo: dateTextFieldContainer.trailingAnchor),
            dateTextField.bottomAnchor.constraint(equalTo: dateTextFieldContainer.bottomAnchor)
        ])
    }

    private func configureKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flexibleSpace, doneButton]
        stepTextView.inputAccessoryView = toolbar
        dateTextField.inputAccessoryView = toolbar
    }

    private func populateData() {
        stepTextView.text = initialStepText ?? ""
        dateTextField.text = initialDateText ?? ""
    }

    @objc private func dismissKeyboard() {
        stepTextView.resignFirstResponder()
        dateTextField.resignFirstResponder()
        updateGoal()
    }

    @objc private func dismissKeyboardFromTap() {
        view.endEditing(true)
    }

    // MARK: - Helpers

    private func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private func isValidDate(_ dateString: String) -> Bool {
        let components = dateString.split(separator: ".")
        guard components.count == 3,
              let day = Int(components[0]),
              let month = Int(components[1]),
              let year = Int(components[2]) else {
            return false
        }
        if day < 1 || day > 31 { return false }
        if month < 1 || month > 12 { return false }
        if year < 2024 || year > 2035 { return false }
        return true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Networking: Обновление шага

    private func updateGoal() {
        // Получаем введённое описание шага и дату из текстовых полей
        let newDescription = stepTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let newDateText = dateTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Проверяем, что описание не пустое
        guard !newDescription.isEmpty else {
            showAlert(title: "Missing Step", message: "Please enter a step description.")
            return
        }
        
        // Если поле даты пустое, просим ввести дату
        guard !newDateText.isEmpty else {
            showAlert(title: "Missing Date", message: "Please enter a date in DD.MM.YYYY format.")
            return
        }
        
        // Проверяем корректность даты: строка должна содержать ровно 10 символов и соответствовать формату DD.MM.YYYY
        guard newDateText.count == 10, isValidDate(newDateText) else {
            showAlert(title: "Invalid Date", message: "Please enter a valid date in DD.MM.YYYY format.")
            return
        }
        
        // Преобразуем дату из "dd.MM.yyyy" в ISO‑формат "yyyy-MM-dd'T'HH:mm:ss"
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "dd.MM.yyyy"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let newDate = inputFormatter.date(from: newDateText) else {
            showAlert(title: "Date Conversion Error", message: "Unable to convert the date. Please try again.")
            return
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        outputFormatter.timeZone = TimeZone.current
        let isoDateString = outputFormatter.string(from: newDate)
        
        // Извлекаем access token
        guard let currentUserToken = KeychainManager.loadString(key: "accessToken") else {
            showAlert(title: "Error", message: "Access token not found.")
            return
        }
        
        // Получаем идентификатор шага (stepId) и цели (goalId)
        guard let stepId = cardId else {
            showAlert(title: "Error", message: "Step identifier is missing.")
            return
        }
        guard let goalId = self.goalId else {
            showAlert(title: "Error", message: "Goal identifier is missing.")
            return
        }
        
        // Обновляем шаг (description + дата)
        updateStep(token: currentUserToken,
                   stepId: stepId,
                   title: nil,
                   description: newDescription,
                   status: nil,
                   dateString: isoDateString) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    if "\(error)".contains("Token has expired") {
                        self.parentViewController()?.showTokenExpiredAlert()
                    } else {
                        self.showAlert(title: "Update Failed", message: "\(error)")
                    }
                    
                case .success(_):
                    // После успешного update идём за актуальной (Goal, Step)
                    getGoalStepDetail(token: currentUserToken,
                                      goalId: goalId,
                                      stepId: stepId) { detailResult in
                        DispatchQueue.main.async {
                            switch detailResult {
                            case .failure(let error):
                                if "\(error)".contains("Token has expired") {
                                    self.parentViewController()?.showTokenExpiredAlert()
                                } else {
                                    self.showAlert(title: "Update Failed", message: "Error in getGoalStepDetail: \(error)")
                                }
                            case .success(let (updatedGoal, updatedStep)):
                                // Отправляем (Goal, Step), чтобы MainViewController сразу обновил UI
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("StepUpdated"),
                                    object: (updatedGoal, updatedStep)
                                )
                                // Закрываем экран
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }


    // MARK: - UITextFieldDelegate & UITextViewDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == dateTextField {
            let allowedCharacters = CharacterSet.decimalDigits
            if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                return false
            }
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            let digitsOnly = updatedText.replacingOccurrences(of: ".", with: "")
            if digitsOnly.count > 8 {
                return false
            }
            var formattedText = ""
            for (index, character) in digitsOnly.enumerated() {
                if index == 2 || index == 4 {
                    formattedText.append(".")
                }
                formattedText.append(character)
            }
            textField.text = formattedText
            return false
        }
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}
