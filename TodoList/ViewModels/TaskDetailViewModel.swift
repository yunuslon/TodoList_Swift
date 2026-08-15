import Foundation
import SwiftData

@Observable
@MainActor
final class TaskDetailViewModel {
    private let repository: TodoRepositoryProtocol
    private let todoId: PersistentIdentifier

    var todo: TodoItem?
    var isLoading: Bool = false
    var showDeleteConfirmation: Bool = false
    var error: String?

    init(todoId: PersistentIdentifier, repository: TodoRepositoryProtocol? = nil) {
        self.todoId = todoId
        self.repository = repository ?? DIContainer.shared.resolve(TodoRepositoryProtocol.self)
    }

    func loadTodo() async {
        isLoading = true
        do {
            todo = try await repository.fetchTodo(by: todoId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleComplete() async {
        guard let todo else { return }
        do {
            try await repository.toggleComplete(todo)
            await loadTodo()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteTodo() async -> Bool {
        guard let todo else { return false }
        do {
            try await repository.deleteTodo(todo)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
