//
//  ProfileHeaderView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-21.
//

import SwiftUI

struct ProfileHeaderView: View {
    @Binding var name: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(.tint)
                    .font(.system(size: 80))

                TextField("Name", text: $name)
                    .font(.title)
                    .fontDesign(.rounded)
                    .bold()
                    .submitLabel(.done)
            }
        }
    }
}

#Preview {
    ProfileHeaderView(name: .constant("Mark"))
}
