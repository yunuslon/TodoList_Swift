# TaskDetailViewModel.swift

**Lokasi:** `TodoList/ViewModels/TaskDetailViewModel.swift`

---

## Tujuan

ViewModel untuk Task Detail/Info screen. Load single task by ID, toggle complete, delete.

---

## Konsep

- **PersistentIdentifier → Object** — resolve SwiftData ID ke full object
- **Delete returns Bool** — caller tahu kapan harus `goBack()`
- **`showDeleteConfirmation`** — state untuk confirmation dialog

---

## Penjelasan Code

### Init dengan PersistentIdentifier

```swift
init(todoId: PersistentIdentifier, repository: TodoRepositoryProtocol? = nil) {
    self.todoId = todoId
    self.repository = repository ?? DIContainer.shared.resolve(TodoRepositoryProtocol.self)
}
```

Screen ini di-navigate via `Destination.taskDetail(PersistentIdentifier)`. Init terima ID, bukan object langsung.

### loadTodo()

```swift
func loadTodo() async {
    isLoading = true
    do {
        todo = try await repository.fetchTodo(by: todoId)
    } catch {
        self.error = error.localizedDescription
    }
    isLoading = false
}
```

Resolve ID → object. Hasilnya optional (`TodoItem?`) — bisa nil kalau sudah dihapus.

### deleteTodo() → Bool

```swift
func deleteTodo() async -> Bool {
    guard let todo else { return false }
    do {
        try await repository.deleteTodo(todo)
        return true   // → router.goBack()
    } catch {
        self.error = error.localizedDescription
        return false  // → stay on screen, show error
    }
}
```

Return Bool supaya View tahu: `if deleted { router.goBack() }`.

---

## Analog TypeScript

```typescript
// Screen yang dapat params.id dari navigation
const { id } = useRoute<'TaskDetail'>().params
const [todo, setTodo] = useState<TodoItem | null>(null)

useEffect(() => {
    repository.fetchTodo(id).then(setTodo)
}, [id])

const handleDelete = async () => {
    const success = await repository.deleteTodo(todo)
    if (success) navigation.goBack()
}
```

---

## Dependency

- Depends on: `TodoRepositoryProtocol`, `TodoItem`, `DIContainer`, `SwiftData` (PersistentIdentifier)
- Dipakai oleh: `TaskInfoScreen.swift`

---

## Gotcha

- **`todo` bisa nil** — kalau ID invalid atau object sudah dihapus. View harus handle nil state.
- **Setelah `toggleComplete()`, panggil `loadTodo()` ulang** — refresh data yang ditampilkan.
