//
//  SearchBarView.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Try to find task...."
    var onFilterTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: AppConstants.iconMedium))
                .foregroundStyle(AppColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textPrimary)
                .tint(AppColors.primaryPurple)

            if let onFilterTap {
                Button(action: onFilterTap) {
                    Text("Filter")
                        .font(AppFonts.small())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppColors.primaryPurple)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: AppConstants.searchBarHeight)
        .background(
            Capsule()
                .strokeBorder(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        SearchBarView(text: .constant(""), onFilterTap: {})
        SearchBarView(text: .constant("Design"), onFilterTap: nil)
    }
    .padding()
    .background(AppColors.background)
}
