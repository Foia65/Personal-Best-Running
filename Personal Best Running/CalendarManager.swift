import Foundation
import EventKit
import Combine

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var isProcessing = false
    @Published var lastEventCount = 0
    @Published var showConfirmation = false
    
    func addEventsBatch(_ events: [EventData]) {
        print("🚀 Avvio addEventsBatch con \(events.count) eventi")
        
        isProcessing = true
        
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Errore richiesta accesso: \(error.localizedDescription)")
                    self.isProcessing = false
                    return
                }
                
                if !granted {
                    print("⚠️ Accesso NEGATO al calendario. Controlla Impostazioni > Privacy.")
                    self.isProcessing = false
                    return
                }
                
                print("✅ Accesso garantito, inizio elaborazione...")
                self.processBatch(events)
            }
        }
    }
    
    private func processBatch(_ events: [EventData]) {
        let calendarName = "PB Running"
        var targetCalendar = self.findCalendar(name: calendarName)
        
        if targetCalendar == nil {
            print("📅 Calendario '\(calendarName)' non trovato, provo a crearlo...")
            targetCalendar = self.createCalendar(name: calendarName)
        }
        
        guard let calendar = targetCalendar else {
            print("❌ Impossibile trovare o creare il calendario target.")
            self.isProcessing = false
            return
        }
        
        print("📍 Usando calendario: \(calendar.title) (ID: \(calendar.calendarIdentifier))")
        
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
                print("📝 Preparato: \(data.title)")
            } catch {
                print("❌ Errore durante il salvataggio di \(data.title): \(error)")
            }
        }
        
        do {
            print("💾 Eseguo il commit di \(count) eventi...")
            try self.eventStore.commit()
            print("🎉 Commit completato con successo!")
            
            DispatchQueue.main.async {
                self.lastEventCount = count
                self.isProcessing = false
                self.showConfirmation = true
            }
        } catch {
            print("❌ Errore critico nel commit: \(error)")
            DispatchQueue.main.async { self.isProcessing = false }
        }
    }
    
    private func findCalendar(name: String) -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)
        let found = calendars.first(where: { $0.title == name })
        if found != nil { print("🔍 Calendario trovato: \(name)") }
        return found
    }
    
    private func createCalendar(name: String) -> EKCalendar? {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = name
        
        if let source = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = source
            print("ℹ️ Sorgente calendario impostata su: \(source.title)")
        } else {
            newCalendar.source = eventStore.sources.first(where: { $0.sourceType == .local }) ?? eventStore.sources.first
            print("⚠️ Usata sorgente di backup per il calendario")
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            print("✅ Calendario '\(name)' creato con successo")
            return newCalendar
        } catch {
            print("❌ Errore creazione calendario: \(error)")
            return nil
        }
    }
}
