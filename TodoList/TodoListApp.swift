//
//  TodoListApp.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI
import SwiftData

@main
struct TodoListApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([TodoItem.self, TodoCategory.self])
        let config = ModelConfiguration("Listodo", isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        DIContainer.shared.registerAll(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
