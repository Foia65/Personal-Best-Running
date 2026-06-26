import SwiftUI

struct PremiumInfoView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
            // Header
            VStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.orange)
                    .padding(.top, 25)
                Text("Passa a Premium")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 2)
                Text("Sblocca tutto il potenziale di PB Running")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 3)
            }
            .padding(.bottom, 20)
            
            Divider()
            
            // Features List
            VStack(spacing: 14) {
                PremiumFeatureRow(
                    icon: "tablecells.badge.ellipsis",
                    title: "Esporta in CSV",
                    description: "Esporta il tuo piano di allenamento in formato CSV per analizzarlo in Excel e altri strumenti, oppure per importarlo in altre app."
                )
                
                PremiumFeatureRow(
                    icon: "calendar.badge.plus",
                    title: "Esporta nel calendario",
                    description: "Ogni sessione di allenamento viene automaticamente aggiunta al tuo calendario come evento giornaliero."
                )
                
                PremiumFeatureRow(
                    icon: "doc",
                    title: "Esporta in PDF",
                    description: "Genera un file PDF con il tuo piano di allenamento completo, pronto da stampare o condividere facilmente."
                )
                
                PremiumFeatureRow(
                    icon: "person",
                    title: "Profilo Atleta",
                    description: "Lo stato attuale del tuo percorso atletico e le previsioni dei tuoi tempi stimati per ogni distanza."
                )
            }
            .padding(.vertical, 10)
            
            Divider()
            
            VStack(spacing: 10) {
                Text("Prezzo chiaro:")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                
                if let price = storeKitManager.premiumLocalizedPrice {
                    Text(price)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                } else {
                    Text("\u{2014}")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Purchase Button
            Group {
                if !storeKitManager.productsLoaded {
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            ProgressView().tint(.white)
                            Text("Caricamento...")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(LinearGradient(colors: [Color.gray, Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                    }
                    .disabled(true)
                } else if let errorMsg = storeKitManager.productsErrorMessage {
                    Button {
                        Task { await storeKitManager.requestProducts() }
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill").font(.title2)
                                Text("Errore").font(.headline).fontWeight(.semibold)
                            }
                            Text("Prodotto non disponibile al momento")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Color.red)
                        .cornerRadius(16)
                    }
                } else {
                    Button {
                        Task {
                            await storeKitManager.purchasePremium()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if storeKitManager.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "crown.fill").font(.title2)
                            }
                            Text(storeKitManager.isPurchasing ? "Elaborazione..." : "Passa a Premium")
                                .font(.headline)
                                .fontWeight(.semibold)
                            if !storeKitManager.isPurchasing {
                                Image(systemName: "arrow.right").font(.title2)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: !storeKitManager.isPurchasing
                                ? [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.4, blue: 0.6), Color(red: 0.3, green: 0.5, blue: 0.7)]
                                : [Color.gray, Color.gray, Color.gray],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(storeKitManager.isPurchasing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 15.0)
            
            Text("Pagamento unico. Nessun abbonamento.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
        }
    }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Chiudi") { dismiss() }
            }
        }
        .onChange(of: isPremiumUser) { _, newValue in
            if newValue { dismiss() }
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    PremiumInfoView()
        .environmentObject(StoreKitManager.shared)
        .environment(\.locale, .init(identifier: "en"))
}
