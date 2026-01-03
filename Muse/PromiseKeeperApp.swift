import SwiftUI
import SwiftData

@main
struct MuseApp: App {
    @StateObject private var entitlementManager = EntitlementManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
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
            .onAppear {
                // Ensure background music starts playing if enabled
                BackgroundMusicManager.shared.startIfNeeded()
                // Refresh notifications on launch
                NotificationService.shared.refreshDailyNotifications()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    // Refresh notifications when app becomes active
                    NotificationService.shared.refreshDailyNotifications()
                }
            }
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([AffirmationSession.self])
        
        // Create a local-only store URL to completely avoid iCloud/CloudKit
        let localStoreURL = URL.documentsDirectory.appending(path: "MuseLocalStore.sqlite")
        
        // Use explicit local-only configuration
        let modelConfiguration = ModelConfiguration(
            "LocalStore",
            schema: schema,
            url: localStoreURL,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("⚠️ MuseApp: Failed to create ModelContainer: \(error)")
            print("⚠️ MuseApp: Attempting to delete and recreate database...")
            
            // Delete and recreate
            do {
                try FileManager.default.removeItem(at: localStoreURL)
                try? FileManager.default.removeItem(at: localStoreURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: localStoreURL.appendingPathExtension("shm"))
                print("✅ MuseApp: Deleted old database, creating fresh one...")
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("❌ MuseApp: Failed to recreate database: \(error)")
            }
            
            // Last resort: use in-memory storage
            print("⚠️ MuseApp: Falling back to in-memory storage")
            let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Could not create ModelContainer even in memory: \(error)")
            }
        }
    }
}
