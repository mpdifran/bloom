//
//  View+ListSeparatorInset.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-03.
//

import SwiftUI

extension View {

    func standardListSeparatorInset() -> some View {
        alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }

    func removeListSeparator() -> some View {
        alignmentGuide(.listRowSeparatorLeading) { viewDimensions in viewDimensions.width * 2 }
    }
}
