# AppColors.swift

**Lokasi:** `TodoList/Theme/AppColors.swift`

---

## Tujuan

Centralized color constants yang diambil dari Figma design. Satu sumber kebenaran untuk semua warna di app — tidak ada hardcode hex di View.

---

## Konsep

- **Caseless enum sebagai namespace** — `enum` tanpa `case` tidak bisa di-instantiate. Murni container untuk static properties.
- Semua warna pakai `Color(hex:)` dari extension yang kita buat
- Group pakai `// MARK: -` supaya navigable di Xcode (jumpbar)

---

## Penjelasan Code

### Kenapa `enum` bukan `struct`?

```swift
enum AppColors {           // ✅ Tidak bisa: let x = AppColors()
    static let background = ...
}

struct AppColors {          // ❌ Bisa: let x = AppColors() — tidak make sense
    static let background = ...
}
```

`enum` tanpa case = compile-time guarantee bahwa nobody akan instantiate ini. Di TypeScript ini seperti:
```typescript
// Tidak ada exact equivalent, tapi mirip:
namespace AppColors {
    export const background = '#0B011A'
}
// atau
abstract class AppColors {
    static readonly background = '#0B011A'
}
```

### Color Groups

```swift
// MARK: - Background
static let background = Color(hex: "#0B011A")     // Warna utama seluruh app
static let cardHeader = Color(hex: "#0E0E0E")     // Area header/action bar
```

Background `#0B011A` = very dark purple (bukan pure black). Ini memberikan nuansa purple subtle pada keseluruhan app.

```swift
// MARK: - Task Card Backgrounds (15% opacity)
static let taskCardRed = Color(hex: "#FF5959")
```

Warna ini TANPA opacity. Opacity diterapkan di view saat dipakai: `.opacity(0.15)`. Kenapa? Supaya warna base bisa dipakai untuk hal lain (dot indicator, text highlight) tanpa harus define ulang.

---

## Penggunaan

```swift
// Background seluruh screen
.background(AppColors.background)

// Task card
RoundedRectangle(cornerRadius: 16)
    .fill(AppColors.taskCardRed.opacity(0.15))

// Text
Text("Title")
    .foregroundStyle(AppColors.textPrimary)

// Border
Capsule()
    .strokeBorder(AppColors.border, lineWidth: 1)
```

---

## Dependency

- Depends on: `Color+Hex.swift` (extension `Color(hex:)`)
- Dipakai oleh: Semua View dan Component di project

---

## Gotcha

- Jangan pakai `.opacity()` di definisi constant — terapkan di point-of-use supaya fleksibel
- Kalau nanti mau support Light Mode, warna-warna ini perlu di-wrap ke `Color` asset catalog (adaptive). Untuk sekarang app ini dark-only.
- Xcode autocomplete: ketik `AppColors.` dan lihat semua opsi — ini keuntungan centralized constants
