//
//  Delay.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation

public func Delay(_ milliseconds: Int, _ closure: @escaping @Sendable @MainActor () -> Void) {
    Task {
        await Delay(milliseconds)
        await MainActor.run {
            closure()
        }
    }
}

public func Delay(_ milliseconds: Int) async {
    let nanoseconds = UInt64(milliseconds) * 1_000_000  // Convert milliseconds to nanoseconds
    try? await Task.sleep(nanoseconds: nanoseconds)
}
