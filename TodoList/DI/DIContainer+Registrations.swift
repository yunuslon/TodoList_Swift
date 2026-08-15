//
//  DIContainer+Registrations.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation
import SwiftData

extension DIContainer {
    /// Composition Root — dipanggil SEKALI di TodoListApp.init
    func registerAll(modelContainer: ModelContainer) {
        // MARK: - Singletons
        registerSingleton(AppRouter.self) {
            AppRouter()
        }

        // MARK: - Transient
        register(TodoRepositoryProtocol.self) {
            TodoRepository(modelContainer: modelContainer)
        }
    }

    /// Untuk SwiftUI Preview — pakai mock
    func registerForPreviews() {
        registerSingleton(AppRouter.self) {
            AppRouter()
        }

        register(TodoRepositoryProtocol.self) {
            MockTodoRepository()
        }
    }
}
