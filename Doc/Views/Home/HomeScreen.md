# HomeScreen.swift

**Lokasi:** `TodoList/Views/Home/HomeScreen.swift`

---

## Tujuan

Screen utama app. Menampilkan daftar task grouped by Today/Future/Previous, category pills, search bar, dan FAB button. Ini tempat NavigationStack dan sheet routing di-setup.

---

## Konsep

- **NavigationStack(path:)** — programmatic navigation via AppRouter
- **`.navigationDestination(for:)`** — resolve Destination enum ke View
- **`.sheet(item:)`** — present sheet based on router state
- **`.task { }`** — load data saat View appear (auto-cancel saat disappear)
- **Composition** — View kecil (components) disusun jadi screen besar

---

## Penjelasan Code

### State & Dependencies

```swift
@State private var viewModel = HomeViewModel()
@State private var router = DIContainer.shared.resolve(AppRouter.self)
```

- `@State` — SwiftUI owns the lifecycle. Dibuat sekali, persist across re-renders.
- ViewModel di-init inline (resolve repository dari DI secara internal)
- Router di-resolve dari DI (singleton — semua screen share 1 router)

### NavigationStack Setup

```swift
NavigationStack(path: $router.path) {
    ZStack { ... }
    .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .taskDetail(let id): TaskInfoScreen(todoId: id)
        case .categoryFilter(let id): CategoryScreen(categoryId: id)
        ...
        }
    }
    .sheet(item: $router.presentedSheet) { destination in
        switch destination {
        case .createTask: CreateTaskScreen()
        case .createCategory: CreateCategorySheet()
        ...
        }
    }
}
```

**Alur:**
1. `router.navigate(to: .taskDetail(id))` → append ke `path`
2. NavigationStack detect path change → cari `.navigationDestination` yang match
3. Match `.taskDetail(let id)` → render `TaskInfoScreen(todoId: id)`
4. Push animation otomatis

**Sheet:**
1. `router.present(.createTask)` → set `presentedSheet = .createTask`
2. `.sheet(item:)` detect non-nil → present `CreateTaskScreen()`
3. User dismiss (swipe/cancel) → SwiftUI auto-set nil

### Destination: Identifiable Extension

```swift
extension Destination: Identifiable {
    var id: Int { hashValue }
}
```

`.sheet(item:)` butuh `Identifiable`. Pakai `hashValue` sebagai id — simple approach. Setiap enum case punya hash berbeda.

### Content Sections

```swift
private func taskSection(title: String, tasks: [TodoItem]) -> some View {
    VStack(alignment: .leading, spacing: AppConstants.cardSpacing) {
        Text(title)
        ForEach(tasks, id: \.id) { item in
            TaskCardView(...)
                .onTapGesture {
                    router.navigate(to: .taskDetail(item.persistentModelID))
                }
        }
    }
}
```

- `ForEach(tasks, id: \.id)` — loop items, keyed by UUID
- `.onTapGesture` — navigate ke detail saat tap card
- `item.persistentModelID` — SwiftData-generated unique identifier

### FAB Button

```swift
.overlay(alignment: .bottomTrailing) { fabButton }
```

`.overlay` = layer di atas content (floating). `alignment: .bottomTrailing` = bottom-right corner.

### Data Loading

```swift
.task {
    await viewModel.loadData()
}
.refreshable {
    await viewModel.loadData()
}
```

- `.task` — dipanggil saat View appear. Auto-cancel saat disappear. Juga re-trigger saat sheet dismiss (View reappear).
- `.refreshable` — pull-to-refresh gesture. Otomatis show spinner.

---

## Analog React Native

```typescript
function HomeScreen() {
    const vm = useHomeViewModel()
    const navigation = useNavigation()

    useEffect(() => { vm.loadData() }, [])

    return (
        <ScrollView refreshControl={<RefreshControl onRefresh={vm.loadData} />}>
            <AppHeader onSettingsTap={() => {}} />
            <SearchBar value={vm.searchText} onChange={vm.setSearchText} />
            <CategoryPills ... />
            {vm.todayTasks.length > 0 && <TaskSection title="Today" tasks={vm.todayTasks} />}
            {vm.futureTasks.length > 0 && <TaskSection title="Future" tasks={vm.futureTasks} />}
        </ScrollView>
        <FAB onPress={() => navigation.navigate('CreateTask')} />
    )
}
```

---

## Dependency

- Depends on: `HomeViewModel`, `AppRouter`, `Destination`, `DIContainer`, semua Components, `TaskInfoScreen`, `CreateTaskScreen`, `CreateCategorySheet`, `CategoryScreen`
- Dipakai oleh: `MainTabView.swift` (Tab 1)

---

## Gotcha

- **`@State private var router`** — ini resolve singleton. `@State` menjaga reference stable across re-renders. Tanpa `@State`, bisa re-resolve setiap render (walau singleton tetap sama object).
- **`.task` re-trigger setelah sheet dismiss** — ini behavior yang kita MAU. Data refresh otomatis setelah create task.
- **`item.persistentModelID`** — hanya available setelah object di-persist ke ModelContext. Fresh objects dari MockTodoRepository TIDAK punya valid persistentModelID.
- **No nested NavigationStack** — HomeScreen punya 1 NavigationStack. Screen yang di-push (TaskInfoScreen, CategoryScreen) TIDAK boleh punya NavigationStack sendiri.
