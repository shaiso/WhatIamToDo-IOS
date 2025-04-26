//
//  Routes.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 02.04.2025.
//

import Foundation

/// Базовый URL  на сервер
let baseUrl = "https://whatiamtodo.ru"


/// Для случая, когда сервер возвращает { "message": "..." }
struct SimpleMessageResponse: Codable {
    let message: String
}

/// Для логина (сервер возвращает message + access_token)
struct LoginResponse: Decodable {
    let message: String
    let access_token: String?
}

/// Ошибки при сетевых запросах
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case serverError(String) // чтобы хранить message сервера
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .noData:
            return "Нет данных от сервера"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .serverError(let message):
            return message
        }
    }
}

/// Вспомогательная структура для создания шага (при createGoal)
struct StepForCreation {
    let title: String
    let description: String?
    let dateString: String?  // "YYYY-MM-DD"
}

// MARK: - Auth Routes

// POST /auth/register
func registerUser(email: String,
                  password: String,
                  name: String,
                  completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/auth/register") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "email": email,
        "password": password,
        "name": name
    ]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// POST /auth/login
func loginUser(email: String,
               password: String,
               completion: @escaping (Result<(String, String?), Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/auth/login") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["email": email, "password": password]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(LoginResponse.self, from: data)
            completion(.success((parsed.message, parsed.access_token)))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// POST /auth/recover-password
func recoverPassword(email: String,
                     completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/auth/recover-password") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["email": email]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// POST /auth/reset-password
func resetPassword(token: String,
                   newPassword: String,
                   completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/auth/reset-password") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["token": token, "new_password": newPassword]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// GET /auth/protected
func checkProtected(token: String,
                    completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/auth/protected") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// MARK: - Goals Routes

// POST /api/goals  (Создание цели + шаги)
func createGoal(token: String,
                title: String,
                description: String,
                steps: [StepForCreation],
                completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let stepsData = steps.map { step in
        [
            "title": step.title,
            "description": step.description ?? "",
            "date": step.dateString ?? ""
        ]
    }
    let body: [String: Any] = [
        "title": title,
        "description": description,
        "steps": stepsData
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// GET /api/goals
func getGoals(token: String,
              completion: @escaping (Result<[Goal], Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let goals = try JSONDecoder().decode([Goal].self, from: data)
            completion(.success(goals))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// GET /api/goals/<goal_id>
func getGoalDetail(token: String,
                   goalId: Int,
                   completion: @escaping (Result<Goal, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let goal = try JSONDecoder().decode(Goal.self, from: data)
            completion(.success(goal))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// GET /api/goals/<goal_id>/steps/<step_id>
func getGoalStepDetail(token: String,
                       goalId: Int,
                       stepId: Int,
                       completion: @escaping (Result<(Goal, Step), Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)/steps/\(stepId)") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            // Декодируем полученный JSON как словарь
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NetworkError.noData
            }
            
            // Декодируем цель из всего объекта
            let goalData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            let goal = try JSONDecoder().decode(Goal.self, from: goalData)
            
            // Извлекаем из объекта значение для ключа "step"
            guard let stepsArray = jsonObject["steps"] as? [[String: Any]], let stepJSON = stepsArray.first else {
                   throw NetworkError.noData
               }
            let stepData = try JSONSerialization.data(withJSONObject: stepJSON, options: [])
            let step = try JSONDecoder().decode(Step.self, from: stepData)
            
            completion(.success((goal, step)))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// GET /api/goals/<goal_id>/info
func getGoalInfo(token: String,
                 goalId: Int,
                 completion: @escaping (Result<Goal, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)/info") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let goal = try JSONDecoder().decode(Goal.self, from: data)
            completion(.success(goal))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// GET /api/goals/with-steps
func getGoalsWithSteps(token: String,
                       completion: @escaping (Result<[Goal], Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/with-steps") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let goals = try JSONDecoder().decode([Goal].self, from: data)
            completion(.success(goals))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// PATCH (или PUT) /api/goals/<goal_id>
func updateGoal(token: String,
                goalId: Int,
                title: String?,
                description: String?,
                color: String?,
                completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH" // или "PUT"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    var body: [String: Any] = [:]
    if let t = title { body["title"] = t }
    if let d = description { body["description"] = d }
    if let c = color { body["color"] = c }
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// DELETE /api/goals/<goal_id>
func deleteGoal(token: String,
                goalId: Int,
                completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// MARK: - Steps

// POST /api/goals/<goal_id>/steps
func addStepToGoal(token: String,
                   goalId: Int,
                   stepTitle: String,
                   stepDescription: String?,
                   stepDate: String?,
                   completion: @escaping (Result<Int, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)/steps") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    var body: [String: Any] = ["title": stepTitle]
    if let desc = stepDescription { body["description"] = desc }
    if let date = stepDate { body["date"] = date }
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data,
              let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        
        // ПАРСИМ JSON ручным способом, чтобы вытащить step_id
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let stepId = jsonObject["step_id"] as? Int else {
                completion(.failure(NetworkError.noData))
                return
            }
            completion(.success(stepId))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// PATCH /api/steps/<step_id>
func updateStep(token: String,
                stepId: Int,
                title: String?,
                description: String?,
                status: String?,
                dateString: String?,
                completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/steps/\(stepId)") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "PATCH" // или PUT
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    var body: [String: Any] = [:]
    if let t = title { body["title"] = t }
    if let desc = description { body["description"] = desc }
    if let s = status { body["status"] = s }
    if let d = dateString { body["date"] = d }
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// DELETE /api/steps/<step_id>
func deleteStep(token: String,
                stepId: Int,
                completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/steps/\(stepId)") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            let parsed = try JSONDecoder().decode(SimpleMessageResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// POST /api/steps/bulk
func getStepsBulk(token: String,
                  stepIds: [Int],
                  completion: @escaping (Result<[Step], Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/steps/bulk") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = ["step_ids": stepIds]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        
        struct StepsBulkResponse: Decodable {
            let steps: [Step]
        }
        do {
            let parsed = try JSONDecoder().decode(StepsBulkResponse.self, from: data)
            completion(.success(parsed.steps))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// MARK: - AI Routes

// POST /api/ai/reschedule
func rescheduleTasks(token: String,
                     problemText: String,
                     completion: @escaping (Result<(String, [Int]), Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/ai/reschedule") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["problem": problemText]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            // Пытаемся декодировать сообщение об ошибке
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            // Декодируем ответ сервера в RescheduleResponse
            let parsed = try JSONDecoder().decode(RescheduleResponse.self, from: data)
            // Извлекаем список ID обновлённых шагов
            let stepIds = parsed.updated_tasks.map { $0.task_id }
            // Возвращаем (message, [stepIds]) в случае успеха
            completion(.success((parsed.message, stepIds)))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}


// POST /api/ai/generate-goal
func generateGoalAI(token: String,
                    userPrompt: String,
                    completion: @escaping (Result<Int, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/ai/generate-goal") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["user_prompt": userPrompt]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { completion(.failure(error)); return }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        do {
            // Сервер возвращает JSON: { "message": "...", "goal_id": 123 }
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let goalId = json?["goal_id"] as? Int else {
                completion(.failure(NetworkError.noData))
                return
            }
            completion(.success(goalId))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

// MARK: - Bulk Creation

func addStepsBulk(token: String,
                  goalId: Int,
                  steps: [StepForBulk],
                  completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "\(baseUrl)/api/goals/\(goalId)/steps/bulk") else {
        completion(.failure(NetworkError.invalidURL))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Тело запроса – {"steps": [...]}
    let body: [String: Any] = [
        "steps": steps.map { ["description": $0.description, "date": $0.date] }
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    } catch {
        completion(.failure(error))
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        // Если статус-код не 2xx, пытаемся вытащить ошибку из ответа
        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = try? JSONDecoder().decode(SimpleMessageResponse.self, from: data) {
                completion(.failure(NetworkError.serverError(msg.message)))
            } else {
                completion(.failure(NetworkError.serverError("Status \(httpResponse.statusCode)")))
            }
            return
        }
        
        // Если всё ок, декодируем ответ {"message": "...", "created_steps": [...] }
        struct BulkResponse: Decodable {
            let message: String
        }
        do {
            let parsed = try JSONDecoder().decode(BulkResponse.self, from: data)
            completion(.success(parsed.message))
        } catch {
            completion(.failure(error))
        }
        
    }.resume()
}

