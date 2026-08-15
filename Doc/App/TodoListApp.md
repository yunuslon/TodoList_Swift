# TodoListApp.swift

**Lokasi:** `TodoList/TodoListApp.swift`

---

## Tujuan

Entry point app. Setup ModelContainer (database), register semua dependencies di DI Container, dan render root view (MainTabView).

---

## Konsep

- **@main** — penanda entry point (hanya boleh 1 di seluruh project)
- **App protocol** — top-level structure SwiftUI app
- **Composition Root** — tempat semua wiring terjadi (DI registration)
- **ModelContainer** — "database connection" yang di-share ke seluruh app

---

## Penjelasan Code

### App Struct

```swift
@main
struct TodoListApp: App {
    let container: ModelContainer
```

- `@main` — compiler mulai eksekusi dari sini
- `App` protocol — wajib punya `body: some Scene`
- `container` stored property — persist sepanjang app lifecycle

### Init — Setup Everything

```swift
init() {
    let schema = Schema([TodoItem.self, TodoCategory.self])
    let config = ModelConfiguration("Listodo", isStoredInMemoryOnly: false)
    do {
        container = try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to create ModelContainer: \(error)")
    }

    DIContainer.shared.registerAll(modelContainer: container)
}
```

**Urutan critical:**
1. Buat Schema (daftarkan semua @Model types)
2. Buat Config (nama database "Listodo", stored on disk)
3. Buat Container (gagal = fatalError, app tidak bisa jalan tanpa DB)
4. Register ALL dependencies (DI Container siap sebelum View render)

**`isStoredInMemoryOnly: false`** — data persist ke disk (SQLite). Beda dengan PreviewContainer yang `true`.

**`fatalError`** — intentional crash. Kalau database tidak bisa dibuat, app tidak berguna.

**`DIContainer.shared.registerAll(modelContainer:)`** — composition root. Setelah ini, semua `resolve()` di ViewModel akan berhasil.

### Body — Root View

```swift
var body: some Scene {
    WindowGroup {
        MainTabView()
    }
    .modelContainer(container)
}
```

- `WindowGroup` — window utama (single window di iPhone)
- `MainTabView()` — root UI (TabView dengan 4 tabs)
- `.modelContainer(container)` — inject ke environment. Semua child View bisa akses via `@Environment(\.modelContext)`.

---

## Execution Order

```
1. App launch
2. TodoListApp.init()
   ├── ModelContainer created (SQLite ready)
   └── DIContainer.registerAll() (dependencies wired)
3. body evaluated
   ├── WindowGroup created
   ├── MainTabView rendered
   │   └── HomeScreen rendered
   │       └── HomeViewModel.init()
   │           └── DIContainer.resolve(TodoRepositoryProtocol.self) ← works!
   └── .modelContainer(container) injected to environment
4. HomeScreen .task { } triggers
   └── viewModel.loadData() → fetch from SwiftData
5. UI renders with data ✅
```

---

## Analog TypeScript (React Native)

```typescript
// App.tsx — entry point
function App() {
    const [container] = useState(() => {
        const db = new Database('Listodo.sqlite')
        DIContainer.shared.registerAll(db)
        return db
    })

    return (
        <DatabaseProvider database={container}>
            <NavigationContainer>
                <MainTabNavigator />
            </NavigationContainer>
        </DatabaseProvider>
    )
}

AppRegistry.registerComponent('TodoList', () => App)
```

---

## Dependency

- Depends on: `MainTabView`, `DIContainer`, `TodoItem`, `TodoCategory`, `SwiftData`
- Dipakai oleh: System (entry point)

---

## Gotcha

- **`init()` dipanggil SEBELUM `body`** — ini guarantee DI ready sebelum View render. Kalau DI setup di body, bisa race condition.
- **`fatalError` di init** — production app seharusnya handle gracefully (show error screen). Untuk learning project, crash OK.
- **Schema harus LENGKAP** — semua @Model class HARUS terdaftar di Schema. Kalau ada yang missing → crash saat fetch.
- **`ModelConfiguration("Listodo")`** — nama jadi filename SQLite: `Listodo.store`. Ganti nama = database baru (data lama hilang).
- **`.modelContainer` di WindowGroup** — inject ke environment SETELAH init. Berarti Views di dalam bisa pakai `@Environment(\.modelContext)`. Views di LUAR (kalau ada) tidak bisa.
