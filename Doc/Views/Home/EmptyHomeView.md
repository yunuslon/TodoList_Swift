# EmptyHomeView.swift

**Lokasi:** `TodoList/Views/Home/EmptyHomeView.swift`

---

## Tujuan

View yang ditampilkan saat user belum punya task sama sekali. Memberikan visual feedback + CTA button untuk create task pertama.

---

## Konsep

- **Empty state pattern** — jangan tampilkan blank screen, berikan context + action
- **Composition** — reuse `EmptyStateView` component dengan custom text
- **Callback prop** — `onCreateTap` delegate action ke parent

---

## Penjelasan Code

```swift
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
                ...
            }
            Spacer()
        }
    }
}
```

- `Spacer()` atas dan bawah → content vertical-centered
- `EmptyStateView` = reusable component (icon + title + subtitle)
- CTA button: purple capsule, langsung create task

---

## Penggunaan di HomeScreen

```swift
if viewModel.hasNoTasks && !viewModel.isLoading {
    EmptyHomeView(onCreateTap: {
        router.present(.createTask)
    })
} else {
    mainContent
}
```

Conditional render: empty state ATAU task list. Tidak keduanya.

---

## Dependency

- Depends on: `EmptyStateView` component, `AppColors`, `AppFonts`
- Dipakai oleh: `HomeScreen.swift`
