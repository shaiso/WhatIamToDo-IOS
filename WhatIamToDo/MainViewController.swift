//
//  MainViewController.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 14.02.2025.
//

import UIKit


// MARK: - Кастомный FlowLayout с анимацией перелистывания
class StackCardFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        // Горизонтальная прокрутка, небольшой зазор между карточками
        scrollDirection = .horizontal
        minimumLineSpacing = 5
        
        // Размер карточки = весь размер коллекции
        let width = collectionView.bounds.width
        let height = collectionView.bounds.height
        itemSize = CGSize(width: width, height: height)
        sectionInset = .zero
    }
    
    // Анимация: центр — чуть крупнее, края — чуть меньше
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let array = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }),
              let collectionView = collectionView else {
            return nil
        }
        
        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        
        for attributes in array {
            let distance = abs(attributes.center.x - centerX)
            let scale = max(0.9, 1 - distance / collectionView.bounds.width)
            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
            attributes.zIndex = Int(scale * 10)
        }
        return array
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    // "Прилипание" к ближайшей карточке
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        
        let targetRect = CGRect(origin: proposedContentOffset, size: collectionView.bounds.size)
        guard let attributesArray = super.layoutAttributesForElements(in: targetRect) else {
            return proposedContentOffset
        }
        
        let centerX = proposedContentOffset.x + collectionView.bounds.width / 2
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        
        for attributes in attributesArray {
            let itemCenterX = attributes.center.x
            if abs(itemCenterX - centerX) < abs(offsetAdjustment) {
                offsetAdjustment = itemCenterX - centerX
            }
        }
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}

class MainViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private let contentView: UIView = {
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Данные календаря
    private var currentYear: Int = 2025
    private var allMonths: [[Int?]] = []
    private var currentMonthIndex: Int = 11
    
    private let monthNames: [String] = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    // Данные, переданные с экрана входа (массив целей, где каждая цель содержит свой массив шагов)
    var preloadedGoalsWithSteps: [Goal]?
    
    // Когда пользователь нажимает на день календаря, формируется строка вида "05.12.2025"
    private var selectedDayString: String? = nil
    private var selectedIndexPath: IndexPath? = nil
    
    // MARK: - Шаги
    /// Словарь, где ключ – дата (без времени), а значение – массив шагов на эту дату
    private var stepsByDate: [Date: [Step]] = [:]
    /// Текущий массив шагов для выбранной даты
    private var currentSteps: [Step] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Если данные переданы с экрана входа – извлекаем шаги из каждой цели
        if let goals = preloadedGoalsWithSteps {
            var allSteps: [Step] = []
            for goal in goals {
                allSteps.append(contentsOf: goal.steps)
            }
            buildStepsByDate(from: allSteps)
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStepUpdated(_:)),
                                               name: NSNotification.Name("StepUpdated"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDetailNotification(_:)),
                                               name: Notification.Name("DetailTodoCard"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNewStepCreated(_:)),
                                               name: NSNotification.Name("NewStepCreated"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNewGoalCreated(_:)),
                                               name: Notification.Name("NewGoalCreated"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleGoalCascadeDeleted(_:)),
                                               name: Notification.Name("GoalCascadeDeleted"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleStepsRescheduled(_:)),
                                                   name: Notification.Name("StepsRescheduled"),
                                                   object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleGoalInfoUpdated(_:)),
                                               name: Notification.Name("GoalInfoUpdated"),
                                               object: nil)

        setupUI()
    }
    
    
    private func buildStepsByDate(from steps: [Step]) {
        stepsByDate.removeAll()
        for step in steps {
            guard let d = step.dateObject else { continue }
            let dateOnly = stripTime(from: d)
            stepsByDate[dateOnly, default: []].append(step)
        }

        for dateKey in stepsByDate.keys {
            if var arr = stepsByDate[dateKey] {
                sortSteps(&arr)  // вызываем функцию сортировки
                stepsByDate[dateKey] = arr
            }
        }
    }

    /// Удаляет из даты время (оставляет год, месяц, день)
    private func stripTime(from date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func dateFromString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    func removeStep(withID id: Int) {
        if let index = currentSteps.firstIndex(where: { $0.id == id }) {
            currentSteps.remove(at: index)
            cardsCollectionView.reloadData()
            pageControl.numberOfPages = currentSteps.count + 1
        }
    }
    
    func removeStepFromCalendar(withID id: Int, stepDate: Date) {
        let dateOnly = stripTime(from: stepDate)  // Получаем дату без времени
        if var stepsForDate = stepsByDate[dateOnly] {
            if let index = stepsForDate.firstIndex(where: { $0.id == id }) {
                stepsForDate.remove(at: index)
                stepsByDate[dateOnly] = stepsForDate
            }
        }
        // Перезагружаем календарь, чтобы индикаторы обновились
        calendarCollectionView.reloadData()
    }
    
    private func updateTodoTitleLabel() {
        guard let selectedString = selectedDayString else {
            // Если дата не выбрана, прячем заголовок
            todoTitleLabel.text = ""
            todoTitleLabel.isHidden = true
            editIconImageView.isHidden = true
            return
        }
        
        if currentSteps.isEmpty {
            todoTitleLabel.text = "To-do list for \(selectedString)"
            editIconImageView.isHidden = false
            return
        }
        
        let completedCount = currentSteps.filter { $0.status == "done" }.count
        let totalCount = currentSteps.count
        
        todoTitleLabel.text = "To-do list for \(selectedString) (\(completedCount)/\(totalCount))"
        todoTitleLabel.isHidden = false
        editIconImageView.isHidden = false
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        var customCalendar = Calendar(identifier: .gregorian)
        customCalendar.locale = Locale(identifier: "en_US_POSIX")
        customCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        // Определяем текущий год/месяц (диапазон 2024–2035)
        let now = Date()
        let realYear = customCalendar.component(.year, from: now)
        let realMonth = customCalendar.component(.month, from: now)
        if realYear < 2024 {
            currentYear = 2024
        } else if realYear > 2035 {
            currentYear = 2035
        } else {
            currentYear = realYear
        }
        currentMonthIndex = realMonth - 1
        
        // Формируем массив ячеек для календаря
        allMonths = createAllMonthsFor(year: currentYear, calendar: customCalendar)
        
        view.backgroundColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        
        // Верхние элементы
        contentView.addSubview(profileButton)
        contentView.addSubview(scheduleLabel)
        contentView.addSubview(addGoalButton)
        
        // Контейнер календаря с тенью
        contentView.addSubview(calendarShadowContainer)
        calendarShadowContainer.addSubview(calendarContainerView)
        
        // Внутренние элементы календарного блока
        calendarContainerView.addSubview(calendarIconImageView)
        calendarContainerView.addSubview(calendarTitleLabel)
        calendarContainerView.addSubview(prevMonthButton)
        calendarContainerView.addSubview(monthLabel)
        calendarContainerView.addSubview(nextMonthButton)
        calendarContainerView.addSubview(daysStackView)
        
        let days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        for d in days {
            daysStackView.addArrangedSubview(makeDayOval(d))
        }
        
        calendarContainerView.addSubview(calendarCollectionView)
        calendarCollectionView.register(DayCell.self, forCellWithReuseIdentifier: "DayCell")
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate = self
        
        monthLabel.text = "\(monthNames[currentMonthIndex]) \(currentYear)"
        
        // Нижний блок (To-do list)
        contentView.addSubview(todoContainerView)
        contentView.addSubview(editIconImageView)
        contentView.addSubview(todoTitleLabel)
        todoTitleLabel.isHidden = true
        editIconImageView.isHidden = true
        
        todoContainerView.addSubview(cardsCollectionView)
        todoContainerView.addSubview(pageControl)
        todoContainerView.isHidden = true
        
        setupConstraints()
        
        // Кнопки
        profileButton.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
        addGoalButton.addTarget(self, action: #selector(addGoalButtonTapped), for: .touchUpInside)
        addGoalButton.addTarget(self, action: #selector(darkenButton(_:)), for: [.touchDown, .touchDragEnter])
        addGoalButton.addTarget(self, action: #selector(resetButtonColor(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])
        
        prevMonthButton.addTarget(self, action: #selector(darkenArrowButton(_:)), for: [.touchDown, .touchDragEnter])
        prevMonthButton.addTarget(self, action: #selector(resetArrowButtonColor(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])
        nextMonthButton.addTarget(self, action: #selector(darkenArrowButton(_:)), for: [.touchDown, .touchDragEnter])
        nextMonthButton.addTarget(self, action: #selector(resetArrowButtonColor(_:)), for: [.touchUpInside, .touchDragExit, .touchCancel])
        
        prevMonthButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)
        nextMonthButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft(_:)))
        swipeLeft.direction = .left
        calendarContainerView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight(_:)))
        swipeRight.direction = .right
        calendarContainerView.addGestureRecognizer(swipeRight)
        
        // Уведомления
        NotificationCenter.default.addObserver(self, selector: #selector(handleEditNotification(_:)), name: Notification.Name("EditTodoCard"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDetailNotification(_:)), name: Notification.Name("DetailTodoCard"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func createAllMonthsFor(year: Int, calendar: Calendar) -> [[Int?]] {
        var result: [[Int?]] = []
        for month in 1...12 {
            let comps = DateComponents(year: year, month: month, day: 1)
            guard let firstDayDate = calendar.date(from: comps) else {
                result.append([])
                continue
            }
            let weekday = calendar.component(.weekday, from: firstDayDate)
            let weekdayForMondayBase = (weekday + 5) % 7 + 1
            let range = calendar.range(of: .day, in: .month, for: firstDayDate)!
            let daysInMonth = range.count
            let offset = weekdayForMondayBase - 1
            var monthCells: [Int?] = []
            for _ in 0..<offset {
                monthCells.append(nil)
            }
            for dayNum in 1...daysInMonth {
                monthCells.append(dayNum)
            }
            result.append(monthCells)
        }
        return result
    }
    
    /// Сортируем так, чтобы "planned" шли раньше "done",
    /// а при одинаковом статусе – сравниваем по id (возрастающе).
    private func sortSteps(_ steps: inout [Step]) {
        steps.sort { lhs, rhs in
            // Cначала статус (planned < done)
            if lhs.status != rhs.status {
                return lhs.status < rhs.status
            }
            // Если статус одинаковый, сравним по id
            return lhs.id < rhs.id
        }
    }

    // MARK: - Actions
    @objc private func profileButtonTapped() {
        print("Profile button tapped")
        let profileVC = ProfileViewController()
        // Передаём актуальный массив целей (если он не nil)
        profileVC.preloadedGoalsWithSteps = self.preloadedGoalsWithSteps ?? []
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true, completion: nil)
    }

    
    @objc private func addGoalButtonTapped() {
        let addGoalVC = AddGoalViewController()
        if let sheet = addGoalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        addGoalVC.modalPresentationStyle = .automatic
        present(addGoalVC, animated: true)
    }
    
    @objc private func darkenButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = UIColor(red: 150/255, green: 150/255, blue: 150/255, alpha: 1.0)
        }
    }
    
    @objc private func resetButtonColor(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1.0)
        }
    }
    
    @objc private func darkenArrowButton(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
        }
    }
    
    @objc private func resetArrowButtonColor(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = .white
        }
    }
    
    private func animateMonthLabelUpdate(newText: String) {
        UIView.animate(withDuration: 0.2, animations: {
            self.monthLabel.alpha = 0.0
            self.monthLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.monthLabel.text = newText
            UIView.animate(withDuration: 0.2) {
                self.monthLabel.alpha = 1.0
                self.monthLabel.transform = .identity
            }
        }
    }
    
    @objc private func prevMonthTapped() {
        if currentMonthIndex > 0 {
            currentMonthIndex -= 1
        } else if currentYear > 2024 {
            currentYear -= 1
            currentMonthIndex = 11
            var customCalendar = Calendar(identifier: .gregorian)
            customCalendar.locale = Locale(identifier: "en_US_POSIX")
            customCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
            allMonths = createAllMonthsFor(year: currentYear, calendar: customCalendar)
        }
        animateMonthLabelUpdate(newText: "\(monthNames[currentMonthIndex]) \(currentYear)")
        selectedIndexPath = nil
        calendarCollectionView.reloadData()
        todoContainerView.isHidden = true
        todoTitleLabel.isHidden = true
        editIconImageView.isHidden = true
        selectedDayString = nil
    }
    
    @objc private func nextMonthTapped() {
        if currentMonthIndex < 11 {
            currentMonthIndex += 1
        } else if currentYear < 2035 {
            currentYear += 1
            currentMonthIndex = 0
            var customCalendar = Calendar(identifier: .gregorian)
            customCalendar.locale = Locale(identifier: "en_US_POSIX")
            customCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
            allMonths = createAllMonthsFor(year: currentYear, calendar: customCalendar)
        }
        animateMonthLabelUpdate(newText: "\(monthNames[currentMonthIndex]) \(currentYear)")
        selectedIndexPath = nil
        calendarCollectionView.reloadData()
        todoContainerView.isHidden = true
        todoTitleLabel.isHidden = true
        editIconImageView.isHidden = true
        selectedDayString = nil
    }
    
    @objc private func didSwipeLeft(_ gesture: UISwipeGestureRecognizer) {
        nextMonthTapped()
    }
    
    @objc private func didSwipeRight(_ gesture: UISwipeGestureRecognizer) {
        prevMonthTapped()
    }
    
    // MARK: - Notifications (Edit / Detail)
    @objc private func handleEditNotification(_ notification: Notification) {
        
        guard let cardIndex = notification.object as? Int, cardIndex >= 0, cardIndex < currentSteps.count else {
            print("Не удалось определить индекс карточки для редактирования")
            return
        }
        
        let step = currentSteps[cardIndex]
        let editGoalVC = EditGoalViewController()
        
        editGoalVC.initialStepText = step.description
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let dateObj = step.dateObject {
            editGoalVC.initialDateText = formatter.string(from: dateObj)
        } else {
            editGoalVC.initialDateText = ""
        }
        
        editGoalVC.cardId = step.id
        editGoalVC.goalId = step.goal_id
        
        if let sheet = editGoalVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        editGoalVC.modalPresentationStyle = .automatic
        present(editGoalVC, animated: true, completion: nil)
    }

    
    @objc private func handleStepUpdated(_ notification: Notification) {
        // Получаем данные обновлённого шага
        guard let payload = notification.object as? (Goal, Step) else { return }
        let (updatedGoal, updatedStep) = payload

        // 1. Удаляем старую версию обновлённого шага из всех корзин (stepsByDate)
        for (date, var stepsArray) in stepsByDate {
            if let idx = stepsArray.firstIndex(where: { $0.id == updatedStep.id }) {
                stepsArray.remove(at: idx)
                stepsByDate[date] = stepsArray
            }
        }
        
        // 2. Добавляем обновлённый шаг в нужную корзину по новой дате
        guard let newDateObj = updatedStep.dateObject else { return }
        let newDateOnly = stripTime(from: newDateObj)
        stepsByDate[newDateOnly, default: []].append(updatedStep)
        if var arr = stepsByDate[newDateOnly] {
            sortSteps(&arr)
            stepsByDate[newDateOnly] = arr
        }
        
        // Обновляем календарь
        calendarCollectionView.reloadData()
        
        // 3. Если выбранная дата совпадает – обновляем массив карточек и UI коллекции
        if let selectedString = selectedDayString,
           let selectedDate = dateFromString(selectedString) {
            
            let selectedDateOnly = stripTime(from: selectedDate)
            // Пересчитываем currentSteps согласно обновлённым данным
            currentSteps = stepsByDate[selectedDateOnly] ?? []
            
            // Сохраняем старый индекс страницы
            let oldPage = pageControl.currentPage
            
            // Обновляем коллекцию карточек единоразово
            cardsCollectionView.reloadData()
            // Принудительно обновляем layout коллекции – заставляем пересчитать расположение ячеек
            cardsCollectionView.layoutIfNeeded()
            
            // Синхронизируем pageControl
            pageControl.numberOfPages = currentSteps.count + 1
            let maxIndex = currentSteps.count
            let newPage = (oldPage >= maxIndex) ? maxIndex : oldPage
            pageControl.currentPage = newPage
            
            // Прокручиваем коллекцию к нужной карточке
            let indexPath = IndexPath(item: newPage, section: 0)
            if newPage <= maxIndex {
                cardsCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
            }
            
            updateTodoTitleLabel()
        }
    }




    @objc private func handleDetailNotification(_ notification: Notification) {
        // Извлекаем индекс карточки, который был передан в уведомлении
        guard let cardIndex = notification.object as? Int, cardIndex >= 0, cardIndex < currentSteps.count else {
            print("Не удалось определить индекс карточки для показа деталей")
            return
        }
        
        let selectedStep = currentSteps[cardIndex]
        

        let detailVC = DetailGoalViewController()
        
        detailVC.initialGoalText = selectedStep.goal_name
        detailVC.initialStepText = selectedStep.description
        detailVC.initialGoalColor = selectedStep.color
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let dateObj = selectedStep.dateObject {
            detailVC.initialDateText = formatter.string(from: dateObj)
        } else {
            detailVC.initialDateText = "Н/Д"
        }
        detailVC.cardId = cardIndex

        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        detailVC.modalPresentationStyle = .automatic
        present(detailVC, animated: true, completion: nil)
    }
    
    @objc private func handleNewStepCreated(_ notification: Notification) {
        guard let payload = notification.object as? (Goal, Step) else {
            return
        }
        let (updatedGoal, newStep) = payload
        print("handleNewStepCreated => goalId=\(updatedGoal.id), stepId=\(newStep.id)")
        
        guard let dateObj = newStep.dateObject else {
            return
        }
        let dateOnly = stripTime(from: dateObj)
        stepsByDate[dateOnly, default: []].append(newStep)
        
        if var arr = stepsByDate[dateOnly] {
            sortSteps(&arr)
            stepsByDate[dateOnly] = arr
        }
        
        // Если у нас выбрана та же дата — добавляем в currentSteps
        if let selectedString = selectedDayString,
           let selectedDate = dateFromString(selectedString) {
            
            let selectedDateOnly = stripTime(from: selectedDate)
            if selectedDateOnly == dateOnly {
                // ★ Сохраняем старый page
                let oldPage = pageControl.currentPage
                
                // Добавляем шаг
                currentSteps.append(newStep)
                
                // Перезагружаем карточки
                cardsCollectionView.reloadData()
                // Обновляем кол-во страниц
                pageControl.numberOfPages = currentSteps.count + 1
                
                let newPage = currentSteps.count - 1
                pageControl.currentPage = newPage
                
                let idxPath = IndexPath(item: newPage, section: 0)
                if newPage >= 0 {
                    cardsCollectionView.scrollToItem(at: idxPath, at: .left, animated: false)
                }
            }
        }
        
        // Обновляем календарь после добавления
        calendarCollectionView.reloadData()
    }

    
    @objc private func handleNewGoalCreated(_ notification: Notification) {
        // Извлекаем созданную цель
        guard let createdGoal = notification.object as? Goal else {
            print("NewGoalCreated notification received, but object is not a Goal")
            return
        }
        print("handleNewGoalCreated => goalId=\(createdGoal.id), title=\(createdGoal.title)")
        
        self.preloadedGoalsWithSteps?.append(createdGoal)
        
        for step in createdGoal.steps {
            if let dateObj = step.dateObject {
                let dateOnly = stripTime(from: dateObj)
                stepsByDate[dateOnly, default: []].append(step)
                
                if var arr = stepsByDate[dateOnly] {
                    sortSteps(&arr)
                    stepsByDate[dateOnly] = arr
                }

            }
        }
        
        calendarCollectionView.reloadData()

    }
    
    @objc private func handleGoalCascadeDeleted(_ notification: Notification) {
        guard let deletedGoal = notification.object as? Goal else { return }
        
        // Удаляем цель
        self.preloadedGoalsWithSteps?.removeAll { $0.id == deletedGoal.id }
        
        // Удаляем шаги этой цели из словаря
        for (dateKey, stepsArray) in stepsByDate {
            let filteredSteps = stepsArray.filter { $0.goal_id != deletedGoal.id }
            stepsByDate[dateKey] = filteredSteps
        }
        
        // Удаляем их из currentSteps
        currentSteps.removeAll { $0.goal_id == deletedGoal.id }
        
        // Обновляем календарь
        calendarCollectionView.reloadData()
        
        // ★ Сохраняем старый page
        let oldPage = pageControl.currentPage
        
        // Перезагружаем карточки
        cardsCollectionView.reloadData()
        pageControl.numberOfPages = currentSteps.count + 1
        
        let maxIndex = currentSteps.count
        let newPage = (oldPage >= maxIndex) ? maxIndex : oldPage
        pageControl.currentPage = newPage
        
        let indexPath = IndexPath(item: newPage, section: 0)
        if newPage <= maxIndex {
            cardsCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        }
    }

    
    @objc private func handleStepsRescheduled(_ notification: Notification) {
        guard let updatedSteps = notification.object as? [Step] else { return }
        
        // Обновляем массив целей
        if var goals = preloadedGoalsWithSteps {
            for step in updatedSteps {
                if let goalIndex = goals.firstIndex(where: { $0.id == step.goal_id }) {
                    var stepsArray = goals[goalIndex].steps
                    if let existingIndex = stepsArray.firstIndex(where: { $0.id == step.id }) {
                        stepsArray[existingIndex] = step
                    } else {
                        stepsArray.append(step)
                    }
                    goals[goalIndex].steps = stepsArray
                }
            }
            self.preloadedGoalsWithSteps = goals
        }
        
        // Удаляем старые версии шагов
        for (dateKey, var oldSteps) in stepsByDate {
            oldSteps.removeAll { updatedSteps.map({ $0.id }).contains($0.id) }
            stepsByDate[dateKey] = oldSteps
        }
        // Добавляем новые / пересохраняем
        for step in updatedSteps {
            if let realDate = step.dateObject {
                let dateOnly = stripTime(from: realDate)
                stepsByDate[dateOnly, default: []].append(step)
                
                if var arr = stepsByDate[dateOnly] {
                    sortSteps(&arr)
                    stepsByDate[dateOnly] = arr
                }
            }
        }
        
        // Обновляем currentSteps, если дата совпадает
        if let selectedStr = selectedDayString,
           let selectedDate = dateFromString(selectedStr) {
            let dateOnly = stripTime(from: selectedDate)
            currentSteps = stepsByDate[dateOnly] ?? []
        }
        
        // Обновляем календарь
        calendarCollectionView.reloadData()
        
        // ★ Сохраняем старый page
        let oldPage = pageControl.currentPage
        
        // Перезагружаем карточки
        cardsCollectionView.reloadData()
        pageControl.numberOfPages = currentSteps.count + 1
        
        let maxIndex = currentSteps.count
        let newPage = (oldPage >= maxIndex) ? maxIndex : oldPage
        pageControl.currentPage = newPage
        
        let indexPath = IndexPath(item: newPage, section: 0)
        if newPage <= maxIndex {
            cardsCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        }
    }
    
    @objc private func handleGoalInfoUpdated(_ notification: Notification) {
        guard let updatedGoal = notification.object as? Goal else { return }

        // 1. Обновляем массив целей
        if var goals = preloadedGoalsWithSteps {
            if let idx = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                goals[idx] = updatedGoal
            } else {
                goals.append(updatedGoal)
            }
            preloadedGoalsWithSteps = goals
        } else {
            preloadedGoalsWithSteps = [updatedGoal]
        }

        // 2. Перестраиваем словарь stepsByDate
        //    – удаляем все старые шаги этой цели
        for (dateKey, var stepsArr) in stepsByDate {
            stepsArr.removeAll { $0.goal_id == updatedGoal.id }
            stepsByDate[dateKey] = stepsArr
        }
        //    – добавляем новые
        for step in updatedGoal.steps {
            if let d = step.dateObject {
                let dateOnly = stripTime(from: d)
                stepsByDate[dateOnly, default: []].append(step)
                if var arr = stepsByDate[dateOnly] {
                    sortSteps(&arr)
                    stepsByDate[dateOnly] = arr
                }
            }
        }

        // 3. Если сейчас выбран день, пересчитываем currentSteps
        if let selectedStr = selectedDayString,
           let selectedDate = dateFromString(selectedStr) {
            let dateOnly = stripTime(from: selectedDate)
            currentSteps = stepsByDate[dateOnly] ?? []
        }

        // 4. Перерисовываем UI
        calendarCollectionView.reloadData()
        cardsCollectionView.reloadData()
        pageControl.numberOfPages = currentSteps.count + 1
        if pageControl.currentPage >= pageControl.numberOfPages { pageControl.currentPage = 0 }
        updateTodoTitleLabel()
    }

    // MARK: - Constraints Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 15),
            profileButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 21),
            profileButton.widthAnchor.constraint(equalToConstant: 58),
            profileButton.heightAnchor.constraint(equalToConstant: 58),
            
            scheduleLabel.centerYAnchor.constraint(equalTo: profileButton.centerYAnchor),
            scheduleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            addGoalButton.centerYAnchor.constraint(equalTo: profileButton.centerYAnchor),
            addGoalButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -21),
            addGoalButton.widthAnchor.constraint(equalToConstant: 58),
            addGoalButton.heightAnchor.constraint(equalToConstant: 58),
            
            calendarShadowContainer.topAnchor.constraint(equalTo: scheduleLabel.bottomAnchor, constant: 35),
            calendarShadowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            calendarShadowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            calendarShadowContainer.heightAnchor.constraint(equalToConstant: 470),
            
            calendarContainerView.topAnchor.constraint(equalTo: calendarShadowContainer.topAnchor),
            calendarContainerView.leadingAnchor.constraint(equalTo: calendarShadowContainer.leadingAnchor),
            calendarContainerView.trailingAnchor.constraint(equalTo: calendarShadowContainer.trailingAnchor),
            calendarContainerView.bottomAnchor.constraint(equalTo: calendarShadowContainer.bottomAnchor),
            
            calendarIconImageView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor, constant: 10),
            calendarIconImageView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor, constant: 9),
            calendarIconImageView.widthAnchor.constraint(equalToConstant: 20),
            calendarIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            calendarTitleLabel.centerYAnchor.constraint(equalTo: calendarIconImageView.centerYAnchor),
            calendarTitleLabel.leadingAnchor.constraint(equalTo: calendarIconImageView.trailingAnchor, constant: 2),
            
            prevMonthButton.topAnchor.constraint(equalTo: calendarIconImageView.bottomAnchor, constant: 15),
            prevMonthButton.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor, constant: 33),
            prevMonthButton.widthAnchor.constraint(equalToConstant: 30),
            prevMonthButton.heightAnchor.constraint(equalToConstant: 30),
            
            monthLabel.centerYAnchor.constraint(equalTo: prevMonthButton.centerYAnchor),
            monthLabel.centerXAnchor.constraint(equalTo: calendarContainerView.centerXAnchor),
            
            nextMonthButton.centerYAnchor.constraint(equalTo: prevMonthButton.centerYAnchor),
            nextMonthButton.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor, constant: -33),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 30),
            nextMonthButton.heightAnchor.constraint(equalToConstant: 30),
            
            daysStackView.topAnchor.constraint(equalTo: prevMonthButton.bottomAnchor, constant: 15),
            daysStackView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor, constant: 7),
            daysStackView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor, constant: -7),
            daysStackView.heightAnchor.constraint(equalToConstant: 20),
            
            calendarCollectionView.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 3),
            calendarCollectionView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor, constant: 7),
            calendarCollectionView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor, constant: -7),
            calendarCollectionView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor, constant: -10),
            
            editIconImageView.topAnchor.constraint(equalTo: calendarShadowContainer.bottomAnchor, constant: 10),
            editIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
            editIconImageView.widthAnchor.constraint(equalToConstant: 20),
            editIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            todoTitleLabel.centerYAnchor.constraint(equalTo: editIconImageView.centerYAnchor),
            todoTitleLabel.leadingAnchor.constraint(equalTo: editIconImageView.trailingAnchor, constant: 2),
            
            todoContainerView.topAnchor.constraint(equalTo: todoTitleLabel.bottomAnchor),
            todoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            todoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            todoContainerView.heightAnchor.constraint(equalToConstant: 170),
            
            cardsCollectionView.topAnchor.constraint(equalTo: todoContainerView.topAnchor),
            cardsCollectionView.leadingAnchor.constraint(equalTo: todoContainerView.leadingAnchor),
            cardsCollectionView.trailingAnchor.constraint(equalTo: todoContainerView.trailingAnchor),
            cardsCollectionView.bottomAnchor.constraint(equalTo: todoContainerView.bottomAnchor),
            
            pageControl.centerXAnchor.constraint(equalTo: todoContainerView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: todoContainerView.bottomAnchor),
            
            todoContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Коллекции
    private let calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private lazy var cardsCollectionView: UICollectionView = {
        let layout = StackCardFlowLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.showsHorizontalScrollIndicator = false
        collection.decelerationRate = .fast
        collection.isPagingEnabled = false
        collection.backgroundColor = .clear
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(TodoCardCell.self, forCellWithReuseIdentifier: "TodoCardCell")
        return collection
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPage = 0
        pc.pageIndicatorTintColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1.0)
        pc.currentPageIndicatorTintColor = .lightGray
        pc.hidesForSinglePage = true
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    private let todoContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let todoTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "To-do list for 05.12.2025"
        lbl.font = UIFont(name: "Poppins-Regular", size: 20)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let editIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Edit")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let scheduleLabel: UILabel = {
        let label = UILabel()
        label.text = "Schedule"
        label.font = UIFont(name: "Poppins-Regular", size: 24)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let profileButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 29
        button.clipsToBounds = true
        if let defaultAvatar = UIImage(named: "Default_person") {
            button.setImage(defaultAvatar, for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFill
        button.tintColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let addGoalButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1.0)
        button.layer.cornerRadius = 29
        button.clipsToBounds = true
        if let plusImage = UIImage(named: "PLUS") {
            button.setImage(plusImage, for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let calendarShadowContainer: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 6
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    
    private let calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let calendarIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "calendar")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let calendarTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-Medium", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .medium)
        label.text = "Calendar"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let prevMonthButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        if let leftImg = UIImage(named: "Arrow_left") {
            button.setImage(leftImg, for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nextMonthButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        if let rightImg = UIImage(named: "Arrow_right") {
            button.setImage(rightImg, for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Poppins-SemiBold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private func makeDayOval(_ text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        container.layer.cornerRadius = 11
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "Poppins-Regular", size: 17) ?? UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor(red: 27/255, green: 31/255, blue: 38/255, alpha: 0.72)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 20),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // Для календаря – число ячеек месяца; для карточек – (количество шагов + 1)
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == calendarCollectionView {
            return allMonths[currentMonthIndex].count
        } else {
            return currentSteps.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == calendarCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as? DayCell else {
                return UICollectionViewCell()
            }
            let day = allMonths[currentMonthIndex][indexPath.item]
            let isSelected = (indexPath == selectedIndexPath)
            cell.configure(day: day,
                           isSelected: isSelected,
                           stepsByDate: stepsByDate,
                           year: currentYear,
                           monthIndex: currentMonthIndex)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodoCardCell", for: indexPath) as? TodoCardCell else {
                return UICollectionViewCell()
            }
            
            if indexPath.item == currentSteps.count {
                cell.configureCard(index: -1, dateString: selectedDayString)
                cell.cardIndex = -1
            } else {
                cell.configureCard(index: indexPath.item, dateString: selectedDayString)
                cell.cardIndex = indexPath.item
                let step = currentSteps[indexPath.item]
                cell.updateWith(step: step)
            }
            return cell
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == cardsCollectionView {
            let page = Int(scrollView.contentOffset.x / scrollView.bounds.width + 0.5)
            pageControl.currentPage = page
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == calendarCollectionView {
            guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
                return CGSize(width: 50, height: 57)
            }
            let columns: CGFloat = 7
            let totalWidth = collectionView.bounds.width
            let totalSpacing = flowLayout.minimumInteritemSpacing * (columns - 1)
            let itemWidth = (totalWidth - totalSpacing) / columns
            let itemHeight: CGFloat = 57
            return CGSize(width: itemWidth, height: itemHeight)
        } else {
            if let layout = collectionViewLayout as? StackCardFlowLayout {
                return layout.itemSize
            }
            return CGSize(width: 300, height: 150)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == calendarCollectionView {
            return .zero
        } else {
            if let layout = collectionViewLayout as? StackCardFlowLayout {
                return layout.sectionInset
            }
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == calendarCollectionView {
            let day = allMonths[currentMonthIndex][indexPath.item]
            
            if indexPath == selectedIndexPath {
                selectedIndexPath = nil
                collectionView.reloadItems(at: [indexPath])
                todoContainerView.isHidden = true
                todoTitleLabel.isHidden = true
                editIconImageView.isHidden = true
                selectedDayString = nil
                currentSteps = []
                cardsCollectionView.reloadData()
                pageControl.numberOfPages = 0
                return
            }
            
            let old = selectedIndexPath
            selectedIndexPath = indexPath
            var toReload: [IndexPath] = [indexPath]
            if let oldPath = old {
                toReload.append(oldPath)
            }
            collectionView.reloadItems(at: toReload)
            
            if let dayNumber = day {
                let dateString = formatDate(dayNumber: dayNumber, monthIndex: currentMonthIndex)
                todoTitleLabel.text = "To-do list for \(dateString)"
                selectedDayString = dateString
                todoTitleLabel.isHidden = false
                editIconImageView.isHidden = false
                todoContainerView.isHidden = false
                
                if let realDate = makeRealDate(dayNumber: dayNumber, monthIndex: currentMonthIndex, year: currentYear) {
                    let dateOnly = stripTime(from: realDate)
                    currentSteps = stepsByDate[dateOnly] ?? []
                } else {
                    currentSteps = []
                }
                cardsCollectionView.reloadData()
                pageControl.currentPage = 0
                pageControl.numberOfPages = currentSteps.count + 1
                
                updateTodoTitleLabel()
                
                if !currentSteps.isEmpty {
                    let firstIndexPath = IndexPath(item: 0, section: 0)
                    cardsCollectionView.scrollToItem(at: firstIndexPath, at: .left, animated: true)
                }
            } else {
                selectedDayString = nil
                todoTitleLabel.isHidden = true
                editIconImageView.isHidden = true
                todoContainerView.isHidden = true
                currentSteps = []
                cardsCollectionView.reloadData()
                pageControl.numberOfPages = 0
                
                updateTodoTitleLabel()
            }
            
        } else if collectionView == cardsCollectionView {
            if indexPath.item == currentSteps.count {
                let addStepVC = AddStepViewController()
                if let goals = preloadedGoalsWithSteps {
                        addStepVC.availableGoals = goals
                    }
                if let selectedDateString = selectedDayString {
                        addStepVC.initialSelectedDate = selectedDateString
                    }
                if let sheet = addStepVC.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                }
                addStepVC.modalPresentationStyle = .automatic
                present(addStepVC, animated: true, completion: nil)
            } else {
                print("Selected task card at index \(indexPath.item)")
            }
        }
    }

    
    private func formatDate(dayNumber: Int, monthIndex: Int) -> String {
        let dayStr = dayNumber < 10 ? "0\(dayNumber)" : "\(dayNumber)"
        let monthNum = monthIndex + 1
        let monthStr = monthNum < 10 ? "0\(monthNum)" : "\(monthNum)"
        return "\(dayStr).\(monthStr).\(currentYear)"
    }
    
    private func makeRealDate(dayNumber: Int, monthIndex: Int, year: Int) -> Date? {
        var comps = DateComponents()
        comps.year = year
        comps.month = monthIndex + 1
        comps.day = dayNumber
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: comps)
    }
}

// MARK: - DayCell
class DayCell: UICollectionViewCell {
    
    private let dayLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .gray
        lbl.font = UIFont(name: "Poppins-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .regular)
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private var leftConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var centerXConstraint: NSLayoutConstraint?
    private var centerYConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.addSubview(dayLabel)
        
        leftConstraint = dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
        bottomConstraint = dayLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        centerXConstraint = dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        centerYConstraint = dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        
        leftConstraint?.isActive = true
        bottomConstraint?.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(day: Int?,
                   isSelected: Bool,
                   stepsByDate: [Date: [Step]],
                   year: Int,
                   monthIndex: Int) {
        contentView.viewWithTag(999)?.removeFromSuperview()
        
        let baseLightColor = UIColor(red: 220/255, green: 225/255, blue: 210/255, alpha: 1.0)
        
        if let dayNumber = day {
            dayLabel.text = "\(dayNumber)"
            contentView.backgroundColor = baseLightColor
            dayLabel.textColor = .gray
        } else {
            dayLabel.text = ""
            contentView.backgroundColor = .clear
        }
        
        if isSelected {
            leftConstraint?.isActive = false
            bottomConstraint?.isActive = false
            centerXConstraint?.isActive = true
            centerYConstraint?.isActive = true
            dayLabel.font = UIFont(name: "Poppins-Regular", size: 26)
            dayLabel.textAlignment = .center
        } else {
            centerXConstraint?.isActive = false
            centerYConstraint?.isActive = false
            leftConstraint?.isActive = true
            bottomConstraint?.isActive = true
            dayLabel.font = UIFont(name: "Poppins-Regular", size: 18)
            dayLabel.textAlignment = .left
        }
        
        if let dayNumber = day {
            let comps = DateComponents(year: year, month: monthIndex + 1, day: dayNumber)
            let cal = Calendar(identifier: .gregorian)
            if let date = cal.date(from: comps) {
                let dateOnly = {
                    let components = cal.dateComponents([.year, .month, .day], from: date)
                    return cal.date(from: components) ?? date
                }()
                if let stepsForDay = stepsByDate[dateOnly], !stepsForDay.isEmpty {
                    // Берём все цвета
                    let allColors = stepsForDay.map { $0.color }

                    // Делаем Set, чтобы убрать дубликаты
                    let uniqueColors = Set(allColors)

                    // Сортируем Set по строке, чтобы каждый раз был одинаковый порядок
                    let sortedColors = uniqueColors.sorted()  // сортируем по алфавиту

                    // Преобразуем в UIColor
                    let uiColors = sortedColors.compactMap { UIColor(hex: $0) }

                    // Рисуем сегменты
                    addColorSegments(colors: uiColors)
                    dayLabel.textColor = UIColor(red: 123/255, green: 114/255, blue: 114/255, alpha: 1.0)
                }
            }
        }
    }
    
    private func addColorSegments(colors: [UIColor]) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.tag = 999
        
        for color in colors {
            let colorView = UIView()
            colorView.backgroundColor = color
            stackView.addArrangedSubview(colorView)
        }
        
        contentView.addSubview(stackView)
        contentView.sendSubviewToBack(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - TodoCardCell
class TodoCardCell: UICollectionViewCell {
    
    var cardIndex: Int?
    var step: Step?

    private let shadowView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.3
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let blockContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let clipboardCircleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 203/255, green: 207/255, blue: 194/255, alpha: 1.0)
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let clipboardImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "Clipboard")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let goalLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "Poppins-Medium", size: 18)
        lbl.textColor = .black
        lbl.numberOfLines = 2
        lbl.text = "Goal:..."
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let stepLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "Poppins-Medium", size: 18)
        lbl.textColor = .black
        lbl.numberOfLines = 2
        lbl.text = "Step:..."
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "Poppins-Light", size: 16) ?? UIFont.systemFont(ofSize: 14, weight: .regular)
        lbl.textColor = .black
        lbl.text = "Completed"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let checkBoxSquareView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
        v.layer.cornerRadius = 3
        v.clipsToBounds = true
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.black.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let greenDotView: UIView = {
        let dot = UIView()
        dot.backgroundColor = UIColor(red: 0x34/255, green: 0xA0/255, blue: 0x3B/255, alpha: 1.0)
        dot.layer.cornerRadius = 4
        dot.clipsToBounds = true
        dot.isHidden = true
        dot.translatesAutoresizingMaskIntoConstraints = false
        return dot
    }()
    
    private var isGreenDotShown = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .clear
        contentView.addSubview(shadowView)
        shadowView.addSubview(blockContainerView)
        
        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            blockContainerView.topAnchor.constraint(equalTo: shadowView.topAnchor, constant: 5),
            blockContainerView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor, constant: 12),
            blockContainerView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor, constant: -12),
            blockContainerView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor, constant: -22)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleGreenDot))
        checkBoxSquareView.addGestureRecognizer(tapGesture)
        
        setupContextMenuInteraction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCard(index: Int, dateString: String?) {
        for subview in blockContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        if index == -1 {
            setupAddStepCard()
        } else {
            setupFirstCard()
        }
    }
    
    private func setupFirstCard() {
        blockContainerView.addSubview(clipboardCircleView)
        clipboardCircleView.addSubview(clipboardImageView)
        blockContainerView.addSubview(goalLabel)
        blockContainerView.addSubview(stepLabel)
        blockContainerView.addSubview(statusLabel)
        blockContainerView.addSubview(checkBoxSquareView)
        checkBoxSquareView.addSubview(greenDotView)
        
        NSLayoutConstraint.activate([
            clipboardCircleView.topAnchor.constraint(equalTo: blockContainerView.topAnchor, constant: 30),
            clipboardCircleView.leadingAnchor.constraint(equalTo: blockContainerView.leadingAnchor, constant: 10),
            clipboardCircleView.widthAnchor.constraint(equalToConstant: 40),
            clipboardCircleView.heightAnchor.constraint(equalToConstant: 40),
            
            clipboardImageView.centerXAnchor.constraint(equalTo: clipboardCircleView.centerXAnchor),
            clipboardImageView.centerYAnchor.constraint(equalTo: clipboardCircleView.centerYAnchor),
            clipboardImageView.widthAnchor.constraint(equalToConstant: 30),
            clipboardImageView.heightAnchor.constraint(equalToConstant: 30),
            
            goalLabel.topAnchor.constraint(equalTo: blockContainerView.topAnchor, constant: 5),
            goalLabel.leadingAnchor.constraint(equalTo: blockContainerView.leadingAnchor, constant: 60),
            goalLabel.trailingAnchor.constraint(lessThanOrEqualTo: blockContainerView.trailingAnchor, constant: -15),
            
            stepLabel.topAnchor.constraint(equalTo: goalLabel.bottomAnchor, constant: 1),
            stepLabel.leadingAnchor.constraint(equalTo: goalLabel.leadingAnchor),
            stepLabel.trailingAnchor.constraint(lessThanOrEqualTo: blockContainerView.trailingAnchor, constant: -15),
            
            checkBoxSquareView.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 6),
            checkBoxSquareView.leadingAnchor.constraint(equalTo: stepLabel.leadingAnchor),
            checkBoxSquareView.widthAnchor.constraint(equalToConstant: 20),
            checkBoxSquareView.heightAnchor.constraint(equalToConstant: 20),
            
            statusLabel.centerYAnchor.constraint(equalTo: checkBoxSquareView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: checkBoxSquareView.trailingAnchor, constant: 5),
            
            greenDotView.centerXAnchor.constraint(equalTo: checkBoxSquareView.centerXAnchor),
            greenDotView.centerYAnchor.constraint(equalTo: checkBoxSquareView.centerYAnchor),
            greenDotView.widthAnchor.constraint(equalToConstant: 8),
            greenDotView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    func updateWith(step: Step) {
        self.step = step
        statusLabel.text = "Completed"
        goalLabel.text = "Goal: \(step.goal_name)"
        stepLabel.text = "Step: \(step.description)"
        if let color = UIColor(hex: step.color) {
            clipboardCircleView.backgroundColor = color
        }
        if step.status == "done" {
            greenDotView.isHidden = false
            isGreenDotShown = true
        } else {
            greenDotView.isHidden = true
            isGreenDotShown = false
        }
    }
    
    private func setupAddStepCard() {
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "Poppins-Medium", size: 20) ?? UIFont.systemFont(ofSize: 22, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.text = "Ready to add something new?"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.font = UIFont(name: "Poppins-Medium", size: 20) ?? UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = UIColor(red: 245/255, green: 123/255, blue: 93/255, alpha: 1.0)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "Tap and Go!"
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        blockContainerView.addSubview(titleLabel)
        blockContainerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: blockContainerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: blockContainerView.centerYAnchor, constant: -15),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: blockContainerView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blockContainerView.trailingAnchor, constant: -10),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.centerXAnchor.constraint(equalTo: blockContainerView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: blockContainerView.leadingAnchor, constant: 10),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: blockContainerView.trailingAnchor, constant: -10)
        ])
    }
    
/// Обновление статуса шага
    @objc private func toggleGreenDot() {
        guard let step = self.step else { return }
        
        // Извлекаем токен из Keychain
        guard let currentUserToken = KeychainManager.loadString(key: "accessToken") else {
            print("Не удалось получить токен пользователя")
            return
        }
        
        // Определяем новый статус: если "done" -> "planned", иначе -> "done"
        let newStatus = step.status == "done" ? "planned" : "done"
        
        // Вызываем updateStep; если сервер вернет ошибку с "Token has expired",
        // алерт будет показан, и дальнейшие действия не выполнятся.
        updateStep(token: currentUserToken,
                   stepId: step.id,
                   title: nil,
                   description: nil,
                   status: newStatus,
                   dateString: nil) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    if "\(error)".contains("Token has expired") {
                        self.parentViewController()?.showTokenExpiredAlert()
                    } else {
                        print("Ошибка обновления шага: \(error)")
                    }
                case .success(let message):
                    print("Шаг обновлен: \(message)")
                    // После успешного обновления шага запрашиваем обновленные данные по цели и шагу
                    getGoalStepDetail(token: currentUserToken,
                                      goalId: step.goal_id,
                                      stepId: step.id) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .failure(let error):
                                if "\(error)".contains("Token has expired") {
                                    self.parentViewController()?.showTokenExpiredAlert()
                                } else {
                                    print("Ошибка получения данных цели: \(error)")
                                }
                            case .success(let (updatedGoal, updatedStep)):
                                // Обновляем локальную модель шага
                                self.step = updatedStep
                                // Обновляем UI ячейки: отображаем зеленый кружок если статус "done"
                                self.isGreenDotShown = (updatedStep.status == "done")
                                self.greenDotView.isHidden = !self.isGreenDotShown
                                // Обновляем глобальный массив preloadedGoalsWithSteps:
                                if var goals = (self.parentViewController() as? MainViewController)?.preloadedGoalsWithSteps {
                                    if let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
                                        goals[index] = updatedGoal
                                        (self.parentViewController() as? MainViewController)?.preloadedGoalsWithSteps = goals
                                        }
                                    }
                                // Отправляем уведомление для обновления глобального состояния
                                NotificationCenter.default.post(name: NSNotification.Name("StepUpdated"), object: (updatedGoal, updatedStep))
                            }
                        }
                    }
                }
            }
        }
    }



    private func setupContextMenuInteraction() {
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            blockContainerView.addInteraction(interaction)
        }
    }
}

@available(iOS 13.0, *)
extension TodoCardCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint)
    -> UIContextMenuConfiguration? {
        if let idx = self.cardIndex, idx == -1 {
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let detailAction = UIAction(
                title: "Detail",
                image: UIImage(systemName: "info.circle")
            ) { _ in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                print("Detail tapped for cardIndex =", self.cardIndex ?? -1)
                NotificationCenter.default.post(name: Notification.Name("DetailTodoCard"), object: self.cardIndex)
            }
            let editAction = UIAction(
                title: "Edit the step",
                image: UIImage(systemName: "pencil")
            ) { _ in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                print("Edit tapped for cardIndex =", self.cardIndex ?? -1)
                NotificationCenter.default.post(name: Notification.Name("EditTodoCard"), object: self.cardIndex)
            }
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // Проверяем, что у нас есть данные шага
                guard let step = self.step else { return }
                // Извлекаем access token из Keychain
                guard let currentUserToken = KeychainManager.loadString(key: "accessToken") else {
                    print("Не удалось получить токен пользователя")
                    return
                }
                
                // Вызываем маршрут удаления шага
                deleteStep(token: currentUserToken, stepId: step.id) { deleteResult in
                    DispatchQueue.main.async {
                        switch deleteResult {
                        case .failure(let error):
                            // Если токен просрочен, показываем alert и не вносим изменений
                            if "\(error)".contains("Token has expired") {
                                self.parentViewController()?.showTokenExpiredAlert()
                            } else {
                                print("Ошибка удаления шага: \(error)")
                            }
                        case .success(let message):
                            print("Шаг успешно удалён: \(message)")
                            // После удаления шага вызываем маршрут для обновления информации по цели
                            getGoalInfo(token: currentUserToken, goalId: step.goal_id) { infoResult in
                                DispatchQueue.main.async {
                                    switch infoResult {
                                    case .failure(let error):
                                        if "\(error)".contains("Token has expired") {
                                            self.parentViewController()?.showTokenExpiredAlert()
                                        } else {
                                            print("Ошибка обновления информации по цели: \(error)")
                                        }
                                    case .success(let updatedGoal):
                                        // Отправляем уведомление для обновления глобального UI по цели
                                        NotificationCenter.default.post(name: NSNotification.Name("GoalInfoUpdated"), object: updatedGoal)
                                        
                                        // Обновляем локальный массив currentSteps в MainViewController
                                        if let mainVC = self.parentViewController() as? MainViewController {
                                            mainVC.removeStep(withID: step.id)
                                            // Обновляем календарь: удаляем шаг из словаря и перезагружаем DayCell с индикаторами
                                            if let stepDate = step.dateObject {
                                                mainVC.removeStepFromCalendar(withID: step.id, stepDate: stepDate)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return UIMenu(title: "", children: [detailAction, editAction, deleteAction])
        }
    }
}
