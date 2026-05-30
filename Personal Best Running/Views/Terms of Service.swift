import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Termini di Utilizzo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Ultimo aggiornamento: 20 maggio 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                    // 1. Introduzione
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Introduzione")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Benvenuto in **Personal Best Running**. I presenti Termini di Servizio (\"Termini\") disciplinano l'utilizzo della nostra applicazione. Scaricando, installando o utilizzando Personal Best Running, l'utente accetta di essere vincolato dai presenti Termini.")
                    }
                    
                    // 2. Descrizione dell'App
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Descrizione dell'App")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Personal Best Running è uno strumento dedicato ai runner che permette di creare  piani di allenamento personalizzati.")
                    }
                    
                    // 3. Disclaimer Medico Importante
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Disclaimer Medico Importante")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("L'applicazione fornisce piani di allenamento e informazioni a puro scopo illustrativo e informativo. L'attività fisica può comportare rischi per la salute.")
                        
                        Text("**Si raccomanda vivamente di consultare un medico professionista o uno specialista prima di iniziare qualsiasi piano di allenamento**, di modificare le proprie abitudini di esercizio fisico o se si hanno dubbi sulle proprie condizioni di salute generali. ")
                        Text("Non ignorare mai il parere del medico a causa di informazioni lette all'interno dell'app.")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                                        
                    // 4. Responsabilità dell'Utente
                    VStack(alignment: .leading, spacing: 10) {
                        Text("4. Responsabilità dell'Utente")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("L'utente accetta di:")
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Utilizzare l'app esclusivamente per scopi leciti e personali")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Non decompilare, effettuare reverse engineering o modificare l'app")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Rispettare i diritti di proprietà intellettuale relativi ai contenuti dell'app")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Ascoltare il proprio corpo e interrompere immediatamente l'allenamento in caso di dolore, vertigini o malessere")
                                Spacer()
                            }
                        }
                        .padding(.leading, 15)
                    }
                    
                    // 5. Limitazione di Responsabilità ed Esonero
                    VStack(alignment: .leading, spacing: 10) {
                        Text("5. Limitazione di Responsabilità")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Personal Best Running viene fornita \"così com'è\" senza garanzie di alcun tipo. **Lo sviluppatore è esonerato da qualsiasi responsabilità per danni, infortuni, lesioni fisiche o problemi di salute derivanti direttamente o indirettamente dall'esecuzione dei piani di allenamento** ottenuti tramite l'applicazione.") // swiftlint:disable:this line_length
                            .fontWeight(.medium)
                    }
                    
                    // 6. Aggiornamenti e Modifiche
                    VStack(alignment: .leading, spacing: 10) {
                        Text("6. Aggiornamenti e Modifiche")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Ci riserviamo il diritto di modificare i presenti Termini in qualsiasi momento. L'uso continuato dell'app dopo le modifiche costituisce l'accettazione dei nuovi Termini. Potremmo aggiornare l'app per migliorare le funzionalità, correggere bug o conformarci ai requisiti del sistema operativo.") // swiftlint:disable:this line_length
                    }
                    
                    // 7. Risoluzione
                    VStack(alignment: .leading, spacing: 10) {
                        Text("7. Risoluzione")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("I presenti Termini rimangono in vigore fino alla loro risoluzione. L'utente può recedere in qualsiasi momento disinstallando l'app. Lo sviluppatore può sospendere o interrompere l'accesso alle funzionalità dell'app in caso di violazione dei presenti Termini.")
                    }
                    
                    // 8. Contatti
                    VStack(alignment: .leading, spacing: 10) {
                        Text("8. Contatti")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Per domande relative ai presenti Termini, è possibile contattarci a:")
                        
                        Button {
                            if let url = URL(string: "mailto:info.foiasoft@gmail.com?subject=Personal%20Best%20Running%20-%20Domanda%20Termini%20di%20Servizio") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("info.foiasoft@gmail.com")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // 9. Legge Applicabile e Foro Competente
                    VStack(alignment: .leading, spacing: 10) {
                        Text("9. Legge Applicabile")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("I presenti Termini sono regolati dalle leggi dello Stato Italiano. Qualsiasi controversia derivante dall'utilizzo dell'applicazione sarà devoluta alla competenza esclusiva del Foro di Milano, Italia.")
                    }
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fine") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TermsOfServiceView()
}
