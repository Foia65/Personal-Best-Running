import SwiftUI

struct SplashView: View {
    // 1. Stato per controllare se lo splash screen è attivo
    @State private var isSplashActive = true
    @StateObject private var languageManager = LanguageManager()
    
    var body: some View {
        #if DEBUG
        // In Debug: salta completamente lo splash (anche l'animazione)
        ContentView()
            .environmentObject(languageManager)
        #else
        ZStack {
            if isSplashActive {
                ZStack {
                    // 2. Mostra il video splash screen
                    SplashVideoView(videoName: "splash_iphone", videoType: "mp4") {
                        // Quando il video finisce, spegniamo lo splash con un'animazione fluida
                        withAnimation(.easeInOut(duration: 1.5)) {
                            isSplashActive = false
                        }
                    }
                    // + le version info in basso
                    VStack {
                        Spacer() // Push content to bottom
                        HStack(spacing: 4) {
                            Text("Version:")
                            Text(Bundle.main.appVersionDisplay)
                            Text("Build:")
                            Text(Bundle.main.appBuild)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                        .padding(30)
                        .padding([.leading, .bottom, .trailing])
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity) // Dissolvenza incrociata quando scompare
            } else {
                // 3. main view
                ContentView()
                    .transition(.opacity)
                    .environmentObject(languageManager)
            }
        }
        #endif
    }
}

#Preview {

}
