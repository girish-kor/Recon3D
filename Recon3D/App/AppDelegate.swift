import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CaptureViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

// Additional files: SceneDelegate.swift, Info.plist, bridging header, etc. are standard.

// =============================================================================
// TESTS (Recon3DTests)
// =============================================================================
// For brevity, test files are summarized but would contain XCTest cases covering:
// - Frame quality evaluation
// - Coverage map sufficiency
// - Ring buffer eviction
// - Orchestrator state transitions
// - Error recovery
// - Repository save/load
// - Export cancellation
// Each test case would assert expected outcomes as per specification.

// End of implementation.
