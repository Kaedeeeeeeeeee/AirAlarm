import SwiftUI
import SwiftData
import UIKit

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
    @State private var alarmManager = SleepAlarmManager()
    @State private var localization = LocalizationManager()
    @State private var contentView: ContentView?

    @ViewBuilder
    private func glassContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GlassEffectContainer {
            content()
        }
    }

    var body: some Scene {
        WindowGroup {
            glassContainer {
                ZStack {
                    BreathingBackground()

                    if alarmManager.isRinging {
                        MorningGreetingView(
                            cycles: alarmManager.scheduledCycles,
                            onDismiss: {
                                // Save widget data
                                let duration = SleepCycleCalculator.formatDuration(cycles: alarmManager.scheduledCycles)
                                let defaults = UserDefaults(suiteName: "group.com.zhangshifeng.airalarm")
                                defaults?.set(duration, forKey: "lastSleepDuration")
                                defaults?.set(alarmManager.scheduledCycles, forKey: "lastSleepCycles")
                                defaults?.set(Date(), forKey: "lastSleepDate")

                                withAnimation(.smooth(duration: 0.5)) {
                                    alarmManager.stopRinging()
                                    alarmManager.cancelAlarm()
                                }

                                // Gracefully send app to background after a brief moment
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    UIControl().sendAction(
                                        #selector(URLSessionTask.suspend),
                                        to: UIApplication.shared,
                                        for: nil
                                    )
                                }
                            }
                        )
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
            .environment(localization)
            .modelContainer(for: SleepRecord.self)
            .preferredColorScheme(.dark)
            .onAppear {
                showOnboarding = !hasSeenOnboarding
                alarmManager.localization = localization
                alarmManager.checkAlarmCompleted()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                alarmManager.checkAlarmCompleted()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                alarmManager.checkAlarmCompleted()
            }
            .onOpenURL { url in
                if url.host == "start" {
                    // Skip to alarm setup and auto-start would need AudioManager access
                    // For now, just navigate to the main screen
                    withAnimation(.smooth(duration: 0.5)) {
                        showOnboarding = false
                        currentStep = .alarmSetup
                    }
                }
            }
        }
    }
}
