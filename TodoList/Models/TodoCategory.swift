//
//  TodoCategory.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation
import SwiftData

@Model
final class TodoCategory {
    var id: UUID
    var name: String
    var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.category)
    var items: [TodoItem] = []

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

// MARK: - Predefined Colors

extension TodoCategory {
    static let predefinedColors: [(name: String, hex: String)] = [
        ("Work", "#F8CD7A"),
        ("Home", "#9B60F7"),
        ("Personal", "#5977FF"),
        ("Health", "#59FF8C"),
        ("Shopping", "#FF9B59"),
    ]
}

//
//    Penjelasan:
//    - @Relationship(deleteRule: .nullify, inverse: \TodoItem.category):
//    - deleteRule: .nullify — kalau category dihapus, TodoItem.category jadi nil (bukan ikut dihapus)
//    - inverse: \TodoItem.category — bilang ke SwiftData bahwa ini 2-arah relationship
//    - Analog: @OneToMany(() => TodoItem, item => item.category) di TypeORM
//    - var items: [TodoItem] = [] — default empty array
//    - predefinedColors — static data untuk seeding, bukan stored di DB
