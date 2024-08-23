//
//  OnboardingHealthKitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI
import HealthKitUI
import Charts

struct OnboardingHealthKitView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var healthPermissionTrigger = false

    @State private var showArea = false
    @State private var dataPoints = [DataPoint]()
    @State private var unplottedDataPoints: [DataPoint] = [
        DataPoint(date: Date(prevDays: 6), value: 80),
        DataPoint(date: Date(prevDays: 5), value: 61),
        DataPoint(date: Date(prevDays: 4), value: 67),
        DataPoint(date: Date(prevDays: 3), value: 60),
        DataPoint(date: Date(prevDays: 2), value: 63),
        DataPoint(date: Date(prevDays: 1), value: 76),
        DataPoint(date: Date(prevDays: 0), value: 77)
    ]

    var body: some View {
        OnboardingCardTemplateView {
            Image(.healthAppIcon)
                .resizable()
                .scaledToFit()
                .frame(square: 100)

            Text("Health App")
                .font(.largeTitle)
                .bold()

            Group {
                Text("Bloom uses data in the Health App to give you recommendations on how to improve your health.")
                Text("Your data is always private and never leaves your device.")
            }
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)
                .multilineTextAlignment(.center)
                .padding(.top)
        } bottom: {
            Chart {
                ForEach(dataPoints) { dataPoint in
                    PointMark(
                        x: .value("", dataPoint.date),
                        y: .value("", dataPoint.value)
                    )
                    .foregroundStyle(.pink)

                    LineMark(
                        x: .value("", dataPoint.date),
                        y: .value("", dataPoint.value)
                    )
                    .foregroundStyle(.pink)

                    if showArea {
                        AreaMark(
                            x: .value("", dataPoint.date),
                            y: .value("", dataPoint.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
            .chartXScale(domain: Date(prevDays: 6)...Date(prevDays: 0), range: .plotDimension)
            .chartYScale(domain: 0...100, range: .plotDimension)
            .padding()
        }
        .animation(.easeInOut, value: dataPoints)
        .animation(.easeInOut, value: showArea)
        .shelf {
            VStack {
                ProminentButton("Continue") {
                    onContinue()
                }
//                Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .font(.caption)
            }
        }
        .onAppear {
            addDataPoint()
        }
    }
}

private extension OnboardingHealthKitView {

    func addDataPoint() {
        guard unplottedDataPoints.isNotEmpty else {
            showArea = true
            return
        }

        let dataPoint = unplottedDataPoints.removeFirst()
        dataPoints.append(dataPoint)

        Delay(300) {
            addDataPoint()
        }
    }
}

private struct DataPoint: Hashable, Identifiable {
    var id: Int { hashValue }

    let date: Date
    let value: Double
}

#Preview {
    OnboardingHealthKitView { }
}
