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
    HStack {
      Text(title)
        .bold()
        .fontDesign(.rounded)
        .minimumScaleFactor(0.7)
        .lineLimit(2)
        .layoutPriority(10)

      Group {
        Spacer()
        contentBuilder()
          .layoutPriority(0)
        if showDisclosureIndicator {
          DisclosureIndicator()
            .bold()
        }
      }
      .foregroundStyle(.secondary)
    }
    .frame(minHeight: 60)
    .selectable()
  }
}

#Preview {
  PreviewEnvironment {
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
            .buttonStyle(.plain)
          }

          SettingsSectionContainer {
            SettingsCell("Morning Report on Wake Up") {
              Toggle("", isOn: .constant(true))
            }

            Divider()

            SettingsCell("User ID") {
              Text("21345-3terdgf-xbbfxg-hrae-g4a-t5s4ysrt-htxr-g")
            }
          }
        }
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Preview")
    }
  }
}
