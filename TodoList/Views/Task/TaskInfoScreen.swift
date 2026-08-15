import SwiftUI
import SwiftData

struct TaskInfoScreen: View {
    let todoId: PersistentIdentifier
    @State private var viewModel: TaskDetailViewModel
    @State private var router = DIContainer.shared.resolve(AppRouter.self)

    init(todoId: PersistentIdentifier) {
        self.todoId = todoId
        self._viewModel = State(initialValue: TaskDetailViewModel(todoId: todoId))
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if let todo = viewModel.todo {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Status badge
                        HStack {
                            statusBadge(todo: todo)
                            Spacer()
                            priorityBadge(todo: todo)
                        }

                        // Title
                        Text(todo.title)
                            .font(AppFonts.brand(size: 22))
                            .foregroundStyle(AppColors.textPrimary)
                            .strikethrough(todo.isCompleted, color: AppColors.textSecondary)

                        // Subtitle
                        if !todo.subtitle.isEmpty {
                            Text(todo.subtitle)
                                .font(AppFonts.body(weight: .regular))
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        // Info cards
                        VStack(spacing: 12) {
                            if let dueDate = todo.dueDate {
                                infoRow(icon: "calendar", label: "Due Date", value: dueDate.formatted())
                            }

                            infoRow(icon: "clock", label: "Created", value: todo.createdAt.relativeFormatted())

                            if let category = todo.category {
                                infoRow(icon: "folder", label: "Category", value: category.name)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.cardRadius)
                                .fill(AppColors.cardHeader)
                        )

                        Spacer(minLength: 40)

                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                Task { await viewModel.toggleComplete() }
                            }) {
                                HStack {
                                    Image(systemName: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                    Text(todo.isCompleted ? "Mark Incomplete" : "Mark Complete")
                                }
                                .font(AppFonts.body())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(AppColors.primaryPurple)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                viewModel.showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Task")
                                }
                                .font(AppFonts.body())
                                .foregroundStyle(Color(hex: "#FF5959"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .strokeBorder(Color(hex: "#FF5959").opacity(0.5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppConstants.paddingHorizontal)
                    .padding(.top, 16)
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(AppColors.primaryPurple)
            } else {
                Text("Task not found")
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog(
            "Delete Task",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    let deleted = await viewModel.deleteTodo()
                    if deleted { router.goBack() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
        .task {
            await viewModel.loadTodo()
        }
    }

    // MARK: - Components

    private func statusBadge(todo: TodoItem) -> some View {
        Text(todo.isCompleted ? "Completed" : "In Progress")
            .font(AppFonts.small(weight: .medium))
            .foregroundStyle(todo.isCompleted ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(todo.isCompleted ? Color(hex: "#59FF8C") : AppColors.primaryPurple)
            )
    }

    private func priorityBadge(todo: TodoItem) -> some View {
        Text(todo.taskPriority.label)
            .font(AppFonts.small(weight: .medium))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(hex: todo.taskPriority.colorHex))
            )
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.primaryPurple)
                .frame(width: 24)

            Text(label)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}
