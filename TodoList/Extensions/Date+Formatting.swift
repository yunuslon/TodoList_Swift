//
//  Date+Formatting.swift
//  TodoList
//
//  Created by M Yunus on 15/08/26.
//

import Foundation


extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isFuture: Bool {
        self > .now && !isToday
    }
    
    var isPast: Bool {
        self < Calendar.current.startOfDay(for: .now)
    }
    
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func timeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }
    
    static func today() -> Date {
        Calendar.current.startOfDay(for: .now)
    }
}


// Notes
// - Calendar.current.isDateInToday — built-in Apple, handle timezone
// - startOfDay(for:) — midnight hari ini (00:00)
// - RelativeDateTimeFormatter — otomatis output "2 hr ago", "in 3 days", dll
// - Ini analog dayjs().isToday(), format('HH:mm'), fromNow() di JS
