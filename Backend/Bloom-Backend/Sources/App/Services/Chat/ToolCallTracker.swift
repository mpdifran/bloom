import Foundation
import Vapor

/// Tracks tool calls per request to prevent excessive API usage
actor ToolCallTracker {
    /// Maximum number of tool calls allowed per request
    private let maxToolCallsPerRequest: Int
    
    /// Active request tracking - maps request ID to tool call count
    private var activeRequests: [String: Int] = [:]
    
    init(maxToolCallsPerRequest: Int = 3) {
        self.maxToolCallsPerRequest = maxToolCallsPerRequest
    }
    
    /// Checks if tools should be included for a request based on current tool call count
    /// - Parameter requestId: Unique identifier for the request
    /// - Returns: true if tools should be included, false if limit has been reached
    func shouldIncludeTools(for requestId: String) -> Bool {
        let currentCount = activeRequests[requestId] ?? 0
        return currentCount < maxToolCallsPerRequest
    }
    
    /// Increments the tool call count for a request
    /// - Parameters:
    ///   - requestId: Unique identifier for the request
    /// - Returns: true if the tool call is allowed, false if limit exceeded
    func incrementToolCallCount(for requestId: String) -> Bool {
        let currentCount = activeRequests[requestId] ?? 0
        
        // Check if limit would be exceeded
        if currentCount >= maxToolCallsPerRequest {
            return false
        }
        
        // Increment count
        activeRequests[requestId] = currentCount + 1
        return true
    }
    
    /// Gets the current tool call count for a request
    /// - Parameter requestId: Unique identifier for the request
    /// - Returns: Current number of tool calls for the request
    func getToolCallCount(for requestId: String) -> Int {
        return activeRequests[requestId] ?? 0
    }
    
    /// Clears tracking for a completed request
    /// - Parameter requestId: Unique identifier for the request
    func clearRequest(_ requestId: String) {
        activeRequests.removeValue(forKey: requestId)
    }
    
    /// Clears all tracked requests (for cleanup)
    func clearAllRequests() {
        activeRequests.removeAll()
    }
}
