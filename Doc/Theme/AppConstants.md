# AppConstants.swift

**Lokasi:** `TodoList/Theme/AppConstants.swift`

---

## Tujuan

Centralized numeric constants (spacing, radius, heights, icon sizes). Menghindari magic numbers yang tersebar di seluruh codebase.

---

## Konsep

- **Single source of truth** untuk semua dimensi UI
- Nama descriptive — self-documenting code
- `CGFloat` type — karena semua SwiftUI modifier (padding, frame, cornerRadius) menerima `CGFloat`

---

## Penjelasan Code

### Spacing

```swift
static let paddingHorizontal: CGFloat = 16
static let paddingVertical: CGFloat = 16
static let cardSpacing: CGFloat = 8
static let sectionSpacing: CGFloat = 24
```

Dari Figma layout grid: horizontal padding 16, gutter 16. Card spacing 8 (antar task card). Section spacing 24 (antar "Today task" dan "Future").

### Corner Radius

```swift
static let cardRadius: CGFloat = 16     // Task card
static let pillRadius: CGFloat = 39     // Search bar, category pill (full capsule)
static let buttonRadius: CGFloat = 39   // Action buttons
```

`39` = half of height (untuk pill-shaped). Task card pakai `16` (rounded rectangle, bukan full capsule).

### Heights

```swift
static let taskCardHeight: CGFloat = 80
static let searchBarHeight: CGFloat = 48
static let categoryPillHeight: CGFloat = 32
```

Exact values dari Figma. Menjaga consistency antar screens.

---

## Analog TypeScript

```typescript
// React Native — biasa di file constants/layout.ts
export const Layout = {
    paddingHorizontal: 16,
    paddingVertical: 16,
    cardSpacing: 8,
    sectionSpacing: 24,
} as const

export const Radius = {
    card: 16,
    pill: 39,
} as const

export const Heights = {
    taskCard: 80,
    searchBar: 48,
    categoryPill: 32,
} as const
```

---

## Penggunaan

```swift
// Padding
.padding(.horizontal, AppConstants.paddingHorizontal)

// Corner radius
RoundedRectangle(cornerRadius: AppConstants.cardRadius)

// Frame height
.frame(height: AppConstants.taskCardHeight)

// Spacing antar card
VStack(spacing: AppConstants.cardSpacing) { ... }

// Spacing antar section
VStack(spacing: AppConstants.sectionSpacing) { ... }

// Icon size
Image(systemName: "gear")
    .frame(width: AppConstants.iconMedium, height: AppConstants.iconMedium)
```

---

## Dependency

- Tidak depend ke file lain (pure Foundation)
- Dipakai oleh: Semua View dan Component

---

## Gotcha

- `import Foundation` cukup — tidak perlu `import SwiftUI` karena `CGFloat` ada di Foundation
- Kalau nanti butuh responsive (iPad), bisa ubah dari `static let` ke computed property yang hitung berdasarkan screen size. Untuk sekarang fixed values fine.
- Jangan tambah warna atau font di sini — tetap pisah per concern (AppColors untuk warna, AppFonts untuk font)
