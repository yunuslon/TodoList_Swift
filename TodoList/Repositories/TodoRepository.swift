//
//  TodoRepository.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation
import SwiftData

final class TodoRepository: TodoRepositoryProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    private var context: ModelContext {
        modelContainer.mainContext
    }

    // MARK: - Todos

    func fetchAllTodos() async throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        return try await MainActor.run {
            try context.fetch(descriptor)
        }
    }

    func fetchTodos(for category: TodoCategory?) async throws -> [TodoItem] {
        let all = try await fetchAllTodos()
        guard let category else { return all }
        return all.filter { $0.category?.id == category.id }
    }

    func addTodo(_ item: TodoItem) async throws {
        await MainActor.run {
            context.insert(item)
            try? context.save()
        }
    }

    func updateTodo(_ item: TodoItem) async throws {
        await MainActor.run {
            try? context.save()
        }
    }

    func deleteTodo(_ item: TodoItem) async throws {
        await MainActor.run {
            context.delete(item)
            try? context.save()
        }
    }

    func toggleComplete(_ item: TodoItem) async throws {
        await MainActor.run {
            item.isCompleted.toggle()
            try? context.save()
        }
    }

    // MARK: - Categories

    func fetchAllCategories() async throws -> [TodoCategory] {
        let descriptor = FetchDescriptor<TodoCategory>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try await MainActor.run {
            try context.fetch(descriptor)
        }
    }

    func addCategory(_ category: TodoCategory) async throws {
        await MainActor.run {
            context.insert(category)
            try? context.save()
        }
    }

    func deleteCategory(_ category: TodoCategory) async throws {
        await MainActor.run {
            context.delete(category)
            try? context.save()
        }
    }

    // MARK: - Lookup by ID

    func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem? {
        await MainActor.run {
            context.model(for: id) as? TodoItem
        }
    }

    func fetchCategory(by id: PersistentIdentifier) async throws -> TodoCategory? {
        await MainActor.run {
            context.model(for: id) as? TodoCategory
        }
    }
}

//
//    Penjelasan penting:
//    1. **`model
//    2. **`@
//    3. **`await
//    4. **
//    5. **`try
//    6. **`context
//    Analog TypeScript (TypeORM):
//    class
