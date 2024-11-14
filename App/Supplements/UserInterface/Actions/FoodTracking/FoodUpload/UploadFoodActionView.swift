//
//  UploadFoodActionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-13.
//

import SwiftUI

struct UploadFoodActionView: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Spacer()
            Image(systemName: systemImage)
                .font(.title)
            Text(title)
                .font(.title3)
                .bold()
            Spacer()
        }
        .fontDesign(.rounded)
        .foregroundStyle(.tint)
        .selectable()
    }
}

#Preview {
    UploadFoodActionView(
        title: "Scan Barcode",
        systemImage: "barcode.viewfinder"
    )
}
