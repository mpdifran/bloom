//
//  MockHealthAppPermissionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-24.
//

import SwiftUI

struct MockHealthAppPermissionView: View {
    var body: some View {
        VStack {
            Image(.healthAppIcon)
                .resizable()
                .frame(square: 60)
                .padding(.top, 30)

            Text("Health")
                .font(.title)
                .fontDesign(.rounded)
                .bold()
                .padding(.bottom, 30)

            Text("Turn on All")
                .bold()
                .horizontalAlignment(.leading)
                .foregroundStyle(.mutedBlue)
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.background)
                }
                .padding(.bottom, 15)

            VStack {
                MockHealthPermissionItemView()
                MockHealthPermissionItemView()
                MockHealthPermissionItemView()
                MockHealthPermissionItemView()
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
            }

            Spacer()
        }
        .padding()
        .frame(width: 320, height: 600)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .fill(.background.secondary)
        }
    }
}

private struct MockHealthPermissionItemView: View {

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.fill)
                .frame(square: 30)

            VStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.fill)
                    .frame(width: 100, height: 10)
                RoundedRectangle(cornerRadius: 6)
                    .fill(.fill)
                    .frame(width: 60, height: 10)
            }

            Toggle(isOn: .constant(true), label: {  })
                .opacity(0.3)
        }
        .padding(14)
    }
}

#Preview {
    MockHealthAppPermissionView()
}
