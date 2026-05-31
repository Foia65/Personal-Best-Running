// Gestisce la creazione do un PDF con tutti gli allenamenti
 
import UIKit
import SwiftUI

struct PDFDocumentItem: Identifiable {
    let id = UUID()
    let url: URL
}

class TrainingPlanPDFGenerator {
    
    // Configurazione del layout A4 standard (72 punti per pollice)
    private let pageWidth: CGFloat = 595.2
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 40
    private var currentY: CGFloat = 0
    
    func generatePDF(plan: TrainingPlan, unitSystem: UnitSystem) -> Data {
        // CORREZIONE: Convertiamo le chiavi CFString in String per evitare errori di subscripting
        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "PB Running App",
            kCGPDFContextTitle as String: "Piano di Allenamento: \(plan.input.raceName)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            currentY = margin
            
            // 1. Header Principale con Riepilogo e Distanza Totale
            drawHeader(plan: plan, unitSystem: unitSystem)
            
            // 2. Profilo VDOT dell'Atleta
            drawAthleteProfile(plan: plan)
            
            // 3. Tabella dei Ritmi di Riferimento (Jack Daniels VDOT)
            drawPacesTable(plan: plan, unitSystem: unitSystem)
            
            // 4. Calendario degli Allenamenti suddiviso per Fasi
            drawCalendarByPhases(plan: plan, unitSystem: unitSystem, context: context)
            
            // 5. Piè di pagina
            drawFooter()
        }
        
        return data
    }
    
    // MARK: - Disegno Header Principale
    private func drawHeader(plan: TrainingPlan, unitSystem: UnitSystem) {
        let totalDistance = plan.weeks.reduce(0) { $0 + $1.totalKm }
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ]

        let title = plan.input.raceName.uppercased()
        title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += 26
        
        let raceDateStr = plan.input.raceDate.formatted(date: .abbreviated, time: .omitted)
        let infoLine = "\(plan.input.raceDistance.rawValue) • Obiettivo: \(formatTime(plan.input.targetTime)) • \(plan.weeks.count) Settimane • Gara: \(raceDateStr)"
        infoLine.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subtitleAttributes)
        currentY += 18
        
        let totalDistStr = "DISTANZA TOTALE DEL PROGRAMMA: \(unitSystem.formatDistance(totalDistance))"
        totalDistStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.systemOrange
        ])
        
        currentY += 22
        drawDivider()
        currentY += 15
    }

    // MARK: - Disegno Calendario Avanzato per Fasi
    private func drawCalendarByPhases(plan: TrainingPlan, unitSystem: UnitSystem, context: UIGraphicsPDFRendererContext) {
        var currentPhase: String?
        
        for week in plan.weeks {
            if currentY > pageHeight - 120 {
                context.beginPage()
                currentY = margin
            }
            
            // CORREZIONE: Gestione coerente con la stringa/enum della fase proveniente da TrainingPlanView
            if week.phase.rawValue != currentPhase {
                currentPhase = week.phase.rawValue
                drawPhaseHeader(phaseName: week.phase.rawValue)
            }
            
            let weekTitle = "SETTIMANA \(week.weekNumber)".uppercased()
            weekTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)])
            
            let volStr = "Volume: \(unitSystem.formatDistance(week.totalKm))"
            let volWidth = volStr.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11)]).width
            volStr.draw(at: CGPoint(x: pageWidth - margin - volWidth, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11)])
            
            currentY += 16
            
            let noteRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 32)
            week.weeklyNote.draw(in: noteRect, withAttributes: [
                .font: UIFont.italicSystemFont(ofSize: 9),
                .foregroundColor: UIColor.secondaryLabel
            ])
            currentY += 26
            
            for workout in week.workouts {
                if currentY > pageHeight - 65 {
                    context.beginPage()
                    currentY = margin
                }
                
                drawWorkoutRow(workout: workout, unitSystem: unitSystem)
            }
            
            currentY += 10
            drawDivider(color: .systemGray6)
            currentY += 10
        }
    }
    
    private func drawPhaseHeader(phaseName: String) {
        currentY += 5
        let rect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 22)
        
        let phaseBgColor = UIColor.systemGroupedBackground
        phaseBgColor.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
        
        let phaseAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.systemBlue
        ]
        
        let fullPhaseTitle = "FASE DI ALLENAMENTO: \(phaseName.uppercased())"
        let size = fullPhaseTitle.size(withAttributes: phaseAttr)
        fullPhaseTitle.draw(at: CGPoint(x: margin + 8, y: currentY + (22 - size.height) / 2), withAttributes: phaseAttr)
        
        currentY += 32
    }
    
    private func drawWorkoutRow(workout: Workout, unitSystem: UnitSystem) {
        let dateStr = workout.date.formatted(.dateTime.weekday(.abbreviated).day().month())
        let titleStr = workout.title
        
        dateStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.secondaryLabel
        ])
        
        titleStr.draw(at: CGPoint(x: margin + 65, y: currentY), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)])
        
        if let pace = workout.paceTargetSecsPerKm, workout.type != .rest {
            let pStr = unitSystem.formatPace(pace)
            let pWidth = pStr.size(withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 9, weight: .semibold)]).width
            pStr.draw(at: CGPoint(x: pageWidth - margin - pWidth, y: currentY), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: UIColor.label
            ])
        }
        
        currentY += 14
        
        var detailText = workout.description
        if let structuredSets = workout.structuredSets, !structuredSets.isEmpty {
            detailText += " \nSets: \(structuredSets)"
        }
        
        let detailRect = CGRect(x: margin + 65, y: currentY, width: pageWidth - margin - 140, height: 28)
        detailText.draw(in: detailRect, withAttributes: [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.darkGray
        ])
        
        if let kms = workout.distanceKm {
            let distStr = unitSystem.formatDistance(kms)
            let distWidth = distStr.size(withAttributes: [.font: UIFont.systemFont(ofSize: 8.5)]).width
            distStr.draw(at: CGPoint(x: pageWidth - margin - distWidth, y: currentY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 8.5),
                .foregroundColor: UIColor.secondaryLabel
            ])
        }
        
        currentY += 22
    }

    private func drawAthleteProfile(plan: TrainingPlan) {
        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8.5), .foregroundColor: UIColor.secondaryLabel]
        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13), .foregroundColor: UIColor.label]
        
        "VDOT ATTUALE".draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttr)
        String(format: "%.1f", plan.paces.vdot).draw(at: CGPoint(x: margin, y: currentY + 11), withAttributes: valueAttr)
        
//        "VALUTAZIONE GAP DI FITNESS".draw(at: CGPoint(x: margin + 110, y: currentY), withAttributes: labelAttr)
//        let gapRect = CGRect(x: margin + 110, y: currentY + 11, width: pageWidth - margin * 2 - 110, height: 28)
//        plan.fitnessGap.draw(in: gapRect, withAttributes: [.font: UIFont.systemFont(ofSize: 9.5), .foregroundColor: UIColor.label])
        
        currentY += 42
    }
    
    private func drawPacesTable(plan: TrainingPlan, unitSystem: UnitSystem) {
        let headerAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10)]
        "RITMI DI ALLENAMENTO DI RIFERIMENTO (MIN/KM)".draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttr)
        currentY += 15
        
        let passi = plan.paces
        let paceData = [
            ("Easy (E)", passi.easyFormatted(unitSystem: unitSystem)),
            ("Marathon (M)", passi.mpFormatted(unitSystem: unitSystem)),
            ("Threshold (T)", passi.thresholdFormatted(unitSystem: unitSystem)),
            ("Interval (I)", passi.intervalFormatted(unitSystem: unitSystem)),
            ("Repetition (R)", passi.repetitionFormatted(unitSystem: unitSystem))
        ]
        
        var tempX = margin
        let columnWidth = (pageWidth - margin * 2) / 5
        
        for item in paceData {
            item.0.draw(at: CGPoint(x: tempX, y: currentY), withAttributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.secondaryLabel])
            item.1.draw(at: CGPoint(x: tempX, y: currentY + 11), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10.5)])
            tempX += columnWidth
        }
        
        currentY += 35
        drawDivider()
        currentY += 15
    }

    private func drawFooter() {
        let footerStr = "Generato da PB Running • Logiche scientifiche basate sul sistema VDOT di Jack Daniels e polarizzazione 80/20"
        let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: UIColor.lightGray]
        let size = footerStr.size(withAttributes: attr)
        footerStr.draw(at: CGPoint(x: (pageWidth - size.width) / 2, y: pageHeight - 30), withAttributes: attr)
    }
    
    private func drawDivider(color: UIColor = .systemGray5) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: currentY))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        color.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let ore = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        let sec = Int(seconds) % 60
        return ore > 0 ? String(format: "%d:%02d:%02d", ore, min, sec) : String(format: "%d:%02d", min, sec)
    }
}
