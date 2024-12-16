//
//  SettingsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI

struct SettingsCell<Content>: View where Content: View {
  let title: String
  let systemImage: String?
  let indentationLevel: Int
  let contentBuilder: () -> Content

  init(
    title: String,
    systemImage: String? = nil,
    indentationLevel: Int = 0,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.systemImage = systemImage
    self.indentationLevel = indentationLevel
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    LabeledContent {
      contentBuilder()
        .foregroundStyle(.secondary)
    } label: {
      HStack {
        if let systemImage {
          Image(systemName: systemImage)
            .symbolVariant(.fill)
            .bold()
            .padding(6)
            .background {
              RoundedRectangle(cornerRadius: 10)
                .fill(.tint)
            }
        }

        Text(title)
      }
      .padding(.leading, CGFloat(indentationLevel) * 20)
    }
  }
}

#Preview {
  NavigationStack {
    List {
      SettingsCell(title: "Goal", systemImage: "bag") {
        Picker(selection: .constant("Maintain Weight")) {
          Text("Maintain Weight")
            .tag("Maintain Weight")
          Text("Lose Weight")
            .tag("Lose Weight")
          Text("Gain Weight")
            .tag("Gain Weight")
        } label: {
          EmptyView()
        }
      }
      .tint(.mutedGreen)

      NavigationLink {
        Text("Details")
      } label: {
        SettingsCell(title: "Target Weight", indentationLevel: 1) {
          Text("160 lbs")
        }
        .tint(.mutedBlue)
      }
    }
    .navigationTitle("Preview")
  }
}
