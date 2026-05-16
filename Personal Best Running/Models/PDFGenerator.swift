// Gestisce la creazione do un PDF con tutti gli allenamenti
 
import UIKit
import SwiftUI

struct PDFDocumentItem: Identifiable {
    let id = UUID()
    let url: URL
}

class TrainingPlanPDFGenerator {
    
    // Configurazione layout
    private let pageWidth: CGFloat = 595.2 // A4
    private let pageHeight: CGFloat = 841.8 // A4
    private let margin: CGFloat = 40
    private var currentY: CGFloat = 0
    
    func generatePDF(plan: TrainingPlan, unitSystem: UnitSystem) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PB Running App",
            kCGPDFContextAuthor: "Jack Daniels VDOT System",
            kCGPDFContextTitle: "Piano di Allenamento: \(plan.input.raceName)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            currentY = margin
            
            // 1. Header (Titolo e Info Gara)
            drawHeader(plan: plan)
            
            // 2. Profilo Atleta e Andature
            drawAthleteProfile(plan: plan, unitSystem: unitSystem)
            
            // 3. Tabella Andature (Paces)
            drawPacesTable(plan: plan, unitSystem: unitSystem)
            
            // 4. Calendario Allenamenti
            drawCalendar(plan: plan, unitSystem: unitSystem, context: context)
            
            // 5. Fonti e Note finali
            drawFooter(plan: plan)
        }
        
        return data
    }
    
    // MARK: - Componenti di Disegno
    
    private func drawHeader(plan: TrainingPlan) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.black
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // Nome Gara
        let title = "🏃‍♂️ " +  plan.input.raceName.uppercased()
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += 28
        
        // Info Sottotitolo
        let subtitle = "\(plan.input.raceDistance.rawValue) • \(plan.input.raceDate.formatted(date: .abbreviated, time: .omitted)) • \(plan.weeks.count) Settimane"
        subtitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subtitleAttributes)
        
        currentY += 20
        drawDivider()
        currentY += 15
    }
    // swiftlint:disable:next unused_parameter
    private func drawAthleteProfile(plan: TrainingPlan, unitSystem: UnitSystem) {
        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.secondaryLabel]
        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.label]
        
        // VDOT attuale
        "VDOT ATTUALE".draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttr)
        String(format: "%.1f", plan.paces.vdot).draw(at: CGPoint(x: margin, y: currentY + 12), withAttributes: valueAttr)
        
        // Target Time
        "TARGET GARA".draw(at: CGPoint(x: margin + 150, y: currentY), withAttributes: labelAttr)
        formatTime(plan.input.targetTime).draw(at: CGPoint(x: margin + 150, y: currentY + 12), withAttributes: valueAttr)
        
        currentY += 45
        
        let gapAttr: [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
        let gapRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin*2), height: 40)
        plan.fitnessGap.draw(in: gapRect, withAttributes: gapAttr)
        
        currentY += 40
    }
    
    private func drawPacesTable(plan: TrainingPlan, unitSystem: UnitSystem) {
        "ANDATURE DI RIFERIMENTO".draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
        currentY += 15
        
        let paces = plan.paces
        let rows = [
            ("Easy (E)", paces.easyFormatted(unitSystem: unitSystem), "Z2 / Recupero"),
            ("Marathon (M)", paces.mpFormatted(unitSystem: unitSystem), "Z3 / Aerobico"),
            ("Threshold (T)", paces.thresholdFormatted(unitSystem: unitSystem), "Z4 / Soglia"),
            ("Interval (I)", paces.intervalFormatted(unitSystem: unitSystem), "Z5 / VO2Max"),
            ("Repetition (R)", paces.repetitionFormatted(unitSystem: unitSystem), "Velocità")
        ]
        
        for row in rows {
            let rowText = "\(row.0):"
            rowText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
            row.1.draw(at: CGPoint(x: margin + 120, y: currentY), withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)])
            row.2.draw(at: CGPoint(x: margin + 220, y: currentY), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.secondaryLabel])
            currentY += 18
        }
        
        currentY += 20
        drawDivider()
        currentY += 20
    }
    
    private func drawCalendar(plan: TrainingPlan, unitSystem: UnitSystem, context: UIGraphicsPDFRendererContext) {
        for week in plan.weeks {
            // Controllo spazio rimanente per la sezione settimana
            if currentY > pageHeight - 150 {
                context.beginPage()
                currentY = margin
            }
            
            // Header Settimana
            let weekTitle = "SETTIMANA \(week.weekNumber) - \(week.phase.rawValue)".uppercased()
            weekTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.systemBlue])
            
            let volume = "Volume: \(unitSystem.formatDistance(week.totalKm))"
            let volWidth = volume.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11)]).width
            volume.draw(at: CGPoint(x: pageWidth - margin - volWidth, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11)])
            
            currentY += 18
            
            // Nota settimanale
            let noteRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin*2), height: 30)
            week.weeklyNote.draw(in: noteRect, withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray])
            currentY += 25
            
            // Workout
            for workout in week.workouts {
                if currentY > pageHeight - 60 {
                    context.beginPage()
                    currentY = margin
                }
                
                let dateStr = workout.date.formatted(.dateTime.weekday().day().month())
                let workoutTitle = "\(workout.title) \(workout.distanceKm != nil ? "(\(unitSystem.formatDistance(workout.distanceKm!)))" : "")"
                
                let dateAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.secondaryLabel]
                let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10)]
                
                dateStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: dateAttr)
                workoutTitle.draw(at: CGPoint(x: margin + 80, y: currentY), withAttributes: titleAttr)
                
                if let pace = workout.paceTargetSecsPerKm {
                    let paceStr = unitSystem.formatPace(pace)
                    let paceWidth = paceStr.size(withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)]).width
                    paceStr.draw(at: CGPoint(x: pageWidth - margin - paceWidth, y: currentY), withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular)])
                }
                
                currentY += 14
                
                // Descrizione sintetica
                let descRect = CGRect(x: margin + 80, y: currentY, width: pageWidth - margin - 150, height: 40)
                let desc = workout.structuredSets ?? workout.description
                desc.draw(in: descRect, withAttributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.darkGray])
                
                currentY += 22
            }
            currentY += 10
        }
    }
    
    // swiftlint:disable:next unused_parameter
    private func drawFooter(plan: TrainingPlan) {
        if currentY > pageHeight - 100 { return } // Evitiamo di creare una pagina solo per il footer se troppo lungo
        
        currentY += 10
        drawDivider()
        currentY += 10
        
        "FONTI SCIENTIFICHE E NOTE".draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)])
        currentY += 15
        
        let footerText = "Metodologia: Jack Daniels' Running Formula (VDOT). Distribuzione intensità 80/20. Progressione volume < 10% settimanale."
        footerText.draw(in: CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 50), withAttributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.secondaryLabel])
    }
    
    // MARK: - Helpers
    
    private func drawDivider() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: currentY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        UIColor.systemGray5.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hour = Int(seconds) / 3600
        let minute = (Int(seconds) % 3600) / 60
        let second = Int(seconds) % 60
        if hour > 0 { return String(format: "%d:%02d:%02d", hour, minute, second) }
        return String(format: "%d:%02d", minute, second)
    }
}
