//
//  SettingsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI

struct SettingsCell<Content>: View where Content: View {
  let title: String
  let showDisclosureIndicator: Bool
  let contentBuilder: () -> Content

  init(
    _ title: String,
    showDisclosureIndicator: Bool = false,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.showDisclosureIndicator = showDisclosureIndicator
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    LabeledContent {
      HStack {
        Spacer()
        contentBuilder()
        if showDisclosureIndicator {
          DisclosureIndicator()
            .bold()
        }
      }
      .foregroundStyle(.secondary)
      .fixedSize()
    } label: {
      Text(title)
        .bold()
        .fontDesign(.rounded)
        .minimumScaleFactor(0.7)
        .lineLimit(2)
    }
    .frame(height: 60)
    .selectable()
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      VStack {
        SettingsSectionContainer {
          SettingsCell("Goal") {
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

          Divider()

          NavigationLink {
            Text("Details")
          } label: {
            SettingsCell(
              "Target Weight",
              showDisclosureIndicator: true
            ) {
              Text("160 lbs")
            }
          }
        }

        SettingsSectionContainer {
          SettingsCell("Morning Report on Wake Up") {
            Toggle("", isOn: .constant(true))
          }
        }
      }
      .padding()
    }
    .groupedBackground()
    .navigationTitle("Preview")
  }
}
