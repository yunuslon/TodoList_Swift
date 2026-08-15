import SwiftUI
import SwiftData

struct CreateTaskScreen: View {
    @State private var viewModel = CreateTaskViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        inputSection(title: "Task Title") {
                            TextField("What do you want to do?", text: $viewModel.title)
                                .font(AppFonts.body())
                                .foregroundStyle(AppColors.textPrimary)
                                .tint(AppColors.primaryPurple)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppConstants.cardRadius)
                                        .strokeBorder(AppColors.border, lineWidth: 1)
                                )
                        }

                        // Subtitle
                        inputSection(title: "Description") {
                            TextField("Add a note...", text: $viewModel.subtitle)
                                .font(AppFonts.caption())
                                .foregroundStyle(AppColors.textPrimary)
                                .tint(AppColors.primaryPurple)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppConstants.cardRadius)
                                        .strokeBorder(AppColors.border, lineWidth: 1)
                                )
                        }

                        // Due Date
                        inputSection(title: "Due Date") {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle("Set due date", isOn: $viewModel.hasDueDate)
                                    .font(AppFonts.caption())
                                    .foregroundStyle(AppColors.textPrimary)
                                    .tint(AppColors.primaryPurple)

                                if viewModel.hasDueDate {
                                    DatePicker(
                                        "Date",
                                        selection: $viewModel.dueDate,
                                        displayedComponents: [.date, .hourAndMinute]
                                    )
                                    .datePickerStyle(.compact)
                                    .font(AppFonts.caption())
                                    .foregroundStyle(AppColors.textPrimary)
                                    .tint(AppColors.primaryPurple)
                                }
                            }
                        }

                        // Priority
                        inputSection(title: "Priority") {
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases) { priority in
                                    Button(action: {
                                        viewModel.priority = priority.rawValue
                                    }) {
                                        Text(priority.label)
                                            .font(AppFonts.small())
                                            .foregroundStyle(
                                                viewModel.priority == priority.rawValue
                                                    ? .black
                                                    : AppColors.textPrimary
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        viewModel.priority == priority.rawValue
                                                            ? Color(hex: priority.colorHex)
                                                            : .clear
                                                    )
                                            )
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(
                                                        viewModel.priority == priority.rawValue
                                                            ? .clear
                                                            : AppColors.border,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Category
                        inputSection(title: "Category") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    CategoryPillView(
                                        name: "None",
                                        colorHex: "#616161",
                                        isSelected: viewModel.selectedCategory == nil,
                                        action: { viewModel.selectedCategory = nil }
                                    )

                                    ForEach(viewModel.categories, id: \.id) { category in
                                        CategoryPillView(
                                            name: category.name,
                                            colorHex: category.colorHex,
                                            isSelected: viewModel.selectedCategory?.id == category.id,
                                            action: { viewModel.selectedCategory = category }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppConstants.paddingHorizontal)
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.save()
                            if success { dismiss() }
                        }
                    }
                    .foregroundStyle(viewModel.canSave ? AppColors.primaryPurple : AppColors.textSecondary)
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
        }
        .task {
            await viewModel.loadCategories()
        }
    }

    // MARK: - Input Section Helper

    private func inputSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.small(weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            content()
        }
    }
}

#Preview {
    CreateTaskScreen()
}
