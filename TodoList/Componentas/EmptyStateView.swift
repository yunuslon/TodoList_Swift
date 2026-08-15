//
//  EmptyStateView.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

struct EmptyStateView: View {
    var title: String = "No tasks yet"
    var subtitle: String = "Tap + to create your first task"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))

            Text(title)
                .font(AppFonts.sectionTitle())
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView()
        .background(AppColors.background)
}
