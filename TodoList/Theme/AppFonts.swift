//
//  AppFonts.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

enum AppFonts {
    // MARK: - Brand (Playfair Display — custom font, fallback ke serif)
    static func brand(size: CGFloat = 24) -> Font {
        .custom("PlayfairDisplay-ExtraBold", size: size)
    }

    // MARK: - Section Title
    static func sectionTitle() -> Font {
        .system(size: 18, weight: .medium)
    }

    // MARK: - Body
    static func body(weight: Font.Weight = .medium) -> Font {
        .system(size: 16, weight: weight)
    }

    // MARK: - Caption / Subtitle
    static func caption() -> Font {
        .system(size: 14, weight: .regular)
    }

    // MARK: - Small (category pill, badge)
    static func small(weight: Font.Weight = .medium) -> Font {
        .system(size: 12, weight: weight)
    }

}

//  Note: .custom("PlayfairDisplay-ExtraBold") akan fallback ke system font sampai kamu register .ttf di Info.plist. Nanti bisa dipasang kapan saja.
