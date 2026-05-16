import SwiftUI
import StoreKit

struct InfoView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("🪚 Lavori in corso... 🔨")
                    .foregroundStyle(.red)
                    .padding(.top, 20)
                Form {
                    Section(header:
                        Text("Informazioni e Supporto")
                        .font(.title3)
                        .padding(.top, 20)) {
                            
                            NavigationLink(destination: Segnalibro()) {
                                Label {
                                    Text("About Depth of Field")
                                } icon: {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                            }
                            
                            NavigationLink(destination: Segnalibro()) {
                                Label {
                                    Text("Aiuto")
                                } icon: {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                            }
                            
                            NavigationLink(destination: Segnalibro()) {
                                Label {
                                    Text("???")
                                } icon: {
                                    Image(systemName: "camera")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                            }
                            
                            Button {
                                if let url = URL(string: "mailto:info.foiasoft@gmail.com") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label {
                                    Text("Contatta il supporto")
                                        .foregroundColor(.primary)
                                } icon: {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                            }
                            
                            HStack {
                                Label {
                                    Text("Versione: ") // Unstyled text
                                } icon: {
                                    Image(systemName: "shippingbox")
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                }
                                Spacer()
                                Text("\(Bundle.main.appVersionDisplay) (\(Bundle.main.appBuild))")
                                    .font(.system(.subheadline, design: .rounded, weight: .regular))
                                    .foregroundColor(.secondary)
                                
                            }
                        }
                    
                    Section(header: Text("Account & Preferences").font(.title3)) {
                        HStack {
                            Label {
                                Text("Product level:")
                            } icon: {
                                Image(systemName: "person.badge.shield.checkmark")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            Spacer()
                        }
                        
                        NavigationLink(destination: Segnalibro()) {
                            Label {
                                Text("Language")
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "globe")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                        
                        Button {
                            //  requestAppReview()
                            
                        } label: {
                            Label {
                                Text("Rate this App")
                                    .foregroundColor(.primary)
                            } icon: {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                    }
                    
                    Section(header: Text("Privacy & Security").font(.title3)) {
                        
                        NavigationLink(destination: Segnalibro()) {
                            Label {
                                Text("Privacy Policy")
                            } icon: {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                        
                        NavigationLink(destination: Segnalibro()) {
                            Label {
                                Text("Terms of Service")
                            } icon: {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                        }
                        
                    }
                }
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .environment(\.defaultMinListRowHeight, 28)
            }
        }
    }
}

// MARK: - Helpers

// Convenience accessors for app version and build information.
extension Bundle {
    var appVersionDisplay: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

// MARK: - Preview
#Preview {
    InfoView()
        .environmentObject(ThemeManager())
}
