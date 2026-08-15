# Listodo — Project Specification

## Overview

Real-world todo app built from scratch using SwiftUI + Architecture L2 (Coordinator + DI Container).
Based on Figma design: "Listodo - Todo List App UI Kit"
Figma file key: `UxMhMOiPU1FX4M5IrTfdHv`

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Persistence | SwiftData (@Model, @Query) |
| Architecture | MVVM + Coordinator + DI Container (L2) |
| Navigation | NavigationStack + Destination enum + AppRouter |
| State | @Observable (Observation framework) |
| Charts | Swift Charts (Phase 2) |
| Target | iPhone, iOS 17+ |
| Toolchain | Xcode 16+ / Swift 5.9+ |

---

## Design System (dari Figma)

### Colors

```swift
// Background
let background = Color(hex: "#0B011A")        // Very dark purple
let cardBackground = Color(hex: "#0E0E0E")    // Dark card header area

// Accent
let primaryPurple = Color(hex: "#9B60F7")     // Purple accent (buttons, highlights)
let accentGold = Color(hex: "#F8CD7A")        // Gold/yellow (category pills, badges)

// Task Card (background with opacity)
let taskCardRed = Color(hex: "#FF5959").opacity(0.15)  // Red card at 15%
let taskCardBlue = Color(hex: "#5959FF").opacity(0.15) // Blue variant
let taskCardGreen = Color(hex: "#59FF59").opacity(0.15) // Green variant

// Text
let textPrimary = Color.white
let textSecondary = Color(hex: "#616161")     // Placeholder/muted text

// Border
let borderColor = Color(hex: "#3A3A3A")       // Subtle borders
```

### Typography

| Usage | Font | Weight | Size |
|---|---|---|---|
| App Logo/Brand | Playfair Display | ExtraBold (800) | 24 |
| Section Title | Roboto | Medium (500) | 18 |
| Body/Card Title | Roboto | Medium (500) | 16 |
| Card Subtitle | Roboto | Regular (400) | 14 |
| Category Pill | Roboto | Medium (500) | 12 |
| Search Placeholder | Roboto | Regular (400) | 14 |

### Component Specs

| Component | Corner Radius | Height | Notes |
|---|---|---|---|
| Task Card | 16 | 80 | Background color at 15% opacity |
| Search Bar | 39 (full pill) | 48 | Border 1px #3A3A3A |
| Category Pill | 39 (full pill) | 32 | Filled (active) or bordered (inactive) |
| Action Button | 39 (full pill) | 48 | Purple filled |
| Settings Icon Circle | 24 (full circle) | 48x48 | Border #3A3A3A |
| Add Category Button | 16 | 32 | Dashed border |
| Bottom Tab Bar | — | 56 | 4 tabs |

### Layout

- Screen width: 360 (design), responsive
- Horizontal padding: 16
- Grid: 4 columns, gutter 16
- Card spacing (vertical): 8
- Section spacing: 16-24

---

## Screens & Navigation Flow

### Prototype Flow (dari Figma)

```
Splash Screen (0.8s auto)
    → Get Start
        → Fill Name (step 1)
            → Fill Name (step 2)
                → Home Screen

Home Screen (Tab 1 - default)
    → Task Info (tap card)
        → Delete Task (dialog)
    → Create Task (FAB / add button)
        → Create Category (from create task)

Daily Task (Tab 2)
    → Task Info

Graph Screen (Tab 3)

Profile & Setting (Tab 4)
    → Edit Profile
    → Search Task (from search bar on Home)

Category View (from category pill on Home)
    → Filter by category
```

### Tab Bar Structure

| Tab | Icon | Screen | Status |
|---|---|---|---|
| 1 | Home | HomeScreen | Phase 1 |
| 2 | Calendar | DailyTaskScreen | Phase 2 |
| 3 | Chart | GraphScreen | Phase 2 |
| 4 | Person | ProfileScreen | Phase 2 |

---

## Data Models

### TodoItem (@Model — SwiftData)

```swift
@Model
final class TodoItem {
    var id: UUID
    var title: String
    var subtitle: String           // Optional description
    var isCompleted: Bool
    var dueDate: Date?
    var createdAt: Date
    var category: TodoCategory?    // Relationship
    var priority: Int              // 0=low, 1=medium, 2=high (lihat catatan di bawah)
}
```

> **Kenapa `priority: Int` bukan nested enum?**
> SwiftData `#Predicate` macro punya limitasi — tidak support semua expression,
> termasuk enum comparison di dalam predicate. Pakai `Int` supaya bisa di-query
> langsung: `#Predicate { $0.priority == 2 }`. Buat enum helper terpisah (bukan
> nested di @Model) untuk UI display.

```swift
// Enum helper TERPISAH (bukan di dalam @Model)
enum TaskPriority: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }
    var label: String { ... }
    var colorHex: String { ... }
}
```

### TodoCategory (@Model — SwiftData)

```swift
@Model
final class TodoCategory {
    var id: UUID
    var name: String
    var colorHex: String          // e.g. "#F8CD7A"

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.category)
    var items: [TodoItem] = []
}
```

> **deleteRule: .nullify** — saat category dihapus, TodoItem.category jadi nil
> (bukan ikut dihapus). Ini lebih aman.

### UserProfile (AppStorage / simple persistence)

```swift
struct UserProfile: Codable {
    var name: String
    var hasCompletedOnboarding: Bool
}
```

---

## Architecture L2 — File Structure

```
TodoList/
├── App/
│   └── TodoListApp.swift                    // @main, DIContainer.registerAll(), TabView
│
├── Coordinator/
│   ├── AppRouter.swift                      // @Observable, @MainActor, NavigationPath
│   └── Destination.swift                    // enum Destination: Hashable (all routes)
│
├── DI/
│   ├── DIContainer.swift                    // register/registerSingleton/resolve
│   └── DIContainer+Registrations.swift      // registerAll() — composition root
│
├── Models/
│   ├── TodoItem.swift                       // @Model
│   └── TodoCategory.swift                   // @Model
│
├── Repositories/
│   ├── TodoRepositoryProtocol.swift         // Protocol
│   ├── TodoRepository.swift                 // SwiftData concrete
│   └── MockTodoRepository.swift             // Preview & test
│
├── ViewModels/
│   ├── HomeViewModel.swift                  // @Observable, @MainActor
│   ├── CreateTaskViewModel.swift
│   └── TaskDetailViewModel.swift
│
├── Views/
│   ├── MainTabView.swift                    // TabView (4 tabs)
│   ├── Home/
│   │   ├── HomeScreen.swift                 // NavigationStack + list
│   │   └── EmptyHomeView.swift              // Empty state
│   ├── Task/
│   │   ├── CreateTaskScreen.swift           // Sheet — form
│   │   ├── TaskInfoScreen.swift             // Detail view
│   │   └── DeleteTaskDialog.swift           // Confirmation
│   ├── Category/
│   │   ├── CategoryScreen.swift             // Filter by category
│   │   └── CreateCategorySheet.swift        // Create new category
│   ├── Daily/
│   │   └── DailyTaskScreen.swift            // Phase 2
│   ├── Graph/
│   │   └── GraphScreen.swift                // Phase 2
│   ├── Profile/
│   │   ├── ProfileScreen.swift              // Phase 2
│   │   └── EditProfileScreen.swift          // Phase 2
│   ├── Search/
│   │   └── SearchTaskScreen.swift           // Phase 2
│   ├── Onboarding/
│   │   ├── SplashScreen.swift               // Phase 3
│   │   ├── GetStartScreen.swift             // Phase 3
│   │   └── FillNameScreen.swift             // Phase 3
│   └── Components/
│       ├── TaskCardView.swift               // Reusable task row
│       ├── CategoryPillView.swift           // Category chip/pill
│       ├── SearchBarView.swift              // Custom search bar
│       ├── EmptyStateView.swift             // No tasks illustration
│       └── AppHeaderView.swift              // "Listodo" + settings icon
│
├── Theme/
│   ├── AppColors.swift                      // Color constants
│   ├── AppFonts.swift                       // Font helpers
│   └── AppConstants.swift                   // Spacing, radius, etc.
│
├── Extensions/
│   ├── Color+Hex.swift                      // hex init
│   └── Date+Formatting.swift                // Date display helpers
│
└── Preview Content/
    └── PreviewContainer.swift               // In-memory ModelContainer
```

---

## Architecture Rules (L2)

1. **DIContainer.registerAll()** dipanggil SEKALI di `TodoListApp.init`
2. **Singleton:** AppRouter (shared navigation state)
3. **Transient:** TodoRepository, ViewModels (per-usage/per-screen)
4. **Destination enum** = single source of truth untuk semua route
5. **AppRouter @MainActor** — navigasi = UI concern
6. **Repository nonisolated** — data layer (SwiftData context)
7. **ViewModel @MainActor** — drives UI
8. **Protocol → Concrete → Mock** pattern untuk semua repositories
9. **resolve() fatal error** kalau belum register (sengaja crash agar developer sadar)
10. **No nested NavigationStack** — hanya 1 per tab

---

## Implementation Phases

### Phase 1 — Core (MVP)

**Goal:** App bisa digunakan untuk CRUD tasks + categories

| # | Task | Priority |
|---|---|---|
| 1.1 | Setup Theme (Colors, Fonts, Constants) | High |
| 1.2 | Setup DI (DIContainer, Registrations) | High |
| 1.3 | Setup Coordinator (AppRouter, Destination) | High |
| 1.4 | Data Models (TodoItem, TodoCategory) | High |
| 1.5 | Repository layer (Protocol + SwiftData concrete + Mock) | High |
| 1.6 | Components (TaskCardView, CategoryPillView, SearchBarView, EmptyState) | High |
| 1.7 | HomeScreen + HomeViewModel (sections: Today/Future/Previous) | High |
| 1.8 | CreateTaskScreen + ViewModel | High |
| 1.9 | TaskInfoScreen (detail) | High |
| 1.10 | DeleteTask (confirmationDialog) | High |
| 1.11 | CategoryScreen + CreateCategorySheet | Medium |
| 1.12 | MainTabView (4 tabs, placeholder for 2-4) | Medium |
| 1.13 | EmptyHomeView | Medium |
| 1.14 | Preview Content (in-memory container) | Medium |

### Phase 2 — Features

| # | Task | Priority |
|---|---|---|
| 2.1 | SearchTaskScreen (.searchable or custom) | Medium |
| 2.2 | DailyTaskScreen (today's tasks, filtered) | Medium |
| 2.3 | GraphScreen (Swift Charts — completion stats) | Low |
| 2.4 | ProfileScreen + settings | Low |
| 2.5 | EditProfileScreen | Low |

### Phase 3 — Polish

| # | Task | Priority |
|---|---|---|
| 3.1 | Onboarding flow (Splash → GetStart → FillName) | Low |
| 3.2 | Animations (card transitions, tab switch) | Low |
| 3.3 | Haptic feedback | Low |
| 3.4 | Widget (optional) | Low |

---

## Key Patterns to Apply

### Task Sections (Home Screen)

Tasks grouped by date relative to today:
- **Today:** `dueDate == today`
- **Future:** `dueDate > today`
- **Previous:** `dueDate < today` OR `dueDate == nil && createdAt < today`

### Category Filter

- "All" = show everything (default, gold filled pill)
- Tap specific category → filter list
- Add new category via dashed "+" button → sheet

### SwiftData Query Strategy

```swift
// BUKAN pakai @Query di View (tidak testable)
// ❌ struct HomeScreen: View {
//        @Query(sort: \TodoItem.dueDate) var allTodos: [TodoItem]
//    }

// ✅ Manual fetch di ViewModel (testable, sesuai L2)
@Observable @MainActor
final class HomeViewModel {
    private let repository: TodoRepositoryProtocol
    var allTodos: [TodoItem] = []

    func loadData() async {
        allTodos = try await repository.fetchAllTodos()
    }

    // Computed groupings (filter di Swift, bukan predicate)
    var todayTasks: [TodoItem] {
        allTodos.filter { $0.isToday && !$0.isCompleted }
    }
    var futureTasks: [TodoItem] {
        allTodos.filter { $0.isFuture && !$0.isCompleted }
    }
    var previousTasks: [TodoItem] {
        allTodos.filter { $0.isPrevious || $0.isCompleted }
    }
}
```

> **Penting:** Setelah mutasi (add/delete/toggle), SELALU panggil `loadData()`
> karena manual fetch tidak auto-refresh seperti `@Query`.

### Navigation Pattern

```swift
// AppRouter usage
router.navigate(to: .taskDetail(taskId))
router.navigate(to: .createTask)
router.present(.createCategory)  // sheet

// Destination enum — pakai PersistentIdentifier, BUKAN @Model langsung
enum Destination: Hashable {
    case taskDetail(PersistentIdentifier)   // ← bukan TodoItem
    case createTask
    case createCategory
    case categoryFilter(PersistentIdentifier)
    case dailyTask
    case graph
    case profile
    case editProfile
    case search
}
```

> **Kenapa PersistentIdentifier bukan TodoItem langsung?**
> `@Model` class tidak auto-conform `Hashable`. Kamu bisa implement manual,
> tapi `PersistentIdentifier` sudah Hashable by default dan lebih lightweight
> (hanya ID, bukan seluruh object). Di destination view, resolve ID ke object
> via `modelContext.model(for: id)`.

### Data Fetching: @Query vs Manual Fetch

Ada 2 pendekatan di SwiftData:

| Approach | Pros | Cons |
|---|---|---|
| `@Query` di View | Auto-refresh saat data berubah, zero boilerplate | Tidak testable, logic di View |
| Manual fetch di ViewModel | Testable (mock repo), sesuai MVVM/L2 | Harus manual trigger `loadData()` setelah mutasi |

**Keputusan project ini:** Manual fetch via ViewModel (sesuai L2).
Konsekuensinya: setiap kali add/update/delete, panggil `loadData()` ulang
di ViewModel supaya UI ter-update. Jangan lupa ini.

---

## Gotchas & Reminders (dari NavigationLab)

- Jangan nested NavigationStack di dalam destination
- @MainActor hanya di ViewModel, BUKAN di Repository/Protocol
- State = .loading saat refresh → jangan hapus List (keep old data)
- SwiftData @Model final class (bukan struct)
- Preview pakai in-memory ModelContainer
- Default param init @MainActor class → bisa error di nonisolated context

---

## SwiftData Predicate Limitations

`#Predicate` macro punya banyak batasan yang **tidak ada di Core Data NSPredicate**:

```swift
// ❌ TIDAK BISA — enum comparison
#Predicate<TodoItem> { $0.priority == .high }

// ✅ BISA — Int comparison
#Predicate<TodoItem> { $0.priority == 2 }

// ❌ TIDAK BISA — computed property
#Predicate<TodoItem> { $0.isToday }

// ✅ BISA — inline date logic
let startOfDay = Calendar.current.startOfDay(for: .now)
let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
#Predicate<TodoItem> { $0.dueDate >= startOfDay && $0.dueDate < endOfDay }

// ❌ TIDAK BISA — optional relationship deep access di semua kasus
#Predicate<TodoItem> { $0.category?.persistentModelID == someId }
// ↑ kadang crash runtime, tergantung versi iOS

// ✅ LEBIH AMAN — fetch semua, filter di Swift
let all = try context.fetch(FetchDescriptor<TodoItem>())
let filtered = all.filter { $0.category?.id == selectedId }
```

**Strategi project ini:** Fetch all + filter di ViewModel (computed property).
Lebih predictable daripada push complex predicate ke SwiftData.

---

## Custom Font Setup (Playfair Display)

Font "Playfair Display" BUKAN system font. Perlu di-bundle manual:

### Steps:
1. Download `PlayfairDisplay-ExtraBold.ttf` dari Google Fonts
2. Drag file `.ttf` ke project (centang "Add to target: TodoList")
3. Buka `Info.plist` (atau target → Info), tambahkan:
   ```
   Key: Fonts provided by application (UIAppFonts)
   Item 0: PlayfairDisplay-ExtraBold.ttf
   ```
4. Gunakan di code:
   ```swift
   Font.custom("PlayfairDisplay-ExtraBold", size: 24)
   ```
5. Verify nama font yang benar:
   ```swift
   // Debug helper — jalankan sekali untuk lihat nama terdaftar
   for family in UIFont.familyNames.sorted() {
       for name in UIFont.fontNames(forFamilyName: family) {
           print(name)
       }
   }
   ```

> **Fallback:** Kalau belum mau setup custom font, pakai `.serif` sebagai placeholder:
> `Font.system(size: 24, weight: .heavy, design: .serif)`

---

## Repository & MainActor — Penjelasan

```
┌─────────────────────────────────────┐
│ ViewModel (@MainActor)              │  ← UI thread
│   calls: repository.fetchAll()      │
└──────────────┬──────────────────────┘
               │ async
┌──────────────▼──────────────────────┐
│ TodoRepository (nonisolated class)  │  ← data layer
│   tapi akses mainContext:           │
│   await MainActor.run {             │
│       context.fetch(...)            │  ← SwiftData context = MainActor-bound
│   }                                 │
└─────────────────────────────────────┘
```

**Kenapa Repository "nonisolated" tapi tetap pakai MainActor.run?**
- Protocol-nya nonisolated (supaya bisa di-mock tanpa @MainActor constraint)
- Tapi SwiftData `ModelContext` hanya boleh diakses dari actor yang membuatnya
- `modelContainer.mainContext` = MainActor-bound → harus `await MainActor.run {}`
- Ini pattern yang benar untuk SwiftData + MVVM

---

## Learning Order (Urutan Menulis Code)

Tulis file dalam urutan ini supaya bisa compile **incremental** (setiap step
compilable, tidak perlu 20 file sekaligus):

### Step 1 — Foundation (compilable sendiri, zero dependency)
```
1. Extensions/Color+Hex.swift
2. Extensions/Date+Formatting.swift
3. Theme/AppColors.swift         (depends on Color+Hex)
4. Theme/AppFonts.swift
5. Theme/AppConstants.swift
```

### Step 2 — Data Layer (compilable setelah Step 1)
```
6. Models/TodoItem.swift
7. Models/TodoCategory.swift     (depends on TodoItem — inverse relationship)
8. Repositories/TodoRepositoryProtocol.swift
9. Repositories/MockTodoRepository.swift
10. Repositories/TodoRepository.swift
```

### Step 3 — DI & Coordinator (compilable setelah Step 2)
```
11. DI/DIContainer.swift
12. Coordinator/Destination.swift
13. Coordinator/AppRouter.swift
14. DI/DIContainer+Registrations.swift  (depends on semua di atas)
```

### Step 4 — Components (compilable setelah Step 1-3)
```
15. Views/Components/TaskCardView.swift
16. Views/Components/CategoryPillView.swift
17. Views/Components/SearchBarView.swift
18. Views/Components/EmptyStateView.swift
19. Views/Components/AppHeaderView.swift
```

### Step 5 — Screens (compilable setelah semua di atas)
```
20. ViewModels/HomeViewModel.swift
21. Views/Home/HomeScreen.swift
22. Views/Home/EmptyHomeView.swift
23. ViewModels/CreateTaskViewModel.swift
24. Views/Task/CreateTaskScreen.swift
25. ViewModels/TaskDetailViewModel.swift
26. Views/Task/TaskInfoScreen.swift
27. Views/Task/DeleteTaskDialog.swift
28. Views/Category/CreateCategorySheet.swift
29. Views/Category/CategoryScreen.swift
```

### Step 6 — App Shell (terakhir, wire everything)
```
30. Views/MainTabView.swift
31. Preview Content/PreviewContainer.swift
32. App/TodoListApp.swift         (update entry point)
```

> **Tips:** Setiap selesai 1 step, `Cmd+B` untuk verify compilation.
> Jangan lompat step — compile error yang menumpuk lebih susah di-debug.

---

## Figma Reference

Quick access untuk rendering screens saat implementasi:

| Screen | Node ID |
|---|---|
| Splash | 1:5103 |
| Get Start | 1:4936 |
| Fill Name 1 | 1:5330 |
| Fill Name 2 | 1:5353 |
| Home | 1:4257 |
| Empty Home | 1:5500 |
| Create Task | 1:4336 |
| Create Category | 1:4455 |
| Daily Task | 1:4574 |
| Daily Task variant | 1:7692 |
| Category 1 | 1:4691 |
| Category 2 | 1:4785 |
| Search | 1:4886 |
| Task Info | 1:5378 |
| Delete Task | 1:5433 |
| Graph | 1:5127 |
| Profile & Setting | 1:5223 |
| Edit Profile | 1:5294 |
