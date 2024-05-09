//
//  Delay.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import Foundation

public func Delay(_ milliseconds: Int, _ closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds), execute: closure)
}
