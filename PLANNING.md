# Listodo — Planning & Step-by-Step Guide

Panduan pengerjaan berurutan. Setiap step bisa di-compile (`Cmd+B`) sebelum lanjut.

---

## Pre-requisites

Sebelum mulai coding:

- [ ] Buka project `TodoList.xcodeproj` di Xcode
- [ ] Pastikan target iOS 17.0+
- [ ] Download font `PlayfairDisplay-ExtraBold.ttf` dari [Google Fonts](https://fonts.google.com/specimen/Playfair+Display)
- [ ] Buat folder groups di Xcode sesuai structure di SPEC.md (atau buat saat nulis file)

### Cara buat folder group di Xcode:
1. Klik kanan folder `TodoList/` → New Group
2. Rename sesuai nama (Theme, Extensions, DI, Coordinator, Models, dll)
3. JANGAN pakai "New Folder" dari Finder — harus via Xcode supaya masuk target

---

## Step 1 — Foundation (Theme & Extensions)

### 1.1 `Extensions/Color+Hex.swift`

**Tujuan:** Extension `Color` agar bisa init dari hex string.

**Yang perlu ditulis:**
- `extension Color` dengan `init(hex: String)`
- Handle 3 kasus: RGB 3 digit, RGB 6 digit, ARGB 8 digit
- Pakai `Scanner` untuk parse hex → `UInt64`
- Convert ke `Double` (0-1 range) untuk `Color(.sRGB, red:green:blue:opacity:)`

**Analog TypeScript:**
```typescript
// Seperti utility function hexToRgba()
const hexToColor = (hex: string) => { r, g, b, a }
```

**Verify:** Compile (`Cmd+B`). Belum ada UI yang pakai, tapi harus zero error.

---

### 1.2 `Extensions/Date+Formatting.swift`

**Tujuan:** Helper untuk date comparison dan formatting.

**Yang perlu ditulis:**
- `extension Date` dengan computed properties:
  - `isToday: Bool` — pakai `Calendar.current.isDateInToday(self)`
  - `isFuture: Bool` — `self > .now && !isToday`
  - `isPast: Bool` — `self < Calendar.current.startOfDay(for: .now)`
- Helper formatting:
  - `formatted(style:) -> String` — DateFormatter
  - `timeFormatted() -> String` — "HH:mm"
  - `relativeFormatted() -> String` — RelativeDateTimeFormatter
  - `static func today() -> Date` — start of today

**Analog TypeScript:**
```typescript
// Seperti dayjs().isToday(), format('HH:mm'), fromNow()
```

**Verify:** `Cmd+B` ✅

---

### 1.3 `Theme/AppColors.swift`

**Tujuan:** Centralized color constants dari Figma.

**Yang perlu ditulis:**
- `enum AppColors` (enum tanpa case = namespace, seperti static class)
- Semua warna dari SPEC.md section "Design System > Colors"
- Import SwiftUI (untuk akses `Color`)
- Pakai `Color(hex:)` dari extension yang baru dibuat

**Referensi:** Lihat SPEC.md section "Colors"

**Tips:**
- Pakai `enum` bukan `struct` untuk prevent instantiation
- Group dengan `// MARK: -` comments

**Verify:** `Cmd+B` ✅

---

### 1.4 `Theme/AppFonts.swift`

**Tujuan:** Font helpers yang consistent.

**Yang perlu ditulis:**
- `enum AppFonts` dengan static functions:
  - `brand(size:) -> Font` — `.custom("PlayfairDisplay-ExtraBold", size:)`
  - `sectionTitle() -> Font` — `.system(size: 18, weight: .medium)`
  - `body(weight:) -> Font` — `.system(size: 16, weight:)`
  - `caption() -> Font` — `.system(size: 14, weight: .regular)`
  - `small(weight:) -> Font` — `.system(size: 12, weight:)`

**Catatan:** Custom font belum akan muncul sampai `.ttf` di-register di Info.plist.
Untuk sementara tetap tulis `.custom(...)` — akan fallback ke system font.

**Verify:** `Cmd+B` ✅

---

### 1.5 `Theme/AppConstants.swift`

**Tujuan:** Magic numbers di satu tempat.

**Yang perlu ditulis:**
- `enum AppConstants` dengan static properties:
  - Spacing: `paddingHorizontal`, `paddingVertical`, `cardSpacing`, `sectionSpacing`
  - Corner radius: `cardRadius(16)`, `pillRadius(39)`, `buttonRadius(39)`
  - Heights: `taskCardHeight(80)`, `searchBarHeight(48)`, `categoryPillHeight(32)`, dll
  - Icon sizes: `iconSmall(20)`, `iconMedium(24)`, `iconLarge(32)`

**Referensi:** Lihat SPEC.md section "Component Specs" dan "Layout"

**Verify:** `Cmd+B` ✅

---

## Step 2 — Data Layer

### 2.1 `Models/TodoItem.swift`

**Tujuan:** SwiftData model untuk task.

**Yang perlu ditulis:**
- `import SwiftData`
- `@Model final class TodoItem` dengan properties:
  - `var id: UUID`
  - `var title: String`
  - `var subtitle: String`
  - `var isCompleted: Bool`
  - `var dueDate: Date?`
  - `var createdAt: Date`
  - `var priority: Int` (0/1/2 — BUKAN enum di dalam @Model)
  - `var category: TodoCategory?`
- Init dengan default values
- `enum TaskPriority: Int, CaseIterable, Identifiable` — DI LUAR @Model class
- Computed extension: `taskPriority`, `isToday`, `isFuture`, `isPrevious`, `cardColorHex`

**Gotcha:**
- `priority` harus `Int`, bukan enum (SwiftData predicate limitation)
- `TaskPriority` enum letaknya DI LUAR class, bukan nested

**Verify:** `Cmd+B` — akan error karena `TodoCategory` belum ada. Ini expected, lanjut ke 2.2.

---

### 2.2 `Models/TodoCategory.swift`

**Tujuan:** SwiftData model untuk category.

**Yang perlu ditulis:**
- `@Model final class TodoCategory`
- Properties: `id: UUID`, `name: String`, `colorHex: String`
- `@Relationship(deleteRule: .nullify, inverse: \TodoItem.category) var items: [TodoItem] = []`
- Init
- Extension dengan `static let predefinedColors` (array of tuples: name + hex)

**Gotcha:**
- Inverse relationship HARUS match dengan property di TodoItem
- `deleteRule: .nullify` → hapus category, task tetap ada (category jadi nil)

**Verify:** `Cmd+B` ✅ (sekarang TodoItem juga resolve)

---

### 2.3 `Repositories/TodoRepositoryProtocol.swift`

**Tujuan:** Protocol (interface) untuk repository — testable.

**Yang perlu ditulis:**
- `import SwiftData` (untuk `PersistentIdentifier`)
- `protocol TodoRepositoryProtocol`
- Methods:
  - `func fetchAllTodos() async throws -> [TodoItem]`
  - `func fetchTodos(for category: TodoCategory?) async throws -> [TodoItem]`
  - `func addTodo(_ item: TodoItem) async throws`
  - `func updateTodo(_ item: TodoItem) async throws`
  - `func deleteTodo(_ item: TodoItem) async throws`
  - `func toggleComplete(_ item: TodoItem) async throws`
  - `func fetchAllCategories() async throws -> [TodoCategory]`
  - `func addCategory(_ category: TodoCategory) async throws`
  - `func deleteCategory(_ category: TodoCategory) async throws`
  - `func fetchTodo(by id: PersistentIdentifier) async throws -> TodoItem?`
  - `func fetchCategory(by id: PersistentIdentifier) async throws -> TodoCategory?`

**Analog TypeScript:**
```typescript
interface ITodoRepository {
    fetchAllTodos(): Promise<TodoItem[]>
    addTodo(item: TodoItem): Promise<void>
    // ...
}
```

**Verify:** `Cmd+B` ✅

---

### 2.4 `Repositories/MockTodoRepository.swift`

**Tujuan:** In-memory mock untuk Preview dan testing.

**Yang perlu ditulis:**
- `final class MockTodoRepository: TodoRepositoryProtocol`
- Internal arrays: `var todos: [TodoItem]`, `var categories: [TodoCategory]`
- `init()` yang call `seedData()` — buat sample data
- Implement semua protocol methods dengan operasi array biasa
- `fetchTodo(by:)` dan `fetchCategory(by:)` return nil (mock tidak pakai PersistentIdentifier)

**Tips untuk seedData():**
- Buat 3 categories (Work, Personal, Health)
- Buat 5-7 todos dengan campuran: today, tomorrow, yesterday, completed/uncompleted

**Verify:** `Cmd+B` ✅

---

### 2.5 `Repositories/TodoRepository.swift`

**Tujuan:** Real SwiftData implementation.

**Yang perlu ditulis:**
- `final class TodoRepository: TodoRepositoryProtocol`
- `private let modelContainer: ModelContainer`
- Init terima `modelContainer`
- Computed property: `@MainActor private var context: ModelContext { modelContainer.mainContext }`
- Semua method pakai `await MainActor.run { ... }` untuk akses context

**Pattern untuk setiap method:**
```swift
func fetchAllTodos() async throws -> [TodoItem] {
    let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.dueDate)])
    return try await MainActor.run {
        try context.fetch(descriptor)
    }
}

func addTodo(_ item: TodoItem) async throws {
    await MainActor.run {
        context.insert(item)
        try? context.save()
    }
}
```

**Gotcha:**
- SEMUA akses ke `context` harus di dalam `MainActor.run {}`
- `try? context.save()` — pakai `try?` untuk simplicity (SwiftData auto-save juga)
- Untuk `fetchTodos(for:)` — fetch all lalu filter di Swift (jangan complex predicate)

**Verify:** `Cmd+B` ✅

---

## Step 3 — DI & Coordinator

### 3.1 `DI/DIContainer.swift`

**Tujuan:** Simple DI container (register/resolve pattern).

**Yang perlu ditulis:**
- `final class DIContainer`
- `static let shared = DIContainer()` (singleton)
- `private init()` (prevent external init)
- Storage: `private var factories: [String: () -> Any]` dan `private var singletons: [String: Any]`
- Methods:
  - `func register<T>(_ type: T.Type, factory: @escaping () -> T)` — simpan factory
  - `func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T)` — langsung buat & simpan instance
  - `func resolve<T>(_ type: T.Type) -> T` — cek singletons dulu, lalu factories, `fatalError` kalau tidak ada
  - `func reset()` — untuk testing

**Key pattern:** `String(describing: type)` sebagai dictionary key.

**Analog NestJS:**
```typescript
// register() = @Injectable({ scope: Scope.TRANSIENT })
// registerSingleton() = @Injectable({ scope: Scope.DEFAULT })
// resolve() = @Inject(TOKEN)
```

**Verify:** `Cmd+B` ✅

---

### 3.2 `Coordinator/Destination.swift`

**Tujuan:** Type-safe routes untuk semua navigasi.

**Yang perlu ditulis:**
- `import SwiftData` (untuk `PersistentIdentifier`)
- `enum Destination: Hashable` dengan cases:
  - `.taskDetail(PersistentIdentifier)`
  - `.createTask`
  - `.createCategory`
  - `.categoryFilter(PersistentIdentifier)`
  - `.dailyTask`
  - `.graph`
  - `.profile`
  - `.editProfile`
  - `.search`

**Analog React Navigation:**
```typescript
type RootStackParamList = {
    TaskDetail: { id: string }
    CreateTask: undefined
    // ...
}
```

**Verify:** `Cmd+B` ✅

---

### 3.3 `Coordinator/AppRouter.swift`

**Tujuan:** Centralized navigation manager.

**Yang perlu ditulis:**
- `@Observable @MainActor final class AppRouter`
- Properties:
  - `var path = NavigationPath()`
  - `var presentedSheet: Destination?`
  - `var presentedFullScreen: Destination?`
- Methods:
  - `func navigate(to:)` — `path.append(destination)`
  - `func goBack()` — `path.removeLast()` (guard isEmpty)
  - `func popToRoot()` — `path = NavigationPath()`
  - `func present(_:)` — set `presentedSheet`
  - `func presentFullScreen(_:)` — set `presentedFullScreen`
  - `func dismissSheet()` — set nil
  - `func dismissFullScreen()` — set nil

**Analog React Navigation:**
```typescript
// navigate(to:) = navigation.navigate('Screen', params)
// goBack() = navigation.goBack()
// popToRoot() = navigation.popToTop()
// present() = navigation.navigate('Modal')
```

**Verify:** `Cmd+B` ✅

---

### 3.4 `DI/DIContainer+Registrations.swift`

**Tujuan:** Composition root — register semua dependency di 1 tempat.

**Yang perlu ditulis:**
- `extension DIContainer`
- `func registerAll(modelContainer: ModelContainer)`:
  - `registerSingleton(AppRouter.self) { AppRouter() }`
  - `register(TodoRepositoryProtocol.self) { TodoRepository(modelContainer: modelContainer) }`
- `func registerForPreviews()`:
  - `registerSingleton(AppRouter.self) { AppRouter() }`
  - `register(TodoRepositoryProtocol.self) { MockTodoRepository() }`

**Catatan:** Import `SwiftData` untuk `ModelContainer`.

**Verify:** `Cmd+B` ✅

---

## Step 4 — Reusable Components

Mulai dari sini, kamu bisa lihat Figma sebagai referensi visual.
Gunakan MCP `render_images` dengan node ID dari SPEC.md kalau perlu.

### 4.1 `Views/Components/TaskCardView.swift`

**Referensi Figma:** Home screen task cards (node `1:4257`)

**Yang perlu ditulis:**
- `struct TaskCardView: View`
- Props: `title`, `subtitle`, `colorHex`, `isCompleted`, `onToggle: () -> Void`
- Layout: `HStack` → checkbox (Circle) + VStack(title, subtitle) + Spacer + priority dot
- Styling:
  - Background: `RoundedRectangle(cornerRadius: 16).fill(Color(hex:).opacity(0.15))`
  - Height: 80
  - Checkbox: Circle with strokeBorder, checkmark overlay saat completed
  - Strikethrough text saat completed
- Tambahkan `#Preview`

---

### 4.2 `Views/Components/CategoryPillView.swift`

**Referensi Figma:** Category pills di Create Task screen (node `1:4336`)

**Yang perlu ditulis:**
- `struct CategoryPillView: View` — props: `name`, `colorHex`, `isSelected`, `action`
- `struct AddCategoryPillView: View` — props: `action` (tombol "+" dashed border)
- Selected state: Capsule filled dengan color
- Unselected: Capsule stroke border only
- Tambahkan `#Preview`

---

### 4.3 `Views/Components/SearchBarView.swift`

**Referensi Figma:** Search bar di Create Task screen

**Yang perlu ditulis:**
- `struct SearchBarView: View`
- Props: `@Binding var text: String`, `placeholder`, `onFilterTap: (() -> Void)?`
- Layout: HStack → magnifying glass icon + TextField + optional "Filter" button (Capsule purple)
- Styling: Capsule strokeBorder, height 48
- Tambahkan `#Preview`

---

### 4.4 `Views/Components/EmptyStateView.swift`

**Referensi Figma:** Empty home screen (node `1:5500`)

**Yang perlu ditulis:**
- `struct EmptyStateView: View`
- Props: `title`, `subtitle` (with defaults)
- Layout: VStack centered → icon + title text + subtitle text
- Pakai SF Symbol (misalnya `checklist`) sebagai placeholder icon
- Tambahkan `#Preview`

---

### 4.5 `Views/Components/AppHeaderView.swift`

**Referensi Figma:** Header "Listodo" + badge + settings icon

**Yang perlu ditulis:**
- `struct AppHeaderView: View`
- Props: `onSettingsTap: (() -> Void)?`
- Layout: HStack → "Listodo" brand font + "Pro" gold badge (Capsule) + Spacer + settings button (Circle border)
- Badge: rotated slightly (`rotationEffect(.degrees(-2))`)
- Tambahkan `#Preview`

---

**Verify semua components:** `Cmd+B` ✅

---

## Step 5 — Screens & ViewModels

### 5.1 `ViewModels/HomeViewModel.swift`

**Yang perlu ditulis:**
- `@Observable @MainActor final class HomeViewModel`
- `private let repository: TodoRepositoryProtocol`
- State: `allTodos`, `categories`, `selectedCategory`, `searchText`, `isLoading`, `error`
- Init: resolve dari DIContainer (dengan default param)
- Computed: `todayTasks`, `futureTasks`, `previousTasks`, `hasNoTasks`, `filteredTodos`(private)
- Actions: `loadData()`, `toggleComplete(_:)`, `deleteTodo(_:)`, `selectCategory(_:)`

**Gotcha init pattern:**
```swift
// ✅ Ini aman karena resolve() sendiri bukan async
init(repository: TodoRepositoryProtocol? = nil) {
    self.repository = repository ?? DIContainer.shared.resolve(TodoRepositoryProtocol.self)
}
```

---

### 5.2 `Views/Home/HomeScreen.swift`

**Referensi Figma:** node `1:4257`

**Yang perlu ditulis:**
- `struct HomeScreen: View`
- `@State private var viewModel = HomeViewModel()`
- Get `AppRouter` dari DI atau `@Environment`
- Layout utama:
  - `AppHeaderView`
  - `SearchBarView` (bound to `viewModel.searchText`)
  - Category pills (horizontal ScrollView)
  - "Today task" section → list of `TaskCardView`
  - "Future" section
  - "Previous" section
- `.task { await viewModel.loadData() }`
- Navigation: `.navigationDestination(for: Destination.self)`
- FAB button (floating, bottom-right) untuk create task → `router.present(.createTask)`

**Tips:**
- Pakai `ScrollView` bukan `List` (lebih cocok untuk design custom ini)
- Conditional: tampilkan `EmptyStateView` kalau `viewModel.hasNoTasks`

---

### 5.3 `Views/Home/EmptyHomeView.swift`

**Referensi Figma:** node `1:5500`

**Yang perlu ditulis:**
- Wrapper view khusus empty state home
- Bisa langsung pakai `EmptyStateView` component dengan custom text/icon
- Atau buat layout lebih elaborate sesuai Figma

---

### 5.4 `ViewModels/CreateTaskViewModel.swift`

**Yang perlu ditulis:**
- `@Observable @MainActor final class CreateTaskViewModel`
- Form state: `title`, `subtitle`, `dueDate`, `priority`, `selectedCategory`
- `categories: [TodoCategory]` (loaded dari repo)
- Actions: `loadCategories()`, `save()` → create TodoItem, insert via repo
- Validation: `var canSave: Bool { !title.isEmpty }`

---

### 5.5 `Views/Task/CreateTaskScreen.swift`

**Referensi Figma:** node `1:4336`

**Yang perlu ditulis:**
- Sheet/full screen form
- Fields: title TextField, subtitle TextField, DatePicker (dueDate), priority picker, category picker
- "Save" button (disabled saat `!canSave`)
- Dismiss setelah save

---

### 5.6 `ViewModels/TaskDetailViewModel.swift`

**Yang perlu ditulis:**
- `@Observable @MainActor final class TaskDetailViewModel`
- `var todo: TodoItem?`
- Init terima `PersistentIdentifier`, resolve TodoItem dari repo
- Actions: `loadTodo()`, `toggleComplete()`, `deleteTodo()`
- `var showDeleteConfirmation: Bool`

---

### 5.7 `Views/Task/TaskInfoScreen.swift`

**Referensi Figma:** node `1:5378`

**Yang perlu ditulis:**
- Detail view: title, subtitle, due date, priority, category
- Toggle complete button
- Delete button (trigger confirmationDialog)
- Edit action (optional Phase 1)

---

### 5.8 `Views/Task/DeleteTaskDialog.swift`

**Referensi Figma:** node `1:5433`

**Yang perlu ditulis:**
- Bisa pakai `.confirmationDialog` modifier di TaskInfoScreen
- ATAU buat custom overlay dialog sesuai Figma (dark overlay + card)
- 2 buttons: "Cancel" + "Delete" (destructive)

---

### 5.9 `Views/Category/CreateCategorySheet.swift`

**Referensi Figma:** node `1:4455`

**Yang perlu ditulis:**
- Sheet: name TextField + color picker (predefined hex options)
- Save button
- Simple — bisa selesai cepat

---

### 5.10 `Views/Category/CategoryScreen.swift`

**Referensi Figma:** node `1:4691`

**Yang perlu ditulis:**
- Filtered list view by category
- Bisa reuse `TaskCardView` components
- Header: category name + back button

---

**Verify semua screens:** `Cmd+B` ✅

---

## Step 6 — App Shell (Wiring)

### 6.1 `Views/MainTabView.swift`

**Yang perlu ditulis:**
- `TabView` dengan 4 tabs
- Tab 1: `HomeScreen()` — active
- Tab 2-4: Placeholder views (`Text("Coming Soon")`)
- Custom tab bar styling (dark background, purple active color)
- SF Symbols: `house`, `calendar`, `chart.bar`, `person`

---

### 6.2 `Preview Content/PreviewContainer.swift`

**Yang perlu ditulis:**
- Struct dengan `let container: ModelContainer`
- Init: buat `ModelContainer` dengan `isStoredInMemoryOnly: true`
- `@MainActor private func seedData()` — insert sample categories + todos
- Dipakai di `#Preview` blocks:
  ```swift
  #Preview {
      HomeScreen()
          .modelContainer(PreviewContainer().container)
  }
  ```

---

### 6.3 Update `TodoListApp.swift`

**Yang perlu ditulis:**
- Setup `ModelContainer` untuk TodoItem + TodoCategory
- `init()` → `DIContainer.shared.registerAll(modelContainer:)`
- Body: `MainTabView().modelContainer(container)`

```swift
@main
struct TodoListApp: App {
    let container: ModelContainer

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

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
```

---

### 6.4 Hapus `ContentView.swift`

File template bawaan Xcode — sudah tidak dipakai. Hapus dari project.

---

## Final Verify

- [ ] `Cmd+B` — zero errors
- [ ] Run di Simulator — app tampil dengan tab bar
- [ ] Tab 1 (Home) menampilkan empty state atau data
- [ ] Tap "+" bisa buka create task sheet
- [ ] Bisa create task, muncul di list
- [ ] Bisa toggle complete
- [ ] Bisa swipe/tap delete

---

## Tips Selama Pengerjaan

1. **Compile setiap selesai 1 file** — jangan numpuk error
2. **Pakai `#Preview`** di setiap component/screen untuk lihat visual tanpa run full app
3. **Lihat Figma** kalau ragu layout — render via MCP: `render_images(file_key, ids, scale: 2)`
4. **Kalau stuck compile error** — baca error message dari bawah (yang paling spesifik biasanya di bawah)
5. **SwiftData error "failed to find..."** — pastikan model sudah masuk Schema di TodoListApp
6. **Font tidak muncul** — cek nama di `UIFont.fontNames(forFamilyName:)`, sering beda dari filename
