# DIContainer+Registrations.swift

**Lokasi:** `TodoList/DI/DIContainer+Registrations.swift`

---

## Tujuan

Composition Root — tempat satu-satunya yang menghubungkan abstraksi (protocol) dengan implementasi konkret. Dipanggil SEKALI saat app start. Semua "wiring" ada di sini.

---

## Konsep

- **Composition Root** — 1 tempat di app yang tahu semua concrete types. Di luar sini, code hanya tahu protocol/interface.
- **Extension** — memisahkan registration logic dari container logic (separation of concerns). File berbeda tapi class sama.
- **Separation: production vs preview** — 2 function untuk 2 context berbeda

---

## Penjelasan Code

### Extension pada DIContainer

```swift
extension DIContainer {
```

Ini bukan class baru — ini nambah method ke `DIContainer` yang sudah ada. Alasan pisah file:
- `DIContainer.swift` = generic container logic (bisa reuse di project lain)
- `DIContainer+Registrations.swift` = spesifik project ini (tahu TodoRepository, AppRouter, dll)

### registerAll (Production)

```swift
func registerAll(modelContainer: ModelContainer) {
    // MARK: - Singletons
    registerSingleton(AppRouter.self) {
        AppRouter()
    }

    // MARK: - Transient
    register(TodoRepositoryProtocol.self) {
        TodoRepository(modelContainer: modelContainer)
    }
}
```

**`modelContainer` parameter:**
- `ModelContainer` dibuat di `TodoListApp.init` (app entry point)
- Di-pass ke sini supaya `TodoRepository` bisa akses database
- Closure capture `modelContainer` — setiap kali resolve, buat `TodoRepository` baru dengan container yang sama

**AppRouter = Singleton karena:**
- Navigasi = global state. Hanya boleh 1 navigation path.
- Kalau transient, setiap screen dapat router beda = push/pop tidak terkoordinasi

**TodoRepositoryProtocol = Transient karena:**
- Stateless (tidak simpan data di instance, semua di SwiftData)
- Fresh instance = no stale reference
- Ringan (hanya menyimpan reference ke container)

**Perhatikan: register PROTOCOL, resolve PROTOCOL:**
```swift
// Register implementation ke interface key
register(TodoRepositoryProtocol.self) {  // key = "TodoRepositoryProtocol"
    TodoRepository(modelContainer: ...)  // value = concrete class
}

// Resolve pakai interface
let repo = resolve(TodoRepositoryProtocol.self)  // return TodoRepository
// repo dianggap sebagai TodoRepositoryProtocol
// caller tidak tahu (dan tidak perlu tahu) itu TodoRepository
```

### registerForPreviews (Mock)

```swift
func registerForPreviews() {
    registerSingleton(AppRouter.self) {
        AppRouter()
    }

    register(TodoRepositoryProtocol.self) {
        MockTodoRepository()
    }
}
```

Sama structure, beda implementation:
- `MockTodoRepository()` bukan `TodoRepository(modelContainer:)`
- Tidak butuh `ModelContainer` parameter — mock tidak pakai database
- Data dari `seedData()` di memory

**Kapan dipanggil:**
```swift
// Di Preview block
#Preview {
    DIContainer.shared.reset()
    DIContainer.shared.registerForPreviews()
    return HomeScreen()
}
```

---

## Analog TypeScript / NestJS

```typescript
// NestJS: AppModule = composition root
@Module({
    providers: [
        // Singleton (default scope)
        { provide: AppRouter, useClass: AppRouter },
        // Transient
        {
            provide: 'ITodoRepository',
            useFactory: (container) => new TodoRepository(container),
            scope: Scope.TRANSIENT,
            inject: [ModelContainer],
        },
    ],
})
export class AppModule {}

// Testing module
@Module({
    providers: [
        { provide: AppRouter, useClass: AppRouter },
        { provide: 'ITodoRepository', useClass: MockTodoRepository },
    ],
})
export class TestModule {}
```

---

## Alur Pemanggilan

```
App Start
    │
    ├── TodoListApp.init()
    │       │
    │       ├── ModelContainer created
    │       │
    │       └── DIContainer.shared.registerAll(modelContainer: container)
    │               │
    │               ├── registerSingleton(AppRouter.self) → instance dibuat
    │               │
    │               └── register(TodoRepositoryProtocol.self) → factory disimpan
    │
    ├── WindowGroup { MainTabView() }
    │       │
    │       └── HomeViewModel.init()
    │               │
    │               └── DIContainer.shared.resolve(TodoRepositoryProtocol.self)
    │                       │
    │                       └── factory() → TodoRepository(modelContainer:) → return
    │
    └── App running ✅
```

---

## Penggunaan

```swift
// Di TodoListApp.swift (dipanggil SEKALI)
init() {
    let container = try! ModelContainer(for: TodoItem.self, TodoCategory.self)
    DIContainer.shared.registerAll(modelContainer: container)
}

// Setelah ini, di mana saja:
let router = DIContainer.shared.resolve(AppRouter.self)     // singleton
let repo = DIContainer.shared.resolve(TodoRepositoryProtocol.self) // transient baru
```

---

## Dependency

- Depends on: `DIContainer.swift`, `AppRouter.swift`, `TodoRepository.swift`, `MockTodoRepository.swift`, `TodoRepositoryProtocol.swift`, `SwiftData`
- Dipakai oleh: `TodoListApp.swift` (registerAll), Preview blocks (registerForPreviews)

---

## Gotcha

- **Panggil `registerAll()` SEBELUM View apapun dibuat** — di `init()` App, bukan di `body`. Kalau di body, sudah terlambat (View init butuh resolve).
- **Jangan panggil `registerAll()` lebih dari sekali** — akan overwrite singleton dengan instance baru. Reset state navigation, dll.
- **Order register tidak penting** — tapi resolve harus setelah semua register selesai.
- **Kalau nanti tambah dependency baru** (misal AuthStore, APIService), tambahkan di sini. Ini satu-satunya file yang perlu diubah untuk wiring baru.
