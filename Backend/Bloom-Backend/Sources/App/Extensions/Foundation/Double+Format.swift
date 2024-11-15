//
//  Double+Format.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation

extension Double {

    func prettyFormat() -> String {
        if self == rounded() {
            return String(Int(self))
        } else {
            return String(format: "%g", self)
        }
    }
}
