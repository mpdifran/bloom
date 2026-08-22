//
//  BloodPressureStatCard.swift
//  Bloom
//
//  Created by Assistant on 2024-12-31.
//

import SwiftUI
import BloomFoundation
import CoreHealth

struct BloodPressureStatCard: View {
  let data: BloodPressureCardData?

  private var formattedValue: String? {
    guard let data else { return nil }
    return "\(Int(data.latestSystolic))/\(Int(data.latestDiastolic))"
  }

  private var subtitle: String? {
    guard let data else { return nil }
    let categoryName = data.category.name
    let dateText = formattedDate(data.latestDate)
    return "\(categoryName) • \(dateText)"
  }

  private var statCardTrend: StatCardTrend? {
    guard let category = data?.category else { return nil }
    switch category {
    case .normal: return .ok
    case .low, .elevated: return .warning
    case .hypertensionStage1, .hypertensionStage2, .hypertensiveCrisis: return .critical
    @unknown default: return nil
    }
  }

  private var tintColor: AnyShapeStyle {
    guard let data else { return AnyShapeStyle(.gray) }
    return AnyShapeStyle(data.category.color)
  }

  var body: some View {
    StatCard(
      symbol: .heartFill,
      title: "Blood Pressure",
      value: formattedValue ?? String(localized: "No Data", comment: "Blood pressure card value when there are no readings"),
      valueStyle: .largeTinted(subtitle),
      trend: statCardTrend
    )
    .tint(tintColor)
  }

  private func formattedDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let now = Date()

    if calendar.isDateInToday(date) {
      return String(localized: "Today", comment: "Blood pressure card date label for a reading taken today")
    } else if calendar.isDateInYesterday(date) {
      return String(localized: "Yesterday", comment: "Blood pressure card date label for a reading taken yesterday")
    } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
      return String(localized: "\(daysAgo)d ago", comment: "Blood pressure card date label. The placeholder is a number of days.")
    } else {
      return DateFormatter.monthAndDay.string(from: date)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        BloodPressureStatCard(data: previewBloodPressureCardData)
        BloodPressureStatCard(data: nil)
      }
    }
  }
}

private let previewBloodPressureCardData = BloodPressureCardData(
  latestSystolic: 118,
  latestDiastolic: 78,
  latestDate: Date(),
  category: .normal
)
