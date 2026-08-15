# PreviewContainer.swift

**Lokasi:** `TodoList/Preview Content/PreviewContainer.swift`

---

## Tujuan

In-memory SwiftData container dengan sample data untuk Xcode Previews. Supaya preview bisa render data tanpa database asli.

---

## Konsep

- **In-memory container** — data TIDAK disimpan ke disk, hilang saat preview di-refresh
- **Seeding** — pre-populate dengan data representatif (campuran today/tomorrow/yesterday, completed/uncompleted)
- **Isolated** — tidak affect data production di simulator/device

---

## Penjelasan Code

### Container Setup

```swift
let schema = Schema([TodoItem.self, TodoCategory.self])
let config = ModelConfiguration(isStoredInMemoryOnly: true)
container = try ModelContainer(for: schema, configurations: [config])
```

- `Schema` — definisikan model mana yang included
- `isStoredInMemoryOnly: true` — KEY DIFFERENCE dari production. No SQLite file.
- Kalau gagal bikin container → `fatalError` (preview env, crash = OK)

### Seed Data

```swift
@MainActor
private func seedData() {
    let context = container.mainContext

    let work = TodoCategory(name: "Work", colorHex: "#F8CD7A")
    // ... insert categories

    let today = Calendar.current.startOfDay(for: .now)
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
    // ... insert todos with mixed dates
}
```

- `@MainActor` — karena akses `mainContext`
- Campuran data: 3 categories, 7 todos (today/tomorrow/yesterday, completed/not)
- Ini membuat preview HomeScreen langsung terlihat 3 section

### Penggunaan di #Preview

```swift
#Preview {
    HomeScreen()
        .modelContainer(PreviewContainer().container)
}
```

`.modelContainer()` — inject container ke environment. Semua child View yang akses `@Environment(\.modelContext)` akan pakai container ini.

---

## Analog TypeScript

```typescript
// Mock data untuk Storybook / component preview
const mockContainer = {
    categories: [
        { id: '1', name: 'Work', colorHex: '#F8CD7A' },
        { id: '2', name: 'Personal', colorHex: '#9B60F7' },
    ],
    todos: [
        { id: '1', title: 'Meeting', dueDate: new Date(), category: '1' },
        // ...
    ],
}

// Provider wrapper
<MockDataProvider data={mockContainer}>
    <HomeScreen />
</MockDataProvider>
```

---

## Dependency

- Depends on: `TodoItem`, `TodoCategory`, `SwiftData`
- Dipakai oleh: `#Preview` blocks di semua Views

---

## Gotcha

- **`@MainActor` di `seedData()`** — WAJIB karena akses `mainContext`. Tanpa ini = compile error.
- **Data hilang setiap refresh preview** — ini expected. In-memory = volatile.
- **`PreviewContainer()` buat container BARU setiap kali** — setiap preview instance punya data fresh. Tidak share antar preview blocks.
- **Jangan pakai di production** — `isStoredInMemoryOnly: true` berarti data hilang saat app close.
