//
//  ProfileSectionHeader.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-22.
//

import SwiftUI

struct ProfileSectionHeader: View {
    let title: String
    let viewAll: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .bold()
            Spacer()
//            Button(action: {
//                viewAll()
//            }, label: {
//                HStack(spacing: 3) {
//                    Text("View All")
//                    Image(systemName: "chevron.forward")
//                }
//                .font(.caption)
//                .bold()
//            })
        }
    }
}

#Preview {
    List {
        Section {
            Text("Content")
        } header: {
            ProfileSectionHeader(title: "Title") { }
        }
    }
}
