import Foundation
import EventKit
import Combine

// MARK: - CalendarManager
//
// Manages writing workout events to a dedicated "PB Running" calendar.

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var isProcessing = false
    @Published var lastEventCount = 0
    @Published var showConfirmation = false
    
    // Writes a batch of workout events to the "PB Running" calendar.
    // Creates the calendar if it doesn't exist.
    func addEventsBatch(_ events: [EventData]) {
        print("Starting addEventsBatch with \(events.count) events")
        
        isProcessing = true
        
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Access request error: \(error.localizedDescription)")
                    self.isProcessing = false
                    return
                }
                
                if !granted {
                    print("⚠️ Calendar access denied. Check Settings > Privacy.")
                    self.isProcessing = false
                    return
                }
                
                print("✅ Access granted, processing...")
                self.processBatch(events)
            }
        }
    }
    
    private func processBatch(_ events: [EventData]) {
        let calendarName = "PB Running"
        var targetCalendar = self.findCalendar(name: calendarName)
        
        if targetCalendar == nil {
            print("📅 Calendar '\(calendarName)' not found, creating...")
            targetCalendar = self.createCalendar(name: calendarName)
        }
        
        guard let calendar = targetCalendar else {
            print("❌ Failed to find or create target calendar.")
            self.isProcessing = false
            return
        }
        
        print("Using calendar: \(calendar.title)")
        
        var count = 0
        for data in events {
            let event = EKEvent(eventStore: self.eventStore)
            event.title = data.title
            event.notes = data.notes
            event.startDate = data.date
            event.endDate = data.date
            event.isAllDay = true
            event.calendar = calendar
            
            do {
                try self.eventStore.save(event, span: .thisEvent, commit: false)
                count += 1
                print("Prepared: \(data.title)")
            } catch {
                print("❌ Error saving \(data.title): \(error)")
            }
        }
        
        do {
            print("Committing \(count) events...")
            try self.eventStore.commit()
            print("Commit successful!")
            
            DispatchQueue.main.async {
                self.lastEventCount = count
                self.isProcessing = false
                self.showConfirmation = true
            }
        } catch {
            print("Critical commit error: \(error)")
            DispatchQueue.main.async { self.isProcessing = false }
        }
    }
    
    private func findCalendar(name: String) -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)
        let found = calendars.first(where: { $0.title == name })
        if found != nil { print("Calendar found: \(name)") }
        return found
    }
    
    private func createCalendar(name: String) -> EKCalendar? {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = name
        
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = source
            print("Calendar source: \(source.title)")
        } else {
            newCalendar.source = eventStore.sources.first(where: { $0.sourceType == .local }) ?? eventStore.sources.first
            print("Using fallback calendar source")
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("Calendar '\(name)' created")
            return newCalendar
        } catch {
            print("Calendar creation error: \(error)")
            return nil
        }
    }
}
