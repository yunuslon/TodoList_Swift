# TodoCategory.swift

**Lokasi:** `TodoList/Models/TodoCategory.swift`

---

## Tujuan

SwiftData model untuk category/group. Setiap category punya nama dan warna, serta relasi one-to-many ke TodoItem.

---

## Konsep

- **@Model** — persistent model (sama seperti TodoItem)
- **@Relationship** — explicit relationship configuration (delete rule, inverse)
- **One-to-Many** — 1 category punya banyak items
- **Static data** — predefined colors untuk seeding/pilihan user

---

## Penjelasan Code

### Relationship Declaration

```swift
@Relationship(deleteRule: .nullify, inverse: \TodoItem.category)
var items: [TodoItem] = []
```

**`deleteRule: .nullify`:**
- Saat category DIHAPUS, semua `TodoItem.category` yang pointing ke sini jadi `nil`
- Task TIDAK ikut dihapus
- Alternatif: `.cascade` (hapus category → semua task di dalamnya juga dihapus) — terlalu berbahaya untuk todo app

**`inverse: \TodoItem.category`:**
- Bilang ke SwiftData: "property `category` di TodoItem adalah sisi lain dari relationship ini"
- SwiftData otomatis sync kedua sisi
- Kalau `item.category = work`, maka `work.items` otomatis include item itu

**`= []`:**
- Default empty array. Category baru belum punya items.

**Analog TypeORM:**
```typescript
@Entity()
class TodoCategory {
    @OneToMany(() => TodoItem, item => item.category, {
        onDelete: 'SET NULL'  // deleteRule: .nullify
    })
    items: TodoItem[]
}
```

### Init

```swift
init(id: UUID = UUID(), name: String, colorHex: String) {
    self.id = id
    self.name = name
    self.colorHex = colorHex
}
```

Simple. `items` tidak di-init karena sudah punya default `[]`. Relationship di-manage oleh SwiftData — kamu set `item.category = someCategory` dan SwiftData otomatis update `someCategory.items`.

### Predefined Colors

```swift
extension TodoCategory {
    static let predefinedColors: [(name: String, hex: String)] = [
        ("Work", "#F8CD7A"),
        ("Home", "#9B60F7"),
        ("Personal", "#5977FF"),
        ("Health", "#59FF8C"),
        ("Shopping", "#FF9B59"),
    ]
}
```

- Static data, BUKAN disimpan di database
- Dipakai di UI: "Create Category" screen menampilkan pilihan warna
- Bisa juga untuk seeding (first launch, pre-populate categories)
- Tuple array `[(name, hex)]` — lightweight, tidak perlu struct khusus

---

## Analog TypeScript

```typescript
@Entity()
class TodoCategory {
    @PrimaryGeneratedColumn('uuid')
    id: string

    @Column()
    name: string

    @Column()
    colorHex: string

    @OneToMany(() => TodoItem, item => item.category, {
        onDelete: 'SET NULL',
        eager: false,
    })
    items: TodoItem[]
}

// Static data (bukan DB)
const PREDEFINED_COLORS = [
    { name: 'Work', hex: '#F8CD7A' },
    { name: 'Home', hex: '#9B60F7' },
    { name: 'Personal', hex: '#5977FF' },
    { name: 'Health', hex: '#59FF8C' },
    { name: 'Shopping', hex: '#FF9B59' },
] as const
```

---

## Penggunaan

```swift
// Buat category
let work = TodoCategory(name: "Work", colorHex: "#F8CD7A")

// Assign ke task
let task = TodoItem(title: "Meeting", category: work)
// Otomatis: work.items sekarang berisi [task]

// Akses warna di UI
Color(hex: work.colorHex)  // Gold/kuning

// Hapus category
context.delete(work)
// task.category sekarang = nil (nullify)
// task TIDAK dihapus
```

---

## Dependency

- Depends on: `TodoItem.swift` (inverse relationship reference)
- Dipakai oleh: `TodoRepositoryProtocol`, ViewModels, CategoryPillView, CreateCategorySheet

---

## Gotcha

- **Circular reference** — TodoItem punya `category: TodoCategory?`, TodoCategory punya `items: [TodoItem]`. Ini OK di SwiftData (managed automatically). Tapi JANGAN bikin 2 file yang cross-reference tanpa keduanya di target yang sama.
- **`@Relationship` optional** — sebenarnya SwiftData bisa infer relationship tanpa macro. Tapi explicit `@Relationship` memberi kontrol atas delete rule. Tanpa macro, default delete rule = `.nullify` juga.
- **Array order tidak dijamin** — `items: [TodoItem]` tidak punya guaranteed order. Kalau perlu sorted, sort saat akses: `category.items.sorted(by: { $0.createdAt < $1.createdAt })`.
