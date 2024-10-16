//
//  MainTask.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import Foundation

public func MainTask(_ execute: @escaping @MainActor @Sendable () -> Void) {
    Task {
        await MainActor.run {
            execute()
        }
    }
}
