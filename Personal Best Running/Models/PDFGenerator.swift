// MARK: - TrainingPlanPDFGenerator
//
// Generates a complete PDF of the training plan.
// All strings are localized via AppLocalizedString + explicit locale.
// Distances and paces respect the user's chosen UnitSystem (metric/imperial).

import UIKit
import SwiftUI

struct PDFDocumentItem: Identifiable {
    let id = UUID()
    let url: URL
}

class TrainingPlanPDFGenerator {

    // Standard A4 layout configuration (72 points per inch)
    private let pageWidth: CGFloat = 595.2
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 40
    private var currentY: CGFloat = 0
    private var unitSystem: UnitSystem = .metric
    private var locale: Locale = .current

    // MARK: - Public API

    func generatePDF(plan: TrainingPlan, unitSystem: UnitSystem, locale: Locale) -> Data {
        self.unitSystem = unitSystem
        self.locale = locale

        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "PB Running App",
            kCGPDFContextTitle as String: String(
                localized: LocalizedStringResource(
                    "pdf.title",
                    defaultValue: "Piano di Allenamento: \(plan.input.raceName)"
                )
            )
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let data = renderer.pdfData { context in
            context.beginPage()
            currentY = margin

            drawHeader(plan: plan)
            drawAthleteProfile(plan: plan)
            drawPacesTable(plan: plan)
            drawCalendarByPhases(plan: plan, context: context)
            drawFooter()
        }

        return data
    }

    // MARK: - Header

    private func drawHeader(plan: TrainingPlan) {
        let totalDistance = plan.weeks.reduce(0) { $0 + $1.totalKm }

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.secondaryLabel
        ]

        plan.input.raceName.uppercased().draw(
            at: CGPoint(x: margin, y: currentY),
            withAttributes: titleAttributes
        )
        currentY += 26

        let raceDistanceStr = AppLocalizedString.resolve(plan.input.raceDistance.localizedName, locale: locale)
        let goalTimeStr = formatTime(plan.input.targetTime)
        let raceDateStr = plan.input.raceDate.formatted(date: .abbreviated, time: .omitted)

        let info = AppLocalizedString.formatted(
            LocalizedStringResource(
                "pdf.header.info",
                defaultValue: "%1$@ • Obiettivo: %2$@ • %3$lld Settimane • Gara: %4$@"
            ),
            locale: locale,
            arguments: [raceDistanceStr, goalTimeStr, plan.weeks.count, raceDateStr]
        )
        info.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subtitleAttributes)
        currentY += 18

        let totalDistStr = AppLocalizedString.formatted(
            LocalizedStringResource(
                "pdf.header.totalDistance",
                defaultValue: "DISTANZA TOTALE DEL PROGRAMMA: %1$@"
            ),
            locale: locale,
            arguments: [unitSystem.formatDistance(totalDistance)]
        )
        totalDistStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.systemOrange
        ])
        currentY += 22

        drawDivider()
        currentY += 15
    }

    // MARK: - Athlete Profile (VDOT)

    private func drawAthleteProfile(plan: TrainingPlan) {
        let labelAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let valueAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.label
        ]

        let vdotLabel = AppLocalizedString.resolve(
            LocalizedStringResource("pdf.athlete.vdot", defaultValue: "VDOT ATTUALE"),
            locale: locale
        )
        vdotLabel.draw(at: CGPoint(x: margin, y: currentY), withAttributes: labelAttr)
        String(format: "%.1f", plan.paces.vdot).draw(
            at: CGPoint(x: margin, y: currentY + 11),
            withAttributes: valueAttr
        )

        currentY += 42
    }

    // MARK: - Paces Table

    private func drawPacesTable(plan: TrainingPlan) {
        let headerAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 10)]
        let header = AppLocalizedString.resolve(
            LocalizedStringResource("pdf.paces.header", defaultValue: "RITMI DI ALLENAMENTO DI RIFERIMENTO"),
            locale: locale
        )
        header.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttr)
        currentY += 15

        let passi = plan.paces
        let paceData: [(String, String)] = [
            (AppLocalizedString.resolve(
                LocalizedStringResource("pdf.paces.easy", defaultValue: "Easy (E)"), locale: locale
            ), passi.easyFormatted(unitSystem: unitSystem)),
            (AppLocalizedString.resolve(
                LocalizedStringResource("pdf.paces.marathon", defaultValue: "Marathon (M)"), locale: locale
            ), passi.mpFormatted(unitSystem: unitSystem)),
            (AppLocalizedString.resolve(
                LocalizedStringResource("pdf.paces.threshold", defaultValue: "Threshold (T)"), locale: locale
            ), passi.thresholdFormatted(unitSystem: unitSystem)),
            (AppLocalizedString.resolve(
                LocalizedStringResource("pdf.paces.interval", defaultValue: "Interval (I)"), locale: locale
            ), passi.intervalFormatted(unitSystem: unitSystem)),
            (AppLocalizedString.resolve(
                LocalizedStringResource("pdf.paces.repetition", defaultValue: "Repetition (R)"), locale: locale
            ), passi.repetitionFormatted(unitSystem: unitSystem))
        ]

        var tempX = margin
        let columnWidth = (pageWidth - margin * 2) / CGFloat(paceData.count)

        for (label, value) in paceData {
            label.draw(
                at: CGPoint(x: tempX, y: currentY),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            value.draw(
                at: CGPoint(x: tempX, y: currentY + 11),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10.5)]
            )
            tempX += columnWidth
        }

        currentY += 35
        drawDivider()
        currentY += 15
    }

    // MARK: - Calendar by Phase

    private func drawCalendarByPhases(plan: TrainingPlan, context: UIGraphicsPDFRendererContext) {
        var currentPhase: String?

        for week in plan.weeks {
            if currentY > pageHeight - 120 {
                context.beginPage()
                currentY = margin
            }

            let phaseName = AppLocalizedString.resolve(week.phase.localizedName, locale: locale)
            if phaseName != currentPhase {
                currentPhase = phaseName
                drawPhaseHeader(phaseName: phaseName)
            }

            let weekTitle = AppLocalizedString.formatted(
                LocalizedStringResource(
                    "pdf.week.header",
                    defaultValue: "SETTIMANA %1$lld"
                ),
                locale: locale,
                arguments: [week.weekNumber]
            )
                .uppercased()
            weekTitle.draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12)]
            )

            let volStr = AppLocalizedString.formatted(
                LocalizedStringResource("pdf.week.volume", defaultValue: "Volume: %1$@"),
                locale: locale,
                arguments: [unitSystem.formatDistance(week.totalKm)]
            )
            let volWidth = volStr.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11)]).width
            volStr.draw(
                at: CGPoint(x: pageWidth - margin - volWidth, y: currentY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
            )
            currentY += 16

            let noteText = week.localizedWeeklyNote(locale: locale)
            let noteRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 32)
            noteText.draw(in: noteRect, withAttributes: [
                .font: UIFont.italicSystemFont(ofSize: 9),
                .foregroundColor: UIColor.secondaryLabel
            ])
            currentY += 26

            for workout in week.workouts {
                if currentY > pageHeight - 65 {
                    context.beginPage()
                    currentY = margin
                }
                drawWorkoutRow(workout: workout)
            }

            currentY += 10
            drawDivider(color: .systemGray6)
            currentY += 10
        }
    }

    private func drawPhaseHeader(phaseName: String) {
        currentY += 8
        let rect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 28)

        UIColor.systemGroupedBackground.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 6).fill()

        // Blue left border to highlight phase change
        let borderRect = CGRect(x: margin, y: currentY, width: 4, height: 28)
        UIColor.systemBlue.setFill()
        UIBezierPath(roundedRect: borderRect, cornerRadius: 2).fill()

        let phaseAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.systemBlue
        ]

        let size = phaseName.size(withAttributes: phaseAttr)
        phaseName.draw(
            at: CGPoint(x: margin + 14, y: currentY + (28 - size.height) / 2),
            withAttributes: phaseAttr
        )
        currentY += 36
    }

    // MARK: - Workout Row

    private func drawWorkoutRow(workout: Workout) {
        let dateStr = workout.date.formatted(.dateTime.weekday(.abbreviated).day().month())

        dateStr.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.secondaryLabel
        ])

        let titleStr = workout.localizedTitle(locale: locale)
        titleStr.draw(
            at: CGPoint(x: margin + 65, y: currentY),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10)]
        )

        if let pace = workout.paceTargetSecsPerKm, workout.type != .rest {
            let pStr = unitSystem.formatPace(pace)
            let pWidth = pStr.size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold)
            ]).width
            pStr.draw(at: CGPoint(x: pageWidth - margin - pWidth, y: currentY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: UIColor.label
            ])
        }

        currentY += 14

        let descText = workout.localizedDescription(locale: locale)
        let descRect = CGRect(x: margin + 65, y: currentY, width: pageWidth - margin - 140, height: 28)
        descText.draw(in: descRect, withAttributes: [
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

        if workout.type != .rest {
            let rpeLabel = AppLocalizedString.resolve(
                LocalizedStringResource("pdf.workout.rpe", defaultValue: "RPE"),
                locale: locale
            )
            let rpeStr = "\(rpeLabel): \(workout.rpe)"
            rpeStr.draw(at: CGPoint(x: margin + 65, y: currentY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.secondaryLabel
            ])
            currentY += 12
        }

        // Structured sets (if present)
        if let localizedSets = workout.localizedStructuredSets(locale: locale) {
            let setsRect = CGRect(x: margin + 65, y: currentY, width: pageWidth - margin - 140, height: 28)
            localizedSets.draw(in: setsRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.darkGray
            ])
            currentY += 22
        }
    }

    // MARK: - Footer

    private func drawFooter() {
        let footerStr = AppLocalizedString.resolve(
            LocalizedStringResource(
                "pdf.footer",
                defaultValue: "Generato da Personal Best Running"
            ),
            locale: locale
        )
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7),
            .foregroundColor: UIColor.lightGray
        ]
        let size = footerStr.size(withAttributes: attr)
        footerStr.draw(
            at: CGPoint(x: (pageWidth - size.width) / 2, y: pageHeight - 30),
            withAttributes: attr
        )
    }

    // MARK: - Utility

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
        return ore > 0
            ? String(format: "%d:%02d:%02d", ore, min, sec)
            : String(format: "%d:%02d", min, sec)
    }
}
