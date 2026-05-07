import UIKit

struct TrainingPlanPDFGenerator {
    
    // Margini e dimensioni pagina A4
    private let pageWidth: CGFloat  = 595.2
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat     = 40.0
    
    private var contentWidth: CGFloat { pageWidth - margin * 2 }
    
    // Colori fase
    private func phaseColor(_ phase: TrainingPhase) -> UIColor {
        switch phase {
        case .base:  return UIColor.systemBlue
        case .build: return UIColor.systemOrange
        case .peak:  return UIColor.systemRed
        case .taper: return UIColor.systemGreen
        case .race:  return UIColor.systemPurple
        }
    }
    
    // MARK: - Entry point
    
    func generatePDF(plan: TrainingPlan, unitSystem: UnitSystem) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        return renderer.pdfData { ctx in
            // — Pagina 1: copertina + ritmi —
            ctx.beginPage()
            var y = drawCover(plan: plan, unitSystem: unitSystem, y: margin)
            y = drawPacesSection(plan: plan, unitSystem: unitSystem, y: y + 20)
            
            // — Pagine settimane —
            var currentY = y + 20
            for week in plan.weeks {
                // Se non c'è spazio sufficiente per l'header settimana, nuova pagina
                if currentY + 60 > pageHeight - margin {
                    ctx.beginPage()
                    currentY = margin
                }
                currentY = drawWeek(week: week, unitSystem: unitSystem, y: currentY)
            }
            
            // — Ultima pagina: fonti scientifiche —
            ctx.beginPage()
            drawSources(plan: plan, y: margin)
        }
    }
    
    // MARK: - Cover
    
    @discardableResult
    private func drawCover(plan: TrainingPlan, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Titolo app
        let appTitle = "🏃 PB Running — Piano di Allenamento"
        currentY = drawText(appTitle, at: currentY, font: .boldSystemFont(ofSize: 20), color: .label)
        currentY += 6
        
        // Linea separatrice
        drawLine(at: currentY)
        currentY += 12
        
        // Info gara
        let dateStr = plan.input.raceDate.formatted(date: .long, time: .omitted)
        let info: [(String, String)] = [
            ("Gara", plan.input.raceName),
            ("Distanza", plan.input.raceDistance.rawValue),
            ("Data", dateStr),
            ("Settimane", "\(plan.weeks.count)"),
            ("Giorni/sett", "\(plan.input.trainingDaysPerWeek)"),
            ("Sesso", plan.input.sex.label)
        ]
        for (label, value) in info {
            currentY = drawLabelValue(label: label, value: value, y: currentY)
        }
        
        currentY += 8
        drawLine(at: currentY)
        currentY += 12
        
        // Gap fitness
        let gap = plan.fitnessGap
        currentY = drawText(gap, at: currentY, font: .italicSystemFont(ofSize: 9), color: .secondaryLabel)
        
        return currentY
    }
    
    // MARK: - Paces
    
    @discardableResult
    private func drawPacesSection(plan: TrainingPlan, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y
        
        currentY = drawText(
            "Ritmi di Allenamento",
            at: currentY,
            font: .boldSystemFont(ofSize: 13),
            color: .label
        )
        currentY += 4
        
        let rows: [(String, String, String)] = [
            ("🟡 Recupero ", plan.paces.recoveryFormatted(unitSystem: unitSystem), "Z1 – RPE 3"),
            ("🟢 Facile", plan.paces.easyFormatted(unitSystem: unitSystem), "Z2 – RPE 4-5"),
            ("🎯 Ritmo Maratona", plan.paces.mpFormatted(unitSystem: unitSystem), "Z3 – RPE 6-7"),
            ("🟠 Soglia / Tempo", plan.paces.thresholdFormatted(unitSystem: unitSystem), "Z4 – RPE 7-8"),
            ("🔴 Interval / VO2", plan.paces.intervalFormatted(unitSystem: unitSystem), "Z5 – RPE 8-9")
        ]
        
        for (label, pace, zone) in rows {
            let line = "\(label)   \(pace)   \(zone)"
            currentY = drawText(line, at: currentY, font: .monospacedSystemFont(ofSize: 9, weight: .regular), color: .label)
        }
        
        return currentY
    }
    
    // MARK: - Week
    
    @discardableResult
    private func drawWeek(week: TrainingWeek, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y + 8
        
        // Header settimana
        let weekTitle = "Settimana \(week.weekNumber) — \(week.phase.rawValue)  |  \(unitSystem.formatDistance(week.totalKm))"
        let color = phaseColor(week.phase)
        drawRect(
            at: currentY,
            height: 18,
            color: color.withAlphaComponent(0.15)
        )
        currentY = drawText(
            weekTitle,
            at: currentY + 3,
            font: .boldSystemFont(ofSize: 10), color: color
        )
        currentY += 2
        
        // Nota settimanale
        currentY = drawText(
            week.weeklyNote,
            at: currentY,
            font: .italicSystemFont(ofSize: 8),
            color: .secondaryLabel
        )
        currentY += 4
        
        // Workout
        for workout in week.workouts {
            currentY = drawWorkoutRow(workout: workout, unitSystem: unitSystem, y: currentY)
        }
        
        return currentY
    }
    
    // MARK: - Workout row
    
    @discardableResult
    private func drawWorkoutRow(workout: Workout, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Data + tipo
        let dayStr = workout.date.formatted(.dateTime.weekday(.wide).day().month())
        let emoji  = workout.type == .rest ? "⚪️" : workout.type.emoji
        let header = "\(emoji) \(dayStr) — \(workout.title)"
        currentY = drawText(
            header,
            at: currentY,
            font: .systemFont(ofSize: 9, weight: .semibold),
            color: .label
        )
        
        // Distanza + passo
        var details: [String] = []
        if let kms = workout.distanceKm {
            details.append(unitSystem.formatDistance(kms))
        }
        if let secsPerKm = workout.paceTargetSecsPerKm {
            details.append(unitSystem.formatPace(secsPerKm))
        } else if let pace = workout.paceTarget, workout.type == .hillRepeat {
            details.append(pace)
        }
        details.append("RPE \(workout.rpe)")
        
        if !details.isEmpty {
            currentY = drawText(
                details.joined(separator: "  ·  "),
                at: currentY,
                font: .systemFont(ofSize: 8),
                color: .secondaryLabel
            )
        }
        
        // Structured sets se presenti
        if let sets = workout.structuredSets {
            currentY = drawText(
                sets,
                at: currentY,
                font: .italicSystemFont(ofSize: 8),
                color: .systemBlue.withAlphaComponent(0.8)
            )
        }
        
        return currentY + 2
    }
    
    // MARK: - Sources
    
    private func drawSources(plan: TrainingPlan, y: CGFloat) {
        var currentY = y
        currentY = drawText(
            "Fonti Scientifiche",
            at: currentY,
            font: .boldSystemFont(ofSize: 13),
            color: .label
        )
        currentY += 6
        for source in plan.scientificSources {
            currentY = drawText(
                source,
                at: currentY,
                font: .systemFont(ofSize: 8),
                color: .secondaryLabel
            )
        }
    }
    
    // MARK: - Drawing primitives
    
    @discardableResult
    private func drawText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let rect = CGRect(x: margin, y: y, width: contentWidth, height: .greatestFiniteMagnitude)
        let str  = NSString(string: text)
        let bound = str.boundingRect(
            with: CGSize(
                width: contentWidth,
                height: .greatestFiniteMagnitude
            ),
            options: .usesLineFragmentOrigin,
            attributes: attrs,
            context: nil
        )
        str.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: bound.height), withAttributes: attrs)
        return y + bound.height + 2
    }
    
    private func drawLabelValue(label: String, value: String, y: CGFloat) -> CGFloat {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.label
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel
        ]
        NSString(string: label + ":").draw(
            in: CGRect(
                x: margin,
                y: y,
                width: 100,
                height: 16
            ),
            withAttributes: labelAttr
        )
        NSString(string: value).draw(
            in: CGRect(x: margin + 110, y: y, width: contentWidth - 110, height: 16),
            withAttributes: valueAttr
        )
        return y + 16
    }
    
    private func drawLine(at y: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        UIColor.separator.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    private func drawRect(at y: CGFloat, height: CGFloat, color: UIColor) {
        let rect = CGRect(x: margin - 4, y: y, width: contentWidth + 8, height: height)
        color.setFill()
        UIBezierPath(rect: rect).fill()
    }
}
