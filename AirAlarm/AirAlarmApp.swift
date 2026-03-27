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
    @State private var alarmManager = AlarmManager()

    var body: some Scene {
        WindowGroup {
            GlassEffectContainer {
                ZStack {
                    BreathingBackground()

                    if alarmManager.isRinging {
                        // Full-screen alarm page — on top of everything
                        AlarmRingingView(cycles: alarmManager.scheduledCycles) {
                            withAnimation(.smooth(duration: 0.5)) {
                                alarmManager.stopRinging()
                                alarmManager.cancelAlarm()
                            }
                        }
                        .transition(.opacity)
                    } else if showOnboarding {
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
                                ContentView(alarmManager: alarmManager)
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .animation(.smooth(duration: 0.7), value: currentStep)
                .animation(.smooth(duration: 0.7), value: showOnboarding)
                .animation(.smooth(duration: 0.5), value: alarmManager.isRinging)
            }
            .preferredColorScheme(.dark)
            .onAppear {
                showOnboarding = !hasSeenOnboarding
            }
        }
    }
}
