import SwiftUI

struct EmptyHomeView: View {
    var onCreateTap: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            EmptyStateView(
                title: "What do you want to do today?",
                subtitle: "Tap + to add your tasks and keep your day organized"
            )

            Button(action: onCreateTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Task")
                }
                .font(AppFonts.body())
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(AppColors.primaryPurple)
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyHomeView(onCreateTap: {})
        .background(AppColors.background)
}
