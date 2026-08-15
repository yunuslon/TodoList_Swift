# TaskInfoScreen.swift

**Lokasi:** `TodoList/Views/Task/TaskInfoScreen.swift`

---

## Tujuan

Detail screen untuk 1 task. Menampilkan info lengkap (title, subtitle, due date, priority, category, status) dan action buttons (toggle complete, delete).

---

## Konsep

- **PersistentIdentifier → resolve object** — terima ID dari navigation, load object via ViewModel
- **Confirmation dialog** — native iOS dialog sebelum delete (destructive action)
- **3 states** — loading, loaded (todo != nil), not found (todo == nil)
- **Action → navigate back** — setelah delete, auto pop

---

## Penjelasan Code

### Init dengan ID

```swift
let todoId: PersistentIdentifier
@State private var viewModel: TaskDetailViewModel

init(todoId: PersistentIdentifier) {
    self.todoId = todoId
    self._viewModel = State(initialValue: TaskDetailViewModel(todoId: todoId))
}
```

- `todoId` disimpan untuk reference
- `self._viewModel = State(initialValue:)` — cara init `@State` di custom init. Underscore `_` akses wrapper langsung.
- ViewModel dibuat dengan ID → nanti load object via `loadTodo()`

### 3-State Rendering

```swift
if let todo = viewModel.todo {
    // Loaded — show detail
    ScrollView { ... }
} else if viewModel.isLoading {
    // Loading
    ProgressView()
} else {
    // Not found
    Text("Task not found")
}
```

Pattern: guard loaded state, fallback ke loading/error. Ini menghindari force unwrap.

### Status & Priority Badges

```swift
private func statusBadge(todo: TodoItem) -> some View {
    Text(todo.isCompleted ? "Completed" : "In Progress")
        .background(Capsule().fill(todo.isCompleted ? Color(hex: "#59FF8C") : AppColors.primaryPurple))
}
```

Visual indicator: green = completed, purple = in progress. Capsule pill shape.

### Info Rows

```swift
private func infoRow(icon: String, label: String, value: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
        Text(label)
        Spacer()
        Text(value)
    }
}
```

Reusable row: icon | label | ———— | value. Dipakai untuk due date, created, category.

### Confirmation Dialog

```swift
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
    Text("Are you sure you want to delete this task?")
}
```

- `isPresented` — bound ke ViewModel bool. Set true → dialog muncul.
- `role: .destructive` — button merah (iOS convention)
- `role: .cancel` — auto-dismiss, no action
- Setelah delete sukses → `router.goBack()` → pop ke HomeScreen

### Toggle Complete

```swift
Button(action: {
    Task { await viewModel.toggleComplete() }
}) {
    HStack {
        Image(systemName: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
        Text(todo.isCompleted ? "Mark Incomplete" : "Mark Complete")
    }
}
```

Dynamic label/icon berdasarkan state. Satu button, dual function.

---

## Analog React Native

```typescript
function TaskInfoScreen({ route }) {
    const { id } = route.params
    const navigation = useNavigation()
    const [todo, setTodo] = useState(null)
    const [showDelete, setShowDelete] = useState(false)

    useEffect(() => { fetchTodo(id).then(setTodo) }, [id])

    const handleDelete = async () => {
        await repository.deleteTodo(todo)
        navigation.goBack()
    }

    return (
        <>
            {todo ? <DetailContent todo={todo} /> : <Loading />}
            <ConfirmDialog
                visible={showDelete}
                onConfirm={handleDelete}
                onCancel={() => setShowDelete(false)}
            />
        </>
    )
}
```

---

## Dependency

- Depends on: `TaskDetailViewModel`, `AppRouter`, `DIContainer`, `Destination`, semua Theme files
- Dipakai oleh: `HomeScreen.swift` (via `.navigationDestination`)

---

## Gotcha

- **`self._viewModel = State(initialValue:)`** — ini satu-satunya cara init @State di custom init. Jangan assign `self.viewModel = ...` (itu assign ke projected value, bukan wrapper).
- **Delete → goBack** — kalau user kembali ke Home, `.task` re-trigger loadData. Deleted item otomatis hilang dari list.
- **`todo` nil setelah delete** — jangan akses `viewModel.todo` setelah `deleteTodo()`. Pop dulu.
- **`.confirmationDialog` vs custom overlay** — native dialog lebih accessible (VoiceOver, Dynamic Type). Custom overlay butuh manual accessibility support.
