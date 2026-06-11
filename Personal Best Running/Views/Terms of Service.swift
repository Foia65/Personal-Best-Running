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
                        
                        Text("Personal Best Running è uno strumento dedicato ai runner che permette di creare piani di allenamento personalizzati.")
                    }
                    
                    // 3. Proprietà Intellettuale e Fonti Scientifiche (NUOVA)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Proprietà Intellettuale e Fonti Scientifiche")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("I piani di allenamento generati dall'applicazione utilizzano formule e principi di fisiologia della corsa di dominio pubblico, liberamente ispirati alle metodologie di allenamento tradizionali della corsa di fondo (tra cui i modelli di Jack Daniels).")
                        
                        Text("Personal Best Running è un progetto software totalmente indipendente. L'applicazione e il suo sviluppatore non sono in alcun modo affiliati, associati, sponsorizzati, autorizzati o ufficialmente collegati a Jack Daniels, al 'Run SMART Project', ai loro partner commerciali o alle rispettive case editrici. Tutti i marchi registrati e i nomi citati appartengono ai legittimi proprietari.") // swiftlint:disable:this line_length
                    }
                    
                    // 4. Disclaimer Medico Importante (Ex 3)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("4. Disclaimer Medico Importante")
                            Image(systemName: "stethoscope")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        
                        Text("L'applicazione fornisce piani di allenamento e informazioni a puro scopo illustrativo e informativo. L'attività fisica può comportare rischi per la salute.")
                        
                        Text("**Si raccomanda vivamente di consultare un medico professionista o uno specialista prima di iniziare qualsiasi piano di allenamento, di modificare le proprie abitudini di esercizio fisico o se si hanno dubbi sulle proprie condizioni di salute generali.**")
                        Text("Non ignorare mai il parere del medico a causa di informazioni lette all'interno dell'app.")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                    
                    // 5. Responsabilità dell'Utente (Ex 4)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("5. Responsabilità dell'Utente")
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
                    
                    // 6. Limitazione di Responsabilità ed Esonero (Ex 5)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("6. Limitazione di Responsabilità")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Personal Best Running viene fornita \"così com'è\" senza garanzie di alcun tipo. Lo sviluppatore è esonerato da qualsiasi responsabilità per danni, infortuni, lesioni fisiche o problemi di salute derivanti direttamente o indirettamente dall'esecuzione dei piani di allenamento ottenuti tramite l'applicazione.") // swiftlint:disable:this line_length
                            .fontWeight(.medium)
                    }
                    
                    // 7. Aggiornamenti e Modifiche (Ex 6)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("7. Aggiornamenti e Modifiche")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Ci riserviamo il diritto di modificare i presenti Termini in qualsiasi momento. L'uso continuato dell'app dopo le modifiche costituisce l'accettazione dei nuovi Termini. Potremmo aggiornare l'app per migliorare le funzionalità, correggere bug o conformarci ai requisiti del sistema operativo.") // swiftlint:disable:this line_length
                    }
                    
                    // 8. Risoluzione (Ex 7)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("8. Risoluzione")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("I presenti Termini rimangono in vigore fino alla loro risoluzione. L'utente può recedere in qualsiasi momento disinstallando l'app. Lo sviluppatore può sospendere o interrompere l'accesso alle funzionalità dell'app in caso di violazione dei presenti Termini.")
                    }
                    
                    // 9. Contatti (Ex 8)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("9. Contatti")
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
                    
                    // 10. Legge Applicabile e Foro Competente (Ex 9)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("10. Legge Applicabile")
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
