//
//  SmokingDetailsView.swift
//  Bloom
//
//  Created by Claude on 2026-01-24.
//

import SwiftUI
import CoreHealth
import TelemetryDeck
import SFSafeSymbols

struct SmokingDetailsView: View {
  @ObservedObject private var healthManager = HealthManager.shared

  @State private var selectedStatus: SmokingStatus
  @State private var quitDate: Date
  @State private var hasChanges = false

  init() {
    _selectedStatus = State(initialValue: HealthManager.shared.smokingStatus)
    _quitDate = State(initialValue: HealthManager.shared.smokingQuitDate ?? Date())
  }

  var body: some View {
    BloomScrollView {
      VStack(spacing: 20) {
        statusSection
        if selectedStatus == .former {
          quitDateSection
        }
        impactSection
        infoSection
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Smoking",
          subtitle: String(localized: "Status", comment: "Subtitle on the Smoking detail screen")
        )
      }
    }
    .navigationTitle("Smoking")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: selectedStatus)
    .onAppear {
      TelemetryDeck.viewScreen("Smoking Details")
    }
    .onChange(of: selectedStatus) { _, newValue in
      healthManager.smokingStatus = newValue
      hasChanges = true
      if newValue == .former && healthManager.smokingQuitDate == nil {
        healthManager.smokingQuitDate = quitDate
      }
      Task {
        await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()
      }
    }
    .onChange(of: quitDate) { _, newValue in
      if selectedStatus == .former {
        healthManager.smokingQuitDate = newValue
        hasChanges = true
        Task {
          await BiologicalAgeViewModel.shared.forceCalculateBiologicalAge()
        }
      }
    }
  }
}

private extension SmokingDetailsView {

  var statusSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Smoking Status")
        .font(.headline)

      VStack(spacing: 12) {
        ForEach(SmokingStatus.allCases, id: \.self) { status in
          Button {
            selectedStatus = status
          } label: {
            HStack {
              Image(systemSymbol: statusIcon(for: status))
                .foregroundStyle(statusColor(for: status))
                .frame(width: 24)

              Text(status.displayName)
                .foregroundStyle(.primary)

              Spacer()

              if selectedStatus == status {
                Image(systemSymbol: .checkmarkCircleFill)
                  .foregroundStyle(.tint)
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(selectedStatus == status ? AnyShapeStyle(Color.accentColor.tertiary) : AnyShapeStyle(.background.secondary))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(selectedStatus == status ? Color.accentColor : Color.clear, lineWidth: 2)
            )
          }
          .buttonStyle(.plain)
        }
      }
    }
    .cardContainer()
  }

  var quitDateSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Quit Date")
        .font(.headline)

      DatePicker(
        "When did you quit?",
        selection: $quitDate,
        in: ...Date(),
        displayedComponents: .date
      )
      .datePickerStyle(.compact)

      if let daysSince = daysSinceQuit {
        HStack {
          Image(systemSymbol: .starFill)
            .foregroundStyle(.vitalGood)
          Text(quitDurationText(days: daysSince))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
    }
    .cardContainer()
  }

  var impactSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Bio Age Impact")
          .font(.headline)
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        switch selectedStatus {
        case .unknown:
          Text("Set your smoking status to see how it affects your biological age.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .transition(.opacity)
        case .never:
          HStack {
            Image(systemSymbol: .checkmarkCircleFill)
              .foregroundStyle(.white, .vitalGreat)
            Text("No impact on your biological age")
              .font(.subheadline)
          }
          .transition(.opacity)
        case .former:
          HStack {
            Image(systemSymbol: .arrowDownCircleFill)
              .foregroundStyle(.white, .vitalGood)
            VStack(alignment: .leading) {
              Text("Reduced impact over time")
                .font(.subheadline)
              if let impact = formerSmokerImpact {
                Text("Current impact: +\(impact, specifier: "%.1f") years")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .transition(.opacity)
        case .current:
          HStack {
            Image(systemSymbol: .exclamationmarkTriangleFill)
              .foregroundStyle(.white, .vitalSevere)
            VStack(alignment: .leading) {
              Text("Adds up to +8 years to your bio age")
                .font(.subheadline)
              Text("Quitting can reduce this over time")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .transition(.opacity)
        @unknown default:
          EmptyView()
        }
      }
    }
    .horizontalAlignment(.leading)
    .cardContainer()
    .compositingGroup()
  }

  var infoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("About Smoking & Health")
          .font(.headline)
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("Smoking is one of the most significant factors affecting biological age and overall health.")

        Text("")

        Text("**Benefits of quitting:**")

        Text("• Within 20 minutes: Heart rate drops")
        Text("• Within 12 hours: Carbon monoxide levels normalize")
        Text("• Within 2-12 weeks: Circulation improves")
        Text("• Within 1-9 months: Coughing decreases")
        Text("• Within 1 year: Heart disease risk halves")
        Text("• Within 5-15 years: Stroke risk equals non-smoker")
      }
      .foregroundStyle(.secondary)
    }
    .horizontalAlignment(.leading)
    .cardContainer()
    .compositingGroup()
  }

  func statusIcon(for status: SmokingStatus) -> SFSymbol {
    switch status {
    case .unknown: .questionmarkCircleFill
    case .never: .checkmarkCircleFill
    case .former: .clockArrowCirclepath
    case .current: .exclamationmarkTriangleFill
    @unknown default: .questionmarkCircleFill
    }
  }

  func statusColor(for status: SmokingStatus) -> Color {
    switch status {
    case .unknown: .secondary
    case .never: .vitalGreat
    case .former: .vitalGood
    case .current: .vitalSevere
    @unknown default: .secondary
    }
  }

  var daysSinceQuit: Int? {
    guard selectedStatus == .former else { return nil }
    let components = Calendar.current.dateComponents([.day], from: quitDate, to: Date())
    return components.day
  }

  func quitDurationText(days: Int) -> String {
    if days < 1 {
      return String(localized: "Quit today - great decision!", comment: "Encouragement shown on the Smoking detail screen when the quit date is today")
    } else if days < 7 {
      return String(localized: "Smoke-free for \(days) days - you're doing great!", comment: "Encouragement on the Smoking detail screen. The placeholder is a number of days.")
    } else if days < 30 {
      let weeks = days / 7
      return String(localized: "Smoke-free for \(weeks) weeks - amazing progress!", comment: "Encouragement on the Smoking detail screen. The placeholder is a number of weeks.")
    } else if days < 365 {
      let months = days / 30
      return String(localized: "Smoke-free for \(months) months - incredible!", comment: "Encouragement on the Smoking detail screen. The placeholder is a number of months.")
    } else {
      let years = days / 365
      return String(localized: "Smoke-free for \(years) years - that's amazing!", comment: "Encouragement on the Smoking detail screen. The placeholder is a number of years.")
    }
  }

  var formerSmokerImpact: Double? {
    guard selectedStatus == .former else { return nil }
    let yearsSinceQuit = Date().timeIntervalSince(quitDate) / (365.25 * 24 * 3600)
    return 6.0 * exp(-yearsSinceQuit / 6.0)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      SmokingDetailsView()
    }
  }
}
