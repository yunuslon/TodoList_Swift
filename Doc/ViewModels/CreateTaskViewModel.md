# CreateTaskViewModel.swift

**Lokasi:** `TodoList/ViewModels/CreateTaskViewModel.swift`

---

## Tujuan

ViewModel untuk Create Task form. Manage form state, validation, dan save logic.

---

## Konsep

- **Form state** — setiap field = satu property
- **Validation** — computed `canSave` yang disable/enable button
- **Save → return Bool** — caller (View) tahu sukses/gagal untuk dismiss

---

## Penjelasan Code

### Form State

```swift
var title: String = ""
var subtitle: String = ""
var dueDate: Date = .now
var hasDueDate: Bool = true
var priority: Int = 1
var selectedCategory: TodoCategory?
var categories: [TodoCategory] = []
```

Setiap property = 1 form field. Default values = initial state form.

### Validation

```swift
var canSave: Bool {
    !title.trimmingCharacters(in: .whitespaces).isEmpty
}
```

Minimum requirement: title tidak kosong (setelah trim whitespace). Button Save disabled kalau `!canSave`.

### save() → Bool

```swift
func save() async -> Bool {
    guard canSave else { return false }
    isSaving = true
    let item = TodoItem(
        title: title.trimmingCharacters(in: .whitespaces),
        subtitle: subtitle.trimmingCharacters(in: .whitespaces),
        dueDate: hasDueDate ? dueDate : nil,
        priority: priority,
        category: selectedCategory
    )
    do {
        try await repository.addTodo(item)
        isSaving = false
        return true
    } catch {
        self.error = error.localizedDescription
        isSaving = false
        return false
    }
}
```

- Return `true` → View dismiss sheet
- Return `false` → View stay open, show error
- `isSaving` → disable button, prevent double-submit
- `hasDueDate ? dueDate : nil` — conditional: user bisa uncheck due date

---

## Analog TypeScript

```typescript
const [form, setForm] = useState({ title: '', subtitle: '', ... })
const canSave = form.title.trim().length > 0

const handleSave = async () => {
    if (!canSave) return false
    setSaving(true)
    try {
        await repository.addTodo(form)
        return true  // → navigation.goBack()
    } catch (e) {
        setError(e.message)
        return false
    } finally {
        setSaving(false)
    }
}
```

---

## Dependency

- Depends on: `TodoRepositoryProtocol`, `TodoItem`, `TodoCategory`, `DIContainer`
- Dipakai oleh: `CreateTaskScreen.swift`

---

## Gotcha

- **`trimmingCharacters` saat save** — prevent "   " (whitespace only) dari disimpan
- **Setelah save, HomeViewModel harus `loadData()` ulang** — data baru tidak otomatis muncul. Ini terjadi karena `.task` di HomeScreen re-trigger saat sheet dismiss.
