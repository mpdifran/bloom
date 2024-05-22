//
//  ProfileItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-21.
//

import SwiftUI

struct ProfileItemCell: View {
    let title: String

    var body: some View {
        Text(title)
            .bold()
            .fontDesign(.rounded)
    }
}

#Preview {
    List {
        ProfileItemCell(title: "Likes playing tennis")
    }
}
