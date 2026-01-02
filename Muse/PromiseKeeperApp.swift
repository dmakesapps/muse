import SwiftUI
import SwiftData

@main
struct MuseApp: App {
    @StateObject private var entitlementManager = EntitlementManager.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingContainerView()
                        .transition(.opacity)
                }
            }
            .environmentObject(entitlementManager)
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([AffirmationSession.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
