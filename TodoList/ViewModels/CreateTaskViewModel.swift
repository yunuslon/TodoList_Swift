import Foundation
import SwiftData

@Observable
@MainActor
final class CreateTaskViewModel {
    private let repository: TodoRepositoryProtocol

    var title: String = ""
    var subtitle: String = ""
    var dueDate: Date = .now
    var hasDueDate: Bool = true
    var priority: Int = 1
    var selectedCategory: TodoCategory?
    var categories: [TodoCategory] = []
    var isSaving: Bool = false
    var error: String?

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(repository: TodoRepositoryProtocol? = nil) {
        self.repository = repository ?? DIContainer.shared.resolve(TodoRepositoryProtocol.self)
    }

    func loadCategories() async {
        do {
            categories = try await repository.fetchAllCategories()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func save() async -> Bool {
        guard canSave else { return false }

        isSaving = true
        let item = TodoItem(
            title: title.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            category: selectedCategory
        )

        do {
            try await repository.addTodo(item)
            isSaving = false
            return true
        } catch {
            self.error = error.localizedDescription
            isSaving = false
            return false
        }
    }
}
