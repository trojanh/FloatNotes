import Foundation
import EventKit
import AppKit

final class CalendarReminderService {
    static let shared = CalendarReminderService()
    private let eventStore = EKEventStore()

    struct DetectedItem {
        let text: String
        let date: Date?
    }

    /// Detect dates and times from note text using NSDataDetector
    func detectDates(in text: String) -> [DetectedItem] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return []
        }

        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length))
        return matches.compactMap { match in
            guard let date = match.date else { return nil }
            let matchedText = (text as NSString).substring(with: match.range)
            return DetectedItem(text: matchedText, date: date)
        }
    }

    /// Add an event to Calendar
    func addToCalendar(title: String, startDate: Date, completion: @escaping (Bool, String?) -> Void) {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            guard let self = self, granted, error == nil else {
                DispatchQueue.main.async {
                    completion(false, error?.localizedDescription ?? "Calendar access denied")
                }
                return
            }

            let event = EKEvent(eventStore: self.eventStore)
            event.title = title.isEmpty ? "Note Action Item" : title
            event.startDate = startDate
            event.endDate = startDate.addingTimeInterval(3600) // 1 hour default
            event.calendar = self.eventStore.defaultCalendarForNewEvents

            do {
                try self.eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    /// Add a task to Apple Reminders
    func addToReminders(title: String, dueDate: Date?, completion: @escaping (Bool, String?) -> Void) {
        eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
            guard let self = self, granted, error == nil else {
                DispatchQueue.main.async {
                    completion(false, error?.localizedDescription ?? "Reminders access denied")
                }
                return
            }

            let reminder = EKReminder(eventStore: self.eventStore)
            reminder.title = title
            reminder.calendar = self.eventStore.defaultCalendarForNewReminders()

            if let due = dueDate {
                let calendar = Calendar.current
                reminder.dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: due)
                let alarm = EKAlarm(absoluteDate: due)
                reminder.addAlarm(alarm)
            }

            do {
                try self.eventStore.save(reminder, commit: true)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
}
