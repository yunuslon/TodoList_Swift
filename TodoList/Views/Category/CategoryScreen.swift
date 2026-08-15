import SwiftUI
import SwiftData

struct CategoryScreen: View {
    let categoryId: PersistentIdentifier
    @State private var category: TodoCategory?
    @State private var todos: [TodoItem] = []
    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if let category {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppConstants.sectionSpacing) {
                        // Category header
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 12, height: 12)

                            Text(category.name)
                                .font(AppFonts.sectionTitle())
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()

                            Text("\(todos.count) tasks")
                                .font(AppFonts.caption())
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(.horizontal, AppConstants.paddingHorizontal)

                        // Tasks
                        if todos.isEmpty {
                            EmptyStateView(
                                title: "No tasks in \(category.name)",
                                subtitle: "Tasks assigned to this category will appear here"
                            )
                            .frame(minHeight: 300)
                        } else {
                            VStack(spacing: AppConstants.cardSpacing) {
                                ForEach(todos, id: \.id) { item in
                                    TaskCardView(
                                        title: item.title,
                                        subtitle: item.subtitle,
                                        colorHex: item.cardColorHex,
                                        isCompleted: item.isCompleted,
                                        onToggle: {
                                            item.isCompleted.toggle()
                                            try? context.save()
                                        }
                                    )
                                    .padding(.horizontal, AppConstants.paddingHorizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical, AppConstants.paddingVertical)
                }
            } else {
                ProgressView()
                    .tint(AppColors.primaryPurple)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            loadCategory()
        }
    }

    @MainActor
    private func loadCategory() {
        guard let cat = context.model(for: categoryId) as? TodoCategory else { return }
        category = cat
        todos = cat.items.sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
    }
}
