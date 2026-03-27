import SwiftUI

enum OnboardingStep {
    case welcome
    case airpodsCheck
    case alarmSetup
}

@main
struct AirAlarmApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    @State private var currentStep: OnboardingStep = .welcome

    var body: some Scene {
        WindowGroup {
            GlassEffectContainer {
                ZStack {
                    // Shared persistent background — never removed during transitions
                    BreathingBackground()

                    // Foreground content with smooth transitions
                    if showOnboarding {
                        OnboardingView {
                            hasSeenOnboarding = true
                            withAnimation(.smooth(duration: 0.7)) {
                                showOnboarding = false
                            }
                        }
                        .transition(.opacity)
                    } else {
                        Group {
                            switch currentStep {
                            case .welcome:
                                WelcomeView {
                                    withAnimation(.smooth(duration: 0.7)) {
                                        currentStep = .airpodsCheck
                                    }
                                }

                            case .airpodsCheck:
                                AirPodsCheckView {
                                    withAnimation(.smooth(duration: 0.7)) {
                                        currentStep = .alarmSetup
                                    }
                                }

                            case .alarmSetup:
                                ContentView()
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .animation(.smooth(duration: 0.7), value: currentStep)
                .animation(.smooth(duration: 0.7), value: showOnboarding)
            }
            .preferredColorScheme(.dark)
            .onAppear {
                showOnboarding = !hasSeenOnboarding
            }
        }
    }
}
