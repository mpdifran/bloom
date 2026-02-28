//
//  CelebrationModalView.swift
//  Bloom
//
//  Created by Claude on 2026-02-26.
//

import SwiftUI
import StoreKit
import BloomUI
import BloomFoundation
import CoreHealth
import DataContainer
@preconcurrency import HealthKit

struct CelebrationModalView: View {

  let kind: CelebrationKind

  @State private var showChart = true
  @State private var isSharing = false
  @State private var chartData: CelebrationChartData?

  @Environment(\.dismiss) private var dismiss
  @Environment(\.requestReview) private var requestReview

  private static let appStoreURL = "https://apps.apple.com/app/apple-store/id6739955926?pt=127532637&ct=bloom-celebration-share&mt=8"

  var body: some View {
    NavigationStack {
      CardView {
        budImageView

        VStack(spacing: 8) {
          HStack(spacing: 6) {
            Image(systemName: "laurel.leading")
            Text(Date().formatted(.dateTime.month(.abbreviated).day().year()))
            Image(systemName: "laurel.trailing")
          }
          .font(.subheadline)
          .fontWeight(.bold)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)

          Text(kind.title)
            .font(.title)
            .bold()
            .fontDesign(.rounded)
            .multilineTextAlignment(.center)

          Text(kind.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

          if showChart {
            chartView
              .padding(.top, 8)
          }

//          Toggle("Include my data", isOn: $showChart)
//            .fontWeight(.medium)
//            .fontDesign(.rounded)
//            .cardContainer()

          Button {
            shareImage()
          } label: {
            Label("Share", systemImage: "square.and.arrow.up")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        }
        .padding(.horizontal)
        .padding(.top)
      }
      .ignoresSafeArea(edges: .top)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          DismissButton()
        }
      }
    }
    .presentationBackground(Color(uiColor: UIColor.secondarySystemBackground))
    .task {
      chartData = await loadChartData()
    }
    .sheet(isPresented: $isSharing) {
      if let url = renderShareImage() {
        ShareSheet(items: [
          url,
          "\(kind.shareMessage())"
        ]) { completed in
          guard completed else { return }
          if RatingPromptTracker.shared.shouldRequestReviewAfterCelebration() {
            requestReview()
          }
        }
      }
    }
  }
}

// MARK: - Content

private extension CelebrationModalView {

  var budImageView: some View {
    GeometryReader { proxy in
      Image(kind.budImage)
        .resizable()
        .scaledToFill()
        .frame(width: proxy.size.width)
        .clipped()
    }
    .frame(height: 250)
  }

  @ViewBuilder
  var chartView: some View {
    switch kind {
    case .biologicalAge(let yearsYounger):
      let ages = bioAgeValues(yearsYounger: yearsYounger)
      BloomUI.BiologicalAgeMeter(
        chronologicalAge: ages.chronological,
        biologicalAge: ages.biological
      )
      .frame(height: 180)
    case .goalStreak(let metricName, let days):
      GoalStreakChartCard(metricName: metricName, days: days)
        .padding(.vertical)
    case .zoneMinutes:
      if case .zoneMinutes(let data) = chartData {
        ZoneMinutesChartCard(zoneData: data)
          .frame(height: 180)
      } else {
        ZoneMinutesChartCard()
          .frame(height: 180)
      }
    case .perfectSleep(let sleepAnalysis):
      if case .sleep(let segments) = chartData {
        AppleSleepStageChartView(sleepAnalysis: sleepAnalysis, segments: segments)
          .frame(height: 180)
      } else {
        AppleSleepStageChartView(sleepAnalysis: sleepAnalysis)
          .frame(height: 180)
      }
    }
  }

  func bioAgeValues(yearsYounger: Int) -> (chronological: Double, biological: Double) {
    if case .bioAge(let records) = chartData, let latest = records.last {
      return (latest.actualAge, latest.biologicalAge)
    }
    let chronological = Double(HealthManager.shared.age())
    return (chronological, chronological - Double(yearsYounger))
  }
}

// MARK: - Share

private extension CelebrationModalView {

  func shareImage() {
    isSharing = true
  }

  @MainActor
  func renderShareImage() -> URL? {
    let view = CelebrationCardView(kind: kind, chartData: chartData)
      .frame(width: UIScreen.main.bounds.width)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 2.0

    guard let image = renderer.uiImage else { return nil }
    return saveImageToTempFile(image)
  }

  func loadChartData() async -> CelebrationChartData? {
    switch kind {
    case .biologicalAge:
      let modelActor = BiologicalAgeRecordModelActor.standard()
      let records = (try? await modelActor.fetchAllRecords()) ?? []
      return .bioAge(records)
    case .zoneMinutes:
      let zoneData = await ZoneMinutesChartCard.fetchZoneMinutesData()
      return .zoneMinutes(zoneData)
    case .perfectSleep(let sleepAnalysis):
      let samples = (try? await HealthStoreFetcher.shared.fetchSamples(
        for: HKCategoryType(.sleepAnalysis),
        dateRange: DateRange(sleepAnalysis.startDate, sleepAnalysis.endDate)
      )) ?? []
      let segments = samples.compactMap { sample -> AppleSleepSegment? in
        guard
          let categorySample = sample as? HKCategorySample,
          let category = categorySample.sleepCategory,
          let stage = AppleSleepStage(from: category)
        else { return nil }
        return AppleSleepSegment(stage: stage, startDate: sample.startDate, endDate: sample.endDate)
      }.sorted { $0.startDate < $1.startDate }
      return .sleep(segments)
    case .goalStreak:
      return nil
    }
  }

  func saveImageToTempFile(_ image: UIImage) -> URL? {
    guard let jpegData = image.jpegData(compressionQuality: 0.85) else { return nil }
    let filename = "Bloom Celebration.jpg"
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    do {
      try jpegData.write(to: tempURL)
      return tempURL
    } catch {
      return nil
    }
  }
}

// MARK: - Preview

#Preview("Bio Age") {
  PreviewSheetPresent {
    CelebrationModalView(kind: .biologicalAge(yearsYounger: 3))
  }
}

#Preview("Goal Streak") {
  PreviewSheetPresent {
    CelebrationModalView(kind: .goalStreak(metricName: "Steps", days: 7))
  }
}

#Preview("Zone Minutes") {
  PreviewSheetPresent {
    CelebrationModalView(kind: .zoneMinutes(minutes: 150))
  }
}

#Preview("Perfect Sleep") {
  PreviewSheetPresent {
    CelebrationModalView(kind: .perfectSleep(SleepAnalysis.previewData[0]))
  }
}
