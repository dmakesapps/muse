import SwiftUI
import RevenueCat
import RevenueCatUI

struct RevenueCatPaywallScreen: View {
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

// MARK: - Scoped paywall presentation (avoids sheet + paywall conflicts)

extension View {
    func paywallFullScreenCover(presenter: EntitlementManager.PaywallPresenter) -> some View {
        modifier(PaywallPresenterModifier(presenter: presenter))
    }
}

private struct PaywallPresenterModifier: ViewModifier {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    let presenter: EntitlementManager.PaywallPresenter

    func body(content: Content) -> some View {
        content.fullScreenCover(
            isPresented: Binding(
                get: {
                    entitlementManager.showPaywall && entitlementManager.paywallPresenter == presenter
                },
                set: { isPresented in
                    if !isPresented {
                        entitlementManager.handlePaywallDismissed(for: entitlementManager.paywallSource)
                    }
                }
            )
        ) {
            RevenueCatPaywallScreen(source: entitlementManager.paywallSource)
                .environmentObject(entitlementManager)
        }
    }
}
