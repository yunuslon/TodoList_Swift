//
//  AppRouter.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

@Observable
@MainActor
final class AppRouter {
    var path = NavigationPath()
    var presentedSheet: Destination?
    var presentedFullScreen: Destination?

    // MARK: - Push
    func navigate(to destination: Destination) {
        path.append(destination)
    }

    // MARK: - Pop
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - Pop to Root
    func popToRoot() {
        path = NavigationPath()
    }

    // MARK: - Sheet
    func present(_ destination: Destination) {
        presentedSheet = destination
    }

    // MARK: - Full Screen Cover
    func presentFullScreen(_ destination: Destination) {
        presentedFullScreen = destination
    }

    // MARK: - Dismiss
    func dismissSheet() {
        presentedSheet = nil
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}
