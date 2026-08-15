# Color+Hex.swift

**Lokasi:** `TodoList/Extensions/Color+Hex.swift`

---

## Tujuan

Menambahkan initializer `Color(hex:)` ke SwiftUI `Color` supaya bisa buat warna dari hex string (seperti `"#FF5959"`). SwiftUI tidak punya ini built-in.

---

## Konsep

- **Extension** — menambahkan fungsi baru ke type yang sudah ada tanpa subclass
- Sama seperti `String.prototype.toColor = function() {...}` di JavaScript
- Bedanya: Swift extension bisa tambah initializer, computed property, method — tapi BUKAN stored property

---

## Penjelasan Code

### Input Processing

```swift
let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
```

Buang karakter non-alphanumeric (termasuk `#`, spasi, newline). Jadi input `"#FF5959"` → `"FF5959"`.

```swift
var int: UInt64 = 0
Scanner(string: hex).scanHexInt64(&int)
```

`Scanner` parse string hex jadi integer. `"FF5959"` → `16734553` (decimal).
`&int` = pass by reference (inout) — Scanner tulis hasilnya ke variabel ini.

### Bitshift Extraction

```swift
case 6: // RGB (24-bit) — e.g. "FF5959"
    (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
```

Hex `FF5959` dalam binary:
```
FF       59       59
11111111 01011001 01011001
│        │        └── & 0xFF = ambil 8 bit terakhir (B)
│        └── >> 8 lalu & 0xFF = geser 8 bit, ambil 8 bit (G)
└── >> 16 = geser 16 bit ke kanan (R)
```

Ini sama dengan:
```typescript
const r = (int >> 16) & 0xFF  // 255
const g = (int >> 8) & 0xFF   // 89
const b = int & 0xFF          // 89
```

### Conversion ke Color

```swift
self.init(
    .sRGB,
    red: Double(r) / 255,    // 0-255 → 0.0-1.0
    green: Double(g) / 255,
    blue: Double(b) / 255,
    opacity: Double(a) / 255
)
```

SwiftUI `Color` butuh range 0.0-1.0, bukan 0-255. Dibagi 255 untuk normalize.

---

## Analog TypeScript

```typescript
// Sama persis konsepnya
function hexToRgba(hex: string): { r: number, g: number, b: number, a: number } {
    const int = parseInt(hex.replace('#', ''), 16)
    return {
        r: (int >> 16) & 0xFF,
        g: (int >> 8) & 0xFF,
        b: int & 0xFF,
        a: 255
    }
}
```

---

## Penggunaan

```swift
Color(hex: "#FF5959")           // Merah
Color(hex: "#0B011A")           // Dark purple (background app)
Color(hex: "9B60F7")            // Tanpa # juga bisa
Color(hex: "#FFF")              // 3 digit shorthand
```

---

## Dependency

- Tidak depend ke file lain
- Dipakai oleh: `AppColors.swift`, `TaskCardView.swift`, semua view yang pakai hex color

---

## Gotcha

- Input `""` atau invalid → akan jadi hitam (0,0,0) karena default case
- Case-insensitive: `"ff5959"` dan `"FF5959"` sama
- 8-digit format = ARGB (Alpha dulu), bukan RGBA
