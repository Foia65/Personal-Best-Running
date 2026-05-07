import SwiftUI
struct PDFDocumentItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct PDFDebugView: View {
    let plan: TrainingPlan
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    @State private var pdfItem: PDFDocumentItem?
    @State private var log: [String] = ["Ready"]

    var body: some View {
        List {
            Section("Status Log") {
                ForEach(log, id: \.self) { message in
                    Text(message)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button {
                    runTest()
                } label: {
                    Label("Test PDF Export", systemImage: "doc.badge.plus")
                        .fontWeight(.bold)
                }
            }
        }
        .navigationTitle("PDF Debugger")
        .sheet(item: $pdfItem) { item in
            ShareSheet(url: item.url)
        }
    }

    private func runTest() {
        log.append("1. Starting Generation...")
        
        let data = TrainingPlanPDFGenerator().generatePDF(plan: plan, unitSystem: unitSystem)
        log.append("2. Data generated: \(data.count) bytes")
        
        let fileName = "\(plan.input.raceName.replacingOccurrences(of: " ", with: "_"))_test.pdf"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tmpURL)
            log.append("3. File written to tmp")
            
            // This order is critical: URL first, then trigger sheet
            self.pdfItem = PDFDocumentItem(url: tmpURL)
            log.append("4. Presenting Sheet")
        } catch {
            log.append("ERROR: \(error.localizedDescription)")
        }
    }
}
