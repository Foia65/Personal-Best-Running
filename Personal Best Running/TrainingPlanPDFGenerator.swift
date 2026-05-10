import UIKit

struct PDFDocumentItem: Identifiable {
    let id = UUID()
    let url: URL
}

final class TrainingPlanPDFGenerator {
    
    // MARK: - Constants
    private enum Layout {
        static let pageWidth: CGFloat = 595.2
        static let pageHeight: CGFloat = 841.8
        static let margin: CGFloat = 45.0
        static let contentWidth: CGFloat = pageWidth - (margin * 2)
        static let headerHeight: CGFloat = 22.0
    }
    
    // MARK: - Entry point
    
    func generatePDF(plan: TrainingPlan, unitSystem: UnitSystem) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let bounds = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        
        return renderer.pdfData { ctx in
            // — Page 1: Cover and Paces —
            ctx.beginPage()
            var currentY = drawCover(plan: plan, y: Layout.margin)
            currentY = drawPacesSection(plan: plan, unitSystem: unitSystem, y: currentY + 30)
            
            // — Training Weeks —
            for week in plan.weeks {
                // Check for page break (minimum space for week header + 1 workout)
                if currentY + 120 > Layout.pageHeight - Layout.margin {
                    ctx.beginPage()
                    currentY = Layout.margin
                }
                currentY = drawWeek(week: week, unitSystem: unitSystem, y: currentY) + 15
            }
            
            // — Final Page: Scientific Sources —
            ctx.beginPage()
            drawSources(plan: plan, y: Layout.margin)
        }
    }
    
    // MARK: - Sections Drawing
    
    private func drawCover(plan: TrainingPlan, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // App Title
        currentY = drawText(
            "🏃 PB Running",
            at: currentY,
            font: .boldSystemFont(ofSize: 24),
            color: .label
        )
        currentY = drawText(
            "Piano di Allenamento Personalizzato",
            at: currentY,
            font: .systemFont(ofSize: 14),
            color: .secondaryLabel
        )
        
        currentY += 15
        drawSeparator(at: currentY)
        currentY += 20
        
        // Race Info Grid
        let raceDate = plan.input.raceDate.formatted(date: .long, time: .omitted)
        let infoItems = [
            ("Gara", plan.input.raceName),
            ("Distanza", plan.input.raceDistance.rawValue),
            ("Data", raceDate),
            ("Volume", "\(plan.weeks.count) settimane")
        ]
        
        for item in infoItems {
            currentY = drawKeyValuePair(key: item.0, value: item.1, y: currentY)
        }
        
        currentY += 10
        let gapFont = UIFont.italicSystemFont(ofSize: 10)
        currentY = drawText(plan.fitnessGap, at: currentY, font: gapFont, color: .secondaryLabel)
        
        return currentY
    }
    
    private func drawPacesSection(plan: TrainingPlan, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y
        
        currentY = drawSectionHeader("Andature di Riferimento", y: currentY, color: .label)
        
        // swiftlint:disable:next large_tuple
        let paces: [(String, String, String, UIColor)] = [
            ("Recupero", plan.paces.recoveryFormatted(unitSystem: unitSystem), "Z1 - RPE 3", .systemBlue),
            ("Corsa Facile", plan.paces.easyFormatted(unitSystem: unitSystem), "Z2 - RPE 4-5", .systemGreen),
            ("Ritmo Maratona", plan.paces.mpFormatted(unitSystem: unitSystem), "Z3 - RPE 6-7", .systemOrange),
            ("Soglia / Tempo", plan.paces.thresholdFormatted(unitSystem: unitSystem), "Z4 - RPE 7-8", .systemRed),
            ("Intervalli / VO2", plan.paces.intervalFormatted(unitSystem: unitSystem), "Z5 - RPE 9+", .systemPurple)
        ]
        
        for pace in paces {
            currentY = drawPaceRow(label: pace.0, pace: pace.1, zone: pace.2, color: pace.3, y: currentY)
        }
        
        return currentY
    }
    
    private func drawWeek(week: TrainingWeek, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y
        let color = phaseColor(for: week.phase)
        
        // Week Header like WeekHeaderView
        let title = "Settimana \(week.weekNumber) — \(week.phase.rawValue.uppercased())"
        drawBackgroundRect(at: currentY, height: Layout.headerHeight, color: color.withAlphaComponent(0.1))
        
        let headerFont = UIFont.boldSystemFont(ofSize: 11)
        currentY = drawText(title, at: currentY + 4, font: headerFont, color: color)
        
        // Total Volume
        let volStr = "Volume stimato: \(unitSystem.formatDistance(week.totalKm))"
        currentY = drawText(volStr, at: currentY, font: .systemFont(ofSize: 9), color: .secondaryLabel)
        
        if !week.weeklyNote.isEmpty {
            currentY = drawText(week.weeklyNote, at: currentY, font: .italicSystemFont(ofSize: 9), color: .label)
        }
        
        currentY += 5
        
        for workout in week.workouts {
            currentY = drawWorkoutRow(workout: workout, unitSystem: unitSystem, y: currentY)
        }
        
        return currentY
    }
    
    private func drawWorkoutRow(workout: Workout, unitSystem: UnitSystem, y: CGFloat) -> CGFloat {
        var currentY = y + 5
        
        let dayStr = workout.date.formatted(.dateTime.weekday(.wide).day().month())
        let emoji = workout.type == .rest ? "⚪️" : workout.type.emoji
        let title = "\(emoji) \(dayStr) · \(workout.title)"
        
        currentY = drawText(title, at: currentY, font: .boldSystemFont(ofSize: 10), color: .label)
        
        var meta: [String] = []
        if let kms = workout.distanceKm { meta.append(unitSystem.formatDistance(kms)) }
        if let pace = workout.paceTargetSecsPerKm { meta.append(unitSystem.formatPace(pace)) }
        meta.append("RPE \(workout.rpe)")
        
        currentY = drawText(
            meta.joined(separator: "  |  "),
            at: currentY,
            font: .monospacedSystemFont(ofSize: 8, weight: .regular),
            color: .secondaryLabel
        )
        
        if let sets = workout.structuredSets {
            currentY = drawText(sets, at: currentY, font: .systemFont(ofSize: 9), color: .systemBlue)
        }
        
        drawSeparator(at: currentY + 2, color: UIColor.separator.withAlphaComponent(0.3))
        return currentY + 5
    }
    
    private func drawSources(plan: TrainingPlan, y: CGFloat) {
        var currentY = y
        currentY = drawSectionHeader("Fonti Scientifiche e Note", y: currentY, color: .label)
        
        let notes = """
        I ritmi di allenamento sono calcolati tramite il sistema VDOT di Jack Daniels. 
        La distribuzione settimanale segue il principio di polarizzazione 80/20 (Seiler).
        """
        currentY = drawText(notes, at: currentY, font: .systemFont(ofSize: 10), color: .label)
        currentY += 10
        
        for source in plan.scientificSources {
            currentY = drawText("• \(source)", at: currentY, font: .systemFont(ofSize: 9), color: .secondaryLabel)
        }
    }
    
    // MARK: - Helper Methods
    
    private func drawSectionHeader(_ text: String, y: CGFloat, color: UIColor) -> CGFloat {
        let currentY = drawText(text.uppercased(), at: y, font: .boldSystemFont(ofSize: 13), color: color)
        drawSeparator(at: currentY)
        return currentY + 10
    }
    
    private func drawPaceRow(label: String, pace: String, zone: String, color: UIColor, y: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 10)
        let boldFont = UIFont.boldSystemFont(ofSize: 10)
        
        // Indicator dot/bar
        let dotRect = CGRect(x: Layout.margin, y: y + 2, width: 4, height: 12)
        color.setFill()
        UIBezierPath(roundedRect: dotRect, cornerRadius: 1).fill()
        
        NSString(string: label).draw(
            at: CGPoint(x: Layout.margin + 12, y: y),
            withAttributes: [.font: font,
                             .foregroundColor: UIColor.label]
        )
        
        let paceX = Layout.pageWidth - Layout.margin - 120
        NSString(string: pace).draw(
            at: CGPoint(x: paceX, y: y),
            withAttributes: [.font: boldFont,
                             .foregroundColor: UIColor.label]
        )
        
        let zoneX = Layout.pageWidth - Layout.margin - 40
        NSString(string: zone).draw(
            at: CGPoint(x: zoneX, y: y),
            withAttributes: [.font: boldFont,
                             .foregroundColor: color]
        )
        
        return y + 18
    }
    
    private func drawKeyValuePair(key: String, value: String, y: CGFloat) -> CGFloat {
        let keyFont = UIFont.boldSystemFont(ofSize: 10)
        let valFont = UIFont.systemFont(ofSize: 10)
        
        NSString(string: "\(key):").draw(
            at: CGPoint(x: Layout.margin, y: y),
            withAttributes: [.font: keyFont]
        )
        
        NSString(string: value).draw(
            at: CGPoint(x: Layout.margin + 80, y: y),
            withAttributes: [.font: valFont,
                             .foregroundColor: UIColor.secondaryLabel]
        )
        
        return y + 16
    }
    
    @discardableResult
    private func drawText(_ text: String, at y: CGFloat, font: UIFont, color: UIColor) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = CGSize(width: Layout.contentWidth, height: .greatestFiniteMagnitude)
        let textRect = attributedString.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        
        let drawRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: textRect.height)
        attributedString.draw(in: drawRect)
        
        return y + textRect.height + 4
    }
    
    private func drawSeparator(at y: CGFloat, color: UIColor = .separator) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: Layout.margin, y: y))
        path.addLine(to: CGPoint(x: Layout.pageWidth - Layout.margin, y: y))
        color.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }
    
    private func drawBackgroundRect(at y: CGFloat, height: CGFloat, color: UIColor) {
        let rect = CGRect(x: Layout.margin - 5, y: y, width: Layout.contentWidth + 10, height: height)
        color.setFill()
        UIRectFill(rect)
    }
    
    private func phaseColor(for phase: TrainingPhase) -> UIColor {
        switch phase {
        case .base: return .systemBlue
        case .build: return .systemOrange
        case .peak: return .systemRed
        case .taper: return .systemGreen
        case .race: return .systemPurple
        }
    }
}
