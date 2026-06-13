import SwiftUI

/// Root view that shows a splash video on launch, then transitions to the main content.
/// In DEBUG builds the splash is skipped entirely.
struct SplashView: View {
    @State private var isSplashActive = true
    @StateObject private var languageManager = LanguageManager()

    var body: some View {
        #if DEBUG
        ContentView()
            .environmentObject(languageManager)
            .environment(\.locale, languageManager.currentLocale)
        #else
        ZStack {
            if isSplashActive {
                ZStack {
                    SplashVideoView(videoName: "splash_iphone", videoType: "mp4") {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            isSplashActive = false
                        }
                    }
                    VStack {
                        Spacer()
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
                .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
                    .environmentObject(languageManager)
                    .environment(\.locale, languageManager.currentLocale)
            }
        }
        #endif
    }
}
