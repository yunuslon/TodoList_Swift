# CategoryScreen.swift

**Lokasi:** `TodoList/Views/Category/CategoryScreen.swift`

---

## Tujuan

Screen yang menampilkan task filtered by specific category. Di-navigate dari Home Screen saat user tap category (via push navigation).

---

## Konsep

- **PersistentIdentifier → resolve** — terima category ID, load dari ModelContext
- **Relationship access** — `category.items` = semua task di category itu
- **`@Environment(\.modelContext)`** — direct ModelContext access (simpler approach untuk read-only screen)

---

## Penjelasan Code

### Direct ModelContext (bukan via ViewModel)

```swift
@Environment(\.modelContext) private var context

@MainActor
private func loadCategory() {
    guard let cat = context.model(for: categoryId) as? TodoCategory else { return }
    category = cat
    todos = cat.items.sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
}
```

Screen ini simple (read-only, no complex logic) → langsung pakai ModelContext tanpa ViewModel terpisah. Ini pragmatic choice — tidak semua screen butuh ViewModel penuh.

**`context.model(for: categoryId)`** — resolve ID ke object. Same as repository pattern, tapi inline.

**`cat.items`** — SwiftData relationship. Otomatis return semua TodoItem yang punya `category == cat`.

**Sort:** `$0.dueDate ?? .distantPast` — nil dates diletakkan di awal (paling lama).

### Toggle langsung

```swift
TaskCardView(
    ...
    onToggle: {
        item.isCompleted.toggle()
        try? context.save()
    }
)
```

Karena punya akses langsung ke context, toggle bisa inline tanpa lewat repository. Mutate property → save.

---

## Analog React Native

```typescript
function CategoryScreen({ route }) {
    const { categoryId } = route.params
    const category = useCategoryById(categoryId)
    const todos = category?.items.sort((a, b) => a.dueDate - b.dueDate) ?? []

    return (
        <ScrollView>
            <Header title={category.name} count={todos.length} />
            {todos.map(item => <TaskCard key={item.id} {...item} />)}
        </ScrollView>
    )
}
```

---

## Dependency

- Depends on: `TaskCardView`, `EmptyStateView`, `AppColors`, `AppFonts`, `AppConstants`
- Dipakai oleh: `HomeScreen.swift` (via `.navigationDestination(.categoryFilter)`)

---

## Gotcha

- **`@Environment(\.modelContext)`** — hanya available kalau parent punya `.modelContainer()`. Di project ini, `TodoListApp` pasang `.modelContainer(container)` di WindowGroup, jadi semua child View dapat access.
- **Stale data** — kalau user toggle complete di sini, lalu back ke Home, Home perlu refresh. `.task` di Home handle ini otomatis.
- **Empty category** — bisa terjadi kalau semua task di-reassign/dihapus. Tampilkan EmptyStateView.
