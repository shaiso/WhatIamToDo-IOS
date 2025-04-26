//
//  ProfileViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 19.03.2025.
//

import UIKit


class ProfileViewController: UIViewController,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {


    private var goals: [Goal] = []
    var preloadedGoalsWithSteps: [Goal]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)

        view.addSubview(backButton)
        view.addSubview(settingsButton)
        view.addSubview(profileImageContainer)
        profileImageContainer.addSubview(profileImageView)
        view.addSubview(nameLabel)

        view.addSubview(statisticsShadowContainer)
        statisticsShadowContainer.addSubview(statisticsContainerView)
        statisticsContainerView.addSubview(statImageView)
        statisticsContainerView.addSubview(statLabel)
        statisticsContainerView.addSubview(goalsScrollView)
        goalsScrollView.addSubview(goalsContentView)

        view.addSubview(tellAiButtonContainer)
        tellAiButtonContainer.addSubview(tellAiButton)
        
        view.addSubview(slackImageView)

        setupConstraints()

        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        
        tellAiButton.addTarget(self, action: #selector(tellAiButtonTapped), for: .touchUpInside)

        loadSavedProfileImage()

        // Подписка на уведомление об удалении цели (через контекстное меню)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleGoalDeletion(notification:)),
                                               name: Notification.Name("GoalDeleted"),
                                               object: nil)

   
        updateGoalsUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    
    
    
    // MARK: - Обработчик удаления цели (через NotificationCenter)
    @objc private func handleGoalDeletion(notification: Notification) {
        guard let goalToDelete = notification.object as? Goal else { return }
        
        // Показываем Alert с подтверждением
        let alert = UIAlertController(title: "Delete Goal",
                                      message: "Are you sure you want to delete \"\(goalToDelete.title)\"?",
                                      preferredStyle: .alert)
        // Кнопка "Отмена"
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // Кнопка "Удалить"
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            
            // 1) Достаём токен из Keychain
            guard let token = KeychainManager.loadString(key: "accessToken") else {
                print("Error: no access token found in Keychain")
                return
            }
            
            // 2) Вызываем deleteGoal(...) из Routes.swift
            deleteGoal(token: token, goalId: goalToDelete.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let msg):
                        print("Goal deleted successfully: \(msg)")
                        // 3) Удаляем из локального массива
                        self.goals.removeAll(where: { $0.id == goalToDelete.id })
                        // Перерисовываем UI
                        self.updateGoalsUI()
                        NotificationCenter.default.post(name: Notification.Name("GoalCascadeDeleted"), object: goalToDelete)
                        
                    case .failure(let error):
                        // 4) Если пришло "Token has expired"
                        if "\(error)".contains("Token has expired") {
                            self.showTokenExpiredAlert()
                        } else {
                            // 5) Показываем обычный Alert с сообщением об ошибке
                            let errorAlert = UIAlertController(title: "Error",
                                                               message: "\(error)",
                                                               preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(errorAlert, animated: true)
                        }
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }


    @objc private func settingsButtonTapped() {
        print("Settings button tapped")
        let settingsVC = SettingsViewController()
        settingsVC.preloadedGoalsWithSteps = self.preloadedGoalsWithSteps ?? []
        settingsVC.modalPresentationStyle = .fullScreen
        present(settingsVC, animated: true, completion: nil)
    }


    // MARK: - UI обновление списка целей
    private func updateGoalsUI() {
        goalsContentView.subviews.forEach { $0.removeFromSuperview() }
        var lastBlock: UIView?

        for (index, goal) in goals.enumerated() {
            let blockView = GoalBlockView(goal: goal)
            
            goalsContentView.addSubview(blockView)
            blockView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                blockView.leadingAnchor.constraint(equalTo: goalsContentView.leadingAnchor, constant: 16),
                blockView.trailingAnchor.constraint(equalTo: goalsContentView.trailingAnchor, constant: -16)
            ])
            
            if let lastBlock = lastBlock {
                blockView.topAnchor.constraint(equalTo: lastBlock.bottomAnchor, constant: 1).isActive = true
            } else {
                blockView.topAnchor.constraint(equalTo: goalsContentView.topAnchor, constant: 1).isActive = true
            }
            lastBlock = blockView
            
            if index == goals.count - 1 {
                blockView.bottomAnchor.constraint(equalTo: goalsContentView.bottomAnchor, constant: -5).isActive = true
            }
        }
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let passedGoals = preloadedGoalsWithSteps {
            goals = passedGoals
        }
        
        updateGoalsUI()
        
        if let userName = KeychainManager.loadString(key: "userName") {
            nameLabel.text = userName
        }
    }


    // Локальное добавление новой цели
    func addNewGoal(_ newGoal: Goal) {
        goals.append(newGoal)
        updateGoalsUI()
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func profileImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc private func tellAiButtonTapped() {
        let problemsVC = TellAiProblemsViewController()
        if let sheet = problemsVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        problemsVC.modalPresentationStyle = .automatic
        present(problemsVC, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            profileImageView.image = selectedImage
            if let savedURL = saveImageToDocumentsDirectory(selectedImage) {
                UserDefaults.standard.set(savedURL.lastPathComponent, forKey: "profileImageName")
            }
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Локальное сохранение / загрузка изображения
    private func saveImageToDocumentsDirectory(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "profile_picture.jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Ошибка при сохранении изображения:", error)
            return nil
        }
    }

    private func loadSavedProfileImage() {
        if let fileName = UserDefaults.standard.string(forKey: "profileImageName") {
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path),
               let image = UIImage(contentsOfFile: fileURL.path) {
                profileImageView.image = image
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - UI Elements (кнопки, контейнеры, и т.п.)
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

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "settings"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let profileImageContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 6
        container.backgroundColor = .clear
        return container
    }()

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.image = UIImage(named: "Default_person")
        iv.layer.cornerRadius = 77
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Jeremy Clarkson"
        label.font = UIFont(name: "Poppins-Regular", size: 22)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private let statisticsShadowContainer: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    private let statisticsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let statImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "statistics")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let statLabel: UILabel = {
        let label = UILabel()
        label.text = "Statistics"
        label.font = UIFont(name: "Poppins-Medium", size: 20)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let goalsScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.isPagingEnabled = false
        scroll.showsVerticalScrollIndicator = true
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()

    private let goalsContentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let slackImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "slack")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let tellAiButtonContainer: UIView = {
        let containerView = UIView()
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    private let tellAiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Tell the AI about the problems", for: .normal)
        button.titleLabel?.font = UIFont(name: "Poppins-Regular", size: 20)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor(red: 245/255, green: 123/255, blue: 93/255, alpha: 1.0)
        button.layer.cornerRadius = 17
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Кнопка Back
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1),

            // Аватар
            profileImageContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7),
            profileImageContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageContainer.widthAnchor.constraint(equalToConstant: 154),
            profileImageContainer.heightAnchor.constraint(equalToConstant: 154),

            profileImageView.topAnchor.constraint(equalTo: profileImageContainer.topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: profileImageContainer.bottomAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: profileImageContainer.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: profileImageContainer.trailingAnchor),
            
            settingsButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            settingsButton.heightAnchor.constraint(equalToConstant: 30),
            // Имя
            nameLabel.topAnchor.constraint(equalTo: profileImageContainer.bottomAnchor, constant: 16),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Островок Statistics
            statisticsShadowContainer.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            statisticsShadowContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            statisticsShadowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statisticsShadowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            statisticsContainerView.topAnchor.constraint(equalTo: statisticsShadowContainer.topAnchor),
            statisticsContainerView.bottomAnchor.constraint(equalTo: statisticsShadowContainer.bottomAnchor),
            statisticsContainerView.leadingAnchor.constraint(equalTo: statisticsShadowContainer.leadingAnchor),
            statisticsContainerView.trailingAnchor.constraint(equalTo: statisticsShadowContainer.trailingAnchor),

            // Иконка Statistics
            statImageView.topAnchor.constraint(equalTo: statisticsContainerView.topAnchor, constant: 14),
            statImageView.leadingAnchor.constraint(equalTo: statisticsContainerView.leadingAnchor, constant: 19),
            statImageView.widthAnchor.constraint(equalToConstant: 20),
            statImageView.heightAnchor.constraint(equalToConstant: 20),

            statLabel.centerYAnchor.constraint(equalTo: statImageView.centerYAnchor),
            statLabel.leadingAnchor.constraint(equalTo: statImageView.trailingAnchor, constant: 2),
            statLabel.trailingAnchor.constraint(lessThanOrEqualTo: statisticsContainerView.trailingAnchor, constant: -16),

            // UIScrollView
            goalsScrollView.topAnchor.constraint(equalTo: statImageView.bottomAnchor, constant: 16),
            goalsScrollView.leadingAnchor.constraint(equalTo: statisticsContainerView.leadingAnchor),
            goalsScrollView.trailingAnchor.constraint(equalTo: statisticsContainerView.trailingAnchor),
            goalsScrollView.bottomAnchor.constraint(equalTo: statisticsContainerView.bottomAnchor),

            goalsContentView.topAnchor.constraint(equalTo: goalsScrollView.topAnchor),
            goalsContentView.bottomAnchor.constraint(equalTo: goalsScrollView.bottomAnchor),
            goalsContentView.leadingAnchor.constraint(equalTo: goalsScrollView.leadingAnchor),
            goalsContentView.trailingAnchor.constraint(equalTo: goalsScrollView.trailingAnchor),
            goalsContentView.widthAnchor.constraint(equalTo: goalsScrollView.widthAnchor),

            // Контейнер для кнопки Tell AI
            tellAiButtonContainer.topAnchor.constraint(equalTo: statisticsShadowContainer.bottomAnchor, constant: 20),
            tellAiButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            tellAiButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            tellAiButtonContainer.heightAnchor.constraint(equalToConstant: 65),

            tellAiButton.topAnchor.constraint(equalTo: tellAiButtonContainer.topAnchor),
            tellAiButton.bottomAnchor.constraint(equalTo: tellAiButtonContainer.bottomAnchor),
            tellAiButton.leadingAnchor.constraint(equalTo: tellAiButtonContainer.leadingAnchor),
            tellAiButton.trailingAnchor.constraint(equalTo: tellAiButtonContainer.trailingAnchor),

            // Slack‑иконка (рядом с кнопкой)
            slackImageView.centerYAnchor.constraint(equalTo: tellAiButtonContainer.centerYAnchor),
            slackImageView.trailingAnchor.constraint(equalTo: tellAiButtonContainer.leadingAnchor, constant: -4),
            slackImageView.widthAnchor.constraint(equalToConstant: 33),
            slackImageView.heightAnchor.constraint(equalToConstant: 33)
        ])
    }
}

// MARK: - представление для цели (GoalBlockView)
class GoalBlockView: UIView {
    
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

        if goal.title != "Повседневные дела", #available(iOS 13.0, *) {
            setupContextMenuInteraction()
        }
    }

}

// MARK: - Контекстное меню (если нужно iOS 13+)
@available(iOS 13.0, *)
extension GoalBlockView: UIContextMenuInteractionDelegate {
    
    func setupContextMenuInteraction() {
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
    }
    
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // Отправляем уведомление об удалении цели
                NotificationCenter.default.post(name: Notification.Name("GoalDeleted"), object: self.goal)
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
}
