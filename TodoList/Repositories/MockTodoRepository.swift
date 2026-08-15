//
//  MockTodoRepository.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation
import SwiftData

final class MockTodoRepository: TodoRepositoryProtocol {
    var todos: [TodoItem] = []
    var categories: [TodoCategory] = []

    init() {
        seedData()
    }

    private func seedData() {
        let work = TodoCategory(name: "Work", colorHex: "#F8CD7A")
        let personal = TodoCategory(name: "Personal", colorHex: "#9B60F7")
        let health = TodoCategory(name: "Health", colorHex: "#59FF8C")
        categories = [work, personal, health]

        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        todos = [
            TodoItem(title: "Design sprint review", subtitle: "Prepare presentation slides", dueDate: today, priority: 2, category: work),
            TodoItem(title: "Buy groceries", subtitle: "Milk, eggs, bread", dueDate: today, priority: 1, category: personal),
            TodoItem(title: "Morning workout", subtitle: "30 min cardio", dueDate: today, priority: 1, category: health),
            TodoItem(title: "Team standup", subtitle: "Daily sync meeting", dueDate: tomorrow, priority: 0, category: work),
            TodoItem(title: "Read book chapter", subtitle: "Swift concurrency ch.5", dueDate: tomorrow, priority: 0, category: personal),
            TodoItem(title: "Submit report", subtitle: "Monthly metrics", isCompleted: true, dueDate: yesterday, priority: 2, category: work),
            TodoItem(title: "Dentist appointment", subtitle: "Routine checkup", isCompleted: true, dueDate: yesterday, priority: 1, category: health),
        ]
    }

    // MARK: - Todos

    func fetchAllTodos() async throws -> [TodoItem] {
        todos
    }

    func fetchTodos(for category: TodoCategory?) async throws -> [TodoItem] {
        guard let category else { return todos }
        return todos.filter { $0.category?.name == category.name }
    }

    func addTodo(_ item: TodoItem) async throws {
        todos.append(item)
    }

    func updateTodo(_ item: TodoItem) async throws {
        // In-memory — object sudah mutated langsung
    }

    func deleteTodo(_ item: TodoItem) async throws {
        todos.removeAll { $0.id == item.id }
    }

    func toggleComplete(_ item: TodoItem) async throws {
        item.isCompleted.toggle()
    }

    // MARK: - Categories

    func fetchAllCategories() async throws -> [TodoCategory] {
        categories
    }

    func addCategory(_ category: TodoCategory) async throws {
        categories.append(category)
    }

    func deleteCategory(_ category: TodoCategory) async throws {
        categories.removeAll { $0.id == category.id }
    }

    // MARK: - Lookup (Mock tidak pakai PersistentIdentifier)

    func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem? {
        nil
    }

    func fetchCategory(by id: PersistentIdentifier) async throws -> TodoCategory? {
        nil
    }
}

//    Penjelasan:
//    - Class biasa (bukan @Model) yang conform protocol
//    - seedData() buat sample data langsung di memory
//    - Method-method tinggal operasi array biasa (.append, .removeAll, .filter)
//    - fetchTodo(by:) return nil — mock tidak generate PersistentIdentifier (itu hanya SwiftData yang buat)
//    - item.isCompleted.toggle() — bisa langsung mutate karena @Model class = reference type

