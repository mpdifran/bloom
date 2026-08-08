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
  @State private var presentedSheet: AnyView?

  @State private var mapCameraPosition: MapCameraPosition = .camera(
    MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), distance: 1000)
  )

  // Route/altitude/heart-rate data are derived ONCE when the underlying data loads and cached here.
  // They must never be recomputed in `body` — the scroll-driven blur re-evaluates `body` every
  // frame, so per-render route math (flatMap/map/filter over thousands of points) tanks scrolling.
  @State private var routeCoordinates: [CLLocationCoordinate2D] = []
  @State private var speedSegments: [SpeedSegment] = []
  @State private var altitudePoints: [AltitudePoint] = []
  @State private var altitudeRange: ClosedRange<Double> = 0...100
  @State private var elevationLow: Double?
  @State private var elevationHigh: Double?
  @State private var heartRateBars: [HeartRateBar] = []
  @State private var selectedZone = 0

  /// Vertical scroll offset (0 at top, positive scrolling up). Drives the map blur/fade.
  @State private var scrollOffset: CGFloat = 0
  /// When true the map fills the screen and is interactive; the scroll content animates away.
  @State private var isMapFullScreen = false
  @State private var locationName: String?

  var body: some View {
    GeometryReader { proxy in
      let routeInset = proxy.size.height * 0.42

      ZStack(alignment: .top) {
        // Standard background revealed as the map fades out on scroll.
        Rectangle()
          .fill(Color(.secondarySystemBackground))
          .ignoresSafeArea()

        if hasLocation {
          mapBackground(routeInset: routeInset)
          mapGradientOverlay
        } else {
          noLocationHeaderIcon(routeInset: routeInset)
        }

        scrollContent(routeInset: routeInset, screenHeight: proxy.size.height)
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(isMapFullScreen)
    .toolbar {
      if isMapFullScreen {
        ToolbarItem(placement: .topBarLeading) {
          DismissButton(performDismiss: {
            setMapFullScreen(false)
          })
        }
      }
    }
    .sheet($presentedSheet)
    .task {
      async let heartRate: () = fetchHeartRateReport()
      async let effort: () = fetchEffortScore()
      _ = await (heartRate, effort)
    }
    .task {
      for await routes in await HealthStoreFetcher.shared.fetchWorkoutRoutes(for: workout) {
        rebuildRouteData(from: routes)
        updateCamera()
        await fetchLocationName(from: routes)
      }
    }
  }

  var hasLocation: Bool {
    routeCoordinates.isNotEmpty
  }
}

// MARK: - Map background

private extension WorkoutDetailsView {

  @ViewBuilder
  func mapBackground(routeInset: CGFloat) -> some View {
    let progress = blurProgress(routeInset: routeInset)

    Map(position: $mapCameraPosition, interactionModes: isMapFullScreen ? .all : []) {
      if routeCoordinates.count > 1 {
        // Path colored by speed (slow → blue, fast → red).
        ForEach(speedSegments) { segment in
          MapPolyline(coordinates: segment.coordinates)
            .stroke(segment.color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }

        if let start = routeCoordinates.first {
          Annotation("", coordinate: start) {
            routeMarker(symbol: workout.workoutActivityType.systemSymbol)
          }
        }
        if let end = routeCoordinates.last {
          Annotation("", coordinate: end) {
            routeMarker(symbol: .flagCheckered)
          }
        }
      } else if let single = routeCoordinates.first {
        // No path — just mark where the workout took place with the workout icon.
        Annotation("", coordinate: single) {
          routeMarker(symbol: workout.workoutActivityType.systemSymbol)
        }
      }
    }
    // Blur AND fade the map tiles out on scroll (the static gradient overlay is a separate
    // layer, so it does not fade — only the map disappears).
    .blur(radius: isMapFullScreen ? 0 : progress * 30)
    .opacity(isMapFullScreen ? 1 : 1 - progress)
    .ignoresSafeArea()
    // Regular mode: taps are handled by the transparent scroll spacer (to enter full screen);
    // only make the map itself interactive once expanded.
    .allowsHitTesting(isMapFullScreen)
  }

  /// Static gradient over the map: its lower portion is the solid standard background so the
  /// scroll content reads cleanly, while the map (beneath) blurs and fades away on scroll. It is
  /// its own layer so it never fades or blurs with the map.
  @ViewBuilder
  var mapGradientOverlay: some View {
    if !isMapFullScreen {
      LinearGradient(
        stops: [
          Gradient.Stop(color: .clear, location: 0),
          Gradient.Stop(color: .clear, location: 0.4),
          Gradient.Stop(color: Color(.secondarySystemBackground), location: 0.6),
          Gradient.Stop(color: Color(.secondarySystemBackground), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)
    }
  }

  /// 0 at the top, ramping to 1 by the time the header reaches the top of the screen.
  /// Clamped so overscroll (pull-down, negative offset) never inverts the blur.
  func blurProgress(routeInset: CGFloat) -> CGFloat {
    guard routeInset > 0 else { return 0 }
    return min(max(scrollOffset / routeInset, 0), 1)
  }

  /// Start/end route marker: the symbol in a filled circle, wrapped in a translucent glass ring.
  func routeMarker(symbol: SFSymbol) -> some View {
    Image(systemSymbol: symbol)
      .font(.system(size: 10, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 20, height: 20)
      .background(.blue.gradient, in: Circle())
      .padding(4)
      .glassEffect(.clear, in: Circle())
  }
}

// MARK: - Scroll content

private extension WorkoutDetailsView {

  func scrollContent(routeInset: CGFloat, screenHeight: CGFloat) -> some View {
    ScrollView {
      VStack(spacing: 0) {
        // Transparent window onto the map; tapping it expands the map full screen.
        Color.clear
          .frame(height: routeInset)
          .contentShape(Rectangle())
          .onTapGesture {
            if hasLocation { setMapFullScreen(true) }
          }

        VStack(spacing: 20) {
          headerSection
          detailsSection
          effortSection
          altitudeSection

          if let heartRateReport {
            heartRateReportSection(heartRateReport: heartRateReport)
            heartRateChart
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
      }
    }
    .scrollIndicators(.hidden)
    .onScrollGeometryChange(for: CGFloat.self) { geometry in
      geometry.contentOffset.y
    } action: { _, newValue in
      scrollOffset = newValue
    }
    .opacity(isMapFullScreen ? 0 : 1)
    .offset(y: isMapFullScreen ? screenHeight : 0)
  }

  var headerSection: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let locationName {
        HStack(spacing: 4) {
          Image(systemSymbol: .locationFill)
            .font(.caption)
          Text(locationName)
            .font(.subheadline)
            .bold()
        }
        .foregroundStyle(.secondary)
      }

      Text(workout.displayName(hasRoute: hasLocation))
        .font(.largeTitle)
        .bold()
        .foregroundStyle(.text)

      Text(headlineText)
        .font(.title2)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(headlineColor)

      HStack(spacing: 6) {
        Text(workout.startDate, formatter: DateFormatter.justDateMedium)
        Image(systemSymbol: sourceSymbol)
        Text(workout.sourceName)
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, 8)
  }

  /// Icon for the workout's data source. Apple hardware maps to its symbol; third-party sources
  /// (Garmin, Fitbit, WHOOP, …) have no SF Symbol, so they get a generic sensor icon.
  var sourceSymbol: SFSymbol {
    let source = (workout.device?.name ?? workout.sourceName).lowercased()
    if source.contains("watch") {
      return .applewatch
    }
    if source.contains("iphone") || source.contains("phone") {
      return .iphone
    }
    return .dotRadiowavesLeftAndRight
  }
}

// MARK: - Stat / effort sections

private extension WorkoutDetailsView {

  var detailsSection: some View {
    VStack {
      SectionTitleView("Workout Details")
        .padding(.horizontal)

      LazyVGrid(
        columns: [
          GridItem(.flexible(), alignment: .topLeading),
          GridItem(.flexible(), alignment: .topLeading)
        ],
        spacing: 20
      ) {
        if let workoutTime {
          statTile(label: "Workout Time", value: workoutTime, unit: nil, color: .yellow)
        }
        if let averageHeartRate {
          statTile(label: "Avg. Heart Rate", value: averageHeartRate, unit: "BPM", color: .red)
        }
        statTile(label: "Active Calories", value: activeCalories, unit: "CAL", color: .green)
        statTile(label: "Total Calories", value: totalCalories, unit: "CAL", color: .pink)
        if let distance {
          statTile(label: "Distance", value: distance, unit: "KM", color: .blue)
        }
        if let elevation {
          statTile(label: "Elevation", value: elevation, unit: "M", color: .orange)
        }
      }
      .cardContainer()
    }
  }

  func statTile(label: String, value: String, unit: String?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value)
          .font(.title)
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(color)

        if let unit {
          Text(unit)
            .font(.subheadline)
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(color)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  var workoutTime: String? {
    DateFormatter.timeIntervalHourMinuteSecondPadded.string(from: workout.duration)
  }

  var activeCalories: String {
    "\(Int(workout.activeEnergyBurned.doubleValue(for: .largeCalorie()).rounded()))"
  }

  var totalCalories: String {
    "\(Int(workout.totalEnergyBurned.doubleValue(for: .largeCalorie()).rounded()))"
  }

  var averageHeartRate: String? {
    let bpm = workout.averageHeartRate.doubleValue(for: .bpm())
    guard bpm > 0 else { return nil }
    return "\(Int(bpm.rounded()))"
  }

  var distance: String? {
    guard let distance = workout.totalDistanceWalkingRunningCycling else { return nil }
    return String(format: "%.2f", distance.doubleValue(for: .meterUnit(with: .kilo)))
  }

  var elevation: String? {
    guard let elevation = workout.elevationAscended else { return nil }
    return "\(Int(elevation.doubleValue(for: .meter()).rounded()))"
  }

  /// Headline stat under the title: distance for distance-based workouts, otherwise active calories.
  var headlineText: String {
    if let distance = workout.totalDistanceWalkingRunningCycling {
      return distance.displayString(for: .meterUnit(with: .kilo), formatter: .twoDecimalPlaces)
    }
    return workout.activeEnergyBurned.displayString(for: .largeCalorie(), formatter: .noDecimalPlaces)
  }

  var headlineColor: Color {
    workout.totalDistanceWalkingRunningCycling != nil ? .blue : .green
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
}

// MARK: - Heart rate

private extension WorkoutDetailsView {

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

  /// Heart rate bucketed into ~20 time groups; each bar spans the bucket's low→high BPM and is
  /// filled with the heart-rate-zone gradient. Because the gradient stops are computed from
  /// absolute BPM values, the zone colors line up horizontally across every bar.
  var heartRateChart: some View {
    VStack {
      SectionTitleView("Heart Rate")
        .padding(.horizontal)

      Chart {
        ForEach(heartRateBars) { bar in
          BarMark(
            x: .value("Bucket", bar.bucket),
            yStart: .value("Min", bar.minHR),
            yEnd: .value("Max", bar.maxHR),
            width: .ratio(0.7)
          )
          .foregroundStyle(
            .linearGradient(
              Gradient(stops: bar.stops),
              startPoint: .bottom,
              endPoint: .top
            )
          )
          .cornerRadius(4)
        }

        if let range = selectedHeartRateZoneRange {
          RectangleMark(
            yStart: .value("Zone", range.lowerBound),
            yEnd: .value("Zone", range.upperBound)
          )
          .foregroundStyle(selectedHeartRateZoneColor.opacity(0.25))
        }
      }
      .chartYScale(domain: minHeartRate...maxHeartRate)
      .chartXAxis(.hidden)
      .frame(height: 220)
      .cardContainer()
      .animation(.easeInOut, value: selectedZone)

      heartRateZonePicker
    }
  }

  var heartRateZonePicker: some View {
    Button {
      selectedZone = (selectedZone + 1) % 6
    } label: {
      HStack {
        Text("Zone")

        Spacer()

        Text(selectedZone == 0 ? "All Zones" : "Zone \(selectedZone)")
      }
    }
    .sensoryFeedback(.impact, trigger: selectedZone)
    .buttonStyle(.zone)
    .tint(selectedHeartRateZoneColor)
  }

  var selectedHeartRateZoneColor: Color {
    switch selectedZone {
    case 1: .heartRateZone1
    case 2: .heartRateZone2
    case 3: .heartRateZone3
    case 4: .heartRateZone4
    case 5: .heartRateZone5
    default: .gray
    }
  }

  var selectedHeartRateZoneRange: ClosedRange<Double>? {
    guard let zones = heartRateReport?.heartRateZones else { return nil }
    switch selectedZone {
    case 1: return zones.zone1...zones.zone2
    case 2: return zones.zone2...zones.zone3
    case 3: return zones.zone3...zones.zone4
    case 4: return zones.zone4...zones.zone5
    case 5: return zones.zone5...220
    default: return nil
    }
  }

  var minHeartRate: Double {
    (heartRateReport?.minHeartRate ?? 5) - 5
  }

  var maxHeartRate: Double {
    (heartRateReport?.maxHeartRate ?? 195) + 5
  }
}

// MARK: - Elevation

private extension WorkoutDetailsView {

  @ViewBuilder
  var altitudeSection: some View {
    if altitudePoints.isNotEmpty {
      VStack {
        SectionTitleView("Elevation")
          .padding(.horizontal)

        Chart {
          ForEach(altitudePoints) { sample in
            LineMark(
              x: .value("Time", sample.date),
              y: .value("Elevation", sample.altitude)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.orange)
            .lineStyle(StrokeStyle(lineWidth: 3))

            AreaMark(
              x: .value("Time", sample.date),
              y: .value("Elevation", sample.altitude)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
              .linearGradient(
                colors: [.orange.opacity(0.25), .orange.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
              )
            )
          }
        }
        .chartYScale(domain: altitudeRange)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 132)
        .overlay(alignment: .topLeading) {
          if let elevationHigh {
            elevationLabel("\(Int(elevationHigh.rounded())) m")
          }
        }
        .overlay(alignment: .bottomLeading) {
          if let elevationLow {
            elevationLabel("\(Int(elevationLow.rounded())) m")
          }
        }
        .padding(.vertical)
        .cardContainer(includePadding: false)
      }
    }
  }

  func elevationLabel(_ text: String) -> some View {
    Text(text)
      .font(.caption2)
      .bold()
      .fontDesign(.rounded)
      .foregroundStyle(.secondary)
      .padding(8)
  }
}

// MARK: - Models

extension WorkoutDetailsView {

  struct AltitudePoint: Identifiable {
    let id: Int
    let date: Date
    let altitude: Double
  }

  struct HeartRateBar: Identifiable {
    let id: Int
    /// Zero-padded so the categorical x-axis keeps chronological order.
    let bucket: String
    let minHR: Double
    let maxHR: Double
    let stops: [Gradient.Stop]
  }

  struct SpeedSegment: Identifiable {
    let id: Int
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
  }
}

// MARK: - No-location fallback

private extension WorkoutDetailsView {

  /// Fallback background for workouts with no location: the workout icon centered in the top area
  /// over the standard background (e.g. indoor workouts).
  func noLocationHeaderIcon(routeInset: CGFloat) -> some View {
    WorkoutIcon(workoutType: workout.workoutActivityType, scale: .large)
      .frame(maxWidth: .infinity)
      .frame(height: routeInset)
      .frame(maxHeight: .infinity, alignment: .top)
      .opacity(1 - blurProgress(routeInset: routeInset))
  }
}

// MARK: - Camera

private extension WorkoutDetailsView {

  func updateCamera() {
    guard routeCoordinates.isNotEmpty else { return }
    mapCameraPosition = cameraPosition(fullScreen: isMapFullScreen)
  }

  /// Frames the route to fit the visible map area for the given mode.
  /// - Full screen: the route fits the whole screen, centered.
  /// - Regular: the lower half is covered by scroll content, so the route is shifted up and zoomed
  ///   out to sit centered within the visible top area.
  func cameraPosition(fullScreen: Bool) -> MapCameraPosition {
    let routeRegion = region()

    if fullScreen {
      let span = MKCoordinateSpan(
        latitudeDelta: routeRegion.span.latitudeDelta * 1.2,
        longitudeDelta: routeRegion.span.longitudeDelta * 1.2
      )
      return .region(MKCoordinateRegion(center: routeRegion.center, span: span))
    }

    let verticalBias = routeRegion.span.latitudeDelta * 0.55
    let zoomOut = 1.9

    let center = CLLocationCoordinate2D(
      latitude: routeRegion.center.latitude - verticalBias,
      longitude: routeRegion.center.longitude
    )
    let span = MKCoordinateSpan(
      latitudeDelta: routeRegion.span.latitudeDelta * zoomOut,
      longitudeDelta: routeRegion.span.longitudeDelta * zoomOut
    )
    return .region(MKCoordinateRegion(center: center, span: span))
  }

  func setMapFullScreen(_ fullScreen: Bool) {
    withAnimation(.easeInOut) {
      isMapFullScreen = fullScreen
      mapCameraPosition = cameraPosition(fullScreen: fullScreen)
    }
  }

  func region() -> MKCoordinateRegion {
    let coordinates = routeCoordinates
    guard !coordinates.isEmpty else {
      return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      )
    }

    // Single location (no path): a tight fixed span so the point/marker sits prominently.
    if coordinates.count == 1, let point = coordinates.first {
      return MKCoordinateRegion(
        center: point,
        span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
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
}

// MARK: - Data building

private extension WorkoutDetailsView {

  /// Computes and caches all route-derived data once, off the render path.
  func rebuildRouteData(from routes: [WorkoutRoute]) {
    let locations = routes.flatMap { $0.locations }
    routeCoordinates = locations.map { $0.coordinate }
    speedSegments = Self.makeSpeedSegments(from: locations)

    // `verticalAccuracy < 0` means the altitude reading is invalid.
    let valid = locations.filter { $0.verticalAccuracy >= 0 }
    guard valid.isNotEmpty else {
      altitudePoints = []
      altitudeRange = 0...100
      elevationLow = nil
      elevationHigh = nil
      return
    }

    // Downsample so long routes (thousands of points) don't bog down the chart.
    let maxPoints = 300
    let step = max(1, valid.count / maxPoints)
    let points = valid.enumerated().compactMap { index, location in
      index % step == 0
        ? AltitudePoint(id: index, date: location.timestamp, altitude: location.altitude)
        : nil
    }

    altitudePoints = points
    altitudeRange = Self.altitudeRange(for: points)

    let altitudes = valid.map { $0.altitude }
    elevationLow = altitudes.min()
    elevationHigh = altitudes.max()
  }

  /// Downsamples the route into ~80 segments colored by speed (slow → blue, fast → red).
  static func makeSpeedSegments(from locations: [CLLocation]) -> [SpeedSegment] {
    guard locations.count > 1 else { return [] }

    let maxSegments = 500
    let step = max(1, locations.count / maxSegments)
    let sampled = stride(from: 0, to: locations.count, by: step).map { locations[$0] }
    guard sampled.count > 1 else { return [] }

    let movingSpeeds = sampled.map { max($0.speed, 0) }.filter { $0 > 0 }
    let minSpeed = movingSpeeds.min() ?? 0
    let maxSpeed = movingSpeeds.max() ?? 1

    return (0..<(sampled.count - 1)).map { index in
      let start = sampled[index]
      let end = sampled[index + 1]
      let speed = max(end.speed, 0)
      let normalized = maxSpeed > minSpeed ? (speed - minSpeed) / (maxSpeed - minSpeed) : 0.5
      return SpeedSegment(
        id: index,
        coordinates: [start.coordinate, end.coordinate],
        color: speedColor(normalized)
      )
    }
  }

  static func speedColor(_ normalized: Double) -> Color {
    let clamped = min(max(normalized, 0), 1)
    // Slow → red (hue 0.0), mid → orange (hue 0.08), fast → green (hue 0.33).
    let hue: Double = clamped < 0.5
      ? (clamped / 0.5) * 0.08
      : 0.08 + ((clamped - 0.5) / 0.5) * (0.33 - 0.08)
    return Color(hue: hue, saturation: 0.9, brightness: 0.95)
  }

  static func altitudeRange(for points: [AltitudePoint]) -> ClosedRange<Double> {
    let altitudes = points.map { $0.altitude }
    guard let lowest = altitudes.min(), let highest = altitudes.max() else {
      return 0...100
    }
    guard highest > lowest else {
      return (lowest - 10)...(highest + 10)
    }
    let padding = (highest - lowest) * 0.1
    return (lowest - padding)...(highest + padding)
  }

  /// Buckets heart-rate samples into ~20 time groups, each carrying its low/high BPM and a
  /// precomputed zone gradient.
  func makeHeartRateBars(report: WorkoutHeartRateReport) -> [HeartRateBar] {
    let samples = report.heartRateSamples
    guard !samples.isEmpty else { return [] }

    let start = workout.startDate.timeIntervalSince1970
    let end = workout.endDate.timeIntervalSince1970
    let span = max(end - start, 1)
    let bucketCount = 20

    var buckets = Array(repeating: [Double](), count: bucketCount)
    for sample in samples {
      let bpm = sample.quantity.doubleValue(for: .bpm())
      let time = sample.startDate.timeIntervalSince1970
      var index = Int(((time - start) / span) * Double(bucketCount))
      index = min(max(index, 0), bucketCount - 1)
      buckets[index].append(bpm)
    }

    return buckets.enumerated().compactMap { index, values in
      guard let low = values.min(), let high = values.max() else { return nil }
      // Guarantee a visible bar height for buckets where every sample is (near) identical.
      let minHR = high - low < 2 ? low - 1 : low
      let maxHR = high - low < 2 ? high + 1 : high
      return HeartRateBar(
        id: index,
        bucket: String(format: "%02d", index),
        minHR: minHR,
        maxHR: maxHR,
        stops: heartRateZoneStops(minHR: minHR, maxHR: maxHR, report: report)
      )
    }
  }

  /// Gradient stops from `minHR`→`maxHR` colored by heart-rate zone. Anchored on absolute BPM, so a
  /// given BPM is the same color in every bar and the zones line up across the chart. Each zone is a
  /// solid band; adjacent colors blend over `transition` BPM (raise it for taller transitions).
  func heartRateZoneStops(minHR: Double, maxHR: Double, report: WorkoutHeartRateReport) -> [Gradient.Stop] {
    let span = maxHR - minHR
    guard span > 0 else {
      return [Gradient.Stop(color: .gray, location: 0), Gradient.Stop(color: .gray, location: 1)]
    }

    let zones = report.heartRateZones
    let transition = 14.0

    // Zone boundaries with the colors below/above each one (zone 0, below zone1, is grey).
    let boundaries: [(bpm: Double, below: Color, above: Color)] = [
      (zones.zone1, .gray, .heartRateZone1),
      (zones.zone2, .heartRateZone1, .heartRateZone2),
      (zones.zone3, .heartRateZone2, .heartRateZone3),
      (zones.zone4, .heartRateZone3, .heartRateZone4),
      (zones.zone5, .heartRateZone4, .heartRateZone5)
    ]

    var anchors: [(bpm: Double, color: Color)] = [(minHR, .gray)]
    for boundary in boundaries {
      anchors.append((boundary.bpm - transition / 2, boundary.below))
      anchors.append((boundary.bpm + transition / 2, boundary.above))
    }
    anchors.append((maxHR, .heartRateZone5))

    var stops: [Gradient.Stop] = []
    var lastLocation = -1.0
    for anchor in anchors {
      let clampedBPM = min(max(anchor.bpm, minHR), maxHR)
      let location = max((clampedBPM - minHR) / span, lastLocation)
      lastLocation = location
      stops.append(Gradient.Stop(color: anchor.color, location: location))
    }
    return stops
  }
}

// MARK: - Fetching

private extension WorkoutDetailsView {

  func fetchHeartRateReport() async {
    let report = await HealthStoreFetcher.shared.fetchWorkoutHeartRateReport(workout: workout)
    heartRateReport = report
    if let report {
      heartRateBars = makeHeartRateBars(report: report)
    }
  }

  func fetchEffortScore() async {
    self.effortScore = await HealthStoreFetcher.shared.fetchWorkoutEffortScore(for: workout)
  }

  func fetchLocationName(from routes: [WorkoutRoute]) async {
    guard let location = routes.first?.locations.first else { return }

    let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
    guard let placemark = placemarks?.first else { return }

    let name = [placemark.locality, placemark.administrativeArea]
      .compactMap { $0 }
      .joined(separator: " ")

    if name.isNotEmpty {
      locationName = name
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      WorkoutDetailsView(
        workout: HKWorkout(
          activityType: .running,
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
