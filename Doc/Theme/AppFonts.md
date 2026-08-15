# AppFonts.swift

**Lokasi:** `TodoList/Theme/AppFonts.swift`

---

## Tujuan

Centralized font helpers. Memastikan konsistensi typography di seluruh app sesuai Figma design (Roboto body, Playfair Display brand).

---

## Konsep

- **Static factory methods** — return `Font` type
- Pakai function bukan property supaya bisa terima parameter (size, weight)
- Custom font (Playfair Display) + system font (untuk body/caption)

---

## Penjelasan Code

### Brand Font

```swift
static func brand(size: CGFloat = 24) -> Font {
    .custom("PlayfairDisplay-ExtraBold", size: size)
}
```

- `.custom("nama-font", size:)` — load font dari bundle app
- Nama string HARUS exact match dengan PostScript name font (bukan filename)
- Default param `size: 24` — sesuai Figma header

**Kenapa function bukan property?**
```swift
// Property — fixed, tidak bisa ubah size
static let brand = Font.custom("PlayfairDisplay-ExtraBold", size: 24)

// Function — flexible, bisa beda size
static func brand(size: CGFloat = 24) -> Font { ... }

// Pakai:
AppFonts.brand()       // 24 (default)
AppFonts.brand(size: 32) // 32 (custom)
```

### System Fonts

```swift
static func sectionTitle() -> Font {
    .system(size: 18, weight: .medium)
}
```

Pakai system font (San Francisco di iOS). Kita tidak bundle Roboto karena:
- San Francisco sudah mirip Roboto (clean, geometric sans-serif)
- Hemat bundle size
- Better native feel di iOS

Kalau mau pixel-perfect dengan Figma, bisa bundle Roboto juga — tapi biasanya tidak perlu.

### Weight Parameter

```swift
static func body(weight: Font.Weight = .medium) -> Font {
    .system(size: 16, weight: weight)
}
```

Default `.medium` (sesuai Figma), tapi bisa override:
```swift
AppFonts.body()              // Medium (default)
AppFonts.body(weight: .bold) // Bold variant
```

---

## Analog TypeScript (React Native StyleSheet)

```typescript
const fonts = {
    brand: (size = 24) => ({
        fontFamily: 'PlayfairDisplay-ExtraBold',
        fontSize: size,
    }),
    sectionTitle: () => ({
        fontFamily: 'System',
        fontSize: 18,
        fontWeight: '500' as const,
    }),
    body: (weight = '500') => ({
        fontSize: 16,
        fontWeight: weight,
    }),
}
```

---

## Penggunaan

```swift
Text("Listodo")
    .font(AppFonts.brand())

Text("Today task")
    .font(AppFonts.sectionTitle())

Text("Design sprint review")
    .font(AppFonts.body())

Text("Prepare presentation")
    .font(AppFonts.caption())

Text("Work")
    .font(AppFonts.small())
```

---

## Dependency

- Tidak depend ke file lain
- Dipakai oleh: Semua View yang render text

---

## Gotcha

- **Custom font belum muncul?** Cek:
  1. File `.ttf` sudah di-add ke target (Build Phases → Copy Bundle Resources)
  2. `Info.plist` punya key `UIAppFonts` dengan value `["PlayfairDisplay-ExtraBold.ttf"]`
  3. Nama string di `.custom()` = PostScript name (bisa beda dari filename)
  4. Debug: print semua font names:
     ```swift
     for family in UIFont.familyNames.sorted() {
         for name in UIFont.fontNames(forFamilyName: family) {
             print(name)
         }
     }
     ```
- **Fallback:** Kalau custom font tidak ditemukan, iOS render dengan system font (tidak crash)
- `CGFloat` bukan `Double` — SwiftUI sizing pakai `CGFloat` (alias ke Double di 64-bit, tapi secara semantic beda)
