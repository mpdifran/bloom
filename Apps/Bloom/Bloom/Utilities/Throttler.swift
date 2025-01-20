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
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue

    init(timeInterval: TimeInterval, queue: DispatchQueue = .main) {
        self.timeInterval = timeInterval
        self.queue = queue
    }

    func perform(_ block: @escaping () -> Void) {
        cancelPerform()

        workItem = DispatchWorkItem {
            block()
        }
        queue.asyncAfter(deadline: .now() + timeInterval, execute: workItem!)
    }

    func cancelPerform() {
        workItem?.cancel()
    }
}
