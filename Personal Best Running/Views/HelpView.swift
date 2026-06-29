import SwiftUI

// MARK: - HelpView

struct HelpView: View {
    var onDismiss: (() -> Void)?

    private var isIPad: Bool { DeviceInfo.isIPad }

    var body: some View {
        NavigationStack {
            List {
                introductionSection
                tabGoalSection
                tabPlanSection
                tabPacesSection
                tabProfileSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Aiuto e Supporto")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("Chiudi") {
//                        onDismiss?()
//                    }
//                }
//            }
        }
    }

    @ViewBuilder
    private func constrainedImage(_ name: String, maxWidth: CGFloat = 400) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .modifier(OptionalMaxWidth(isIPad: isIPad, maxWidth: maxWidth))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - List Sections

    private var introductionSection: some View {
        Section {
            Text("Benvenuto in **Personal Best Running**!\nQuesta applicazione ti aiuta a generare un piano di allenamento personalizzato basato sul metodo VDOT di Jack Daniels.")
                .font(.body)
                .padding(.vertical, 4)
        } header: {
            Text("Introduzione")
        }
    }

    private var tabGoalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nella scheda **Obiettivo** puoi configurare i parametri principali.")
                    .font(.body)

                Text("Dovrai inserire la distanza della gara, la data dell'evento, il tuo tempo obiettivo e un tempo recente di riferimento per permettere all'algoritmo di calcolare accuratamente il tuo VDOT iniziale.")

                constrainedImage("target")

                Text("Una volta scelto il numero di allenamenti a settimana puoi premere il bottone **Genera PIano**: in questo modo saranno generati i dati necessari per la pianificazione e le altre schede saranno popolate.")

                constrainedImage("reference")

            }
            .padding(.vertical, 4)
        } header: {
            Text("1. Configura il tuo Obiettivo")
        }
    }

    private var tabPlanSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Nella parte superiore della scheda **Piano** puoi trovare un riepilogo, con l'indicazione della fattibilità basata sui parametri che hai inserito.")
                    .font(.body)

                constrainedImage("riepilogo", maxWidth: 500)

                Text("Subito sotto, trovi il piano vero e proprio. Rappresenta un percorso articolato in quattro fasi che si sviluppano ai parametri indicati, calcolando la timeline che ti separa dal giorno della gara.")
                    .font(.body)

                Text("Toccando i simboli \"∨\" nel calendario, la vista si espande per mostrare le singole sessioni di allenamento.")
                    .font(.body)

                constrainedImage("calendario")

                Text("Puoi toccare ogni sessione per avere indicazioni sul modo di affrontarla.")
                    .font(.body)

                constrainedImage("dettaglio")

                Text("\nSotto il piano, trovi tre bottoni per esportarlo nei formati PDF e CSV, e per scriverlo direttamente sul calendario del tuo \(isIPad ? "iPad" : "iPhone").")
                    .font(.body)

                constrainedImage("condivisione")

                Text("Per evitare interferenze con il tuo calendario principale, il piano di allenamento sarà importato in un nuovo calendario denominato **PB Running**")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("2. Il tuo Piano di Allenamento")
        }
    }

    private var tabPacesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("La scheda **Ritmi** traduce il tuo valore VDOT attuale in andature precise, eliminando ogni incertezza su come interpretare le sessioni.")
                    .font(.body)

                constrainedImage("andature")

                Text("Nota: Aggiornando le tue performance recenti nella scheda Obiettivo, questa tabella si ricalcolerà automaticamente per riflettere i tuoi progressi.")
                    .font(.callout)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("3. I tuoi Ritmi Personalizzati")
        }
    }

    private var tabProfileSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("La scheda **Profilo** riassume lo stato attuale del tuo percorso atletico. Al suo interno trovi una panoramica dettagliata che include:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {

                    Label("**Calcolo del VDOT:** Visualizza il tuo punteggio VDOT corrente, calcolato  incrociando la tua distanza di riferimento con il tuo ultimo tempo cronometrato.", systemImage: "waveform.path.ecg")

                    Label("**Il tuo livello** attuale basato su VDOT, sesso biologico,distribuzione percentile dei finishing time nelle maratone di massa (RunRepeat Global Report 2023) e sulle tabelle age-grading di WMA (World Masters Athletics)", systemImage: "person.circle")

                    Label("Le **Previsioni** dei tuoi tempi stimati sulle distanze standard, basate sul tuo VDOT attuale.", systemImage: "stopwatch")

                    Label("**Trend VDOT:** Monitora la tua progressione atletica e scopri quanto manca per raggiungere il livello successivo.", systemImage: "chart.line.uptrend.xyaxis")

                }
                .font(.footnote)
                .foregroundStyle(.secondary)

            }
            .padding(.vertical, 4)
            
            constrainedImage("profilo")

        } header: {
            Text("4. Profilo Atleta")
        }
    }
}

// MARK: - OptionalMaxWidth

private struct OptionalMaxWidth: ViewModifier {
    let isIPad: Bool
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        if isIPad {
            content.frame(maxWidth: maxWidth)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    HelpView()
        .environment(\.locale, .init(identifier: "en"))
}
