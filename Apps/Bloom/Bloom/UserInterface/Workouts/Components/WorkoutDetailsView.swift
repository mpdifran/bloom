//
//  WorkoutDetailsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-18.
//

import SFSafeSymbols
import SwiftUI
@preconcurrency import HealthKit
import Charts
import CoreLocation
import MapKit
import CoreHealth

struct WorkoutDetailsView: View {
  let workout: HKWorkout

  init(workout: HKWorkout) {
    self.workout = workout
  }

  @State private var heartRateReport: WorkoutHeartRateReport?
  @State private var effortScore: Double?
  @State private var workoutRoutes = [WorkoutRoute]()
  @State private var presentedSheet: AnyView?

  @State private var mapCameraPosition: MapCameraPosition = .camera(
    MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), distance: 1000)
  )

  @State private var tasks = [Task<Void, Never>]()

  @State private var selectedZone = 0

  var body: some View {
    BloomScrollView {
      iconHeader
      detailsSection
      effortSection

      if let heartRateReport {
        heartRateReportSection(heartRateReport: heartRateReport)
        heartRateChart(heartRateReport: heartRateReport)
      }
    }
    .navigationTitle(workout.displayName())
    .sheet($presentedSheet)
    .onChange(of: workoutRoutes) { (_ ,_) in
      updateCamera()
    }
    .task {
      async let heartRate: () = fetchHeartRateReport()
      async let effort: () = fetchEffortScore()
      _ = await (heartRate, effort)
    }
    // TODO: Get map working
//    .task {
//      observeWorkoutRoutes()
//    }
  }
}

private extension WorkoutDetailsView {

  var iconHeader: some View {
    WorkoutIcon(workoutType: workout.workoutActivityType, scale: .large)
  }

  var detailsSection: some View {
    VStack {
      SectionTitleView("Stats")
        .padding(.horizontal)

      VStack {
        LabeledContent("Date") {
          TimelineView(.everyMinute) { context in
            VStack(alignment: .trailing) {
              Text("\(DateFormatter.justRelativeDayOfWeek(date: workout.startDate))")
                .font(.caption)
                .foregroundStyle(.secondary)
              Text("\(workout.startDate, formatter: DateFormatter.justDateMedium)")
                .foregroundStyle(.text)
              Text("\(workout.startDate, formatter: DateFormatter.justTimeShort)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }

        Divider()

        if let formattedDuration = DateFormatter.timeIntervalHourMinuteSecondPadded.string(from: workout.duration) {
          LabeledContent("Duration") {
            WorkoutStatView(stat: formattedDuration)
              .tint(.yellow)
          }
          .padding(.vertical, 10)

          Divider()
        }

        LabeledContent("Energy") {
          VStack(alignment: .trailing) {
            WorkoutStatView(stat: "\(workout.activeEnergyBurned.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces))", label: "ACTIVE")
            WorkoutStatView(stat: "\(workout.totalEnergyBurned.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces))", label: "TOTAL")
          }
          .tint(.green)
        }
        .padding(.vertical, 10)

        if let distance = workout.totalDistanceWalkingRunningCycling {
          Divider()

          LabeledContent("Distance") {
            WorkoutStatView(stat: "\(distance.displayString(for: .meterUnit(with: .kilo), formatter: .twoDecimalPlaces))")
              .tint(.blue)
          }
          .padding(.vertical, 10)
        }
        
        if let elevationAscended = workout.elevationAscended,
           let elevationDescended = workout.elevationDescended {
          Divider()
          
          LabeledContent("Elevation") {
            VStack(alignment: .trailing) {
              WorkoutStatView(stat: "\(elevationAscended.displayString(for: .meter(), formatter: .noDecimalPlaces))", label: "ASC")
              WorkoutStatView(stat: "\(elevationDescended.displayString(for: .meter(), formatter: .noDecimalPlaces))", label: "DESC")
            }
            .tint(.orange)
          }
          .padding(.vertical, 10)
        } else if let elevationAscended = workout.elevationAscended {
          Divider()
          
          LabeledContent("Elevation") {
            WorkoutStatView(stat: "\(elevationAscended.displayString(for: .meter(), formatter: .noDecimalPlaces))", label: "ASC")
              .tint(.orange)
          }
          .padding(.vertical, 10)
        }
      }
      .cardContainer()
    }
  }

  var effortSection: some View {
    VStack {
      SectionTitleView("Effort")
        .padding(.horizontal)

      Button {
        presentedSheet = WorkoutEffortPickerCard(
          workout: workout,
          performDismiss: {
            presentedSheet = nil
            Task { await fetchEffortScore() }
          }
        ).asAny
      } label: {
        HStack {
          if let effortScore {
            let category = WorkoutEffortCategory(effortScore: effortScore)
            Text("\(Int(effortScore.rounded()))")
              .font(.title2)
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(category.color)

            Text(category.rawValue)
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(category.color)
          } else {
            Text("Rate Your Effort")
              .bold()
              .fontDesign(.rounded)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Image(systemSymbol: .chevronRight)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .cardContainer()
      }
      .buttonStyle(.plain)
    }
  }

  func heartRateChart(heartRateReport: WorkoutHeartRateReport) -> some View {
    VStack {
      SectionTitleView("Heart Rate")
        .padding(.horizontal)

      VStack(spacing: 20) {
        Chart {
          ForEach(heartRateReport.heartRateSamples, id: \.hashValue) { sample in
            PointMark(
              x: .value("Date", sample.startDate),
              y: .value("Heart Rate", sample.quantity.doubleValue(for: .bpm()))
            )
            .foregroundStyle(pointColor(for: sample, heartRateReport: heartRateReport))
            .symbolSize(5)
          }

          if let zoneRange = selectedHeartRateZoneRange(heartRateReport: heartRateReport) {
            RectangleMark(
              yStart: .value("", zoneRange.lowerBound),
              yEnd: .value("", zoneRange.upperBound)
            )
            .foregroundStyle(heartRateReport.zoneColor(for: selectedZone).opacity(0.3))
          }
        }
        .chartYScale(domain: minHeartRate...maxHeartRate, range: .plotDimension)
        .frame(height: 280)
        .clipped()
      }
      .cardContainer()
      .animation(.easeInOut, value: selectedZone)

      heartRateZonePicker
    }
  }

  func pointColor(
    for sample: HKQuantitySample,
    heartRateReport: WorkoutHeartRateReport
  ) -> Color {
    let zone = heartRateReport.zone(for: sample)
    let color = heartRateReport.zoneColor(for: sample)

    if selectedZone == zone || selectedZone == 0 {
      return color
    }
    return color.opacity(0.3)
  }

  func selectedHeartRateZoneRange(heartRateReport: WorkoutHeartRateReport) -> ClosedRange<Double>? {
    switch selectedZone {
    case 1:
      return heartRateReport.heartRateZones.zone1...heartRateReport.heartRateZones.zone2
    case 2:
      return heartRateReport.heartRateZones.zone2...heartRateReport.heartRateZones.zone3
    case 3:
      return heartRateReport.heartRateZones.zone3...heartRateReport.heartRateZones.zone4
    case 4:
      return heartRateReport.heartRateZones.zone4...heartRateReport.heartRateZones.zone5
    case 5:
      return heartRateReport.heartRateZones.zone5...220
    default:
      return nil
    }
  }

  var heartRateZonePicker: some View {
    Button {
      selectedZone = (selectedZone + 1) % 6
    } label: {
      HStack {
        Text("Zone")

        Spacer()

        if selectedZone == 0 {
          Text("All Zones")
        } else {
          Text("Zone \(selectedZone)")
        }
      }
    }
    .sensoryFeedback(.impact, trigger: selectedZone)
    .buttonStyle(.zone)
    .tint(selectedHeartRateZoneColor)
  }

  var selectedHeartRateZoneColor: Color {
    switch selectedZone {
    case 0: .gray
    case 1: .heartRateZone1
    case 2: .heartRateZone2
    case 3: .heartRateZone3
    case 4: .heartRateZone4
    case 5: .heartRateZone5
    default: .gray
    }
  }

  var minHeartRate: Double {
    (heartRateReport?.minHeartRate ?? 5) - 5
  }

  var maxHeartRate: Double {
    (heartRateReport?.maxHeartRate ?? 195) + 5
  }

  func heartRateReportSection(heartRateReport: WorkoutHeartRateReport) -> some View {
    VStack {
      SectionTitleView("Heart Rate Zone Minutes")
        .padding(.horizontal)

      VStack {
        TargetHeartRateZonesDistributionView(
          distribution: heartRateReport.heartZoneDistribution,
          heartRateZones: heartRateReport.heartRateZones,
          displayGoal: false
        )
      }
      .cardContainer()
    }
  }
}

private extension WorkoutDetailsView {

  @ViewBuilder
  var routeMapView: some View {
    if workoutRoutes.isNotEmpty {

      Map(position: $mapCameraPosition) {
        ForEach(allRouteLocations) { location in
          Marker("", coordinate: location.coordinate)
        }
      }
      .overlay(WorkoutRoutePolyline(routes: workoutRoutes))
      .frame(height: 400)
      .ignoresSafeArea(edges: .bottom)
    }
  }

  var allRouteLocations: [CLLocation] {
    workoutRoutes.flatMap({ $0.locations })
  }

  func updateCamera() {
    mapCameraPosition = .camera(
      MapCamera(
        centerCoordinate: region().center,
        distance: calculateRegionDistance()
      )
    )
  }

  func region() -> MKCoordinateRegion {
    let coordinates = allRouteLocations.map { $0.coordinate }
    guard !coordinates.isEmpty else {
      // San Francisco
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }

    let minLat = latitudes.min()!
    let maxLat = latitudes.max()!
    let minLon = longitudes.min()!
    let maxLon = longitudes.max()!

    let center = CLLocationCoordinate2D(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLon + maxLon) / 2
    )

    let span = MKCoordinateSpan(
      latitudeDelta: maxLat - minLat + 0.01,
      longitudeDelta: maxLon - minLon + 0.01
    )

    return MKCoordinateRegion(center: center, span: span)
  }

  func calculateRegionDistance() -> CLLocationDistance {
    let coordinates = allRouteLocations.map { $0.coordinate }
    guard coordinates.count > 1 else { return 500 }

    let latitudes = coordinates.map { $0.latitude }
    let longitudes = coordinates.map { $0.longitude }

    let maxLat = latitudes.max()!
    let minLat = latitudes.min()!
    let maxLon = longitudes.max()!
    let minLon = longitudes.min()!

    let topLeft = CLLocation(latitude: maxLat, longitude: minLon)
    let bottomRight = CLLocation(latitude: minLat, longitude: maxLon)

    return topLeft.distance(from: bottomRight) * 1.5
  }
}

private extension WorkoutDetailsView {

  func fetchHeartRateReport() async {
    self.heartRateReport = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReport(workout: workout)
  }

  func fetchEffortScore() async {
    self.effortScore = await HealthStoreFetcher.shared.fetchWorkoutEffortScore(for: workout)
  }

  func observeWorkoutRoutes() {
    tasks.removeAll(keepingCapacity: true)

    tasks.append(Task.detached {
      for await routes in await HealthStoreFetcher.shared.fetchWorkoutRoutes(for: workout) {
        await MainActor.run {
          self.workoutRoutes = routes
        }
      }
    })
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutDetailsView(
        workout: HKWorkout(
          activityType: .cycling,
          start: Date().addingTimeInterval(-483856),
          end: Date().addingTimeInterval(-480000),
          duration: 3856,
          totalEnergyBurned: HKQuantity(unit: .largeCalorie(), doubleValue: 642),
          totalDistance: HKQuantity(unit: .meterUnit(with: .kilo), doubleValue: 9.6),
          metadata: [
            HKMetadataKeyElevationAscended: HKQuantity(unit: .meter(), doubleValue: 120),
            HKMetadataKeyElevationDescended: HKQuantity(unit: .meter(), doubleValue: 80)
          ]
        )
      )
    }
  }
}
