//
//  DisclosureIndicator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-11.
//

import SwiftUI

struct DisclosureIndicator: View {
    var body: some View {
        Image(systemName: "chevron.forward")
            .foregroundStyle(.secondary)
            .bold()
            .fontDesign(.rounded)
    }
}

#Preview {
    DisclosureIndicator()
}
