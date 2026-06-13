import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Informativa sulla Privacy")
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
                        
                        Text("Questa Informativa sulla Privacy spiega come **Personal Best Running** (\"noi\", \"nostro\" o \"l'app\") gestisce le tue informazioni quando utilizzi la nostra applicazione per la creazione dei piani di allenamento.")
                        
                        Text("Rispettiamo la tua privacy e ci impegniamo a proteggere i tuoi dati personali. Questa informativa ti aiuterà a comprendere i tuoi diritti alla privacy e come la legge ti tutela.")
                    }
                    
                    // 2. Informazioni che Raccogliamo
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Informazioni che Raccogliamo")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Personal Best Running è progettata mettendo la privacy al primo posto:")
                        
                        Text("Informazioni che NON raccogliamo:")
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Informazioni di identificazione personale (nome, email, indirizzo)")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Dati di localizzazione o coordinate GPS sui nostri server")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Accesso alla galleria fotografica o ai contatti")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Identificatori del dispositivo per il tracciamento pubblicitario")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Analisi sull'utilizzo o dati comportamentali")
                            }
                        }
                        .padding(.leading, 15)
                        
                        Text("Informazioni Memorizzate Localmente:")
                            .fontWeight(.medium)
                            .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Le tue preferenze di corsa (obiettivi di tempo, distanza, ritmo)")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Impostazioni dell'app (sistema di misura, genere, lingua)")
                                Spacer()
                            }
                        }
                        .padding(.leading, 15)
                        
                        Text("Queste informazioni sono memorizzate unicamente sul tuo dispositivo utilizzando l'archiviazione locale sicura di iOS e non vengono mai trasmesse ai nostri server.")
                    }
                    
                    // 3. Servizi di Terze Parti
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Servizi di Terze Parti")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("App Store:")
                            .fontWeight(.medium)
                        
                        Text("Il download dell'app viene elaborato tramite l'App Store di Apple. Apple potrebbe raccogliere informazioni sull'account e cronologia degli acquisti in base alla propria informativa sulla privacy. Noi non abbiamo accesso ai tuoi dati di pagamento o account Apple.")
                    }
                    
                    // 4. Come Utilizziamo le Informazioni
                    VStack(alignment: .leading, spacing: 10) {
                        Text("4. Come Utilizziamo le Informazioni")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Dato che non raccogliamo dati personali, utilizziamo le informazioni memorizzate localmente solo per:")
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Ricordare le tue impostazioni preferite")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Fornire un'esperienza utente fluida e personalizzata")
                                Spacer()
                            }
                        }
                        .padding(.leading, 15)
                    }
                    
                    // 5. Sicurezza dei Dati
                    VStack(alignment: .leading, spacing: 10) {
                        Text("5. Sicurezza dei Dati")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Le tue preferenze e i tuoi dati sono memorizzati in modo sicuro sul tuo dispositivo sfruttando le funzionalità di sicurezza integrate in iOS:")
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("I dati sono protetti tramite la crittografia nativa di iOS")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Le informazioni sono isolate (sandboxed) all'interno dell'app")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Nessuna trasmissione dati verso server esterni")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("I dati vengono eliminati automaticamente quando disinstalli l'app")
                                Spacer()
                            }
                        }
                        .padding(.leading, 15)
                    }
                    
                    // 6. I Tuoi Diritti sulla Privacy
                    VStack(alignment: .leading, spacing: 10) {
                        Text("6. I Tuoi Diritti sulla Privacy")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Poiché tutti i dati sono memorizzati localmente sul tuo dispositivo, hai il controllo totale:")
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Puoi eliminare i dati dei piani di allenamento direttamente dall'app")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Puoi disinstallare l'app per rimuovere completamente ogni traccia dei dati")
                                Spacer()
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Nessun problema di portabilità dei dati (non ci sono dati lato server)")
                                Spacer()
                            }
                        }
                        .padding(.leading, 15)
                    }
                    
                    // 7. Privacy dei Minori
                    VStack(alignment: .leading, spacing: 10) {
                        Text("7. Privacy dei Minori")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Personal Best Running non raccoglie intenzionalmente informazioni personali da minori di 13 anni. L'app è progettata per appassionati di corsa di tutte le età e non raccoglie dati identificativi di alcun utente.")
                    }
                    
                    // 8. Utenti Internazionali
                    VStack(alignment: .leading, spacing: 10) {
                        Text("8. Utenti Internazionali")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Personal Best Running è disponibile in tutto il mondo. Poiché tutti i dati rimangono sul tuo dispositivo, non avviene alcun trasferimento internazionale di dati.")
                    }
                    
                    // 9. Modifiche a questa Informativa
                    VStack(alignment: .leading, spacing: 10) {
                        Text("9. Modifiche a questa Informativa sulla Privacy")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Potremmo aggiornare questa Informativa sulla Privacy di tanto in tanto. Le modifiche verranno pubblicate all'interno dell'app e la data di \"Ultimo aggiornamento\" verrà modificata. L'uso continuato dell'app implica l'accettazione della policy aggiornata.")
                    }
                    
                    // 10. Contatti
                    VStack(alignment: .leading, spacing: 10) {
                        Text("10. Contatti")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Se hai domande su questa Informativa sulla Privacy o sui tuoi diritti, non esitare a contattarci:")
                        
                        Button(
                            action: {
                                if let url = URL(string: "mailto:info.foiasoft@gmail.com?subject=Personal%20Best%20Running%20-%20Domanda%20Informativa%20Privacy") {
                                    UIApplication.shared.open(url)
                                }
                            },
                            label: {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                    Text("info.foiasoft@gmail.com")
                                        .foregroundColor(.primary)
                                }
                            }
                        )
                        
                        Text("Risponderemo alle richieste relative alla privacy entro 30 giorni.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    
                    // 11. Conformità GDPR
                    VStack(alignment: .leading, spacing: 10) {
                        Text("11. Conformità GDPR")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Per gli utenti nell'Unione Europea, operiamo in conformità con il Regolamento Generale sulla Protezione dei Dati (GDPR). Poiché non raccogliamo dati personali, la maggior parte dei diritti GDPR (come l'accesso ai server o la portabilità) non si applica. Mantieni comunque il pieno controllo eliminando l'app o pulendo i dati sul telefono.") // swiftlint:disable:this line_length
                    }
                    
                    // 12. Diritti della Privacy in California
                    VStack(alignment: .leading, spacing: 10) {
                        Text("12. Diritti della Privacy in California (CCPA)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("I residenti in California sono tutelati dal California Consumer Privacy Act (CCPA). Poiché Personal Best Running non raccoglie né vende alcuna informazione personale a terzi, l'applicazione rispetta nativamente i requisiti di massima riservatezza imposti dalla legge.")
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
    PrivacyPolicyView()
        .environment(\.locale, .init(identifier: "en"))
}
