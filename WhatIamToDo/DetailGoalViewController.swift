//
//  DetailGoalViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 31.03.2025.
//

import UIKit

class DetailGoalViewController: UIViewController {
    
    // MARK: - Properties для передачи данных
    var initialGoalText: String?   // Название цели, полученное с карточки
    var initialStepText: String?   // Текст шага, полученный с карточки
    var initialDateText: String?   // Дата, полученная с карточки
    var initialGoalColor: String? 
    var cardId: Int?

    
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "More about your Step."
        label.font = UIFont(name: "Poppins-Medium", size: 22)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let goalLabel: UILabel = {
        let label = UILabel()
        label.text = "Goal"
        label.font = UIFont(name: "Poppins-Medium", size: 20)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let goalTextViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let goalTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont(name: "Poppins-Regular", size: 18)
        tv.textColor = .black
        tv.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        tv.layer.cornerRadius = 20
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.textAlignment = .center
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = true
        return tv
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
        tv.textAlignment = .center
        tv.isEditable = false
        tv.isSelectable = false
        tv.isScrollEnabled = true
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
        tf.textAlignment = .center
        tf.isEnabled = false
        return tf
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1.0)
        setupUI()
        populateData()
    }
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(goalLabel)
        view.addSubview(goalTextViewContainer)
        goalTextViewContainer.addSubview(goalTextView)
        view.addSubview(stepLabel)
        view.addSubview(stepTextViewContainer)
        stepTextViewContainer.addSubview(stepTextView)
        view.addSubview(dateLabel)
        view.addSubview(dateTextFieldContainer)
        dateTextFieldContainer.addSubview(dateTextField)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Goal Label
            goalLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            goalLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            goalLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Goal TextView Container
            goalTextViewContainer.topAnchor.constraint(equalTo: goalLabel.bottomAnchor, constant: 4),
            goalTextViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            goalTextViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            goalTextViewContainer.heightAnchor.constraint(equalToConstant: 75),
            
            // Goal TextView
            goalTextView.topAnchor.constraint(equalTo: goalTextViewContainer.topAnchor),
            goalTextView.leadingAnchor.constraint(equalTo: goalTextViewContainer.leadingAnchor),
            goalTextView.trailingAnchor.constraint(equalTo: goalTextViewContainer.trailingAnchor),
            goalTextView.bottomAnchor.constraint(equalTo: goalTextViewContainer.bottomAnchor),
            
            // Step Label
            stepLabel.topAnchor.constraint(equalTo: goalTextViewContainer.bottomAnchor, constant: 5),
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
    
    private func populateData() {
        goalTextView.text = initialGoalText ?? ""
        stepTextView.text = initialStepText ?? ""
        dateTextField.text = initialDateText ?? ""
        
        // Устанавливаем цвет тени для контейнера цели
        if let hexColor = initialGoalColor, let color = UIColor(hex: hexColor) {
            goalTextViewContainer.layer.shadowColor = color.cgColor
        } else {
            goalTextViewContainer.layer.shadowColor = UIColor.black.cgColor 
        }
    }

}
