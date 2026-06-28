import SwiftUI

struct SplashView: View {
    @State private var isSplashActive = true
    @State private var showHelp = false
    @AppStorage("hasSeenHelp") private var hasSeenHelp = false
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        ZStack {
            if isSplashActive {
                ZStack {
                    SplashVideoView(videoName: "splash_iphone", videoType: "mp4") {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            isSplashActive = false
                            if !hasSeenHelp {
                                showHelp = true
                            }
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

            if showHelp {
                HelpView {
                    showHelp = false
                    hasSeenHelp = true
                }
                .environment(\.locale, languageManager.currentLocale)
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 1.5), value: showHelp)
    }
}
