# Destination.swift

**Lokasi:** `TodoList/Coordinator/Destination.swift`

---

## Tujuan

Enum yang mendefinisikan SEMUA route di app. Type-safe — compiler enforce bahwa setiap route valid dan bawa data yang benar. Single source of truth untuk navigasi.

---

## Konsep

- **Enum with associated values** — setiap case bisa bawa data berbeda
- **Hashable conformance** — requirement dari `NavigationPath` (SwiftUI)
- **Centralized routes** — 1 file, semua route. Refactor/rename otomatis propagate.

---

## Penjelasan Code

### Enum Declaration

```swift
enum Destination: Hashable {
```

**Kenapa `Hashable`?**
- `NavigationPath.append()` butuh `Hashable` value
- `.sheet(item:)` butuh `Identifiable` (yang kita handle via optional binding)
- Swift enum otomatis conform `Hashable` JIKA semua associated values juga `Hashable`

### Cases dengan PersistentIdentifier

```swift
case taskDetail(PersistentIdentifier)
case categoryFilter(PersistentIdentifier)
```

Bawa ID, bukan object. Alasan:
1. `@Model` class TIDAK auto-conform `Hashable` — harus implement manual
2. `PersistentIdentifier` sudah `Hashable` by default (lightweight, hanya ID)
3. Di screen tujuan, resolve ID → object via repository: `repo.fetchTodo(by: id)`
4. Avoid retain cycle / stale reference ke managed object

**Kenapa bukan `UUID`?**
- `UUID` (property `id` kita) berbeda dari `PersistentIdentifier` (SwiftData internal ID)
- `PersistentIdentifier` bisa langsung di-resolve via `context.model(for:)` — O(1) lookup
- `UUID` perlu full fetch + filter — lebih lambat

### Cases tanpa Data

```swift
case createTask
case createCategory
case search
```

Screen yang tidak butuh data untuk render. Form kosong, search kosong.

### Cases untuk Tabs (Future Use)

```swift
case dailyTask
case graph
case profile
case editProfile
```

Belum dipakai Phase 1, tapi sudah didefinisikan. Keuntungan:
- Deep linking nanti: `router.navigate(to: .profile)` dari notification
- Programmatic tab switch
- Tidak perlu tambah case + recompile nanti

---

## Analog TypeScript (React Navigation)

```typescript
// React Navigation
type RootStackParamList = {
    TaskDetail: { id: PersistentIdentifier }  // case taskDetail(PersistentIdentifier)
    CreateTask: undefined                      // case createTask
    CreateCategory: undefined                  // case createCategory
    CategoryFilter: { id: PersistentIdentifier }
    DailyTask: undefined
    Graph: undefined
    Profile: undefined
    EditProfile: undefined
    Search: undefined
}

// Navigate:
navigation.navigate('TaskDetail', { id: todo.persistentModelID })
// Swift:
router.navigate(to: .taskDetail(todo.persistentModelID))
```

**Keuntungan enum vs string routes:**

| String routes (RN) | Enum Destination (Swift) |
|---|---|
| Typo = runtime crash | Typo = compile error |
| Params type = manual check | Params type = compiler enforce |
| No autocomplete | Full autocomplete |
| Rename = search/replace | Rename = Xcode auto-refactor |

---

## Penggunaan

```swift
// Push navigation
router.navigate(to: .taskDetail(todo.persistentModelID))
router.navigate(to: .search)

// Sheet presentation
router.present(.createTask)
router.present(.createCategory)

// Di NavigationStack — exhaustive switch
.navigationDestination(for: Destination.self) { destination in
    switch destination {
    case .taskDetail(let id):
        TaskInfoScreen(todoId: id)
    case .createTask:
        CreateTaskScreen()
    case .categoryFilter(let id):
        CategoryScreen(categoryId: id)
    case .search:
        SearchTaskScreen()
    // ... semua case HARUS di-handle (compiler enforce)
    }
}
```

---

## Dependency

- Depends on: `SwiftData` (untuk `PersistentIdentifier` type)
- Dipakai oleh: `AppRouter.swift` (navigate/present param), semua View yang pakai `.navigationDestination`

---

## Gotcha

- **Tambah case baru = compile error di semua `switch`** — ini fitur, bukan bug. Compiler memastikan kamu handle route baru di semua tempat.
- **`PersistentIdentifier` belum ada saat object baru dibuat di memory** — hanya tersedia SETELAH `context.insert()`. Jangan navigate ke detail dari object yang belum di-persist.
- **Enum cases = value type** — `Destination.taskDetail(id)` bisa di-compare, hash, store di collection. Lightweight.
- **Jangan taruh logic di enum ini** — ini murni data definition. Logic routing ada di `AppRouter` dan View.
