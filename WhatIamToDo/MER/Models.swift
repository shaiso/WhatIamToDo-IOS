//
//  Models.swift
//  WhatIamToDo
//
//  Created by Артур Керопьян on 02.04.2025.
//

import Foundation

// Модель цели, которая включает связанные шаги
struct Goal: Decodable {
    let id: Int
    let title: String
    let description: String
    let color: String
    let progress: Double
    let created_at: String
    let updated_at: String
    var steps: [Step]
    
    private enum CodingKeys: String, CodingKey {
         case id, title, description, color, progress, created_at, updated_at, steps
    }
    
    init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         id = try container.decode(Int.self, forKey: .id)
         title = try container.decode(String.self, forKey: .title)
         description = try container.decode(String.self, forKey: .description)
         color = try container.decode(String.self, forKey: .color)
         progress = try container.decode(Double.self, forKey: .progress)
         created_at = try container.decode(String.self, forKey: .created_at)
         updated_at = try container.decode(String.self, forKey: .updated_at)
         steps = try container.decodeIfPresent([Step].self, forKey: .steps) ?? []
    }
}


// Модель шага
struct Step: Decodable {
    let id: Int
    let goal_id: Int
    let goal_name: String
    let color: String
    let title: String
    let description: String
    let status: String  // "planned" / "done"
    let date: String
    let created_at: String
    let updated_at: String
}

struct RescheduleResponse: Decodable {
    let message: String
    let updated_tasks: [UpdatedTaskResponse]
}

struct UpdatedTaskResponse: Decodable {
    let task_id: Int
}

/// Модель для передачи шагов на сервер (без title)
struct StepForBulk: Encodable {
    let description: String
    let date: String
}
