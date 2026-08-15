//
//  TodoRepositoryProtocal.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation


import SwiftData

protocol TodoRepositoryProtocol {
    // MARK: - Todos
    func fetchAllTodos() async throws -> [TodoItem]
    func fetchTodos(for category: TodoCategory?) async throws -> [TodoItem]
    func addTodo(_ item: TodoItem) async throws
    func updateTodo(_ item: TodoItem) async throws
    func deleteTodo(_ item: TodoItem) async throws
    func toggleComplete(_ item: TodoItem) async throws

    // MARK: - Categories
    func fetchAllCategories() async throws -> [TodoCategory]
    func addCategory(_ category: TodoCategory) async throws
    func deleteCategory(_ category: TodoCategory) async throws

    // MARK: - Lookup by ID
    func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem?
    func fetchCategory(by id: PersistentIdentifier) async throws -> TodoCategory?
}

//
//    Penjelasan:
//    - protocol = interface di TypeScript
//    - Semua method async throws — konsisten walaupun mock tidak butuh async
//    - PersistentIdentifier — unique ID dari SwiftData (seperti primary key), dipakai di Destination enum nanti
//    - Ini layer yang bisa di-mock untuk testing dan preview
//    Analog TypeScript:
//    interface ITodoRepository {
//        fetchAllTodos(): Promise<TodoItem[]>
//        addTodo(item: TodoItem): Promise<void>
//        deleteTodo(item: TodoItem): Promise<void>
//        // ...
//    }
