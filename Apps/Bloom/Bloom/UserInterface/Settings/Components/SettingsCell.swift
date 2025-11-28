//
//  SettingsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI
import SFSafeSymbols

extension SettingsCell {
  enum TrailingIconType {
    case disclosure
    case link
  }
}

struct SettingsCell<Content>: View where Content: View {
  let title: String
  let subtitle: String?
  let iconType: TrailingIconType?
  let contentBuilder: () -> Content

  init(
    _ title: String,
    subtitle: String? = nil,
    iconType: TrailingIconType? = nil,
    @ViewBuilder contentBuilder: @escaping () -> Content
  ) {
    self.title = title
    self.subtitle = subtitle
    self.iconType = iconType
    self.contentBuilder = contentBuilder
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .bold()
          .fontDesign(.rounded)
          .minimumScaleFactor(0.7)
          .lineLimit(2)
        
        if let subtitle = subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
      .layoutPriority(10)

      Group {
        Spacer()

        contentBuilder()
          .layoutPriority(0)

        iconView
      }
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 16)
    .frame(minHeight: 60)
    .selectable()
  }
}

private extension SettingsCell {

  @ViewBuilder
  var iconView: some View {
    Group {
      if let iconType {
        switch iconType {
        case .disclosure:
          DisclosureIndicator()
        case .link:
          Image(systemSymbol: .arrowUpForward)
        }
      } else {
        EmptyView()
      }
    }
    .foregroundStyle(.secondary)
    .bold()
    .fontDesign(.rounded)
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
                iconType: .disclosure
              ) {
                Text("160 lbs")
              }
            }
            .buttonStyle(.plain)

            SettingsCell(
              "Privacy Policy",
              iconType: .link
            ) { }
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

          SettingsSectionContainer {
            SettingsCell("Biological Age", subtitle: "Estimate your biological age based on your data") {
              Toggle("", isOn: .constant(false))
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
