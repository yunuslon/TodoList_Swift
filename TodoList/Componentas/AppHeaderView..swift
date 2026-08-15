//
//  AppHeaderView..swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import SwiftUI

struct AppHeaderView: View {
    var onSettingsTap: (() -> Void)?

    var body: some View {
        HStack {
            Text("Listodo")
                .font(AppFonts.brand())
                .foregroundStyle(AppColors.textPrimary)

            // Pro badge
            Text("Pro")
                .font(AppFonts.small(weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppColors.accentGold)
                )
                .rotationEffect(.degrees(-2))

            Spacer()

            // Settings button
            if let onSettingsTap {
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape")
                        .font(.system(size: AppConstants.iconMedium))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(
                            width: AppConstants.iconButtonSize,
                            height: AppConstants.iconButtonSize
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    AppHeaderView(onSettingsTap: {})
        .padding()
        .background(AppColors.background)
}
