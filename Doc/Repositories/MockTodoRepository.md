# MockTodoRepository.swift

**Lokasi:** `TodoList/Repositories/MockTodoRepository.swift`

---

## Tujuan

In-memory implementation dari `TodoRepositoryProtocol` untuk Preview dan unit testing. Data hidup di array biasa — tidak ada database, tidak ada disk I/O.

---

## Konsep

- **Mock pattern** — fake implementation yang conform ke protocol yang sama
- **Seeding** — pre-populate dengan sample data yang representatif
- **Tanpa side effect** — semua operasi di memory, predictable, cepat

---

## Penjelasan Code

### Class Declaration

```swift
final class MockTodoRepository: TodoRepositoryProtocol {
    var todos: [TodoItem] = []
    var categories: [TodoCategory] = []
```

- `final class` — bukan `@Model`, plain Swift class
- `var` (bukan `private`) — supaya test bisa inspect/manipulate state langsung
- Conform `: TodoRepositoryProtocol` — compiler enforce semua method di-implement

### Seed Data

```swift
private func seedData() {
    let work = TodoCategory(name: "Work", colorHex: "#F8CD7A")
    let personal = TodoCategory(name: "Personal", colorHex: "#9B60F7")
    let health = TodoCategory(name: "Health", colorHex: "#59FF8C")
    categories = [work, personal, health]

    let today = Calendar.current.startOfDay(for: .now)
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

    todos = [
        TodoItem(title: "...", dueDate: today, category: work),
        TodoItem(title: "...", dueDate: tomorrow, category: personal),
        TodoItem(title: "...", isCompleted: true, dueDate: yesterday, category: health),
    ]
}
```

**Kenapa seed dengan campuran today/tomorrow/yesterday?**
- Preview Home Screen langsung terlihat 3 section (Today, Future, Previous)
- Bisa verify grouping logic tanpa manual create data
- Campuran completed/uncompleted untuk test toggle

**`Calendar.current.date(byAdding:)`:**
- `value: 1` → besok
- `value: -1` → kemarin
- Force unwrap `!` — aman karena adding days ke valid date selalu succeed

### Method Implementation

```swift
func fetchAllTodos() async throws -> [TodoItem] {
    todos
}
```

Langsung return array. Tidak perlu `await` apapun — tapi signature tetap `async throws` karena protocol requirement. Swift auto-bridge ini.

```swift
func deleteTodo(_ item: TodoItem) async throws {
    todos.removeAll { $0.id == item.id }
}
```

`removeAll(where:)` — hapus semua element yang match condition. Match by `id` (bukan reference equality) karena `@Model` class bisa punya multiple reference ke object yang sama.

```swift
func toggleComplete(_ item: TodoItem) async throws {
    item.isCompleted.toggle()
}
```

Langsung mutate property. Ini bisa karena `TodoItem` = class (reference type). Mutation di sini = mutation di mana pun item itu di-reference.

### Lookup (Mock Limitation)

```swift
func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem? {
    nil
}
```

Return `nil` karena mock items tidak punya `PersistentIdentifier` — itu hanya di-generate saat SwiftData persist object ke ModelContext. Mock tidak pakai ModelContext.

---

## Analog TypeScript

```typescript
class MockTodoRepository implements ITodoRepository {
    todos: TodoItem[] = []
    categories: TodoCategory[] = []

    constructor() {
        this.seedData()
    }

    private seedData() {
        this.categories = [
            { id: uuid(), name: 'Work', colorHex: '#F8CD7A' },
            // ...
        ]
        this.todos = [
            { id: uuid(), title: 'Meeting', dueDate: new Date(), category: this.categories[0] },
            // ...
        ]
    }

    async fetchAllTodos() { return this.todos }
    async addTodo(item: TodoItem) { this.todos.push(item) }
    async deleteTodo(item: TodoItem) {
        this.todos = this.todos.filter(t => t.id !== item.id)
    }
    // ...
}
```

---

## Penggunaan

```swift
// Di Preview
#Preview {
    HomeScreen()
        .environment(HomeViewModel(repository: MockTodoRepository()))
}

// Di Unit Test
@Test func deleteTodo() async throws {
    let repo = MockTodoRepository()
    let initialCount = repo.todos.count

    try await repo.deleteTodo(repo.todos[0])

    #expect(repo.todos.count == initialCount - 1)
}
```

---

## Dependency

- Depends on: `TodoRepositoryProtocol` (conform), `TodoItem`, `TodoCategory`
- Dipakai oleh: `DIContainer+Registrations` (registerForPreviews), Preview blocks, Unit Tests

---

## Gotcha

- **`fetchTodo(by:)` return nil** — kalau nanti ada test yang butuh ini, kamu perlu approach lain (misal simpan mapping UUID → item). Untuk sekarang fine.
- **Thread safety** — mock ini TIDAK thread-safe. Kalau ada concurrent access ke `todos` array, bisa crash. Fine untuk Preview (single thread), tapi kalau pakai di concurrent test, perlu `actor` atau lock.
- **Reference type gotcha** — `item.isCompleted.toggle()` di mock juga mutate item di `todos` array (karena class = reference). Ini match behavior SwiftData. Tapi kalau mock pakai struct, behavior beda — hati-hati.
