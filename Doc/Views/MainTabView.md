# MainTabView.swift

**Lokasi:** `TodoList/Views/MainTabView.swift`

---

## Tujuan

Root view app. TabView dengan 4 tabs: Home (active), Daily (Phase 2), Graph (Phase 2), Profile (Phase 2).

---

## Konsep

- **TabView** — bottom tab bar navigation (seperti `createBottomTabNavigator` di React Navigation)
- **`.tag()`** — identifier untuk setiap tab
- **Placeholder pattern** — tabs yang belum di-implement tetap ada (consistent navigation), tapi tampilkan "Coming Soon"

---

## Penjelasan Code

### TabView Structure

```swift
TabView(selection: $selectedTab) {
    HomeScreen()
        .tag(0)
        .tabItem {
            Image(systemName: "house")
            Text("Home")
        }

    PlaceholderTab(title: "Daily Task", icon: "calendar")
        .tag(1)
        .tabItem { ... }

    // ... tab 2, 3
}
.tint(AppColors.tabBarActive)
```

- `selection: $selectedTab` — controlled tab (bisa switch programmatically: `selectedTab = 2`)
- `.tag(0)` — associate view dengan tab index
- `.tabItem` — icon + label di tab bar
- `.tint` — warna active tab icon/label

### SF Symbols untuk Tab Icons

| Tab | SF Symbol | Meaning |
|---|---|---|
| Home | `house` | Dashboard utama |
| Daily | `calendar` | Daily schedule |
| Graph | `chart.bar` | Statistics |
| Profile | `person` | User settings |

### Placeholder Tabs

```swift
private struct PlaceholderTab: View {
    let title: String
    let icon: String
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack { Image(...), Text(title), Text("Coming in Phase 2") }
        }
    }
}
```

`private struct` — hanya dipakai di file ini. Tidak pollute namespace global.

---

## Analog React Navigation

```typescript
const Tab = createBottomTabNavigator()

function MainTabView() {
    return (
        <Tab.Navigator screenOptions={{ tabBarActiveTintColor: '#9B60F7' }}>
            <Tab.Screen name="Home" component={HomeScreen}
                options={{ tabBarIcon: ({ color }) => <Icon name="home" color={color} /> }}
            />
            <Tab.Screen name="Daily" component={PlaceholderScreen} />
            <Tab.Screen name="Graph" component={PlaceholderScreen} />
            <Tab.Screen name="Profile" component={PlaceholderScreen} />
        </Tab.Navigator>
    )
}
```

---

## Dependency

- Depends on: `HomeScreen`, `AppColors`, `AppFonts`
- Dipakai oleh: `TodoListApp.swift` (root view)

---

## Gotcha

- **Setiap tab punya NavigationStack sendiri** — Home tab punya NavigationStack di HomeScreen. Nanti Daily/Graph/Profile juga akan punya masing-masing. Ini normal (per-tab navigation stack).
- **Tab state persist** — switch tab tidak destroy View. HomeScreen tetap ada di memory saat user di tab lain. Kembali ke Home = View sama (state preserved).
- **`selectedTab` untuk programmatic switch** — nanti bisa deep link: notifikasi → set `selectedTab = 1` → Daily tab.
- **Dark tab bar** — SwiftUI otomatis style tab bar sesuai color scheme. Karena app dark, tab bar juga dark.
