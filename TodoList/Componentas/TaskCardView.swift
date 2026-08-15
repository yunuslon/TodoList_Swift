//
//  TaskCardView.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

struct TaskCardView: View {
    let title: String
    let subtitle: String
    let colorHex: String
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Circle()
                    .strokeBorder(
                        isCompleted ? Color(hex: colorHex) : AppColors.border,
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(
                                isCompleted
                                    ? Color(hex: colorHex).opacity(0.3) : .clear
                            )
                    )
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: colorHex))
                        }
                    }
            }
            .buttonStyle(.plain)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textPrimary)
                    .strikethrough(isCompleted, color: AppColors.textSecondary)
                    .opacity(isCompleted ? 0.6 : 1)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
            // Priority dot
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: AppConstants.taskCardHeight)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.cardRadius)
                .fill(Color(hex: colorHex).opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: AppConstants.cardSpacing) {
        TaskCardView(
            title: "Design sprint review",
            subtitle: "Prepare presentation slides",
            colorHex: "#FF5959",
            isCompleted: false,
            onToggle: {}
        )
        TaskCardView(
            title: "Buy groceries",
            subtitle: "Milk, eggs, bread",
            colorHex: "#F8CD7A",
            isCompleted: true,
            onToggle: {}
        )
        TaskCardView(
            title: "Morning workout",
            subtitle: "",
            colorHex: "#59FF8C",
            isCompleted: false,
            onToggle: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
