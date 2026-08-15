# DIContainer.swift

**Lokasi:** `TodoList/DI/DIContainer.swift`

---

## Tujuan

Simple Dependency Injection container. Menyimpan "resep" untuk membuat object (factory) dan menyediakan instance saat diminta (resolve). Centralized — semua dependency didaftarkan di satu tempat.

---

## Konsep

- **Dependency Injection (DI)** — object tidak buat dependency sendiri, tapi minta dari luar
- **Service Locator pattern** — container sebagai "registry" yang tahu cara buat semua dependency
- **Singleton pattern** — container sendiri = singleton (`static let shared`)
- **Transient vs Singleton lifecycle** — 2 cara menyimpan dependency

---

## Penjelasan Code

### Singleton Container

```swift
final class DIContainer {
    static let shared = DIContainer()
    private init() {}
```

- `static let shared` — satu instance global. Diakses dari mana saja: `DIContainer.shared`
- `private init()` — tidak bisa bikin instance lain dari luar. Guarantee hanya 1 container.

**Kenapa singleton?**
- Container harus sama di seluruh app. Kalau ada 2 container, registrasi di satu tidak visible di lainnya.
- `static let` = lazy by default di Swift. Dibuat pertama kali diakses, thread-safe.

### Storage

```swift
private var factories: [String: () -> Any] = [:]
private var singletons: [String: Any] = [:]
```

- `factories` — dictionary: key = nama type (String), value = closure yang buat instance
- `singletons` — dictionary: key = nama type, value = instance yang sudah dibuat
- `() -> Any` — closure tanpa parameter yang return "apapun" (type-erased)
- `private` — hanya accessible dari dalam class

**Kenapa String key bukan type langsung?**
```swift
// Type tidak bisa jadi dictionary key langsung
// String(describing:) convert type ke string representation
String(describing: TodoRepositoryProtocol.self) // → "TodoRepositoryProtocol"
String(describing: AppRouter.self)              // → "AppRouter"
```

### Register (Transient)

```swift
func register<T>(_ type: T.Type, factory: @escaping () -> T) {
    let key = String(describing: type)
    factories[key] = factory
}
```

- `<T>` — generic. Bisa register type apapun.
- `_ type: T.Type` — metatype parameter. Caller tulis: `register(AppRouter.self)`
- `@escaping () -> T` — closure disimpan untuk dipanggil nanti (bukan langsung)
- Setiap `resolve()` akan panggil closure ini → instance BARU setiap kali

**Kapan pakai transient?**
- Repository (stateless, ringan)
- ViewModel (per-screen, punya state sendiri)

### Register Singleton

```swift
func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
    let key = String(describing: type)
    singletons[key] = factory()  // ← langsung execute, simpan instance
}
```

Perbedaan kunci: `factory()` dipanggil LANGSUNG saat register. Instance disimpan. Semua `resolve()` berikutnya return object yang SAMA.

**Kapan pakai singleton?**
- AppRouter (1 navigation state untuk seluruh app)
- AuthStore (1 session)
- Database connection (1 pool)

### Resolve

```swift
func resolve<T>(_ type: T.Type) -> T {
    let key = String(describing: type)

    // Cek singleton dulu
    if let instance = singletons[key] as? T {
        return instance
    }

    // Lalu cek factory (transient)
    guard let factory = factories[key], let instance = factory() as? T else {
        fatalError("⚠️ DIContainer: No registration found for \(key)")
    }

    return instance
}
```

**Urutan lookup:** Singleton → Factory → fatalError

1. Cek `singletons[key]` — ada? Return instance itu (selalu sama)
2. Cek `factories[key]` — ada? Panggil closure, return instance baru
3. Tidak ada? `fatalError` — CRASH intentional

**Kenapa `fatalError` bukan return nil?**
- Kalau dependency belum diregister = BUG developer (lupa di registerAll)
- Crash saat development lebih baik daripada silent nil yang bikin bug misterius nanti
- Sama seperti NestJS yang throw error: "Nest can't resolve dependencies of..."

**`as? T`** — safe cast dari `Any` ke type yang diminta. Harusnya selalu success karena factory return `T`.

### Reset

```swift
func reset() {
    factories.removeAll()
    singletons.removeAll()
}
```

Untuk unit test: clear semua, re-register dengan mock.

---

## Lifecycle Comparison

| Tipe | Register | Resolve | Instance |
|---|---|---|---|
| Transient | Simpan closure | Panggil closure | Baru setiap kali |
| Singleton | Panggil closure, simpan result | Return result | Selalu sama |

```swift
// Transient: setiap resolve = instance baru
DIContainer.shared.register(TodoRepositoryProtocol.self) { TodoRepository() }
let repo1 = DIContainer.shared.resolve(TodoRepositoryProtocol.self) // instance A
let repo2 = DIContainer.shared.resolve(TodoRepositoryProtocol.self) // instance B (BEDA)

// Singleton: semua resolve = instance sama
DIContainer.shared.registerSingleton(AppRouter.self) { AppRouter() }
let router1 = DIContainer.shared.resolve(AppRouter.self) // instance X
let router2 = DIContainer.shared.resolve(AppRouter.self) // instance X (SAMA)
```

---

## Analog TypeScript / NestJS

```typescript
// Simple DI Container (konsep sama)
class DIContainer {
    private static instance: DIContainer
    private factories = new Map<string, () => any>()
    private singletons = new Map<string, any>()

    static get shared() {
        if (!this.instance) this.instance = new DIContainer()
        return this.instance
    }

    register<T>(token: string, factory: () => T) {
        this.factories.set(token, factory)
    }

    registerSingleton<T>(token: string, factory: () => T) {
        this.singletons.set(token, factory())
    }

    resolve<T>(token: string): T {
        if (this.singletons.has(token)) return this.singletons.get(token) as T
        const factory = this.factories.get(token)
        if (!factory) throw new Error(`No registration for ${token}`)
        return factory() as T
    }
}

// NestJS equivalent:
// register() = { provide: TOKEN, useFactory: () => new Service(), scope: Scope.TRANSIENT }
// registerSingleton() = { provide: TOKEN, useFactory: () => new Service() } (default scope)
// resolve() = @Inject(TOKEN)
```

---

## Penggunaan

```swift
// Register (di registerAll)
DIContainer.shared.registerSingleton(AppRouter.self) { AppRouter() }
DIContainer.shared.register(TodoRepositoryProtocol.self) { TodoRepository(container) }

// Resolve (di ViewModel)
let router = DIContainer.shared.resolve(AppRouter.self)
let repo = DIContainer.shared.resolve(TodoRepositoryProtocol.self)
```

---

## Dependency

- Tidak depend ke file lain (pure Swift)
- Dipakai oleh: `DIContainer+Registrations`, semua ViewModel (resolve)

---

## Gotcha

- **Register SEBELUM resolve** — kalau resolve duluan = fatalError. Pastikan `registerAll()` dipanggil di app init sebelum View apapun dibuat.
- **String key collision** — kalau ada 2 type dengan nama sama di module berbeda, bisa conflik. Untuk project ini fine (semua di 1 module).
- **Thread safety** — container ini BUKAN thread-safe. Fine karena:
  1. `registerAll()` dipanggil sekali saat app start (single thread)
  2. `resolve()` dipanggil dari MainActor (Views/ViewModels)
  3. Tidak ada concurrent registration setelah startup
- **Tidak support init dengan parameter** — factory closure tidak terima argument. Kalau perlu, capture parameter via closure:
  ```swift
  register(TodoRepositoryProtocol.self) {
      TodoRepository(modelContainer: container)  // ← captured dari scope luar
  }
  ```
