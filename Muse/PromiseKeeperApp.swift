import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

@main
struct MuseApp: App {
    @StateObject private var entitlementManager = EntitlementManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    init() {
        EntitlementManager.shared.configureRevenueCatIfNeeded()
        EntitlementManager.shared.refreshCustomerInfo()
    }
    
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
                entitlementManager.refreshCustomerInfo()
                // Ensure background music starts playing if enabled
                BackgroundMusicManager.shared.startIfNeeded()
                // Refresh notifications on launch
                NotificationService.shared.refreshDailyNotifications()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    entitlementManager.refreshCustomerInfo()
                    // Refresh notifications when app becomes active
                    NotificationService.shared.refreshDailyNotifications()
                }
            }
            .fullScreenCover(isPresented: $entitlementManager.showPaywall) {
                RevenueCatPaywallScreen(source: entitlementManager.paywallSource)
                    .environmentObject(entitlementManager)
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

private struct RevenueCatPaywallScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    let source: EntitlementManager.PaywallSource?

    @State private var didResolvePaywall = false
    @State private var selectedOffering: Offering?
    @State private var isLoadingOffering = false
    @State private var offeringLoadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if entitlementManager.isPaywallConfigured {
                    paywallContent
                } else {
                    paywallUnavailableView
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        resolvePaywall {
                            entitlementManager.handlePaywallDismissed(for: source)
                        }
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .task {
            await loadOfferingIfNeeded()
        }
        .onDisappear {
            guard !didResolvePaywall else { return }
            didResolvePaywall = true
            entitlementManager.handlePaywallDismissed(for: source)
        }
    }

    @ViewBuilder
    private var paywallContent: some View {
        if isLoadingOffering {
            ProgressView("Loading subscription options...")
                .tint(.white)
                .foregroundColor(.white)
        } else if let selectedOffering {
            paywallView(offering: selectedOffering)
        } else {
            paywallView(offering: nil)
        }
    }

    private var paywallUnavailableView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 54))
                .foregroundColor(.museAccentBlue)

            Text("Purchases Are Unavailable")
                .font(.museHeadline())
                .foregroundColor(.white)

            Text("Add your RevenueCat public iOS SDK key in the local secrets file or the `REVENUECAT_API_KEY` environment variable to enable subscriptions.")
                .font(.museBodyMedium())
                .foregroundColor(.museLightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Close") {
                resolvePaywall {
                    entitlementManager.handlePaywallDismissed(for: source)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.museAccentBlue)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    @ViewBuilder
    private func paywallView(offering: Offering?) -> some View {
        let paywall: AnyView = {
            if let offering {
                return AnyView(PaywallView(offering: offering))
            } else {
                return AnyView(PaywallView())
            }
        }()

        paywall
            .onPurchaseCompleted { customerInfo in
                resolvePaywall {
                    entitlementManager.handlePurchaseCompleted(customerInfo, for: source)
                }
            }
            .onRestoreCompleted { customerInfo in
                resolvePaywall {
                    entitlementManager.handleRestoreCompleted(customerInfo, for: source)
                }
            }
            .onPurchaseFailure { error in
                print("⚠️ RevenueCatPaywallScreen: Purchase failed: \(error.localizedDescription)")
            }
            .onRestoreFailure { error in
                print("⚠️ RevenueCatPaywallScreen: Restore failed: \(error.localizedDescription)")
            }
    }

    private func resolvePaywall(_ action: () -> Void) {
        guard !didResolvePaywall else { return }
        didResolvePaywall = true
        action()
        dismiss()
    }

    private func loadOfferingIfNeeded() async {
        guard !isLoadingOffering else { return }
        guard let offeringID = preferredOfferingID else { return }

        isLoadingOffering = true
        defer { isLoadingOffering = false }

        do {
            let offerings = try await Purchases.shared.offerings()

            if let preferredOffering = offerings[offeringID] {
                selectedOffering = preferredOffering
                print("💎 RevenueCatPaywallScreen: Loaded offering \(offeringID)")
            } else {
                selectedOffering = offerings.current
                offeringLoadError = "Offering \(offeringID) not found. Falling back to current."
                print("⚠️ RevenueCatPaywallScreen: Offering \(offeringID) not found, falling back to current offering")
            }
        } catch {
            offeringLoadError = error.localizedDescription
            selectedOffering = nil
            print("⚠️ RevenueCatPaywallScreen: Failed to load offering \(offeringID): \(error.localizedDescription)")
        }
    }

    private var preferredOfferingID: String? {
        let localValue = LocalSecrets.revenueCatOfferingID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localValue.isEmpty {
            return localValue
        }

        let environmentValue = ProcessInfo.processInfo.environment["REVENUECAT_OFFERING_ID"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return environmentValue?.isEmpty == false ? environmentValue : nil
    }
}
