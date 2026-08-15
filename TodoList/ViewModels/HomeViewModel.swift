import Foundation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    private let repository: TodoRepositoryProtocol

    var allTodos: [TodoItem] = []
    var categories: [TodoCategory] = []
    var selectedCategory: TodoCategory?
    var searchText: String = ""
    var isLoading: Bool = false
    var error: String?

    init(repository: TodoRepositoryProtocol? = nil) {
        self.repository = repository ?? DIContainer.shared.resolve(TodoRepositoryProtocol.self)
    }

    // MARK: - Grouped Tasks

    var todayTasks: [TodoItem] {
        filteredTodos.filter { $0.isToday && !$0.isCompleted }
    }

    var futureTasks: [TodoItem] {
        filteredTodos.filter { $0.isFuture && !$0.isCompleted }
    }

    var previousTasks: [TodoItem] {
        filteredTodos.filter { $0.isPrevious || $0.isCompleted }
    }

    var hasNoTasks: Bool {
        allTodos.isEmpty
    }

    private var filteredTodos: [TodoItem] {
        var result = allTodos

        if let selectedCategory {
            result = result.filter { $0.category?.id == selectedCategory.id }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    // MARK: - Actions

    func loadData() async {
        isLoading = true
        error = nil
        do {
            allTodos = try await repository.fetchAllTodos()
            categories = try await repository.fetchAllCategories()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleComplete(_ item: TodoItem) async {
        do {
            try await repository.toggleComplete(item)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteTodo(_ item: TodoItem) async {
        do {
            try await repository.deleteTodo(item)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectCategory(_ category: TodoCategory?) {
        if selectedCategory?.id == category?.id {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
}
