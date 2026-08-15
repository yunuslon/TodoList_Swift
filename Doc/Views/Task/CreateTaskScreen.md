# CreateTaskScreen.swift

**Lokasi:** `TodoList/Views/Task/CreateTaskScreen.swift`

---

## Tujuan

Form screen untuk membuat task baru. Ditampilkan sebagai sheet dari Home Screen. Berisi input fields: title, description, due date, priority, category.

---

## Konsep

- **Sheet presentation** — modal form, dismiss via Cancel atau setelah Save
- **`@Environment(\.dismiss)`** — SwiftUI built-in dismiss action
- **Form validation** — Save button disabled kalau `!canSave`
- **`@ViewBuilder` helper** — reusable section layout

---

## Penjelasan Code

### Environment & State

```swift
@State private var viewModel = CreateTaskViewModel()
@Environment(\.dismiss) private var dismiss
```

- `viewModel` = form state + save logic
- `dismiss` = closure untuk tutup sheet. Dipanggil setelah save sukses atau Cancel.

### NavigationStack di Sheet

```swift
NavigationStack {
    ZStack { ... }
    .navigationTitle("Create Task")
    .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) { Button("Save") { ... } }
    }
}
```

Sheet punya NavigationStack sendiri (ini OK — bukan nested dari parent). Toolbar placement:
- `.cancellationAction` → kiri atas
- `.confirmationAction` → kanan atas

### Save Flow

```swift
Button("Save") {
    Task {
        let success = await viewModel.save()
        if success { dismiss() }
    }
}
.disabled(!viewModel.canSave || viewModel.isSaving)
```

1. Wrap dalam `Task { }` — karena `save()` is async
2. `if success` → dismiss sheet → HomeScreen re-appear → `.task` trigger → `loadData()` → data baru muncul
3. `.disabled` — prevent double tap dan enforce validation

### Priority Picker

```swift
ForEach(TaskPriority.allCases) { priority in
    Button(action: { viewModel.priority = priority.rawValue }) {
        Text(priority.label)
            .background(
                Capsule().fill(viewModel.priority == priority.rawValue ? Color(hex: priority.colorHex) : .clear)
            )
    }
}
```

Custom pill-style picker (bukan native Picker). Selected = filled color, unselected = border only.

### @ViewBuilder Helper

```swift
private func inputSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(AppFonts.small(weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
        content()
    }
}
```

Reusable section pattern: label di atas, content di bawah. `@ViewBuilder` = bisa pass any View content sebagai trailing closure.

### .task { loadCategories }

```swift
.task {
    await viewModel.loadCategories()
}
```

Load categories saat sheet appear — supaya category picker terisi.

---

## Analog React Native

```typescript
function CreateTaskScreen() {
    const { goBack } = useNavigation()
    const [form, setForm] = useState(initialState)

    const handleSave = async () => {
        const success = await repository.addTodo(form)
        if (success) goBack()
    }

    return (
        <ScrollView>
            <TextInput placeholder="Title" value={form.title} onChangeText={...} />
            <TextInput placeholder="Description" ... />
            <DateTimePicker value={form.dueDate} ... />
            <PriorityPicker selected={form.priority} onSelect={...} />
            <CategoryPicker categories={categories} selected={form.category} onSelect={...} />
            <Button title="Save" onPress={handleSave} disabled={!canSave} />
        </ScrollView>
    )
}
```

---

## Dependency

- Depends on: `CreateTaskViewModel`, `CategoryPillView`, `AppColors`, `AppFonts`, `AppConstants`, `TaskPriority`
- Dipakai oleh: `HomeScreen.swift` (via `.sheet`)

---

## Gotcha

- **Sheet punya NavigationStack sendiri** — ini BUKAN nested NavigationStack (parent punya 1, sheet punya 1 terpisah). Ini OK.
- **`@Environment(\.dismiss)`** — hanya works di View yang di-present via sheet/navigation. Kalau View bukan presented, `dismiss()` no-op.
- **`.toolbarColorScheme(.dark)`** — force toolbar text jadi putih (karena background gelap).
- **Data setelah dismiss** — HomeScreen `.task` re-trigger → loadData() otomatis. Tidak perlu callback/delegate.
