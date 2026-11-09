import Foundation
import StoreKit

/// Xcode transactions never enter the existing Apple wallet or share its deduplication namespace.
enum TiloWalletStorageScope: String {
    case apple, localStoreKit

    static var current: Self {
        #if DEBUG
        if ProcessInfo.processInfo.environment["TILO_STOREKIT_MODE"] == "local" { return .localStoreKit }
        #endif
        return .apple
    }

    func fileURL(in root: URL, accountID: UUID) -> URL {
        let directory = self == .localStoreKit ? root.appendingPathComponent("StoreKitTesting", isDirectory: true) : root
        return directory.appendingPathComponent(accountID.uuidString.lowercased() + ".json")
    }

    func accepts(_ environment: AppStore.Environment) -> Bool {
        self == .localStoreKit ? environment == .xcode : (environment == .production || environment == .sandbox)
    }
}
