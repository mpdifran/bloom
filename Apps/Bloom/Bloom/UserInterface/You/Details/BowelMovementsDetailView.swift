//
//  BowelMovementsDetailView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-29.
//

import SFSafeSymbols
import SwiftUI
import Charts
import TelemetryDeck
import HealthKit
import CoreHealth
import BloomFoundation
import DataContainer

struct BowelMovementsDetailView: View {

  @State private var selectedPeriod: StatTimePeriod = .sevenDays
  @State private var bowelMovements: [BowelMovementDTO] = []
  @State private var presentedSheet: AnyView?
  @State private var selectedBristolType = 0
  @State private var selectedRegularityFilter = 0

  @State private var dailyWater = [DateQuantitySample]()
  @State private var averageWater: HKQuantity?
  @State private var dailyFiber = [DateQuantitySample]()

  @State private var navigationPushView: AnyView?

  var body: some View {
    Group {
      if bowelMovements.isNotEmpty {
        contentView
      } else {
        emptyView
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        VitalSummaryDetailTitleView(
          title: "Bowel Movements",
          subtitle: selectedPeriod.displayName
        )
      }
    }
    .animation(.default, value: selectedPeriod)
    .animation(.default, value: selectedBristolType)
    .animation(.default, value: selectedRegularityFilter)
    .navigationTitle("Bowel Movements")
    .navigationBarTitleDisplayMode(.inline)
    .sheet($presentedSheet)
    .navigationDestination($navigationPushView)
    .onAppear {
      TelemetryDeck.viewScreen("Bowel Movements Vital Details")
    }
    .task(id: selectedPeriod) {
      let modelActor = BowelMovementModelActor.standard()
      let samples = (try? await modelActor.fetchBowelMovements(
        dateRange: selectedPeriod.dateRange
      )) ?? []
      await MainActor.run {
        self.bowelMovements = samples
      }
    }
    .task(id: selectedPeriod) {
      let dailySamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .dietaryFiber,
        unit: .gram(),
        interval: DateComponents(day: 1),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )

      let samples: [DateQuantitySample]
      if selectedPeriod.aggregatesByWeek {
        let grouped = Dictionary(grouping: dailySamples) { sample in
          Calendar.current.dateInterval(of: .weekOfYear, for: sample.date)?.start ?? sample.date
        }
        samples = grouped.map { (weekStart, weekSamples) in
          let average = weekSamples.map { $0.quantity.doubleValue(for: .gram()) }.average(keyPath: \.self)
          return DateQuantitySample(date: weekStart, quantity: HKQuantity(unit: .gram(), doubleValue: average))
        }.sorted { $0.date < $1.date }
      } else {
        samples = dailySamples
      }

      await MainActor.run {
        self.dailyFiber = samples
      }
    }
    .task(id: selectedPeriod) {
      let dailySamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
        for: .dietaryWater,
        unit: .literUnit(with: .milli),
        interval: DateComponents(day: 1),
        options: [.cumulativeSum],
        dateRange: selectedPeriod.dateRange
      )

      let samples: [DateQuantitySample]
      if selectedPeriod.aggregatesByWeek {
        let grouped = Dictionary(grouping: dailySamples) { sample in
          Calendar.current.dateInterval(of: .weekOfYear, for: sample.date)?.start ?? sample.date
        }
        samples = grouped.map { (weekStart, weekSamples) in
          let average = weekSamples.map { $0.quantity.doubleValue(for: .literUnit(with: .milli)) }.average(keyPath: \.self)
          return DateQuantitySample(date: weekStart, quantity: HKQuantity(unit: .literUnit(with: .milli), doubleValue: average))
        }.sorted { $0.date < $1.date }
      } else {
        samples = dailySamples
      }

      await MainActor.run {
        self.dailyWater = samples
        let averageLitres = samples.map({ $0.quantity.doubleValue(for: .liter()) }).average(keyPath: \.self)
        self.averageWater = HKQuantity(unit: .liter(), doubleValue: averageLitres)
      }
    }
  }
}

private extension BowelMovementsDetailView {

  enum IntervalBucket: Int, CaseIterable, Identifiable {
    case veryFrequent = 0  // < 8 hours
    case optimal = 1       // 8-24 hours
    case good = 2          // 24-48 hours
    case concerning = 3    // 48-72 hours
    case tooInfrequent = 4 // > 72 hours

    var id: Int { rawValue }

    var label: String {
      switch self {
      case .veryFrequent: String(localized: "< 8 Hours", comment: "Label for bowel movements detail view")
      case .optimal: String(localized: "8-24 Hours", comment: "Label for bowel movements detail view")
      case .good: String(localized: "24-48 Hours", comment: "Label for bowel movements detail view")
      case .concerning: String(localized: "48-72 Hours", comment: "Label for bowel movements detail view")
      case .tooInfrequent: String(localized: "> 72 Hours", comment: "Label for bowel movements detail view")
      }
    }

    var color: Color {
      switch self {
      case .veryFrequent: .vitalSevere
      case .optimal: .vitalGreat
      case .good: .vitalGood
      case .concerning: .vitalWarning
      case .tooInfrequent: .vitalSevere
      }
    }

    static func bucket(for hours: Double) -> IntervalBucket {
      if hours < 8 {
        return .veryFrequent
      } else if hours <= 24 {
        return .optimal
      } else if hours <= 48 {
        return .good
      } else if hours <= 72 {
        return .concerning
      } else {
        return .tooInfrequent
      }
    }
  }

  var summary: BowelMovementSummary? {
    guard bowelMovements.isNotEmpty else { return nil }
    return BowelMovementSummary(bowelMovements: bowelMovements)
  }

  var contentView: some View {
    BloomScrollView(spacing: 20) {
      StatTimePeriodPicker(selectedPeriod: $selectedPeriod)
      stoolTypeChart
      regularityChart
      detailsCardForSelectedRegularityFilter
      lastBowelMovementSection
      timeOfDayChart
      waterChart
      fiberChart
      showAllDataCell
    }
  }

  var emptyView: some View {
    ContentUnavailableView {
      Label("No Data Available", systemSymbol: .toiletFill)
    } description: {
      Text("Log your bowel movements to learn more about your regularity.")
    } actions: {
      Button("Log Bowel Movement") {
        presentedSheet = BowelMovementActionCardView(performDismiss: nil).asAny
      }
      .buttonStyle(.primary)
      .tint(.brown)
    }
  }

  var showAggregatedStoolChart: Bool {
    selectedPeriod != .sevenDays && selectedPeriod != .oneMonth
  }

  @ViewBuilder
  var stoolTypeChart: some View {
    if let summary {
      VStack(alignment: .leading, spacing: 20) {
        VStack {
          VitalDetailChartTitleView(
            title: "Bristol Stool Types",
            value: ""
          )

          if showAggregatedStoolChart {
            stoolTypeDistributionChart(summary: summary)
          } else {
            stoolTypeTimelineChart(summary: summary)
          }

          typePicker
        }
        .cardContainer()

        detailsCardForSelectedStoolType
      }
    }
  }

  func stoolTypeTimelineChart(summary: BowelMovementSummary) -> some View {
    Chart {
      ForEach(summary.bowelMovements) { bowelMovement in
        if bowelMovement.isValidBristolStoolType {
          LineMark(
            x: .value("Date", bowelMovement.date),
            y: .value("Bristol Stool Type", "Type \(bowelMovement.bristolStoolType)")
          )
          .foregroundStyle(.fill)

          PointMark(
            x: .value("Date", bowelMovement.date),
            y: .value("Bristol Stool Type", "Type \(bowelMovement.bristolStoolType)")
          )
          .foregroundStyle(chartForegroundColor(for: bowelMovement.bristolStoolType))
        }
      }

      if selectedBristolType != 0 {
        RectangleMark(y: .value("Bristol Stool Type", "Type \(selectedBristolType)"))
          .foregroundStyle(color(for: selectedBristolType).opacity(0.3))
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic) { _ in
        AxisGridLine()
        AxisValueLabel(format: selectedPeriod.chartDateFormat)
      }
    }
    .chartYScale(domain: ["Type 1", "Type 2", "Type 3", "Type 4", "Type 5", "Type 6", "Type 7"])
    .chartYAxis {
      AxisMarks { _ in
        AxisGridLine()
        AxisValueLabel(offsetsMarks: false)
      }
    }
    .frame(height: 350)
  }

  func stoolTypeDistributionChart(summary: BowelMovementSummary) -> some View {
    Chart {
      ForEach(1...7, id: \.self) { type in
        let count = summary.stoolTypeDistribution[type]?.count ?? 0

        BarMark(
          x: .value("Count", count),
          y: .value("Type", "Type \(type)")
        )
        .foregroundStyle(
          selectedBristolType == 0 || selectedBristolType == type
            ? color(for: type)
            : color(for: type).opacity(0.3)
        )
        .cornerRadius(4)
        .annotation(position: .trailing) {
          if count > 0 {
            Text(verbatim: "\(count)")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .chartYScale(domain: ["Type 1", "Type 2", "Type 3", "Type 4", "Type 5", "Type 6", "Type 7"])
    .chartXAxis {
      AxisMarks { _ in
        AxisGridLine()
        AxisValueLabel()
      }
    }
    .chartYAxis {
      AxisMarks { _ in
        AxisGridLine()
        AxisValueLabel(offsetsMarks: true)
      }
    }
    .frame(height: 280)
  }

  var chartMinDate: Date {
    summary?.bowelMovements.min(keyPath: \.date) ?? .now
  }

  func chartForegroundColor(for stoolType: Int) -> Color {
    if selectedBristolType == 0 || selectedBristolType == stoolType {
      return color(for: stoolType)
    }
    return color(for: stoolType).opacity(0.3)
  }

  var typePicker: some View {
    Button {
      selectedBristolType = (selectedBristolType + 1) % 8
    } label: {
      HStack {
        Text("Bristol Stool Type")

        Spacer()

        if selectedBristolType == 0 {
          Text("All")
        } else {
          Text("Type \(selectedBristolType)")
        }
      }
    }
    .buttonStyle(.zone)
    .tint(color(for: selectedBristolType))
    .sensoryFeedback(.selection, trigger: selectedBristolType)
  }

  var detailsCardForSelectedStoolType: some View {
    DetailInfoCardView {
      switch selectedBristolType {
      case 0:
        Text("The Bristol Stool Types are a standard mechanism to help categorize bowel movements. They can help provide insights into your gut health.")
      case 1:
        Text("This type indicates constipation. This can be caused by dehydration, lack of fiber, or other digestive issues. It may be beneficial to increase fluid intake and dietary fiber.")
      case 2:
        Text("This type indicates mild constipation. You might need to improve your diet, increase hydration, and consider physical activity to help regularize bowel movements.")
      case 3:
        Text("This type indicates a healthy gut with slight indication of dehydration. Maintaining a balanced diet with sufficient fiber and hydration is recommended.")
      case 4:
        Text("This type is the ideal stool. This indicates a healthy digestive system with normal bowel function. Continue with your current diet and lifestyle.")
      case 5:
        Text("This type may indicate a dietary change, mild digestive upset, or a temporary imbalance in your gut.")
      case 6:
        Text("This type can be caused by dietary issues, infections, stress, or other gastrointestinal problems. It’s important to stay hydrated and, if persistent, consider evaluating for potential infections or intolerances.")
      case 7:
        Text("This type represents severe diarrhea. This could indicate a significant gastrointestinal issue, such as an infection, food poisoning, or a chronic condition. It’s crucial to stay hydrated and seek medical advice if this persists.")
      default:
        EmptyView()
      }

      HealthCitationLinkView(
        url: .bristolStoolScale,
        title: "Based on the Bristol Stool Form Scale (Heaton & Lewis, 1997)."
      )
    }
  }

  func color(for bristolStoolType: Int) -> Color {
    switch bristolStoolType {
    case 7: .vitalSevere
    case 1, 6: .vitalWarning
    case 2, 5: .vitalGood
    case 3, 4: .vitalGreat
    default: .brown
    }
  }

  @ViewBuilder
  var lastBowelMovementSection: some View {
    if let lastBowelMovement = summary?.bowelMovements.max(by: { $0.date < $1.date }) {
      HStack {
        Text("Last Bowel Movement")
          .multilineTextAlignment(.leading)
          .bold()

        Spacer(minLength: 0)

        Text(lastBowelMovement.date, formatter: DateFormatter.relativeDateMediumTimeShort)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.trailing)
      }
      .fontDesign(.rounded)
      .cardContainer()
    }
  }

  @ViewBuilder
  var timeOfDayChart: some View {
    if let summary {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Time Of Day",
          value: ""
        )

        Chart {
          ForEach(Calendar.TimeOfDay.allCases) { timeOfDay in
            BarMark(
              x: .value("Time Of Day", timeOfDay.name),
              y: .value("Count", summary.timeOfDayDistribution[timeOfDay, default: []].count)
            )
            .foregroundStyle(color(for: timeOfDay))
            .cornerRadius(8)
          }
        }
        .frame(height: 250)
      }
      .cardContainer()
    }
  }

  func color(for timeOfDay: Calendar.TimeOfDay) -> Color {
    switch timeOfDay {
    case .morning: .mutedYellow
    case .afternoon: .mutedOrange
    case .evening: .mutedPurple
    case .overnight: .mutedIndigo
    @unknown default:
      fatalError("Unhandled case")
    }
  }
  
  func colorForInterval(_ intervalHours: Double) -> Color {
    if intervalHours < 8 {
      return .vitalSevere // Too frequent
    } else if intervalHours <= 24 {
      return .vitalGreat // Optimal daily
    } else if intervalHours <= 48 {
      return .vitalGood // Still good
    } else if intervalHours <= 72 {
      return .vitalWarning // Getting concerning
    } else {
      return .vitalSevere // Too infrequent
    }
  }
  
  var regularityFilterPicker: some View {
    Button {
      selectedRegularityFilter = (selectedRegularityFilter + 1) % 6
    } label: {
      HStack {
        Text("Interval Range")
        
        Spacer()
        
        Text(regularityFilterName)
      }
    }
    .buttonStyle(.zone)
    .tint(regularityFilterColor)
    .sensoryFeedback(.selection, trigger: selectedRegularityFilter)
  }
  
  var regularityFilterName: String {
    switch selectedRegularityFilter {
    case 1: String(localized: "< 8 Hours", comment: "Label for bowel movements detail view")
    case 2: String(localized: "8-24 Hours", comment: "Label for bowel movements detail view")
    case 3: String(localized: "24-48 Hours", comment: "Label for bowel movements detail view")
    case 4: String(localized: "48-72 Hours", comment: "Label for bowel movements detail view")
    case 5: String(localized: "> 72 Hours", comment: "Label for bowel movements detail view")
    default: String(localized: "All", comment: "Regularity filter showing every bowel movement interval")
    }
  }
  
  var regularityFilterColor: Color {
    switch selectedRegularityFilter {
    case 0: .brown
    case 1: .vitalSevere
    case 2: .vitalGreat
    case 3: .vitalGood
    case 4: .vitalWarning
    case 5: .vitalSevere
    default: .brown
    }
  }
  
  func shouldShowInterval(_ intervalHours: Double) -> Bool {
    switch selectedRegularityFilter {
    case 0: true // All
    case 1: intervalHours < 8
    case 2: intervalHours >= 8 && intervalHours <= 24
    case 3: intervalHours > 24 && intervalHours <= 48
    case 4: intervalHours > 48 && intervalHours <= 72
    case 5: intervalHours > 72
    default: true
    }
  }
  
  func rangeForSelectedFilter() -> (min: Double, max: Double)? {
    switch selectedRegularityFilter {
    case 0: return nil // All - no range highlight
    case 1: return (min: 0, max: 8) // < 8 Hours
    case 2: return (min: 8, max: 24) // 8-24 Hours
    case 3: return (min: 24, max: 48) // 24-48 Hours
    case 4: return (min: 48, max: 72) // 48-72 Hours
    case 5: return (min: 72, max: 120) // > 72 Hours (capped at chart max)
    default: return nil
    }
  }
  
  func chartYAxisMax(for intervals: [(date: Date, intervalHours: Double)]) -> Double {
    // Get the maximum data point
    let dataMax = intervals.map(\.intervalHours).max() ?? 72
    
    // Get the maximum of the highlighted range (if any)
    let rangeMax = rangeForSelectedFilter()?.max ?? 0
    
    // Take the maximum of data and range, then add 10% padding
    let maxValue = max(dataMax, rangeMax) * 1.1
    
    // Cap at reasonable maximum to prevent excessive scaling
    return min(maxValue, 200)
  }
  
  var detailsCardForSelectedRegularityFilter: some View {
    DetailInfoCardView {
      switch selectedRegularityFilter {
      case 0:
        Text("Time between bowel movements helps indicate digestive health and regularity. Consistent patterns are generally healthier.")
      case 1:
        Text("Very frequent bowel movements (less than 8 hours apart) may indicate digestive sensitivity, dietary issues, or stress.")
      case 2:
        Text("Daily bowel movements (8-24 hours) are considered optimal for most people, indicating healthy digestive function.")
      case 3:
        Text("Every 1-2 days (24-48 hours) is still within normal range for many people, though daily is generally preferred.")
      case 4:
        Text("Every 2-3 days (48-72 hours) may indicate slower digestion. Consider increasing fiber, water, and physical activity.")
      case 5:
        Text("More than 3 days between bowel movements suggests constipation. Consult healthcare provider if this persists.")
      default:
        Text("Time between bowel movements helps indicate digestive health and regularity patterns.")
      }

      HealthCitationLinkView(
        url: .stoolHabits,
        title: "Assessment of normal bowel habits in the general adult population, PubMed"
      )
    }
  }
}

private extension BowelMovementsDetailView {

  var averageFiber: HKQuantity? {
    guard dailyFiber.isNotEmpty else { return nil }
    let average = dailyFiber.map { $0.quantity.doubleValue(for: .gram()) }.average(keyPath: \.self)
    return HKQuantity(unit: .gram(), doubleValue: average)
  }

  @ViewBuilder
  var fiberChart: some View {
    if
      let averageFiber,
      averageFiber.doubleValue(for: .gram()) >= 1
    {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Fiber",
          value: averageFiber.displayString(for: .gram())
        )

        Chart {
          ForEach(dailyFiber) { sample in
            BarMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Daily Fiber", sample.quantity.doubleValue(for: .gram()))
            )
            .foregroundStyle(.fiber)
          }

          let goal = HealthGoalProvider.shared.recommendedMinDailyIntakeForFiber()
          RuleMark(
            y: .value("Min Fiber", goal.doubleValue(for: .gram()))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.fiber)

          RectangleMark(
            yStart: .value("Max Fiber", goal.doubleValue(for: .gram()) * 2),
            yEnd: .value("Min Fiber", goal.doubleValue(for: .gram()))
          )
          .foregroundStyle(
            LinearGradient(
              colors: [
                .fiber.opacity(0.3),
                .clear
              ],
              startPoint: .bottom,
              endPoint: .top
            )
          )
        }
        .frame(height: 160)
      }
      .cardContainer()
    }
  }

  @ViewBuilder
  var waterChart: some View {
    if dailyWater.isNotEmpty {
      VStack(alignment: .leading) {
        VitalDetailChartTitleView(
          title: "Water",
          value: averageWater?.displayString(for: .literUnit(with: .milli)) ?? ""
        )

        Chart {
          ForEach(dailyWater) { sample in
            BarMark(
              x: .value("Date", sample.date, unit: selectedPeriod.aggregatesByWeek ? .weekOfYear : .day),
              y: .value("Water", sample.quantity.localizedValue(for: .literUnit(with: .milli)))
            )
            .foregroundStyle(.mutedBlue)
          }

          RuleMark(
            y: .value("Min Water", HKQuantity(unit: .literUnit(with: .milli), doubleValue: 2000).localizedValue(for: .literUnit(with: .milli)))
          )
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
          .foregroundStyle(.mutedBlue)

          RectangleMark(
            yStart: .value("Min Water", HKQuantity(unit: .literUnit(with: .milli), doubleValue: 2000).localizedValue(for: .literUnit(with: .milli))),
            yEnd: .value("Min Water", HKQuantity(unit: .literUnit(with: .milli), doubleValue: 4000).localizedValue(for: .literUnit(with: .milli)))
          )
          .foregroundStyle(
            LinearGradient(
              colors: [.mutedBlue.opacity(0.3), .clear],
              startPoint: .bottom,
              endPoint: .top
            )
          )
        }
        .frame(height: 160)
      }
      .cardContainer()
    }
  }

  var regularityChart: some View {
    VStack(alignment: .leading) {
      VitalDetailChartTitleView(
        title: "Regularity",
        value: summary?.regularityScore.format(using: .oneDecimalPlace) ?? ""
      )

      if let summary = summary, summary.bowelMovements.count >= 3 {
        if showAggregatedStoolChart {
          intervalDistributionChart(summary: summary)
        } else {
          VStack(alignment: .leading) {
            intervalChart
            regularityFilterPicker
          }
        }
      } else {
        ContentUnavailableView(
          "Insufficient Data",
          systemImage: "chart.bar.fill",
          description: Text("At least 3 bowel movements are needed to analyze regularity patterns.")
        )
        .frame(height: 160)
      }
    }
    .cardContainer()
  }
  
  var intervalChart: some View {
    Group {
      if let summary = summary {
        let intervals = summary.intervalData()
        
        Chart {
          // Dynamic range background based on selected filter
          if selectedRegularityFilter != 0, let range = rangeForSelectedFilter() {
            RectangleMark(
              yStart: .value("Min Range", range.min),
              yEnd: .value("Max Range", range.max)
            )
            .foregroundStyle(regularityFilterColor.opacity(0.2))
            
            // Dynamic range boundary lines
            if range.min > 0 {
              RuleMark(y: .value("Range Min", range.min))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(regularityFilterColor)
            }
            
            if range.max < 120 {
              RuleMark(y: .value("Range Max", range.max))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(regularityFilterColor)
            }
          }
          
          ForEach(intervals.indices, id: \.self) { index in
            let interval = intervals[index]
            
            BarMark(
              x: .value("Date", interval.date),
              y: .value("Hours Between", interval.intervalHours)
            )
            .foregroundStyle(
              shouldShowInterval(interval.intervalHours) 
                ? colorForInterval(interval.intervalHours)
                : colorForInterval(interval.intervalHours).opacity(0.2)
            )
            .cornerRadius(4)
          }
        }
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: selectedPeriod.chartDateFormat)
          }
        }
        .chartYScale(domain: 0...chartYAxisMax(for: intervals))
        .frame(height: 180)
      }
    }
  }

  func intervalDistributionChart(summary: BowelMovementSummary) -> some View {
    let intervals = summary.intervalData()
    let bucketCounts = Dictionary(grouping: intervals) { interval in
      IntervalBucket.bucket(for: interval.intervalHours)
    }.mapValues { $0.count }

    return Chart {
      ForEach(IntervalBucket.allCases) { bucket in
        let count = bucketCounts[bucket] ?? 0

        BarMark(
          x: .value("Count", count),
          y: .value("Interval", bucket.label)
        )
        .foregroundStyle(bucket.color)
        .cornerRadius(4)
        .annotation(position: .trailing) {
          if count > 0 {
            Text(verbatim: "\(count)")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .chartYScale(domain: IntervalBucket.allCases.map(\.label))
    .chartXAxis {
      AxisMarks { _ in
        AxisGridLine()
        AxisValueLabel()
      }
    }
    .chartYAxis {
      AxisMarks { _ in
        AxisGridLine()
        AxisValueLabel(offsetsMarks: true)
      }
    }
    .frame(height: 200)
  }

  var showAllDataCell: some View {
    HStack {
      Text("Show All Logs")
        .bold()
      Spacer()
      DisclosureIndicator()
    }
    .cardContainer()
    .onTapGesture {
      navigationPushView = BowelMovementAllDataView().asAny
    }
  }
}

#Preview {
  BowelMovementsDetailView()
}
