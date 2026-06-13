import SwiftUI
// swiftlint:disable file_length

// MARK: - MethodologySection
//
// Navigation anchor enum for MethodologyView.
// Single source of truth for contextual links from
// PacesView, AthleteProfileView, and TrainingPlanView.
// Each case corresponds to a Section with id in MethodologyView.

enum MethodologySection: String, CaseIterable {
    case vdot         = "vdot"
    case zoneE        = "zone-E"
    case zoneM        = "zone-M"
    case zoneT        = "zone-T"
    case zoneI        = "zone-I"
    case zoneR        = "zone-R"
    case phaseBase    = "fase-base"
    case phaseBuild   = "fase-build"
    case phasePeak    = "fase-peak"
    case taper        = "taper"
    case volume10     = "volume-10"
    case volumeLong   = "volume-lungo"
    case volume8020   = "volume-8020"
    case volumeLimits = "volume-limiti"
    case rpe          = "rpe"
    case sources      = "fonti"

    var localizedSectionTitle: LocalizedStringResource {
        switch self {
        case .vdot:
            return LocalizedStringResource("methodology.section.vdot", defaultValue: "Il Sistema VDOT")
        case .zoneE:
            return LocalizedStringResource("methodology.section.zoneE", defaultValue: "E — Easy")
        case .zoneM:
            return LocalizedStringResource("methodology.section.zoneM", defaultValue: "M — Marathon Pace")
        case .zoneT:
            return LocalizedStringResource("methodology.section.zoneT", defaultValue: "T — Threshold / Tempo")
        case .zoneI:
            return LocalizedStringResource("methodology.section.zoneI", defaultValue: "I — Interval")
        case .zoneR:
            return LocalizedStringResource("methodology.section.zoneR", defaultValue: "R — Repetition")
        case .phaseBase:
            return LocalizedStringResource("methodology.section.phaseBase", defaultValue: "Fase Base (Phase I)")
        case .phaseBuild:
            return LocalizedStringResource("methodology.section.phaseBuild", defaultValue: "Fase di Sviluppo (Phase II)")
        case .phasePeak:
            return LocalizedStringResource("methodology.section.phasePeak", defaultValue: "Fase di Picco (Phase III/IV)")
        case .taper:
            return LocalizedStringResource("methodology.section.taper", defaultValue: "Scarico")
        case .volume10:
            return LocalizedStringResource("methodology.section.volume10", defaultValue: "Regola del 10%")
        case .volumeLong:
            return LocalizedStringResource("methodology.section.volumeLong", defaultValue: "Il Lungo: progressione per fase")
        case .volume8020:
            return LocalizedStringResource("methodology.section.volume8020", defaultValue: "Distribuzione 80/20")
        case .volumeLimits:
            return LocalizedStringResource("methodology.section.volumeLimits", defaultValue: "Limiti di Volume per Zona")
        case .rpe:
            return LocalizedStringResource("methodology.section.rpe", defaultValue: "RPE — Rate of Perceived Exertion")
        case .sources:
            return LocalizedStringResource("methodology.section.sources", defaultValue: "Fonti Scientifiche")
        }
    }
}

// MARK: - MethodologyView
//
// Reference view for training methodology.
// Accessible from Settings and via contextual links (ⓘ) from
// the main views. Supports direct navigation to a section
// via the `scrollTo` parameter.
//
// Structure:
//   1. The VDOT System
//   2. The 5 Daniels Zones (E/M/T/I/R)
//   3. Plan Structure (phases)
//   4. Volume Rules
//   5. Scientific Sources

struct MethodologyView: View {
    // Section to scroll to on open.
    // nil = no auto-scroll (opened from Settings).
    var scrollTo: MethodologySection?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                     vdotSection
                     zonesSection
                     rpeSection
                     phasesSection
                     volumeSection
                     sourcesSection
                }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Chiudi") { dismiss() }
                    }
                }
                .onAppear {
                    if let target = scrollTo {
                        // Small delay to allow List rendering
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo(target.rawValue, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - VDOT Section

    private var vdotSection: some View {
        Section {
            MethodologyCard(
                symbol: "chart.line.uptrend.xyaxis",
                color: .secondary,
                title: "Cos'è il VDOT",
                corpo: """
                                Il VDOT è un indice della capacità aerobica individuale, \
                                derivato dalla formula di Daniels e Gilbert (1979). \
                                Rappresenta il consumo di ossigeno (VO2max) "effettivo" \
                                ricavato dalla performance in gara — non da un test in laboratorio.

                                Un VDOT più alto indica una migliore forma fisica: \
                                VDOT 40 è un runner amatoriale solido, \
                                VDOT 60 è un atleta d'élite.
                                """,
                isInitiallyExpanded: scrollTo == .vdot // <-- PASS EXPANSION CONTROL
            )

            MethodologyCard(
                symbol: "function",
                color: .secondary,
                title: "Come viene calcolato",
                corpo: """
                    Dal tempo e dalla distanza di una performance recente, \
                    il sistema calcola la velocità di corsa e la percentuale \
                    di VO2max utilizzata a quella durata. \
                    La formula è:

                    VO2 richiesto = −4.60 + 0.182258·v + 0.000104·v²
                    %VO2max = 0.8 + 0.1894·e^(−0.01278·t) + 0.2990·e^(−0.1933·t)
                    VDOT = VO2 / %VO2max

                    dove v = velocità in m/min, t = tempo in minuti.
                    Fonte: Daniels & Gilbert (1979), adattato da Daniels (2022).
                    """,
                isInitiallyExpanded: false // no direct link
            )

            MethodologyCard(
                symbol: "person.fill.questionmark",
                color: .secondary,
                title: "Perché i ritmi si basano sul VDOT attuale",
                corpo: """
                    Allenarsi al ritmo target (futuro) anziché al VDOT attuale \
                    è uno degli errori più comuni — e più rischiosi. \
                    Daniels è esplicito: "Train at the level you are, \
                    not at the level you hope to be."

                    I ritmi del piano — Easy, M, T, I, R — riflettono \
                    la tua forma di oggi, non l'obiettivo. \
                    Man mano che il VDOT cresce durante il piano, \
                    le sessioni diventano progressivamente più impegnative \
                    alla stessa intensità relativa.

                    Nota sul lungo: anche la distanza del lungo dipende \
                    dall'E-pace attuale, tramite il cap di 150 minuti. \
                    Un runner più lento farà meno km per la stessa durata — \
                    ed è corretto: lo stimolo fisiologico è equivalente.
                    """,
                isInitiallyExpanded: false // no direct link
            )

            MethodologyCard(
                symbol: "person.2",
                color: .secondary,
                title: "VDOT e sesso biologico",
                corpo: """
                    Il VDOT è sex-neutral per definizione: misura la performance \
                    individuale reale, già "incorporando" le differenze fisiologiche. \
                    Una donna con VDOT 50 e un uomo con VDOT 50 si allenano \
                    agli stessi ritmi.

                    Daniels (2022) cap. 5: "The higher VDOT value is associated \
                    with the better runner, regardless of age or sex."

                    Il sesso viene usato nel piano solo per contestualizzare \
                    il livello del runner (soglie di popolazione differenziate \
                    per distribuzione M/F).
                    """,
                isInitiallyExpanded: false // no direct link
            )
        } header: {
            Text(String(localized: MethodologySection.vdot.localizedSectionTitle))
        }
        .id(MethodologySection.vdot.rawValue)
    }

    // MARK: - Zones Section

    private var zonesSection: some View {
        Section {
            ZoneRow(
                type: .easy,
                title: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.title.E", defaultValue: "E — Easy"), locale: locale),
                intensity: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.intensity.E", defaultValue: "59-74% VO2max · 65-79% FCmax · RPE 4-5"), locale: locale),
                workBout: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.workBout.E", defaultValue: "Qualsiasi durata"), locale: locale),
                recovery: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.recovery.E", defaultValue: "Non applicabile"), locale: locale),
                purpose: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.purpose.E", defaultValue: "Sviluppo aerobico di base, recupero attivo, adattamento muscolo-tendineo. ~80% del volume settimanale totale."), locale: locale),
                source: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.source.E", defaultValue: "Daniels [1] cap. 4"), locale: locale),
                isInitiallyExpanded: scrollTo == .zoneE
            )
            .id(MethodologySection.zoneE.rawValue)

            ZoneRow(
                type: .marPace,
                title: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.title.M", defaultValue: "M — Marathon Pace"), locale: locale),
                intensity: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.intensity.M", defaultValue: "75-84% VO2max · 80-89% FCmax · RPE 6-7"), locale: locale),
                workBout: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.workBout.M", defaultValue: "Sezione principale 10-28 km"), locale: locale),
                recovery: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.recovery.M", defaultValue: "Non applicabile (ritmo continuo)"), locale: locale),
                purpose: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.purpose.M", defaultValue: "Adattamento specifico al ritmo gara maratona. Ottimizza l'economia di corsa e la gestione del ritmo."), locale: locale),
                source: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.source.M", defaultValue: "Daniels [1] cap. 4, Pfitzinger [2]"), locale: locale),
                isInitiallyExpanded: scrollTo == .zoneM
            )
            .id(MethodologySection.zoneM.rawValue)

            ZoneRow(
                type: .tempo,
                title: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.title.T", defaultValue: "T — Threshold / Tempo"), locale: locale),
                intensity: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.intensity.T", defaultValue: "85-88% VO2max · 88-92% FCmax · RPE 7-8"), locale: locale),
                workBout: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.workBout.T", defaultValue: "20 min continui (Tempo Run) o intervalli cruise 3-15 min"), locale: locale),
                recovery: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.recovery.T", defaultValue: "1 min tra gli intervalli cruise"), locale: locale),
                purpose: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.purpose.T", defaultValue: "Migliora la soglia anaerobica e la capacità di clearance del lattato. Max 10% del volume settimanale per sessione."), locale: locale),
                source: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.source.T", defaultValue: "Daniels [1] cap. 4"), locale: locale),
                isInitiallyExpanded: scrollTo == .zoneT
            )
            .id(MethodologySection.zoneT.rawValue)

            ZoneRow(
                type: .interval,
                title: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.title.I", defaultValue: "I — Interval"), locale: locale),
                intensity: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.intensity.I", defaultValue: "95-100% VO2max · ~98% FCmax · RPE 8-9"), locale: locale),
                workBout: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.workBout.I", defaultValue: "3-5 minuti per ripetizione"), locale: locale),
                recovery: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.recovery.I", defaultValue: "Recupero attivo (jog) uguale al tempo di lavoro"), locale: locale),
                purpose: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.purpose.I", defaultValue: "Massimizza il tempo a VO2max. Stimola la portata cardiaca, la densità capillare e la densità mitocondriale. Max 10 km o 8% del volume settimanale, il minore dei due."), locale: locale),
                source: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.source.I", defaultValue: "Daniels [1] cap. 4, Billat [3], Laursen & Jenkins [5]"), locale: locale),
                isInitiallyExpanded: scrollTo == .zoneI
            )
            .id(MethodologySection.zoneI.rawValue)

            ZoneRow(
                type: .repetition,
                title: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.title.R", defaultValue: "R — Repetition"), locale: locale),
                intensity: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.intensity.R", defaultValue: "105-120% VDOT · >100% VO2max · RPE 9+"), locale: locale),
                workBout: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.workBout.R", defaultValue: "MAX 2 minuti per ripetizione (tipico 200-400m)"), locale: locale),
                recovery: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.recovery.R", defaultValue: "COMPLETO: jog uguale o superiore alla distanza percorsa"), locale: locale),
                purpose: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.purpose.R", defaultValue: "Migliora velocità, economia di corsa e potenza anaerobica. Introdotto prima di I (aggiunge solo stimolo di velocità). Max 5% del volume settimanale."), locale: locale),
                source: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.source.R", defaultValue: "Daniels [1] cap. 4"), locale: locale),
                isInitiallyExpanded: scrollTo == .zoneR
            )
            .id(MethodologySection.zoneR.rawValue)
        }         header: {
            Text(AppLocalizedString.resolve(LocalizedStringResource("methodology.section.zones", defaultValue: "Le 5 Zone di Daniels"), locale: locale))
        }
    }

    // MARK: - RPE Section

    private var rpeSection: some View {
        Section {
            MethodologyCard(
                symbol: "questionmark.circle",
                color: .secondary,
                title: "Cos'è l'RPE",
                corpo: """
                    L'RPE (Rate of Perceived Exertion) è una scala soggettiva \
                    dell'intensità dello sforzo percepito durante l'allenamento. \
                    Utilizza una scala da 1 a 10, dove 1 è uno sforzo minimo \
                    (riposo) e 10 è lo sforzo massimo assoluto.

                    A differenza della frequenza cardiaca o del VO2max, l'RPE \
                    incorpora fattori soggettivi come il sonno, lo stress, \
                    l'ambiente e la fatica accumulata — ed è per questo che \
                    Daniels lo considera un indicatore complementare essenziale.

                    L'RPE target per zona è calcolato sull'RPE medio \
                    dell'intera sessione, non dei singoli intervalli.
                    """,
                isInitiallyExpanded: scrollTo == .rpe
            )

            MethodologyCard(
                symbol: "slider.horizontal.3",
                color: .secondary,
                title: "La Scala RPE",
                corpo: """
                    1 — Riposo completo. Nessuno sforzo percepito.

                    2 — Attività leggera. Respiro normale, conversazione illimitata.

                    3 — Facile. Si può mantenere a lungo senza difficoltà.

                    4 — Moderato facile. Respiro profondo ma confortevole. Conversazione fluida. Corrisponde all'inizio dell'E-pace.

                    5 — Moderato. Conversazione ancora possibile con qualche pausa. Meta-alta dell'E-pace.

                    6 — Moderato sostenuto. Conversazione breve. Corrisponde all'M-pace.

                    7 — Sostenuto impegnativo. "Comfortably hard". Frasi brevi. Corrisponde al T-pace.

                    8 — Impegnativo. Conversazione difficile. Poche parole per volta. Corrisponde all'I-pace.

                    9 — Molto intenso. Conversazione impossibile per più di una parola. Corrisponde all'R-pace. Non sostenibile a lungo.

                    10 — Sforzo massimo assoluto. Sprint terminale, tutto quello che rimane.
                    """,
                isInitiallyExpanded: scrollTo == .rpe
            )

            MethodologyCard(
                symbol: "lightbulb",
                color: .secondary,
                title: "Come usarlo in allenamento",
                corpo: """
                    Ogni allenamento nel piano indica l'RPE target. \
                    È un riferimento — non una prescrizione rigida. \
                    Se il tuo RPE è più alto del previsto in un giorno, \
                    rallenta o accorcia la sessione.

                    L'RPE tende ad aumentare durante sessioni lunghe: \
                    se la prima parte è lenta, la seconda potrebbe \
                    sentiresi più dura del previsto

                    Daniels consiglia di usare l'RPE insieme al passo: \
                    se il passo giusto corrisponde all'RPE giusto, \
                    l'intensità è corretta.
                    """,
                isInitiallyExpanded: scrollTo == .rpe
            )
        } header: {
            Text(AppLocalizedString.resolve(LocalizedStringResource("methodology.section.rpe", defaultValue: "RPE — Rate of Perceived Exertion"), locale: locale))
        }
        .id(MethodologySection.rpe.rawValue)
    }

    // MARK: - Phases Section

    private var phasesSection: some View {
        Section {
            MethodologyCard(
                symbol: WorkoutType.easy.sfSymbol,
                color: .secondary,
                title: "Fase Base (Phase I)",
                corpo: """
                    Obiettivo: costruzione aerobica, adattamento muscolo-scheletrico, \
                    volume progressivo.

                    Contenuto: E running (80%+), ripetute in salita leggere, \
                    corse progressive. Nessuna sessione I.

                    Daniels: "Mostly E running" nella Phase I. \
                    I collinari e le progressioni sono stimoli supplementari \
                    che aggiungono forza senza stress aerobico aggiuntivo.

                    Per runner principianti (VDOT < 35): le ripetute in salita \
                    vengono sostituite con corse facili o progressive. \
                    I collinari richiedono una base muscolare già consolidata — \
                    introdurle troppo presto aumenta il rischio di infortuni.

                    Volume: progressione max +10%/settimana. \
                    Ogni 4a settimana: scarico -20%.
                    """,
                isInitiallyExpanded: scrollTo == .phaseBase // <-- AUTO-EXPAND IF CALLED
            )
            .id(MethodologySection.phaseBase.rawValue)

            MethodologyCard(
                symbol: WorkoutType.repetition.sfSymbol,
                color: .secondary,
                title: "Fase di Sviluppo (Phase II)",
                corpo: """
                    Obiettivo: introduzione della qualità, sviluppo velocità e soglia.

                    Contenuto: R (Repetition) + T (Tempo) + L run. \
                    Nessuna sessione I ancora.

                    Daniels: "Going from E running to R workouts is adding \
                    only a speed stress, with little being asked of the aerobic \
                    or lactate-clearance systems." Per questo R arriva prima di I.

                    Volume: micro-scarico ogni 3 settimane.
                    """,
                isInitiallyExpanded: scrollTo == .phaseBuild // <-- AUTO-EXPAND IF CALLED
            )
            .id(MethodologySection.phaseBuild.rawValue)

            MethodologyCard(
                symbol: WorkoutType.interval.sfSymbol,
                color: .secondary,
                title: "Fase di picco (Phase III/IV)",
                corpo: """
                    Obiettivo: massima qualità, picco di forma, simulazione gara.

                    Contenuto: T + I + M (o I per 10K) + L run. \
                    La settimana più impegnativa del piano.

                    Per maratona e mezza: le sessioni M-pace sono centrali \
                    perché adattano al ritmo specifico di gara.
                    Per 10K: le sessioni I a VO2max sono determinanti.

                    Fonte: Daniels [1] Phase III (TQ) e IV (FQ), Pfitzinger [2].
                    """,
                isInitiallyExpanded: scrollTo == .phasePeak // <-- AUTO-EXPAND IF CALLED
            )
            .id(MethodologySection.phasePeak.rawValue)

            MethodologyCard(
                symbol: "arrow.down.circle",
                color: .secondary,
                title: "Scarico",
                corpo: """
                    Obiettivo: supercompensazione, recupero, arrivo alla gara \
                    nella forma migliore.

                    Volume: riduzione del 40-60% rispetto al picco. \
                    Intensità: invariata — almeno una sessione T viene mantenuta \
                    per non perdere lo stimolo alla soglia.

                    Daniels mantiene sessioni T leggere anche nell'ultima settimana \
                    prima della gara.

                    Fonte: Mujika & Padilla (2003) [6].
                    """,
                isInitiallyExpanded: scrollTo == .taper
            )
            .id(MethodologySection.taper.rawValue)
        } header: {
            Text(AppLocalizedString.resolve(LocalizedStringResource("methodology.section.phases", defaultValue: "Struttura del Piano"), locale: locale))
        }
    }

    // MARK: - Volume Section

    private var volumeSection: some View {
        Section {
            MethodologyCard(
                symbol: "arrow.up.right",
                color: .indigo,
                title: "Regola del 10%",
                corpo: """
                    Non aumentare il volume settimanale di più del 10% \
                    rispetto alla settimana precedente.

                    Daniels suggerisce anche di mantenere lo stesso carico \
                    per 3-4 settimane prima di aumentare. \
                    Il piano applica la regola del 10% come limite superiore, \
                    con settimane di scarico ogni 3-4 settimane \
                    (principio di supercompensazione).

                    Fonte: Daniels [1] cap. 2, Galloway [8].
                    """,
                isInitiallyExpanded: scrollTo == .volume10
            )
            .id(MethodologySection.volume10.rawValue)

            MethodologyCard(
                symbol: "person.crop.circle.badge.checkmark",
                color: .indigo,
                title: "Volume iniziale per distanza e livello",
                corpo: """
                    Il volume di partenza del piano dipende sia dalla \
                    distanza obiettivo che dal livello del runner (VDOT).

                    Un beginner che prepara una 10K (VDOT < 35) parte da \
                    ~18-25 km/settimana con sessioni da 4-6 km. \
                    Lo stesso runner su maratona parte da ~30-45 km/settimana.

                    Soglie orientative settimanali per livello:

                    10K: beginner ~25 km · recreational ~42 km · intermedio ~60 km
                    HM:  beginner ~35 km · recreational ~55 km · intermedio ~70 km
                    Mar: beginner ~45 km · recreational ~65 km · intermedio ~85 km

                    Questi cap impediscono volumi sproporzionati per runner \
                    alle prime armi, riducendo il rischio di infortuni da stress.
                    Fonte: Daniels [1] cap. 2, Pfitzinger [2], \
                    RunRepeat Global Report (2023).
                    """,
                isInitiallyExpanded: false // no direct link
            )

            MethodologyCard(
                        symbol: "ruler",
                        color: .indigo,
                        title: "Il Lungo: progressione per fase",
                        corpo: """
                            Il lungo segue una curva di progressione basata sulla fase \
                            del piano, non solo sul volume settimanale corrente.

                            Daniels [1] cap. 4: "I like to limit any single L run \
                            to no more than 25 percent of weekly mileage." \
                            Secondo vincolo: max 150 minuti (2h30') per sessione.

                            Range orientativi per distanza (picco):

                            Maratona: 16 km (base) → fino a 32 km (peak, VDOT alto)
                            Mezza:    10 km (base) → fino a 22 km (peak)
                            10K:       8 km (base) → fino a 18 km (peak)

                            Per maratona e mezza il target è phase-driven (cap \
                            temporale 150 min). Per la 10K si applica anche il \
                            cap 25% del volume settimanale.

                            Fonte: Daniels [1] cap. 4 e 15-16, Pfitzinger [2] cap. 3.
                            """
                    )
                    .id(MethodologySection.volumeLong.rawValue)

            MethodologyCard(
                symbol: "chart.pie",
                color: .indigo,
                title: "Distribuzione 80/20",
                corpo: """
                    ~80% del volume settimanale a bassa intensità (E-pace, Z2), \
                    ~20% ad alta intensità (T/I/R, Z4-Z5+).

                    Seiler & Kjerland (2006) hanno osservato questo pattern \
                    negli atleti d'élite di endurance. È una distribuzione \
                    empirica, non un modello prescrittivo: descrive cosa fanno \
                    i migliori, non necessariamente cosa ottimizza ogni runner.

                    Nel piano viene usata come guida per bilanciare il mix \
                    di intensità nella settimana, coerentemente con la \
                    struttura per fasi di Daniels.

                    Fonte: Seiler & Kjerland [4].
                    """,
                isInitiallyExpanded: scrollTo == .volume8020
            )
            .id(MethodologySection.volume8020.rawValue)

            MethodologyCard(
                symbol: "percent",
                color: .indigo,
                title: "Limiti di Volume per Zona",
                corpo: """
                    Daniels definisce limiti precisi per ogni zona \
                    in una singola sessione:

                    T (Tempo):      max 10% del volume settimanale
                    M (Marathon):   max 20% del volume settimanale
                    I (Interval):   max il minore tra 10 km e 8% settimanale
                    R (Repetition): max 5% del volume settimanale
                    L (Long Run):   max 25% del volume settimanale
                                    E max 150 minuti a E-pace (vincolo primario)

                    Il vincolo temporale (150 min) prevale sul 25% del \
                    volume quando i due entrano in conflitto. \
                    Per HM e maratona è sempre il cap temporale \
                    a determinare i km effettivi del lungo.

                    Questi limiti prevengono il sovraccarico e garantiscono \
                    un recupero adeguato tra le sessioni.

                    Fonte: Daniels [1] cap. 4.
                    """,
                isInitiallyExpanded: scrollTo == .volumeLimits
            )
             .id(MethodologySection.volumeLimits.rawValue)
        } header: {
            Text(AppLocalizedString.resolve(LocalizedStringResource("methodology.section.volume", defaultValue: "Regole di Volume"), locale: locale))
        }
    }

    // MARK: - Sources Section

    private var sourcesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                ForEach([
                    "[1] Daniels J. (2022). Daniels' Running Formula (4th ed.). Human Kinetics.",
                    "[2] Pfitzinger P., Douglas S. (2009). Advanced Marathoning (2nd ed.). Human Kinetics.",
                    "[3] Billat V. (2001). Interval Training for Performance. Sports Medicine, 31(1), 13-31.",
                    "[4] Seiler S., Kjerland G.Ø. (2006). Quantifying training intensity distribution in elite endurance athletes. Scand. J. Med. Sci. Sports, 16(1), 49-56.",
                    "[5] Laursen P.B., Jenkins D.G. (2002). The Scientific Basis for High-Intensity Interval Training. Sports Medicine, 32(1), 53-73.",
                    "[6] Mujika I., Padilla S. (2003). Scientific bases for precompetition tapering strategies. Medicine & Science in Sports & Exercise, 35(7), 1182-1187.",
                    "[7] Bompa T., Haff G. (2009). Periodization: Theory and Methodology of Training (5th ed.). Human Kinetics.",
                    "[8] Galloway J. (2010). Running Until You're 100. Meyer & Meyer Sport."
                ], id: \.self) { source in
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
         } header: {
             Text(AppLocalizedString.resolve(LocalizedStringResource("methodology.section.sources", defaultValue: "Fonti Scientifiche"), locale: locale))
         }
         .id(MethodologySection.sources.rawValue)
    }
}

// MARK: - MethodologyCard
//
// Generic card for text content with SF Symbol icon.
// Used in the VDOT, Phases, Volume sections.
// Supports programmatic expansion via `isInitiallyExpanded`.
struct MethodologyCard: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let corpo: LocalizedStringKey

    // Changed to regular variable with initial value computed in init
    @State private var expanded: Bool

    // CUSTOM INIT: Checks if this specific card should start expanded
    init(symbol: String, color: Color, title: LocalizedStringKey, corpo: LocalizedStringKey, isInitiallyExpanded: Bool = false) {
        self.symbol = symbol
        self.color = color
        self.title = title
        self.corpo = corpo
        // Initialize internal State based on external parameter
        _expanded = State(initialValue: isInitiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                Text(corpo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                    .padding(.leading, 46)   // aligned with title text
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ZoneRow
//
// Expandable row for Daniels zones.
// Shows WorkoutBadge + title, expands to show intensity,
// work bout, recovery, purpose, and source.

struct ZoneRow: View {
    let type: WorkoutType
    let title: String
    let intensity: String
    let workBout: String
    let recovery: String
    let purpose: String
    let source: String

    @Environment(\.locale) private var locale

    // Changed to support programmatic expansion from init
    @State private var expanded: Bool

    init(type: WorkoutType, title: String, intensity: String, workBout: String, recovery: String, purpose: String, source: String, isInitiallyExpanded: Bool = false) {
        self.type = type
        self.title = title
        self.intensity = intensity
        self.workBout = workBout
        self.recovery = recovery
        self.purpose = purpose
        self.source = source
        _expanded = State(initialValue: isInitiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    WorkoutBadge(type: type, size: 34)
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ZoneDetailRow(label: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.label.intensity", defaultValue: "Intensità"), locale: locale), value: intensity)
                    ZoneDetailRow(label: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.label.workBout", defaultValue: "Work bout"), locale: locale), value: workBout)
                    ZoneDetailRow(label: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.label.recovery", defaultValue: "Recupero"), locale: locale), value: recovery)
                    ZoneDetailRow(label: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.label.purpose", defaultValue: "Scopo"), locale: locale), value: purpose)
                    ZoneDetailRow(label: AppLocalizedString.resolve(LocalizedStringResource("methodology.zone.label.source", defaultValue: "Fonte"), locale: locale), value: source)
                }
                .padding(.top, 10)
                .padding(.leading, 46)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ZoneDetailRow

struct ZoneDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
                .kerning(0.5)
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - MethodologyButton
//
// Reusable ⓘ button that opens MethodologyView as a sheet
// with auto-scroll to the specified section.
// Used in the main views as a contextual link.
//
// Usage:
//   MethodologyButton(section: .zoneT)   // opens to T-pace
//   MethodologyButton(section: .vdot)    // opens to VDOT

struct MethodologyButton: View {
    let section: MethodologySection

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            MethodologyView(scrollTo: section)
        }
    }
}

#Preview {
    MethodologyView()
}
