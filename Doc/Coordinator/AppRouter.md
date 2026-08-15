# AppRouter.swift

**Lokasi:** `TodoList/Coordinator/AppRouter.swift`

---

## Tujuan

Centralized navigation manager. Satu object yang mengontrol SEMUA navigasi di app — push, pop, sheet, full screen cover. Menggantikan pattern navigasi yang tersebar di setiap View.

---

## Konsep

- **Coordinator pattern** (simplified) — 1 object mengontrol navigation flow
- **@Observable** — View auto-update saat navigation state berubah
- **@MainActor** — navigasi = UI concern, harus di main thread
- **NavigationPath** — type-erased stack dari SwiftUI

---

## Penjelasan Code

### Class Annotations

```swift
@Observable
@MainActor
final class AppRouter {
```

**`@Observable`:**
- Observation framework (iOS 17+)
- View yang baca property (`path`, `presentedSheet`) otomatis subscribe ke perubahan
- Saat property berubah → View re-render
- Pengganti `ObservableObject` + `@Published` (cara lama)

**`@MainActor`:**
- Semua property dan method hanya bisa diakses dari MainActor (main/UI thread)
- Navigasi mutate UI state → harus di main thread
- Compiler enforce ini: kalau ada code di background thread coba akses router → compile error

**`final class`:**
- `final` = tidak bisa di-subclass. Performance hint untuk compiler.
- `class` (bukan struct) = reference type. Semua View yang hold reference ke router ini lihat state yang SAMA.

### Navigation State

```swift
var path = NavigationPath()
var presentedSheet: Destination?
var presentedFullScreen: Destination?
```

**`NavigationPath`:**
- Type-erased stack. Isinya bisa `Destination` enum values.
- Kosong (`NavigationPath()`) = root screen
- Append = push screen baru ke stack
- RemoveLast = pop screen teratas

**`presentedSheet: Destination?`:**
- `nil` = tidak ada sheet
- Ada value = sheet tampil
- SwiftUI `.sheet(item:)` auto-dismiss saat jadi nil

**`presentedFullScreen: Destination?`:**
- Sama logic, tapi untuk `.fullScreenCover(item:)`
- Beda visual: sheet bisa swipe-dismiss, fullScreen tidak

### Push Navigation

```swift
func navigate(to destination: Destination) {
    path.append(destination)
}
```

Append ke stack → new screen muncul dari kanan (push animation).
`NavigationPath` trigger re-render `NavigationStack(path: $router.path)`.

### Pop

```swift
func goBack() {
    guard !path.isEmpty else { return }
    path.removeLast()
}
```

`guard !path.isEmpty` — safety check. `removeLast()` di empty path = crash.
Kalau sudah di root, do nothing.

### Pop to Root

```swift
func popToRoot() {
    path = NavigationPath()
}
```

Replace path dengan empty path → langsung balik ke root. Semua screen di stack hilang sekaligus.

### Sheet Presentation

```swift
func present(_ destination: Destination) {
    presentedSheet = destination
}

func dismissSheet() {
    presentedSheet = nil
}
```

Set value → sheet muncul. Set nil → sheet dismiss. Simple state machine.

---

## Cara Integrasi di View

### Setup NavigationStack

```swift
struct HomeScreen: View {
    // Resolve router dari DI (atau via @Environment)
    let router = DIContainer.shared.resolve(AppRouter.self)

    var body: some View {
        NavigationStack(path: $router.path) {
            // Root content
            ScrollView { ... }

            // Route resolver
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .taskDetail(let id):
                    TaskInfoScreen(todoId: id)
                case .search:
                    SearchTaskScreen()
                default:
                    EmptyView()
                }
            }
        }
        // Sheet
        .sheet(item: $router.presentedSheet) { destination in
            switch destination {
            case .createTask:
                CreateTaskScreen()
            case .createCategory:
                CreateCategorySheet()
            default:
                EmptyView()
            }
        }
    }
}
```

**`$router.path`** — `$` = Binding. NavigationStack bisa READ (tampilkan stack) dan WRITE (user swipe back → remove dari path).

**`.navigationDestination(for: Destination.self)`** — Mendaftarkan View untuk setiap Destination. Saat `path.append(.taskDetail(id))`, SwiftUI cari destination handler yang match.

**`.sheet(item:)`** — `item` = optional Binding. Tampil saat non-nil, dismiss saat nil.

### Trigger Navigation

```swift
// Dari mana saja
Button("View Detail") {
    router.navigate(to: .taskDetail(todo.persistentModelID))
}

Button("Create Task") {
    router.present(.createTask)
}

Button("Back") {
    router.goBack()
}
```

---

## Analog React Navigation

```typescript
// React Navigation equivalent
const navigationRef = createNavigationContainerRef()

class AppRouter {
    // navigate(to:)
    navigate(screen: string, params?: object) {
        navigationRef.navigate(screen, params)
    }

    // goBack()
    goBack() {
        if (navigationRef.canGoBack()) {
            navigationRef.goBack()
        }
    }

    // popToRoot()
    popToTop() {
        navigationRef.dispatch(StackActions.popToTop())
    }

    // present() — React Navigation tidak punya native sheet
    // Biasanya pakai modal group atau bottom sheet library
}
```

| React Navigation | AppRouter |
|---|---|
| `navigation.navigate('Detail', { id })` | `router.navigate(to: .taskDetail(id))` |
| `navigation.goBack()` | `router.goBack()` |
| `navigation.popToTop()` | `router.popToRoot()` |
| `navigation.navigate('Modal')` | `router.present(.createTask)` |
| `navigation.canGoBack()` | `!router.path.isEmpty` |

---

## Alur Lengkap: User Tap Task → Detail Screen

```
1. User taps task card di HomeScreen
    │
2. HomeScreen: router.navigate(to: .taskDetail(todo.persistentModelID))
    │
3. AppRouter: path.append(.taskDetail(id))
    │
4. @Observable triggers re-render
    │
5. NavigationStack sees new item in path
    │
6. .navigationDestination(for: Destination.self) matches .taskDetail(let id)
    │
7. SwiftUI pushes TaskInfoScreen(todoId: id) dengan animation
    │
8. TaskInfoScreen: repo.fetchTodo(by: id) → load data → render detail
```

---

## Penggunaan

```swift
let router = DIContainer.shared.resolve(AppRouter.self)

// Push
router.navigate(to: .taskDetail(id))
router.navigate(to: .search)

// Pop
router.goBack()
router.popToRoot()

// Sheet
router.present(.createTask)
router.present(.createCategory)
router.dismissSheet()

// Full screen cover
router.presentFullScreen(.editProfile)
router.dismissFullScreen()
```

---

## Dependency

- Depends on: `Destination.swift` (enum type), `SwiftUI` (NavigationPath)
- Dipakai oleh: `DIContainer+Registrations` (registerSingleton), semua View yang navigate

---

## Gotcha

- **Jangan bikin AppRouter kedua** — harus singleton. 2 router = 2 navigation state yang conflict.
- **`$router.path` butuh Bindable** — di SwiftUI, `@Observable` class yang di-`let` atau `@State` otomatis Bindable. Kalau dari DI resolve, mungkin perlu `@Bindable var router` atau akses via wrapper.
- **Sheet dismiss oleh user (swipe down)** — SwiftUI otomatis set `presentedSheet = nil`. Kamu tidak perlu handle manual.
- **Deep stack lalu popToRoot** — semua screen di-deallocate. Pastikan tidak ada async task yang depend pada screen yang akan hilang (gunakan `.task` modifier yang auto-cancel).
- **Nested NavigationStack** — JANGAN. Satu NavigationStack per tab cukup. Kalau ada nested, `navigationDestination` link bisa conflict/broken.
- **Thread safety** — `@MainActor` menjamin semua akses serialized di main thread. Tidak mungkin race condition.
