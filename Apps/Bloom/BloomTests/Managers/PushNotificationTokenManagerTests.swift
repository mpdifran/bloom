import XCTest
@testable import Bloom

@MainActor
final class PushNotificationTokenManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing tokens from UserDefaults
        UserDefaults.standard.removeObject(forKey: "com.bloom.apns.deviceToken")
        UserDefaults.standard.removeObject(forKey: "com.bloom.apns.lastRegistration")
    }
    
    private func clearManagerState() {
        // Clear the manager's in-memory state
        PushNotificationTokenManager.shared.clearToken()
    }
    
    func testTokenStorageAndRetrieval() async {
        clearManagerState()
        
        let manager = PushNotificationTokenManager.shared
        let testTokenData = Data([0x01, 0x02, 0x03, 0x04])
        
        // Initially, no token should be stored
        XCTAssertNil(manager.currentToken)
        
        // Simulate receiving a new token
        await manager.handleNewToken(testTokenData)
        
        // Check that token is stored correctly
        XCTAssertNotNil(manager.currentToken)
        XCTAssertEqual(manager.currentToken, "01020304")
    }
    
    func testTokenRefreshInterval() async {
        clearManagerState()
        
        let manager = PushNotificationTokenManager.shared
        let testTokenData = Data([0x01, 0x02, 0x03, 0x04])
        
        // Store initial token
        await manager.handleNewToken(testTokenData)
        
        // Set last registration to recent time
        UserDefaults.standard.set(Date(), forKey: "com.bloom.apns.lastRegistration")
        
        // Token should not need refresh immediately
        await manager.refreshTokenIfNeeded()
        
        // Verify no additional registration attempts were made
        XCTAssertFalse(manager.isRegistering)
    }
    
    func testAuthenticationStateHandling() async {
        clearManagerState()
        
        let manager = PushNotificationTokenManager.shared
        
        // Test logout clears token
        await manager.handleAuthenticationStateChange(isAuthenticated: false)
        XCTAssertNil(manager.currentToken)
        
        // Test login triggers refresh
        await manager.handleAuthenticationStateChange(isAuthenticated: true)
        // In a real scenario, this would trigger token refresh
    }
}