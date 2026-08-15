# CreateCategorySheet.swift

**Lokasi:** `TodoList/Views/Category/CreateCategorySheet.swift`

---

## Tujuan

Sheet form untuk buat category baru. Input: nama + pilih warna dari predefined palette. Simple form tanpa ViewModel terpisah (logic cukup ringan).

---

## Konsep

- **Inline state (tanpa ViewModel)** — form simple, tidak butuh ViewModel. `@State` langsung di View.
- **Color picker dari predefined** — user pilih dari palette (bukan arbitrary color)
- **Direct ModelContext insert** — save langsung tanpa lewat repository
- **Live preview** — CategoryPillView update real-time saat user ubah nama/warna

---

## Penjelasan Code

### State

```swift
@State private var name: String = ""
@State private var selectedColorHex: String = TodoCategory.predefinedColors[0].hex
@State private var isSaving: Bool = false
@Environment(\.dismiss) private var dismiss
@Environment(\.modelContext) private var context
```

- Form state langsung `@State` — tidak perlu ViewModel untuk 2 fields
- Default color = warna pertama di `predefinedColors`
- `dismiss` + `context` dari environment

### Color Picker Grid

```swift
LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
    ForEach(TodoCategory.predefinedColors, id: \.hex) { item in
        Circle()
            .fill(Color(hex: item.hex))
            .overlay(
                Circle().strokeBorder(.white, lineWidth: selectedColorHex == item.hex ? 3 : 0)
            )
            .scaleEffect(selectedColorHex == item.hex ? 1.1 : 1.0)
            .onTapGesture {
                withAnimation(.spring(duration: 0.2)) {
                    selectedColorHex = item.hex
                }
            }
    }
}
```

- `LazyVGrid` 5 kolom — circles dalam grid
- Selected indicator: white border + scale up 1.1x
- `withAnimation(.spring)` — smooth selection feedback
- Data dari `TodoCategory.predefinedColors` (static array of tuples)

### Live Preview

```swift
CategoryPillView(
    name: name.isEmpty ? "Category" : name,
    colorHex: selectedColorHex,
    isSelected: true,
    action: {}
)
```

Reuse component yang sama dipakai di Home Screen. User langsung lihat hasilnya saat typing.

### Save

```swift
private func saveCategory() {
    guard canSave else { return }
    isSaving = true
    let category = TodoCategory(
        name: name.trimmingCharacters(in: .whitespaces),
        colorHex: selectedColorHex
    )
    context.insert(category)
    try? context.save()
    dismiss()
}
```

Direct insert ke context — tidak lewat repository. Ini trade-off: kurang testable, tapi simpler untuk form kecil. Kalau nanti perlu test, bisa refactor ke ViewModel + Repository.

---

## Kapan Pakai ViewModel vs Inline State?

| Criteria | ViewModel | Inline @State |
|---|---|---|
| Complex logic (validation, multi-step) | ✅ | ❌ |
| Perlu di-test | ✅ | ❌ |
| 1-2 fields, simple save | ❌ | ✅ |
| Reusable logic di screen lain | ✅ | ❌ |

CreateCategorySheet = 2 fields + 1 save → inline fine.

---

## Analog React Native

```typescript
function CreateCategorySheet({ onDismiss }) {
    const [name, setName] = useState('')
    const [color, setColor] = useState(PREDEFINED_COLORS[0].hex)

    const handleSave = async () => {
        await repository.addCategory({ name, colorHex: color })
        onDismiss()
    }

    return (
        <View>
            <TextInput value={name} onChangeText={setName} />
            <ColorGrid selected={color} onSelect={setColor} />
            <Preview name={name} color={color} />
            <Button title="Save" onPress={handleSave} disabled={!name.trim()} />
        </View>
    )
}
```

---

## Dependency

- Depends on: `TodoCategory`, `CategoryPillView`, `AppColors`, `AppFonts`, `AppConstants`
- Dipakai oleh: `HomeScreen.swift` (via `.sheet(.createCategory)`)

---

## Gotcha

- **`withAnimation(.spring)` di color selection** — tanpa ini, perubahan scale/border instant (less polished)
- **`context.insert` + `dismiss()`** — setelah dismiss, Home Screen `.task` re-trigger → `loadData()` → category baru muncul di pills
- **`id: \.hex`** — pakai hex sebagai ForEach ID. Pastikan hex unique di `predefinedColors` (mereka memang unique).
