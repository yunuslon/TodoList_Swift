//
//  TodoItem.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var subtitle: String
    var isCompleted: Bool
    var dueDate: Date?
    var createdAt: Date
    var priority: Int   // 0=low, 1=medium, 2=high
    var category: TodoCategory?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        createdAt: Date = .now,
        priority: Int = 1,
        category: TodoCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.priority = priority
        self.category = category
    }
}

// MARK: - Priority Helper (DI LUAR @Model)

enum TaskPriority: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var colorHex: String {
        switch self {
        case .low: "#59FF8C"
        case .medium: "#F8CD7A"
        case .high: "#FF5959"
        }
    }
}

// MARK: - Computed Helpers

extension TodoItem {
    var taskPriority: TaskPriority {
        TaskPriority(rawValue: priority) ?? .medium
    }

    var isToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isFuture: Bool {
        guard let dueDate else { return false }
        return dueDate > .now && !isToday
    }

    var isPrevious: Bool {
        guard let dueDate else {
            return createdAt < Calendar.current.startOfDay(for: .now)
        }
        return dueDate < Calendar.current.startOfDay(for: .now)
    }

    var cardColorHex: String {
        if let category {
            return category.colorHex
        }
        return taskPriority.colorHex
    }
}

//    Penjelasan:
//    - @Model — macro SwiftData yang otomatis bikin class ini persistent (disimpan ke disk)
//    - final class — @Model WAJIB class, bukan struct (SwiftData requirement)
//    - priority: Int bukan enum — karena #Predicate limitation (lihat SPEC.md)
//    - TaskPriority di LUAR class — supaya bisa dipakai di UI tanpa concern SwiftData
//    - Computed isToday/isFuture/isPrevious — pakai extension Date dari Step 1
//    - guard let dueDate else { return false } — handle optional date safely
