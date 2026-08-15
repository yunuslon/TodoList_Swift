//
//  DIContainer.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation

final class DIContainer {
    static let shared = DIContainer()

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]

    private init() {}

    // MARK: - Register (Transient — instance baru setiap resolve)
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        singletons[key] = factory()
    }

    // MARK: - Register Singleton (1 instance selamanya)
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        singletons[key] = factory()
    }

    // MARK: - Resolve
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)

        // Cek singleton dulu
        if let instance = singletons[key] as? T {
            return instance
        }

        // Lalu cek factory (transient)
        guard let factory = factories[key], let instance = factory() as? T
        else {
            fatalError(
                "⚠️ DIContainer: No registration found for \(key). Did you forget to call registerAll()?"
            )
        }

        return instance
    }

    // MARK: - Reset (untuk testing)
    func reset() {
        factories.removeAll()
        singletons.removeAll()
    }
}
