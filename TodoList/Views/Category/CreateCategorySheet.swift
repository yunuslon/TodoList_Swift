import SwiftUI
import SwiftData

struct CreateCategorySheet: View {
    @State private var name: String = ""
    @State private var selectedColorHex: String = TodoCategory.predefinedColors[0].hex
    @State private var isSaving: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Name")
                            .font(AppFonts.small(weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)

                        TextField("e.g. Work, Personal, Health", text: $name)
                            .font(AppFonts.body())
                            .foregroundStyle(AppColors.textPrimary)
                            .tint(AppColors.primaryPurple)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: AppConstants.cardRadius)
                                    .strokeBorder(AppColors.border, lineWidth: 1)
                            )
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(AppFonts.small(weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                            ForEach(TodoCategory.predefinedColors, id: \.hex) { item in
                                Circle()
                                    .fill(Color(hex: item.hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.white, lineWidth: selectedColorHex == item.hex ? 3 : 0)
                                    )
                                    .scaleEffect(selectedColorHex == item.hex ? 1.1 : 1.0)
                                    .onTapGesture {
                                        withAnimation(.spring(duration: 0.2)) {
                                            selectedColorHex = item.hex
                                        }
                                    }
                            }
                        }
                    }

                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(AppFonts.small(weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)

                        CategoryPillView(
                            name: name.isEmpty ? "Category" : name,
                            colorHex: selectedColorHex,
                            isSelected: true,
                            action: {}
                        )
                    }

                    Spacer()
                }
                .padding(AppConstants.paddingHorizontal)
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .foregroundStyle(canSave ? AppColors.primaryPurple : AppColors.textSecondary)
                    .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private func saveCategory() {
        guard canSave else { return }
        isSaving = true

        let category = TodoCategory(
            name: name.trimmingCharacters(in: .whitespaces),
            colorHex: selectedColorHex
        )
        context.insert(category)
        try? context.save()

        dismiss()
    }
}

#Preview {
    CreateCategorySheet()
}
