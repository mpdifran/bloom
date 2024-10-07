//
//  SectionTitleView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-07.
//

import SwiftUI

struct SectionTitleView: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .bold()
            .zStackAlignment(.leading)
            .padding(.top)
    }
}

#Preview {
    SectionTitleView("Focus Areas")
}
