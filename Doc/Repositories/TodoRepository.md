# TodoRepository.swift

**Lokasi:** `TodoList/Repositories/TodoRepository.swift`

---

## Tujuan

Real SwiftData implementation dari `TodoRepositoryProtocol`. Semua operasi CRUD beneran ke database (SQLite via SwiftData). Ini yang jalan di production.

---

## Konsep

- **Repository pattern** — abstraksi akses data, hide SwiftData details dari ViewModel
- **ModelContainer** — "koneksi database" dari SwiftData
- **ModelContext** — "transaction/session", tempat fetch/insert/delete
- **MainActor-bound context** — SwiftData ModelContext terikat ke actor pembuatnya

---

## Penjelasan Code

### Dependency Injection

```swift
final class TodoRepository: TodoRepositoryProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
```

- Terima `ModelContainer` via init (dari DI Container)
- `private` — tidak boleh diakses dari luar
- Tidak langsung simpan `context` — alasannya di bawah

### Context Access Pattern

```swift
@MainActor
private var context: ModelContext {
    modelContainer.mainContext
}
```

**Kenapa computed property, bukan stored?**

```swift
// ❌ Ini error — init bukan @MainActor, tidak bisa akses mainContext
init(modelContainer: ModelContainer) {
    self.context = modelContainer.mainContext  // Compile error!
}

// ✅ Computed — diakses saat dipanggil, di dalam MainActor.run
@MainActor
private var context: ModelContext {
    modelContainer.mainContext  // Aman, sudah di MainActor
}
```

`mainContext` = MainActor-bound. Hanya boleh diakses dari MainActor. Computed property yang di-annotate `@MainActor` memastikan ini.

### Fetch Pattern

```swift
func fetchAllTodos() async throws -> [TodoItem] {
    let descriptor = FetchDescriptor<TodoItem>(
        sortBy: [SortDescriptor(\.dueDate, order: .forward)]
    )
    return try await MainActor.run {
        try context.fetch(descriptor)
    }
}
```

1. **`FetchDescriptor<TodoItem>`** — deskripsi query: "ambil semua TodoItem, sort by dueDate ascending"
2. **`SortDescriptor(\.dueDate, order: .forward)`** — keypath ke property + arah sort. `.forward` = ascending (paling awal dulu)
3. **`await MainActor.run { ... }`** — pindah eksekusi ke MainActor karena `context.fetch()` harus di MainActor
4. **`try context.fetch(descriptor)`** — execute query, return array

**Analog TypeORM:**
```typescript
async fetchAllTodos(): Promise<TodoItem[]> {
    return this.repository.find({
        order: { dueDate: 'ASC' }
    })
}
```

### Filter Strategy (Fetch All + Filter di Swift)

```swift
func fetchTodos(for category: TodoCategory?) async throws -> [TodoItem] {
    let all = try await fetchAllTodos()
    guard let category else { return all }
    return all.filter { $0.category?.id == category.id }
}
```

**Kenapa tidak pakai Predicate?**
```swift
// ❌ Risky — optional relationship di predicate bisa crash runtime
let catId = category.id
let descriptor = FetchDescriptor<TodoItem>(
    predicate: #Predicate { $0.category?.id == catId }
)
// Kadang works, kadang crash tergantung iOS version

// ✅ Aman — fetch semua, filter di Swift
let all = try await fetchAllTodos()
return all.filter { $0.category?.id == category.id }
```

Untuk todo app (max ratusan items), filter di Swift performanya fine. Kalau ribuan+ items, baru perlu optimize dengan predicate.

### Insert Pattern

```swift
func addTodo(_ item: TodoItem) async throws {
    await MainActor.run {
        context.insert(item)
        try? context.save()
    }
}
```

1. `context.insert(item)` — daftarkan object ke context (belum persist)
2. `try? context.save()` — flush ke disk sekarang
3. `try?` — ignore error karena SwiftData juga auto-save periodik

### Delete Pattern

```swift
func deleteTodo(_ item: TodoItem) async throws {
    await MainActor.run {
        context.delete(item)
        try? context.save()
    }
}
```

Sama pattern: aksi + save. `delete` mark object untuk removal, `save` persist ke disk.

### Toggle Pattern

```swift
func toggleComplete(_ item: TodoItem) async throws {
    await MainActor.run {
        item.isCompleted.toggle()
        try? context.save()
    }
}
```

SwiftData track perubahan di `@Model` properties otomatis. Cukup mutate property → save. Tidak perlu "update" method khusus.

### Lookup by PersistentIdentifier

```swift
func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem? {
    await MainActor.run {
        context.model(for: id) as? TodoItem
    }
}
```

- `context.model(for: id)` — resolve ID ke managed object. Return `PersistentModel` (base protocol)
- `as? TodoItem` — safe downcast. Return nil kalau bukan TodoItem (shouldn't happen)
- Ini dipakai saat navigate: `Destination.taskDetail(id)` → di screen: `repo.fetchTodo(by: id)`

---

## Alur Data Lengkap

```
ViewModel                    TodoRepository                 SwiftData
    │                              │                            │
    │── loadData() ──────────────→ │                            │
    │                              │── MainActor.run ─────────→ │
    │                              │                            │── SQLite query
    │                              │                            │── return [TodoItem]
    │                              │←── [TodoItem] ────────────│
    │←── allTodos = [...] ────────│                            │
    │                              │                            │
    │── deleteTodo(item) ────────→ │                            │
    │                              │── MainActor.run ─────────→ │
    │                              │   context.delete(item)     │── mark deleted
    │                              │   context.save()           │── write to SQLite
    │                              │←── done ──────────────────│
    │←── done ────────────────────│                            │
    │── loadData() (refresh) ────→ │                            │
```

---

## Analog TypeScript (TypeORM)

```typescript
@Injectable()
class TodoRepository implements ITodoRepository {
    constructor(
        @InjectRepository(TodoItem)
        private repo: Repository<TodoItem>,
        private dataSource: DataSource,
    ) {}

    async fetchAllTodos() {
        return this.repo.find({ order: { dueDate: 'ASC' } })
    }

    async addTodo(item: TodoItem) {
        await this.repo.save(item)
    }

    async deleteTodo(item: TodoItem) {
        await this.repo.remove(item)
    }

    async fetchTodo(id: string) {
        return this.repo.findOneBy({ id })
    }
}
```

---

## Dependency

- Depends on: `TodoRepositoryProtocol` (conform), `TodoItem`, `TodoCategory`, `SwiftData`
- Dipakai oleh: `DIContainer+Registrations` (registerAll)

---

## Gotcha

- **SEMUA akses context HARUS di `MainActor.run`** — tanpa ini = runtime crash (actor isolation violation)
- **`try? context.save()`** — kalau mau strict error handling, ganti ke `try context.save()` dan propagate error ke ViewModel
- **`FetchDescriptor` sort by optional** — `\.dueDate` yang nil diletakkan di awal (sebelum semua dated items). Kalau mau nil di akhir, perlu custom sort logic.
- **Object lifecycle** — setelah `context.delete(item)`, object masih di memory tapi marked for deletion. Jangan akses property-nya setelah save.
- **Concurrent access** — jangan panggil 2 method bersamaan yang mutate context. `MainActor.run` serialize akses (satu per satu), jadi aman.
