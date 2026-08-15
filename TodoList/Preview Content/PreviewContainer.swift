import SwiftData
import SwiftUI

struct PreviewContainer {
    let container: ModelContainer

    init() {
        let schema = Schema([TodoItem.self, TodoCategory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
            seedData()
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }

    @MainActor
    private func seedData() {
        let context = container.mainContext

        // Categories
        let work = TodoCategory(name: "Work", colorHex: "#F8CD7A")
        let personal = TodoCategory(name: "Personal", colorHex: "#9B60F7")
        let health = TodoCategory(name: "Health", colorHex: "#59FF8C")

        [work, personal, health].forEach { context.insert($0) }

        // Todos
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let todos: [TodoItem] = [
            TodoItem(title: "Design sprint review", subtitle: "Prepare presentation slides", dueDate: today, priority: 2, category: work),
            TodoItem(title: "Buy groceries", subtitle: "Milk, eggs, bread", dueDate: today, priority: 1, category: personal),
            TodoItem(title: "Morning workout", subtitle: "30 min cardio", dueDate: today, priority: 1, category: health),
            TodoItem(title: "Team standup", subtitle: "Daily sync meeting", dueDate: tomorrow, priority: 0, category: work),
            TodoItem(title: "Read book chapter", subtitle: "Swift concurrency ch.5", dueDate: tomorrow, priority: 0, category: personal),
            TodoItem(title: "Submit report", subtitle: "Monthly metrics", isCompleted: true, dueDate: yesterday, priority: 2, category: work),
            TodoItem(title: "Dentist appointment", subtitle: "Routine checkup", isCompleted: true, dueDate: yesterday, priority: 1, category: health),
        ]

        todos.forEach { context.insert($0) }
    }
}
