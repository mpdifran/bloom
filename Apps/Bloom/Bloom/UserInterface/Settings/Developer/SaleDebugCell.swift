//
//  SaleDebugCell.swift
//  Bloom
//

import BloomModel
import SwiftUI

struct SaleDebugCell: View {
  let sale: SaleDetails
  let eligibilityState: SaleEligibilityState
  let isOverridden: Bool
  let onOverrideChanged: (Bool) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(sale.title)
          .font(.headline)
          .fontDesign(.rounded)

        Spacer()

        Toggle("Override", isOn: Binding(
          get: { isOverridden },
          set: { onOverrideChanged($0) }
        ))
        .labelsHidden()
      }

      Text("\(formatDate(sale.startDate)) - \(formatDate(sale.endDate))")
        .font(.caption)
        .foregroundStyle(.secondary)

      Divider()

      VStack(alignment: .leading, spacing: 4) {
        criteriaRow(label: "Sale is active", met: eligibilityState.isActive)
        criteriaRow(label: "Within date range", met: eligibilityState.isWithinDateRange)
        audienceCriteriaRow
        frequencyCriteriaRow
      }
      .font(.subheadline)

      Divider()

      HStack {
        Text("Overall:")
          .fontWeight(.medium)
        Text(eligibilityState.meetsAllCriteria ? "ELIGIBLE" : "NOT ELIGIBLE")
          .fontWeight(.bold)
          .foregroundStyle(eligibilityState.meetsAllCriteria ? .green : .red)
      }
      .font(.subheadline)
    }
    .padding(.vertical, 12)
  }

  // MARK: - Criteria Rows

  private func criteriaRow(label: String, met: Bool) -> some View {
    HStack(spacing: 6) {
      Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
        .foregroundStyle(met ? .green : .red)
      Text(label)
        .foregroundStyle(met ? .primary : .secondary)
    }
  }

  private var audienceCriteriaRow: some View {
    let met = eligibilityState.userAudienceMatches
    let targetAudienceNames = eligibilityState.targetAudiences.map { audienceDisplayName($0) }.joined(separator: ", ")
    let userAudienceName = audienceDisplayName(eligibilityState.userAudienceType)

    return HStack(spacing: 6) {
      Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
        .foregroundStyle(met ? .green : .red)
      Text("Audience: \(targetAudienceNames) (You: \(userAudienceName))")
        .foregroundStyle(met ? .primary : .secondary)
    }
  }

  private var frequencyCriteriaRow: some View {
    let met = eligibilityState.displayFrequencyMet
    let frequencyText: String

    if let daysSince = eligibilityState.daysSinceLastShown {
      frequencyText = "Frequency: \(daysSince)/\(eligibilityState.displayFrequencyDays) days"
    } else {
      frequencyText = "Frequency met (never shown)"
    }

    return HStack(spacing: 6) {
      Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
        .foregroundStyle(met ? .green : .red)
      Text(frequencyText)
        .foregroundStyle(met ? .primary : .secondary)
    }
  }

  // MARK: - Helpers

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
  }

  private func audienceDisplayName(_ audience: TargetAudience) -> String {
    switch audience {
    case .freeUsers:
      return "Free"
    case .subscribedUsers:
      return "Subscribed"
    case .expiredUsers:
      return "Expired"
    }
  }
}
