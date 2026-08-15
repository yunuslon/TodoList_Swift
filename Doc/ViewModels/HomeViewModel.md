# HomeViewModel.swift

**Lokasi:** `TodoList/ViewModels/HomeViewModel.swift`

---

## Tujuan

ViewModel utama untuk Home Screen. Mengelola state task list, categories, filtering, dan search. Semua business logic Home Screen ada di sini — View hanya render.

---

## Konsep

- **@Observable** — auto-notify View saat property berubah (iOS 17+)
- **@MainActor** — semua property/method di main thread (karena drive UI)
- **MVVM** — View observe ViewModel, ViewModel call Repository
- **Computed properties** — grouping/filtering dihitung dari `allTodos` (single source of truth)

---

## Penjelasan Code

### Class Declaration

```swift
@Observable
@MainActor
final class HomeViewModel {
    private let repository: TodoRepositoryProtocol
```

- `@Observable` — View yang baca `allTodos`, `categories`, dll otomatis re-render saat berubah
- `@MainActor` — guarantee UI-safe. Semua mutasi state di main thread.
- `private let repository` — DI: depend ke protocol, bukan concrete

### Init Pattern

```swift
init(repository: TodoRepositoryProtocol? = nil) {
    self.repository = repository ?? DIContainer.shared.resolve(TodoRepositoryProtocol.self)
}
```

**Dual-purpose init:**
- Production: `HomeViewModel()` → resolve dari DI container
- Testing/Preview: `HomeViewModel(repository: MockTodoRepository())` → inject manual

Optional param dengan `??` fallback = sweet spot antara DI purity dan convenience.

### State Properties

```swift
var allTodos: [TodoItem] = []        // Semua data dari DB
var categories: [TodoCategory] = []   // Semua categories
var selectedCategory: TodoCategory?   // Category filter aktif (nil = All)
var searchText: String = ""           // Search query
var isLoading: Bool = false           // Loading indicator
var error: String?                    // Error message
```

Ini "state" yang View observe. Setiap perubahan = re-render.

### Computed Groupings (Derived State)

```swift
var todayTasks: [TodoItem] {
    filteredTodos.filter { $0.isToday && !$0.isCompleted }
}

var futureTasks: [TodoItem] {
    filteredTodos.filter { $0.isFuture && !$0.isCompleted }
}

var previousTasks: [TodoItem] {
    filteredTodos.filter { $0.isPrevious || $0.isCompleted }
}
```

**Kenapa computed bukan stored?**
- Single source of truth = `allTodos`
- Grouping otomatis update saat `allTodos` berubah
- Tidak perlu manual sync 4 arrays
- Sama seperti `useMemo` di React — derived dari state lain

### Private Filtering

```swift
private var filteredTodos: [TodoItem] {
    var result = allTodos
    if let selectedCategory {
        result = result.filter { $0.category?.id == selectedCategory.id }
    }
    if !searchText.isEmpty {
        result = result.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    return result
}
```

Pipeline: allTodos → filter by category → filter by search → grouping. Semua di-chain.

### loadData()

```swift
func loadData() async {
    isLoading = true
    error = nil
    do {
        allTodos = try await repository.fetchAllTodos()
        categories = try await repository.fetchAllCategories()
    } catch {
        self.error = error.localizedDescription
    }
    isLoading = false
}
```

- `isLoading = true` SEBELUM fetch (show spinner)
- `error = nil` — reset error sebelumnya
- `do/catch` — handle fetch failure
- `isLoading = false` SETELAH (hide spinner, regardless success/fail)

**PENTING:** Dipanggil via `.task { await viewModel.loadData() }` di View. Juga dipanggil ulang setelah mutasi (add/delete/toggle).

### selectCategory()

```swift
func selectCategory(_ category: TodoCategory?) {
    if selectedCategory?.id == category?.id {
        selectedCategory = nil  // Deselect (toggle off)
    } else {
        selectedCategory = category
    }
}
```

Toggle behavior: tap active category → deselect (show all). Tap inactive → select.

---

## Analog TypeScript (React)

```typescript
// Zustand store / custom hook equivalent
function useHomeViewModel() {
    const [allTodos, setAllTodos] = useState<TodoItem[]>([])
    const [categories, setCategories] = useState<TodoCategory[]>([])
    const [selectedCategory, setSelectedCategory] = useState<TodoCategory | null>(null)
    const [searchText, setSearchText] = useState('')

    const filteredTodos = useMemo(() => {
        let result = allTodos
        if (selectedCategory) result = result.filter(t => t.category?.id === selectedCategory.id)
        if (searchText) result = result.filter(t => t.title.includes(searchText))
        return result
    }, [allTodos, selectedCategory, searchText])

    const todayTasks = useMemo(() => filteredTodos.filter(t => t.isToday && !t.isCompleted), [filteredTodos])
    const futureTasks = useMemo(() => filteredTodos.filter(t => t.isFuture && !t.isCompleted), [filteredTodos])

    const loadData = async () => { ... }
    const toggleComplete = async (item) => { ... }

    return { allTodos, todayTasks, futureTasks, loadData, ... }
}
```

---

## Dependency

- Depends on: `TodoRepositoryProtocol`, `TodoItem`, `TodoCategory`, `DIContainer`
- Dipakai oleh: `HomeScreen.swift`

---

## Gotcha

- **`loadData()` harus dipanggil ulang setelah mutasi** — karena manual fetch (bukan @Query auto-refresh)
- **`selectedCategory` = reference ke @Model object** — kalau category dihapus tapi masih selected, bisa stale. `loadData()` ulang akan fix.
- **Computed properties dihitung setiap akses** — untuk ratusan items fine. Kalau ribuan, consider caching.
