//
//  SettingsViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 16.04.2025.
//

import UIKit
import EventKit

class SettingsViewController: UIViewController {
    
    var preloadedGoalsWithSteps: [Goal]?
    private let calendarImportedKey = "calendarImported"

    
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
    
    private let settingsLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = UIFont(name: "Poppins-Regular", size: 24)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let grayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Import iOS Calendar", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        
        view.backgroundColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        view.addSubview(backButton)
        view.addSubview(settingsLabel)
        view.addSubview(grayButton)
        
        // Добавляем индикатор в иерархию
        view.addSubview(activityIndicator)
        
        setupConstraints()
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        grayButton.addTarget(self, action: #selector(importCalendarButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Layout
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1),
            
            settingsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            settingsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            grayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grayButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            grayButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 35),
            grayButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -35),
            grayButton.heightAnchor.constraint(equalToConstant: 65),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func importCalendarButtonTapped() {
        // если уже был импорт – показываем одно‑кнопочный alert и выходим
        if KeychainManager.loadString(key: calendarImportedKey) == "true" {
            showSingleAlert(title: "Calendar Already Imported",
                            message: "You have already imported your iOS calendar.")
            return
         }
         
       
        // обычный сценарий первого импорта
        let alert = UIAlertController(title: "Import iOS Calendar",
                                      message: "Are you sure you want to import iOS calendar events?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Import", style: .default) { [weak self] _ in
            self?.requestCalendarAccessAndFetch()
        })
        present(alert, animated: true)
    }

    
    // MARK: - Calendar Access & Fetch
    
    /// Запрашиваем доступ к календарю и, если доступ предоставлен, извлекаем события
    private func requestCalendarAccessAndFetch() {
        let eventStore = EKEventStore()
        
        // Запускаем анимацию загрузки
        activityIndicator.startAnimating()
        
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                // Останавливаем индикатор (доступ к календарю получили или отказ, запрос завершён)
                self?.activityIndicator.stopAnimating()
                
                if granted {
                    self?.fetchCalendarEvents(with: eventStore)
                } else {
                    let alert = UIAlertController(
                        title: "Access Denied",
                        message: "Please allow calendar access in Settings",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    /// Извлекаем события за период 2024-01-01...2025-12-31
    private func fetchCalendarEvents(with eventStore: EKEventStore) {
        let calendar = Calendar.current
        
        // Начало периода: 1 января 2024
        var startComponents = DateComponents()
        startComponents.year = 2024
        startComponents.month = 1
        startComponents.day = 1
        guard let startDate = calendar.date(from: startComponents) else { return }
        
        // Конец периода: 31 декабря 2025
        var endComponents = DateComponents()
        endComponents.year = 2025
        endComponents.month = 12
        endComponents.day = 31
        guard let endDate = calendar.date(from: endComponents) else { return }
        
        activityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            let events = eventStore.events(matching: predicate)
                // Фильтруем "пустые" события, у которых нет ни названия, ни заметок
                .filter { !($0.title ?? "").isEmpty || !($0.notes ?? "").isEmpty }
            
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.processFetchedEvents(events)
            }
        }
    }
    
    /// Формируем массив StepForBulk и запускаем загрузку (bulk) на сервер
    private func processFetchedEvents(_ events: [EKEvent]) {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let bulkSteps: [StepForBulk] = events.map { event in
            let eventTitle = event.title ?? ""
            let eventNotes = event.notes ?? ""
            let combinedDescription = eventNotes.isEmpty
                ? eventTitle
                : "\(eventTitle)\n\(eventNotes)"
            
            let dateString = isoFormatter.string(from: event.startDate)
            
            return StepForBulk(description: combinedDescription, date: dateString)
        }
        
        uploadBulkStepsToServer(bulkSteps)
    }
    
    // MARK: - Server Upload

    private func uploadBulkStepsToServer(_ steps: [StepForBulk]) {
        guard let goalArray = preloadedGoalsWithSteps,
              let dailyGoal = goalArray.first(where: { $0.title == "Повседневные дела" })
        else {
            let alert = UIAlertController(
                title: "Goal Not Found",
                message: "Could not find 'Повседневные дела' in local data.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        guard let accessToken = KeychainManager.loadString(key: "accessToken") else {
            let alert = UIAlertController(
                title: "Not Authorized",
                message: "You need to be logged in to import events.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Запускаем индикатор перед сетевым запросом
        activityIndicator.startAnimating()
        
        addStepsBulk(token: accessToken, goalId: dailyGoal.id, steps: steps) { [weak self] result in
            DispatchQueue.main.async {
                // Останавливаем индикатор в любом случае (успех/ошибка)
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let message):
                    let alert = UIAlertController(
                        title: "Import Successful",
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                    self?.fetchUpdatedGoal(goalId: dailyGoal.id, token: accessToken)
                    KeychainManager.saveString(key: self?.calendarImportedKey ?? "calendarImported", value: "true")

                    
                case .failure(let error):
                    // Проверяем, не просрочен ли токен
                    if case NetworkError.serverError(let serverMessage) = error,
                       serverMessage.contains("expired") {
                        self?.showTokenExpiredAlert()
                    } else {
                        // Если это не "expired" — показываем универсальное сообщение
                        self?.showUnexpectedErrorAlert()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Goal refresh after bulk import
    private func fetchUpdatedGoal(goalId: Int, token: String) {
        activityIndicator.startAnimating()

        getGoalDetail(token: token, goalId: goalId) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                switch result {
                case .success(let updatedGoal):
                    // 1. обновляем локальный массив настроек
                    if var stored = self?.preloadedGoalsWithSteps {
                        if let idx = stored.firstIndex(where: { $0.id == updatedGoal.id }) {
                            stored[idx] = updatedGoal
                        } else {
                            stored.append(updatedGoal)
                        }
                        self?.preloadedGoalsWithSteps = stored
                    }
                    // 2. пробрасываем цель дальше по приложению
                    NotificationCenter.default.post(name: Notification.Name("GoalInfoUpdated"),
                                                    object: updatedGoal)

                case .failure(let error):
                    self?.showUnexpectedErrorAlert()
                    print("fetchUpdatedGoal error:", error)
                }
            }
        }
    }

    // MARK: - Error Handling Helpers
    
    /// Показываем Alert с универсальным сообщением об ошибке
    private func showUnexpectedErrorAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "An unexpected error occurred. Please try again later.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
  
    private func showSingleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}


