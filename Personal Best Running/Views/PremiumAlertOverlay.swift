import SwiftUI

struct PremiumAlertOverlay: View {
    let title: String
    let message: String
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    Button(action: onUpgrade) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("Vedi l'offerta Premium")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.1, green: 0.2, blue: 0.4),
                                    Color(red: 0.2, green: 0.4, blue: 0.6),
                                    Color(red: 0.3, green: 0.5, blue: 0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }

                    Button(action: onDismiss) {
                        Text("Annulla")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 28)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .frame(maxWidth: 400)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    PremiumAlertOverlay(
        title: "Funzione Premium",
        message: "L'esportazione nel calendario è riservata agli utenti premium.",
        onUpgrade: {},
        onDismiss: {}
    )
    .environment(\.locale, .init(identifier: "it"))

}
