import SwiftUI

struct SettingsView: View {
    @AppStorage("runnerSex") private var runnerSex: RunnerSex    = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem  = .metric

    var body: some View {
        Form {
            Section("Runner") {
                Picker("Sesso", selection: $runnerSex) {
                    ForEach(RunnerSex.allCases) { sex in
                        Label(sex.label, systemImage: sex.icon).tag(sex)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Perché il sesso influisce sul piano?")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("""
                        Le donne presentano in media una VO2max assoluta inferiore \
                        del 10-15% rispetto agli uomini a parità di allenamento, principalmente \
                        per differenze nella concentrazione di emoglobina, percentuale di massa \
                        grassa e dimensioni cardiache. Il VDOT viene corretto con un fattore \
                        derivato dalle tabelle di Daniels per garantire ritmi di allenamento \
                        appropriati al sesso biologico del runner.
                        Fonte: Daniels J. (2014). Daniels' Running Formula, 3rd Ed.
                        """)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 20)

            Section("Sistema di misura") {
                Picker("Unità", selection: $unitSystem) {
                    ForEach(UnitSystem.allCases) { system in
                        Text(system.label).tag(system)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cosa cambia?")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("""
                        Con il sistema imperiale le distanze vengono mostrate in miglia \
                        (mi) anziché chilometri (km), i passi in /mi anziché /km, e le \
                        distanze delle gare vengono visualizzate nella loro denominazione \
                        anglosassone (es. "5K", "Half Marathon"). 
                        """)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    SettingsView()
}
