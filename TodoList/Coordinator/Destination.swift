//
//  Destination.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation
import SwiftData

enum Destination: Hashable {
    // MARK: - Task
    case taskDetail(PersistentIdentifier)
    case createTask
    case createCategory

    // MARK: - Category
    case categoryFilter(PersistentIdentifier)

    // MARK: - Tabs (untuk deep link / programmatic navigation)
    case dailyTask
    case graph
    case profile
    case editProfile

    // MARK: - Search
    case search
}
