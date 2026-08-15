//
//  CategoryPillView.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

struct CategoryPillView: View {
    let name: String
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(AppFonts.small())
                .foregroundStyle(isSelected ? .black : AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: colorHex) : .clear)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? .clear : AppColors.border,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct AddCategoryPillView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 70, height: AppConstants.categoryPillHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConstants.cardRadius)
                        .strokeBorder(
                            AppColors.border,
                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 8) {
        AddCategoryPillView(action: {})
        CategoryPillView(name: "Work", colorHex: "#F8CD7A", isSelected: true, action: {})
        CategoryPillView(name: "Personal", colorHex: "#9B60F7", isSelected: false, action: {})
        CategoryPillView(name: "Health", colorHex: "#59FF8C", isSelected: false, action: {})
    }
    .padding()
    .background(AppColors.background)
}
