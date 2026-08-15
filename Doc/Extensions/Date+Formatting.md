# Date+Formatting.swift

**Lokasi:** `TodoList/Extensions/Date+Formatting.swift`

---

## Tujuan

Helper extension untuk `Date` — comparison (isToday/isFuture/isPast) dan formatting. Dipakai untuk mengelompokkan task di Home Screen.

---

## Konsep

- **Extension** pada `Date` (Foundation type)
- Computed properties = property tanpa storage, dihitung setiap diakses
- `Calendar.current` = kalender sesuai locale/timezone user

---

## Penjelasan Code

### Date Comparison

```swift
var isToday: Bool {
    Calendar.current.isDateInToday(self)
}
```

Built-in Apple API. Handle timezone dan edge case (23:59 → 00:00) otomatis. Jangan manual compare `dateString == todayString` — pasti bug timezone.

```swift
var isFuture: Bool {
    self > .now && !isToday
}
```

Lebih besar dari sekarang DAN bukan hari ini. Tanpa `!isToday`, task due jam 23:00 hari ini akan tercount "future" sebelum jam itu.

```swift
var isPast: Bool {
    self < Calendar.current.startOfDay(for: .now)
}
```

Sebelum midnight hari ini (00:00:00). Pakai `startOfDay` bukan `.now` supaya task yang due hari ini jam 08:00 tidak langsung jadi "past" setelah jam 08:00 lewat.

### Formatting

```swift
func formatted(style: DateFormatter.Style = .medium) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = style
    formatter.timeStyle = .none
    return formatter.string(from: self)
}
```

Output contoh (`.medium`): "Aug 15, 2026". Auto-localize sesuai device language.

```swift
func relativeFormatted() -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: self, relativeTo: .now)
}
```

Output: "2 hr. ago", "in 3 days", "yesterday". Otomatis bahasa sesuai locale.

```swift
static func today() -> Date {
    Calendar.current.startOfDay(for: .now)
}
```

Static helper: return tanggal hari ini jam 00:00:00. Berguna untuk bikin predicate date range.

---

## Analog TypeScript (dayjs)

```typescript
import dayjs from 'dayjs'
import isToday from 'dayjs/plugin/isToday'
import relativeTime from 'dayjs/plugin/relativeTime'

dayjs.extend(isToday)
dayjs.extend(relativeTime)

dayjs(date).isToday()        // var isToday: Bool
dayjs(date).isAfter(dayjs()) // var isFuture: Bool
dayjs(date).isBefore(dayjs().startOf('day')) // var isPast: Bool
dayjs(date).format('HH:mm') // func timeFormatted()
dayjs(date).fromNow()        // func relativeFormatted()
```

---

## Penggunaan

```swift
let dueDate = Date()
dueDate.isToday          // true
dueDate.isFuture         // false
dueDate.isPast           // false
dueDate.timeFormatted()  // "13:45"
dueDate.relativeFormatted() // "in 0 sec."

Date.today()             // 2026-08-15 00:00:00 +0000
```

---

## Dependency

- Tidak depend ke file lain (pure Foundation)
- Dipakai oleh: `TodoItem.swift` (computed `isToday`, `isFuture`, `isPrevious`)

---

## Gotcha

- `DateFormatter` itu berat (expensive to create). Untuk production app dengan ribuan cell, consider caching formatter. Untuk todo app ini, fine.
- `.now` vs `Date()` — sama saja di Swift 5.9+. `.now` lebih readable.
- Timezone: semua pakai `Calendar.current` yang otomatis handle timezone user. Jangan hardcode UTC kecuali perlu sync server.
