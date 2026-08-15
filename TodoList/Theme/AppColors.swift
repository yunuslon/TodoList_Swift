//
//  AppColors.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

enum AppColors {
    // MARK: - Background
    static let background = Color(hex: "#0B011A")
    static let cardHeader = Color(hex: "#0E0E0E")

    // MARK: - Accent
    static let primaryPurple = Color(hex: "#9B60F7")
    static let accentGold = Color(hex: "#F8CD7A")

    // MARK: - Task Card Backgrounds (15% opacity)
    static let taskCardRed = Color(hex: "#FF5959")
    static let taskCardBlue = Color(hex: "#5977FF")
    static let taskCardGreen = Color(hex: "#59FF8C")
    static let taskCardPurple = Color(hex: "#9B60F7")
    static let taskCardOrange = Color(hex: "#FF9B59")

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#616161")
    static let textMuted = Color(hex: "#3A3A3A")

    // MARK: - Border
    static let border = Color(hex: "#3A3A3A")

    // MARK: - Tab Bar
    static let tabBarBackground = Color(hex: "#0E0E0E")
    static let tabBarActive = Color(hex: "#9B60F7")
    static let tabBarInactive = Color(hex: "#616161")
}

// Kenapa enum bukan struct?
//  - enum tanpa case = tidak bisa di-instantiate (let x = AppColors() ← compile error)
//  - Pure namespace, seperti abstract class di TypeScript yang tidak pernah di-new
