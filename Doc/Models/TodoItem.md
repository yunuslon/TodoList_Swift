# TodoItem.swift

**Lokasi:** `TodoList/Models/TodoItem.swift`

---

## Tujuan

SwiftData model untuk task/todo. Ini "tabel" utama di database lokal app. Setiap instance = 1 task yang user buat.

---

## Konsep

- **@Model** — macro SwiftData yang otomatis bikin class ini persistable (disimpan ke SQLite di belakang layar)
- **final class** (bukan struct) — SwiftData requirement. `@Model` hanya bisa di class.
- **Relationship** — optional link ke `TodoCategory`
- **Computed properties** — logic di extension, bukan di `@Model` body (best practice)

---

## Penjelasan Code

### @Model Macro

```swift
@Model
final class TodoItem {
```

`@Model` otomatis generate:
- Conformance ke `PersistentModel` protocol
- Property observation (UI auto-update saat property berubah)
- Persistence metadata (`persistentModelID`, backing storage, dll)
- Codable-like serialization ke/dari SQLite

**Analog TypeORM:**
```typescript
@Entity()
export class TodoItem {
    @PrimaryGeneratedColumn('uuid')
    id: string
    // ...
}
```

### Properties

```swift
var id: UUID
var title: String
var subtitle: String
var isCompleted: Bool
var dueDate: Date?          // Optional — task tanpa deadline
var createdAt: Date
var priority: Int           // 0=low, 1=medium, 2=high
var category: TodoCategory? // Optional relationship
```

- `UUID` — auto-generated unique identifier. SwiftData juga punya `persistentModelID` internal, tapi `id` ini untuk logic kita sendiri.
- `Date?` — optional. Tidak semua task punya deadline.
- `priority: Int` — BUKAN enum. Lihat section "Kenapa Int".
- `category: TodoCategory?` — optional relationship. Task bisa tanpa category.

### Init dengan Default Values

```swift
init(
    id: UUID = UUID(),
    title: String,
    subtitle: String = "",
    isCompleted: Bool = false,
    dueDate: Date? = nil,
    createdAt: Date = .now,
    priority: Int = 1,
    category: TodoCategory? = nil
) {
```

Default values supaya caller tidak perlu specify semua:
```swift
// Minimum
TodoItem(title: "Buy milk")

// Full
TodoItem(title: "Meeting", subtitle: "Room 3A", dueDate: tomorrow, priority: 2, category: work)
```

### TaskPriority Enum (DI LUAR @Model)

```swift
enum TaskPriority: Int, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var label: String { ... }
    var colorHex: String { ... }
}
```

**Kenapa di LUAR class?**
1. SwiftData `#Predicate` tidak support enum comparison: `#Predicate { $0.priority == .high }` ← compile error
2. Nested type di `@Model` bisa cause unexpected behavior
3. Terpisah = bisa dipakai di mana saja tanpa import model

**Kenapa tetap bikin enum kalau tidak disimpan?**
- Untuk UI: Picker, label display, color mapping
- Bridge: `item.taskPriority` convert Int → enum untuk display

### Computed Extension

```swift
extension TodoItem {
    var taskPriority: TaskPriority {
        TaskPriority(rawValue: priority) ?? .medium
    }
```

`?? .medium` = fallback kalau somehow priority di DB punya value invalid (misal 5).

```swift
    var isToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
```

`guard let dueDate else { return false }` — kalau `dueDate` nil (no deadline), bukan "today". Pattern ini disebut "early return" — handle nil case dulu, logic utama di bawah.

```swift
    var cardColorHex: String {
        if let category {
            return category.colorHex
        }
        return taskPriority.colorHex
    }
```

Priority: category color → priority color. Kalau task punya category, pakai warna category. Kalau tidak, fallback ke warna priority.

---

## Analog TypeScript

```typescript
// TypeORM Entity
@Entity()
class TodoItem {
    @PrimaryGeneratedColumn('uuid')
    id: string

    @Column()
    title: string

    @Column({ default: '' })
    subtitle: string

    @Column({ default: false })
    isCompleted: boolean

    @Column({ nullable: true })
    dueDate: Date | null

    @CreateDateColumn()
    createdAt: Date

    @Column({ default: 1 })
    priority: number  // 0=low, 1=medium, 2=high

    @ManyToOne(() => TodoCategory, { nullable: true })
    category: TodoCategory | null

    // Computed (tidak disimpan di DB)
    get isToday(): boolean {
        return dayjs(this.dueDate).isToday()
    }
}

// Enum terpisah
enum TaskPriority {
    Low = 0,
    Medium = 1,
    High = 2,
}
```

---

## Penggunaan

```swift
// Buat task baru
let task = TodoItem(title: "Buy milk", priority: 0)

// Cek grouping
task.isToday     // false (dueDate nil)
task.isFuture    // false
task.isPrevious  // depends on createdAt

// Akses priority
task.taskPriority         // .low
task.taskPriority.label   // "Low"
task.taskPriority.colorHex // "#59FF8C"

// Warna card
task.cardColorHex  // "#59FF8C" (dari priority, karena category nil)
```

---

## Dependency

- Depends on: `TodoCategory.swift` (relationship)
- Dipakai oleh: `TodoRepositoryProtocol`, `MockTodoRepository`, `TodoRepository`, semua ViewModel dan View

---

## Gotcha

- **`@Model` = reference type (class)** — kalau kamu assign `let task2 = task1`, keduanya point ke object yang SAMA. Mutasi di satu tempat affect yang lain.
- **Jangan taruh stored property di extension** — extension @Model class tidak support `var newProp = ...`
- **`persistentModelID`** — auto-generated oleh SwiftData. Ini yang dipakai di `Destination` enum. Baru tersedia SETELAH object di-insert ke ModelContext.
- **Thread safety** — property @Model hanya boleh diakses dari actor yang membuatnya (biasanya MainActor). Akses dari thread lain = crash.
