//
//  View+Expand.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-01.
//

import SwiftUI

extension View {

    func expandHorizontally() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }

    func expandVertically() -> some View {
        VStack {
            Spacer()
            self
            Spacer()
        }
    }
}
