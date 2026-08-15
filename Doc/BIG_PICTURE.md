# Big Picture — Alur Baca Code Listodo

Dokumen ini menjelaskan urutan membaca code agar kamu paham flow app dari awal sampai akhir. Baca dari atas ke bawah.

---

## Peta Arsitektur

```
┌─────────────────────────────────────────────────────────────┐
│  USER                                                        │
│  Buka app → lihat tab → tap task → create → delete          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  1. ENTRY POINT                                              │
│     TodoListApp.swift                                        │
│     → Buat database (ModelContainer)                         │
│     → Register semua dependency (DI)                         │
│     → Render MainTabView                                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  2. NAVIGATION SHELL                                         │
│     MainTabView.swift                                        │
│     → TabView 4 tabs                                         │
│     → Tab 1 = HomeScreen (active)                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  3. SCREEN + VIEWMODEL                                       │
│     HomeScreen.swift ←→ HomeViewModel.swift                  │
│     → View observe ViewModel                                 │
│     → ViewModel call Repository                              │
│     → Data kembali, View re-render                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  4. REPOSITORY                                               │
│     TodoRepository.swift (implements TodoRepositoryProtocol) │
│     → Fetch/Insert/Delete via ModelContext                   │
│     → MainActor.run { context.fetch(...) }                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  5. DATABASE (SwiftData)                                     │
│     TodoItem.swift + TodoCategory.swift (@Model)             │
│     → Persistent storage (SQLite)                            │
│     → Relationship: TodoItem ←→ TodoCategory                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Urutan Baca (Bottom-Up → Top-Down)

Aku sarankan baca **bottom-up** dulu (fondasi), lalu **top-down** (flow).

### Phase A — Fondasi (baca ini dulu, pahami building blocks)

```
1. Extensions/Color+Hex.swift       — utility: hex string → Color
2. Extensions/Date+Formatting.swift — utility: date comparison & formatting
3. Theme/AppColors.swift            — semua warna dari Figma
4. Theme/AppFonts.swift             — semua font sizes
5. Theme/AppConstants.swift         — semua spacing/radius/heights
```

**Setelah baca ini kamu paham:** Design system app. Semua magic number ada di 1 tempat.

---

### Phase B — Data Layer (apa yang disimpan & bagaimana)

```
6. Models/TodoItem.swift            — shape data task (properties + computed)
7. Models/TodoCategory.swift        — shape data category (+ relationship)
8. Repositories/TodoRepositoryProtocol.swift — kontrak: operasi apa yang bisa dilakukan
9. Repositories/TodoRepository.swift — implementasi nyata (SwiftData)
10. Repositories/MockTodoRepository.swift — implementasi fake (in-memory)
```

**Setelah baca ini kamu paham:** Data model, CRUD operations, kenapa pakai protocol, bagaimana SwiftData bekerja.

---

### Phase C — Infrastructure (DI & Navigation)

```
11. DI/DIContainer.swift            — mekanisme register/resolve
12. DI/DIContainer+Registrations.swift — siapa di-register sebagai apa
13. Coordinator/Destination.swift   — semua route yang ada
14. Coordinator/AppRouter.swift     — centralized navigation (push/pop/sheet)
```

**Setelah baca ini kamu paham:** Bagaimana dependency di-wire, bagaimana navigasi bekerja tanpa hardcode di View.

---

### Phase D — UI Components (building blocks visual)

```
15. Views/Components/TaskCardView.swift      — card 1 task
16. Views/Components/CategoryPillView.swift  — chip category
17. Views/Components/SearchBarView.swift     — search input
18. Views/Components/EmptyStateView.swift    — empty placeholder
19. Views/Components/AppHeaderView.swift     — header "Listodo"
```

**Setelah baca ini kamu paham:** Reusable pieces yang disusun jadi screen. Setiap component isolated, bisa di-preview sendiri.

---

### Phase E — Screens & Logic (top-level flow)

```
20. ViewModels/HomeViewModel.swift        — logic Home: load, filter, group, mutate
21. Views/Home/HomeScreen.swift           — UI Home: NavigationStack, routing, layout
22. Views/Home/EmptyHomeView.swift        — empty state variant

23. ViewModels/CreateTaskViewModel.swift  — logic Create: form state, validation, save
24. Views/Task/CreateTaskScreen.swift     — UI Create: form fields, toolbar buttons

25. ViewModels/TaskDetailViewModel.swift  — logic Detail: load by ID, toggle, delete
26. Views/Task/TaskInfoScreen.swift       — UI Detail: info display, action buttons, dialog

27. Views/Category/CreateCategorySheet.swift — create category (inline state)
28. Views/Category/CategoryScreen.swift     — filtered list by category
```

**Setelah baca ini kamu paham:** Bagaimana ViewModel + View bekerja bersama. Alur lengkap setiap fitur.

---

### Phase F — App Shell (entry & wiring)

```
29. Views/MainTabView.swift              — TabView 4 tabs
30. Preview Content/PreviewContainer.swift — in-memory data untuk preview
31. TodoListApp.swift                    — entry point, setup semua
```

**Setelah baca ini kamu paham:** Bagaimana semua pieces di-wire jadi 1 app yang jalan.

---

## Flow Utama: User Create Task

Baca urutan ini untuk pahami 1 flow end-to-end:

```
User tap FAB "+"
    │
    ▼
HomeScreen.swift (line: router.present(.createTask))
    │
    ▼
AppRouter.swift (presentedSheet = .createTask)
    │
    ▼
HomeScreen.swift (.sheet(item:) → switch .createTask → CreateTaskScreen())
    │
    ▼
CreateTaskScreen.swift (appear → .task { viewModel.loadCategories() })
    │
    ▼
CreateTaskViewModel.swift (loadCategories → repository.fetchAllCategories())
    │
    ▼
TodoRepository.swift (MainActor.run { context.fetch(FetchDescriptor<TodoCategory>) })
    │
    ▼
SwiftData/SQLite → return [TodoCategory]
    │
    ▼
CreateTaskViewModel.swift (categories = [...] → View re-render → pills muncul)
    │
    ▼
User isi form → tap Save
    │
    ▼
CreateTaskScreen.swift (Task { let success = await viewModel.save() })
    │
    ▼
CreateTaskViewModel.swift (save → buat TodoItem → repository.addTodo(item))
    │
    ▼
TodoRepository.swift (MainActor.run { context.insert(item); context.save() })
    │
    ▼
SwiftData/SQLite → item persisted ✅
    │
    ▼
CreateTaskViewModel.swift (return true)
    │
    ▼
CreateTaskScreen.swift (if success { dismiss() })
    │
    ▼
Sheet dismissed → HomeScreen reappear
    │
    ▼
HomeScreen.swift (.task re-triggers → viewModel.loadData())
    │
    ▼
HomeViewModel.swift (allTodos = [...including new item...])
    │
    ▼
Computed: todayTasks / futureTasks / previousTasks recalculated
    │
    ▼
HomeScreen re-renders → new task card visible ✅
```

---

## Flow Utama: User Delete Task

```
User tap task card
    │
    ▼
HomeScreen.swift (router.navigate(to: .taskDetail(item.persistentModelID)))
    │
    ▼
AppRouter.swift (path.append(.taskDetail(id)))
    │
    ▼
HomeScreen.swift (.navigationDestination → TaskInfoScreen(todoId: id))
    │
    ▼
TaskInfoScreen.swift (appear → .task { viewModel.loadTodo() })
    │
    ▼
TaskDetailViewModel.swift (repository.fetchTodo(by: id) → todo = item)
    │
    ▼
User tap "Delete Task" button
    │
    ▼
TaskDetailViewModel.swift (showDeleteConfirmation = true)
    │
    ▼
TaskInfoScreen.swift (.confirmationDialog appears)
    │
    ▼
User tap "Delete" (destructive)
    │
    ▼
TaskDetailViewModel.swift (deleteTodo() → repository.deleteTodo(todo))
    │
    ▼
TodoRepository.swift (context.delete(item); context.save())
    │
    ▼
SwiftData/SQLite → item removed ✅
    │
    ▼
TaskDetailViewModel.swift (return true)
    │
    ▼
TaskInfoScreen.swift (if deleted { router.goBack() })
    │
    ▼
AppRouter.swift (path.removeLast())
    │
    ▼
HomeScreen reappear → .task re-triggers → loadData() → deleted item gone ✅
```

---

## Flow: Toggle Complete

```
User tap checkbox di TaskCardView
    │
    ▼
HomeScreen.swift (Task { await viewModel.toggleComplete(item) })
    │
    ▼
HomeViewModel.swift (repository.toggleComplete(item) → loadData())
    │
    ▼
TodoRepository.swift (item.isCompleted.toggle(); context.save())
    │
    ▼
HomeViewModel.swift (allTodos refreshed → computed groups recalculated)
    │
    ▼
Task pindah dari "Today" ke "Previous" (karena isCompleted = true) ✅
```

---

## Flow: Category Filter

```
User tap "Work" pill
    │
    ▼
HomeScreen.swift (viewModel.selectCategory(category))
    │
    ▼
HomeViewModel.swift (selectedCategory = category)
    │
    ▼
filteredTodos (computed) → re-filter allTodos by category
    │
    ▼
todayTasks / futureTasks / previousTasks recalculated (only Work items)
    │
    ▼
View re-renders → hanya task "Work" yang tampil ✅
    │
    ▼
User tap "Work" lagi (toggle off)
    │
    ▼
HomeViewModel.swift (selectedCategory = nil → show all) ✅
```

---

## Dependency Graph (siapa depend ke siapa)

```
TodoListApp
    ├── MainTabView
    │       └── HomeScreen
    │               ├── HomeViewModel
    │               │       ├── TodoRepositoryProtocol ← TodoRepository
    │               │       │                               └── ModelContainer
    │               │       └── DIContainer
    │               ├── AppRouter ← DIContainer (singleton)
    │               ├── TaskInfoScreen
    │               │       └── TaskDetailViewModel
    │               │               └── TodoRepositoryProtocol
    │               ├── CreateTaskScreen
    │               │       └── CreateTaskViewModel
    │               │               └── TodoRepositoryProtocol
    │               ├── CategoryScreen
    │               │       └── ModelContext (environment)
    │               └── CreateCategorySheet
    │                       └── ModelContext (environment)
    │
    ├── DIContainer.registerAll(modelContainer)
    │       ├── AppRouter (singleton)
    │       └── TodoRepositoryProtocol → TodoRepository (transient)
    │
    └── ModelContainer
            └── Schema: [TodoItem, TodoCategory]
```

---

## Layer Summary

| Layer | Files | Tanggung Jawab | Boleh Akses |
|---|---|---|---|
| **App** | TodoListApp, MainTabView | Bootstrap, wiring, shell | Semua |
| **View** | *Screen.swift | Render UI, delegate action ke ViewModel | ViewModel, Components, Router |
| **ViewModel** | *ViewModel.swift | Business logic, state management | Repository (via protocol), Models |
| **Repository** | TodoRepository, Mock | CRUD database, data access | ModelContainer, Models |
| **Model** | TodoItem, TodoCategory | Data shape, relationships | Foundation only |
| **Component** | TaskCardView, dll | Reusable UI pieces | Theme only |
| **Theme** | AppColors, Fonts, Constants | Design tokens | Extensions only |
| **Extension** | Color+Hex, Date+Formatting | Utility helpers | Foundation/SwiftUI only |
| **DI** | DIContainer | Dependency wiring | Semua (composition root) |
| **Coordinator** | AppRouter, Destination | Navigation state | SwiftUI only |

**Aturan:** Layer bawah TIDAK BOLEH import layer atas. Model tidak tahu tentang ViewModel. Repository tidak tahu tentang View. Ini menjaga separation of concerns.

---

## Tips Membaca Code

1. **Mulai dari flow, bukan file** — pick 1 user action (create task), trace dari UI sampai database
2. **Baca ViewModel + View berpasangan** — mereka selalu pair. ViewModel = logic, View = render.
3. **Protocol dulu, concrete kemudian** — baca `TodoRepositoryProtocol` untuk tahu "apa bisa dilakukan", baru `TodoRepository` untuk "bagaimana caranya"
4. **Computed properties = derived state** — kalau bingung data datang dari mana, trace balik ke source (`allTodos`)
5. **`Cmd+Click`** di Xcode untuk jump to definition — paling cepat navigate antar file
6. **Preview (`Cmd+Option+P`)** untuk lihat component visual tanpa run full app
