import SwiftUI
import SwiftData

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @State private var router = DIContainer.shared.resolve(AppRouter.self)

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.hasNoTasks && !viewModel.isLoading {
                    EmptyHomeView(onCreateTap: {
                        router.present(.createTask)
                    })
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .taskDetail(let id):
                    TaskInfoScreen(todoId: id)
                case .categoryFilter(let id):
                    CategoryScreen(categoryId: id)
                case .search:
                    Text("Search — Phase 2")
                default:
                    Text("Coming soon")
                }
            }
            .sheet(item: $router.presentedSheet) { destination in
                switch destination {
                case .createTask:
                    CreateTaskScreen()
                case .createCategory:
                    CreateCategorySheet()
                default:
                    EmptyView()
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConstants.sectionSpacing) {
                // Header
                AppHeaderView(onSettingsTap: {
                    // Phase 2: navigate to settings
                })
                .padding(.horizontal, AppConstants.paddingHorizontal)

                // Search bar
                SearchBarView(text: $viewModel.searchText, onFilterTap: nil)
                    .padding(.horizontal, AppConstants.paddingHorizontal)

                // Category pills
                categorySection

                // Today tasks
                if !viewModel.todayTasks.isEmpty {
                    taskSection(title: "Today task", tasks: viewModel.todayTasks)
                }

                // Future tasks
                if !viewModel.futureTasks.isEmpty {
                    taskSection(title: "Future", tasks: viewModel.futureTasks)
                }

                // Previous tasks
                if !viewModel.previousTasks.isEmpty {
                    taskSection(title: "Previous", tasks: viewModel.previousTasks)
                }
            }
            .padding(.vertical, AppConstants.paddingVertical)
        }
        .refreshable {
            await viewModel.loadData()
        }
        .overlay(alignment: .bottomTrailing) {
            fabButton
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                AddCategoryPillView(action: {
                    router.present(.createCategory)
                })

                CategoryPillView(
                    name: "All",
                    colorHex: "#F8CD7A",
                    isSelected: viewModel.selectedCategory == nil,
                    action: { viewModel.selectCategory(nil) }
                )

                ForEach(viewModel.categories, id: \.id) { category in
                    CategoryPillView(
                        name: category.name,
                        colorHex: category.colorHex,
                        isSelected: viewModel.selectedCategory?.id == category.id,
                        action: { viewModel.selectCategory(category) }
                    )
                }
            }
            .padding(.horizontal, AppConstants.paddingHorizontal)
        }
    }

    // MARK: - Task Section

    private func taskSection(title: String, tasks: [TodoItem]) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.cardSpacing) {
            Text(title)
                .font(AppFonts.sectionTitle())
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppConstants.paddingHorizontal)

            ForEach(tasks, id: \.id) { item in
                TaskCardView(
                    title: item.title,
                    subtitle: item.subtitle,
                    colorHex: item.cardColorHex,
                    isCompleted: item.isCompleted,
                    onToggle: {
                        Task { await viewModel.toggleComplete(item) }
                    }
                )
                .onTapGesture {
                    router.navigate(to: .taskDetail(item.persistentModelID))
                }
                .padding(.horizontal, AppConstants.paddingHorizontal)
            }
        }
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button(action: {
            router.present(.createTask)
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(AppColors.primaryPurple)
                )
                .shadow(color: AppColors.primaryPurple.opacity(0.4), radius: 8, y: 4)
        }
        .padding(AppConstants.paddingHorizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Destination Identifiable (for sheet)

extension Destination: Identifiable {
    var id: Int { hashValue }
}
