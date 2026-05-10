import SwiftUI

struct SettingsView: View {
    @AppStorage("runnerSex") private var runnerSex: RunnerSex = .male
    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    
    var body: some View {
        List {
            // Sezione Runner
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Sesso", selection: $runnerSex) {
                        ForEach(RunnerSex.allCases) { sex in
                            Label(sex.label, systemImage: sex.icon).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DisclosureGroup("Perché il sesso influisce?") {
                        Text("""
                            Le donne presentano in media una VO2max assoluta inferiore \
                            del 10-15% rispetto agli uomini a parità di allenamento, principalmente \
                            per differenze nella concentrazione di emoglobina, percentuale di massa \
                            grassa e dimensioni cardiache. Il VDOT viene corretto con un fattore \
                            derivato dalle tabelle di Daniels per garantire ritmi di allenamento \
                            appropriati al sesso biologico del runner.
                            Fonte: Daniels J. (2014). Daniels' Running Formula, 3rd Ed.
                            """)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 15)
                    
                }
                .padding(.top, 10)
            } header: {
                Text("Runner")
            }
            
            // Sezione Sistema di misura
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Unità", selection: $unitSystem) {
                        ForEach(UnitSystem.allCases) { system in
                            Text(system.label).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DisclosureGroup("Cosa cambia?") {
                        Text("Distanze in miglia (mi) anziché chilometri (km), passi in /mi anziché /km.")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 15)
                    
                }
                .padding(.top, 10)
            } header: {
                Text("Sistema di misura")
            }
        }
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.large)
        .padding(.top, 20)
    }
}

#Preview {
    SettingsView()
}
