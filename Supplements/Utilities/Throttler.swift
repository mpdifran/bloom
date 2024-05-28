//
//  Throttler.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-28.
//

import Foundation

final class Throttler {
    let timeInterval: TimeInterval

    private var timer: Timer?

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    func perform(_ block: @escaping () -> Void) {
        cancelPerform()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { (_) in
            block()
        }
    }

    func cancelPerform() {
        timer?.invalidate()
    }
}
