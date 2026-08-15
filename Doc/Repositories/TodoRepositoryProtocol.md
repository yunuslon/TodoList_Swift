# TodoRepositoryProtocol.swift

**Lokasi:** `TodoList/Repositories/TodoRepositoryProtocol.swift`

---

## Tujuan

Interface (protocol) yang mendefinisikan SEMUA operasi data untuk todo app. Ini "kontrak" antara ViewModel dan data layer — ViewModel tidak perlu tahu apakah data dari SwiftData, API, atau mock.

---

## Konsep

- **Protocol** = interface di TypeScript
- **Dependency Inversion Principle** — ViewModel depend ke abstraksi (protocol), bukan concrete class
- **Testability** — bisa swap real repo dengan mock tanpa ubah ViewModel
- Semua method `async throws` — konsisten untuk real dan mock implementation

---

## Penjelasan Code

### Protocol Declaration

```swift
protocol TodoRepositoryProtocol {
```

Tidak ada `class`, `struct`, atau `actor` — protocol hanya deklarasi "apa yang harus bisa dilakukan", bukan implementasi.

### CRUD Methods

```swift
func fetchAllTodos() async throws -> [TodoItem]
func addTodo(_ item: TodoItem) async throws
func updateTodo(_ item: TodoItem) async throws
func deleteTodo(_ item: TodoItem) async throws
func toggleComplete(_ item: TodoItem) async throws
```

- `async` — operasi mungkin butuh waktu (disk I/O, network)
- `throws` — operasi mungkin gagal (disk full, corrupted data)
- `_ item` — underscore = caller tidak perlu tulis label: `addTodo(item)` bukan `addTodo(item: item)`

### Filter Method

```swift
func fetchTodos(for category: TodoCategory?) async throws -> [TodoItem]
```

`TodoCategory?` — optional. `nil` = fetch semua (tanpa filter).

### Lookup by ID

```swift
func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem?
func fetchCategory(by id: PersistentIdentifier) async throws -> TodoCategory?
```

- `PersistentIdentifier` — unique ID dari SwiftData
- Return optional (`TodoItem?`) — mungkin sudah dihapus
- Dipakai saat navigate: `Destination.taskDetail(id)` → di screen tujuan, resolve id ke object

---

## Analog TypeScript

```typescript
interface ITodoRepository {
    // CRUD
    fetchAllTodos(): Promise<TodoItem[]>
    fetchTodos(category?: TodoCategory): Promise<TodoItem[]>
    addTodo(item: TodoItem): Promise<void>
    updateTodo(item: TodoItem): Promise<void>
    deleteTodo(item: TodoItem): Promise<void>
    toggleComplete(item: TodoItem): Promise<void>

    // Categories
    fetchAllCategories(): Promise<TodoCategory[]>
    addCategory(category: TodoCategory): Promise<void>
    deleteCategory(category: TodoCategory): Promise<void>

    // Lookup
    fetchTodo(id: PersistentIdentifier): Promise<TodoItem | null>
    fetchCategory(id: PersistentIdentifier): Promise<TodoCategory | null>
}
```

**Analog NestJS:**
```typescript
// Biasanya abstract class dengan @Injectable()
@Injectable()
abstract class TodoRepository {
    abstract findAll(): Promise<TodoItem[]>
    abstract create(dto: CreateTodoDto): Promise<TodoItem>
    // ...
}
```

---

## Penggunaan

```swift
// Di ViewModel — depend ke protocol, bukan concrete
class HomeViewModel {
    private let repository: TodoRepositoryProtocol  // ← protocol type

    init(repository: TodoRepositoryProtocol) {      // ← inject via init
        self.repository = repository
    }

    func loadData() async {
        let todos = try await repository.fetchAllTodos()  // ← caller tidak tahu implementasi
    }
}

// Production: inject real repo
HomeViewModel(repository: TodoRepository(modelContainer: container))

// Test: inject mock
HomeViewModel(repository: MockTodoRepository())
```

---

## Dependency

- Depends on: `TodoItem.swift`, `TodoCategory.swift` (return types), `SwiftData` (PersistentIdentifier)
- Dipakai oleh: `TodoRepository`, `MockTodoRepository` (conform), semua ViewModel (consume)

---

## Gotcha

- **Jangan tambah `@MainActor` ke protocol** — ini data layer, harus nonisolated. Kalau protocol di-mark `@MainActor`, mock di test juga harus `@MainActor` → ribet.
- **`async throws` walaupun mock tidak butuh** — consistency. Mock bisa langsung return value tanpa `await` (Swift auto-bridge), tapi signature tetap `async throws` supaya protocol applicable untuk real implementation.
- **Naming: `Protocol` suffix** — konvensi di project ini. Alternatif: `TodoRepositoryType`, `TodoRepositoring`, atau prefix `I` (`ITodoRepository`). Pilih satu, konsisten.
