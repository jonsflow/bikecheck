import Security
import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()

    private let service = "com.ride.bikecheck"
    private let hasUsedAppKey = "hasUsedAppBefore"

    private init() {}

    /// Mark that the user has used the app before (persists across reinstalls)
    func setHasUsedApp() {
        let data = Data("true".utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: hasUsedAppKey,
            kSecValueData as String: data
        ]

        // Delete existing if any
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain write error: \(status)")
        } else {
            print("Keychain: User marked as having used app before")
        }
    }

    /// Check if the user has used the app before
    func hasUsedApp() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: hasUsedAppKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        let hasUsed = status == errSecSuccess
        print("Keychain: User has used app before: \(hasUsed)")
        return hasUsed
    }

    /// Clear the keychain entry (for testing purposes)
    func clearHasUsedApp() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: hasUsedAppKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            print("Keychain: Cleared hasUsedApp flag")
        } else {
            print("Keychain: Error clearing hasUsedApp flag: \(status)")
        }
    }
}
