//
//  AddStepViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 01.04.2025.
//

import UIKit

class AddStepViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    

    private var selectedGoalId: Int? = nil
    var availableGoals: [Goal] = []
    var initialSelectedDate: String?

    // MARK: - UI Elements
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a New Step"
        label.font = UIFont(name: "Poppins-Medium", size: 22)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let goalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Goal"
        label.font = UIFont(name: "Poppins-Medium", size: 20)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Контейнер для текстового поля цели (с тенью). При выборе цели обновляется цвет тени.
    private let goalTextFieldContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let goalTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont(name: "Poppins-Regular", size: 18)
        tf.textColor = .black
        tf.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        tf.layer.cornerRadius = 20
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocorrectionType = .no
        tf.textAlignment = .center
        return tf
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
        label.text = "Due Date"
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
        
        // Добавляем subviews
        view.addSubview(headerLabel)
        view.addSubview(goalTitleLabel)
        view.addSubview(goalTextFieldContainer)
        goalTextFieldContainer.addSubview(goalTextField)
        view.addSubview(stepLabel)
        view.addSubview(stepTextViewContainer)
        stepTextViewContainer.addSubview(stepTextView)
        view.addSubview(dateLabel)
        view.addSubview(dateTextFieldContainer)
        dateTextFieldContainer.addSubview(dateTextField)
        
        goalTextField.delegate = self
        stepTextView.delegate = self
        dateTextField.delegate = self
        
        configureKeyboardToolbar()
        setupConstraints()
        
        // Жест для скрытия клавиатуры при тапе вне полей
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardFromTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        if let initialDate = initialSelectedDate {
                self.dateTextField.text = initialDate
            }
    }
    
    // MARK: - UITextFieldDelegate
    // При тапе на поле Goal открываем попап выбора целей
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == goalTextField {
            presentGoalSelection()
            return false
        }
        return true
    }
    
    /// Открываем попап выбора цели с прокручиваемым списком целей
    private func presentGoalSelection() {
        let popupVC = GoalSelectionPopupViewController()
        popupVC.goals = self.availableGoals
        popupVC.onGoalSelected = { [weak self] (selectedGoal: Goal) in
            guard let self = self else { return }
            self.goalTextField.text = selectedGoal.title
            if let goalColor = UIColor(hex: selectedGoal.color) {
                self.goalTextFieldContainer.layer.shadowColor = goalColor.cgColor
            }
            // Сохраняем реальный id цели для запроса
            self.selectedGoalId = selectedGoal.id
        }
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Toolbar
    private func configureKeyboardToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil,
                                            action: nil)
        let doneButton = UIBarButtonItem(title: "Done",
                                         style: .done,
                                         target: self,
                                         action: #selector(dismissKeyboard))
        toolbar.items = [flexibleSpace, doneButton]
        goalTextField.inputAccessoryView = toolbar
        stepTextView.inputAccessoryView = toolbar
        dateTextField.inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
        createNewStep()
    }
    
    @objc private func dismissKeyboardFromTap() {
        view.endEditing(true)
    }
    
    // MARK: - Create Step
    private func createNewStep() {
        let goalText = goalTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stepText = stepTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let dateText = dateTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Валидации
        guard !goalText.isEmpty else {
            showAlert(title: "Error", message: "Please enter a goal.")
            return
        }
        guard !stepText.isEmpty else {
            showAlert(title: "Error", message: "Please enter a step description.")
            return
        }
        guard dateText.count == 10 else {
            showAlert(title: "Error", message: "Please enter a date in DD.MM.YYYY format.")
            return
        }
        guard isValidDate(dateText) else {
            showAlert(title: "Error", message: "Invalid date. Ensure day (1-31), month (1-12), year (2024-2035).")
            return
        }
        guard let token = KeychainManager.loadString(key: "accessToken") else {
            showAlert(title: "Error", message: "Access token not found.")
            return
        }
        guard let goalId = selectedGoalId else {
            showAlert(title: "Error", message: "No goal selected.")
            return
        }
        
        // Преобразуем дату к формату сервера (yyyy-MM-dd)
        let formatterGet = DateFormatter()
        formatterGet.dateFormat = "dd.MM.yyyy"
        
        let formatterSend = DateFormatter()
        formatterSend.dateFormat = "yyyy-MM-dd"
        
        var serverDate: String? = nil
        if let dateObj = formatterGet.date(from: dateText) {
            serverDate = formatterSend.string(from: dateObj)
        }
        
        addStepToGoal(token: token,
                      goalId: goalId,
                      stepTitle: "Повседневные дела",
                      stepDescription: stepText,
                      stepDate: serverDate) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newStepId):
                    print("addStepToGoal success, step_id =", newStepId)
                    // Теперь запрашиваем актуальную инфу о цели
                    self.requestGoalStepDetail(token: token, goalId: goalId, stepId: newStepId)
                    
                case .failure(let error):
                    let errorStr = "\(error)"
                    if errorStr.contains("expired") {
                        // Токен просрочен
                        self.showTokenExpiredAlert()
                    } else {
                        self.showAlert(title: "Error", message: "Failed to add step: \(error)")
                    }
                }
            }
        }
    }
    
    /// Запрашиваем GET /api/goals/<goal_id>/steps/<step_id>, получаем (Goal, Step)
        private func requestGoalStepDetail(token: String, goalId: Int, stepId: Int) {
            getGoalStepDetail(token: token, goalId: goalId, stepId: stepId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let (updatedGoal, createdStep)):
                        print("Received new step from server. goalId=\(updatedGoal.id) stepId=\(createdStep.id)")
                        
                        // Шлём уведомление, чтобы MainViewController обновил календарь и карточки
                        NotificationCenter.default.post(name: NSNotification.Name("NewStepCreated"),
                                                        object: (updatedGoal, createdStep))
                        
                        // Показываем успех и закрываем экран
                        self.dismiss(animated: true, completion: nil)
                        
                        
                    case .failure(let error):
                        if "\(error)".contains("expired") {
                            self.showTokenExpiredAlert()
                        } else {
                            self.showAlert(title: "Error", message: "Failed to fetch step detail: \(error)")
                        }
                    }
                }
            }
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
    
    // MARK: - Helpers
    /// Алерт с опциональным completion, чтобы после нажатия "OK" можно было закрыть экран
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true)
    }
    
    // MARK: - UITextFieldDelegate & UITextViewDelegate
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        // Автоподстановка точек в формате DD.MM.YYYY
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
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        return true
    }
    
    // MARK: - Setup Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header label
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Goal field
            goalTitleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            goalTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            goalTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            goalTextFieldContainer.topAnchor.constraint(equalTo: goalTitleLabel.bottomAnchor, constant: 4),
            goalTextFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            goalTextFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            goalTextFieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            goalTextField.topAnchor.constraint(equalTo: goalTextFieldContainer.topAnchor),
            goalTextField.leadingAnchor.constraint(equalTo: goalTextFieldContainer.leadingAnchor),
            goalTextField.trailingAnchor.constraint(equalTo: goalTextFieldContainer.trailingAnchor),
            goalTextField.bottomAnchor.constraint(equalTo: goalTextFieldContainer.bottomAnchor),
            
            // Step field
            stepLabel.topAnchor.constraint(equalTo: goalTextFieldContainer.bottomAnchor, constant: 5),
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stepLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            stepTextViewContainer.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 4),
            stepTextViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stepTextViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stepTextViewContainer.heightAnchor.constraint(equalToConstant: 90),
            
            stepTextView.topAnchor.constraint(equalTo: stepTextViewContainer.topAnchor),
            stepTextView.leadingAnchor.constraint(equalTo: stepTextViewContainer.leadingAnchor),
            stepTextView.trailingAnchor.constraint(equalTo: stepTextViewContainer.trailingAnchor),
            stepTextView.bottomAnchor.constraint(equalTo: stepTextViewContainer.bottomAnchor),
            
            // Date field
            dateLabel.topAnchor.constraint(equalTo: stepTextViewContainer.bottomAnchor, constant: 5),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dateTextFieldContainer.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            dateTextFieldContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateTextFieldContainer.widthAnchor.constraint(equalToConstant: 155),
            dateTextFieldContainer.heightAnchor.constraint(equalToConstant: 50),
            
            dateTextField.topAnchor.constraint(equalTo: dateTextFieldContainer.topAnchor),
            dateTextField.leadingAnchor.constraint(equalTo: dateTextFieldContainer.leadingAnchor),
            dateTextField.trailingAnchor.constraint(equalTo: dateTextFieldContainer.trailingAnchor),
            dateTextField.bottomAnchor.constraint(equalTo: dateTextFieldContainer.bottomAnchor)
        ])
    }
}


// MARK: - Контроллер выбора цели в виде попапа
/// Отображает список целей внутри всплывающего окна с заданными отступами и размерами.
class GoalSelectionPopupViewController: UIViewController {
    
    var goals: [Goal] = []
    var onGoalSelected: ((Goal) -> Void)?
    
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let popupContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        setupViews()
        setupConstraints()
        updateGoalsUI()
        
        // Тап вне попапа для закрытия окна
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    private func setupViews() {
        view.addSubview(dimmingView)
        view.addSubview(popupContainerView)
        popupContainerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Dimming view на весь экран
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Контейнер попапа (400pt высотой, 16pt отступы по бокам, по центру)
            popupContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            popupContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            popupContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupContainerView.heightAnchor.constraint(equalToConstant: 400),
            
            // ScrollView заполняет контейнер
            scrollView.topAnchor.constraint(equalTo: popupContainerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: popupContainerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: popupContainerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: popupContainerView.trailingAnchor),
            
            // Контент внутри ScrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func updateGoalsUI() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        var lastView: UIView?
        for (index, goal) in goals.enumerated() {
            let blockView = GoalBlockViewForAddStep(goal: goal)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(goalTapped(_:)))
            blockView.addGestureRecognizer(tapGesture)
            blockView.isUserInteractionEnabled = true
            
            contentView.addSubview(blockView)
            
            blockView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                blockView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                blockView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            
            if let last = lastView {
                blockView.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 8).isActive = true
            } else {
                blockView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
            }
            lastView = blockView
            
            if index == goals.count - 1 {
                blockView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
            }
        }
    }
    
    @objc private func goalTapped(_ gesture: UITapGestureRecognizer) {
        guard let block = gesture.view as? GoalBlockViewForAddStep else { return }
        onGoalSelected?(block.goal)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func dismissPopup() {
        dismiss(animated: true, completion: nil)
    }
}


/// MARK: - Кастомный блок для выбора цели
class GoalBlockViewForAddStep: UIView {
    
    let goal: Goal

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Regular", size: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressBar: UIProgressView = {
        let progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        return progressBar
    }()
    
    init(goal: Goal) {
        self.goal = goal
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.text = goal.title
        let progressValue = Int(goal.progress)
        percentLabel.text = "\(progressValue)%"
        
        if let goalColor = UIColor(hex: goal.color) {
            percentLabel.textColor = goalColor
            progressBar.progressTintColor = goalColor
        } else {
            percentLabel.textColor = .black
            progressBar.progressTintColor = UIColor(red: 203/255, green: 207/255, blue: 194/255, alpha: 1.0)
        }
        
        progressBar.progress = Float(goal.progress / 100.0)
        
        addSubview(titleLabel)
        addSubview(percentLabel)
        addSubview(progressBar)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            percentLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            percentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            progressBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            progressBar.heightAnchor.constraint(equalToConstant: 10),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}
