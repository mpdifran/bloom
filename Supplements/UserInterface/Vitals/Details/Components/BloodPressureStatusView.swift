//
//  BloodPressureStatusView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-08.
//

import SwiftUI
import Charts

struct BloodPressureStatusView: View {
    let systolic: Double
    let diastolic: Double
    let lastMonthSystolic: Double?
    let lastMonthDiastolic: Double?

    @State private var selectedCategoryIndex = 0

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading) {
            VitalDetailChartTitleView(
                title: "Blood Pressure",
                value: "\(systolic.format())/\(diastolic.format())"
            )

            Chart {
                ForEach(framesForSelectedCategory, id: \.self) { frame in
                    RectangleMark(
                        xStart: .value("", frame.xStart),
                        xEnd: .value("", frame.xEnd),
                        yStart: .value("", frame.yStart),
                        yEnd: .value("", frame.yEnd)
                    )
                    .foregroundStyle(selectedCategory.color.opacity(0.3))
                }

                if let lastMonthSystolic, let lastMonthDiastolic {
                    LineMark(
                        x: .value("Last Month Diastolic", lastMonthDiastolic),
                        y: .value("Last Month Systolic", lastMonthSystolic)
                    )
                    .foregroundStyle(.gray)
                    LineMark(
                        x: .value("Diastolic", diastolic),
                        y: .value("Systolic", systolic)
                    )
                    .foregroundStyle(.gray)

                    PointMark(
                        x: .value("Last Month Diastolic", lastMonthDiastolic),
                        y: .value("Last Month Systolic", lastMonthSystolic)
                    )
                    .foregroundStyle(.gray)
                }

                PointMark(
                    x: .value("Diastolic", diastolic),
                    y: .value("Systolic", systolic)
                )
                .foregroundStyle(HealthManager.shared.bloodPressureCategory(systolic: systolic, diastolic: diastolic).color)
            }

            .chartXScale(domain: 40...120, range: .plotDimension)
            .chartYScale(domain: 70...200, range: .plotDimension)
            .chartXAxisLabel("Diastolic")
            .chartYAxisLabel("Systolic")
            .chartXAxis {
                AxisMarks(values: .stride(by: 20)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: 20)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartForegroundStyleScale([
                "Last Month": .gray,
                "This Month": HealthManager.shared.bloodPressureCategory(systolic: systolic, diastolic: diastolic).color
            ])
            .aspectRatio(contentMode: .fit)

            categoryPicker
                .padding(.bottom)

            HStack {
                VStack(alignment: .leading) {
                    Text("Details")
                        .font(.headline)
                        .bold()
                    Text(selectedCategory.description)
                }
                Spacer()
            }
            .cardContainer(fill: .background.secondary)
        }
        .padding()
        .onAppear {
            feedbackGenerator.prepare()
            let userCategory = HealthManager.shared.bloodPressureCategory(
                systolic: systolic,
                diastolic: diastolic
            )
            if let index = BloodPressureCategory.allCases.firstIndex(where: { category in
                userCategory == category
            }) {
                selectedCategoryIndex = index
            }
        }
    }
}

private extension BloodPressureStatusView {

    var selectedCategory: BloodPressureCategory {
        BloodPressureCategory.allCases[selectedCategoryIndex]
    }

    var categoryPicker: some View {
        Button {
            selectedCategoryIndex = (selectedCategoryIndex + 1) % BloodPressureCategory.allCases.count
            feedbackGenerator.impactOccurred()
        } label: {
            HStack {
                Text("Category")

                Spacer()

                Text(selectedCategory.name)
            }
            .bold()
            .foregroundStyle(.invertedText)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedCategory.color)
            }
        }
        .buttonStyle(.plain)
    }

    var framesForSelectedCategory: [RectangleFrame] {
        switch selectedCategory {
        case .low: [.init(40, 60, 70, 90)]
        case .normal: [.init(40, 80, 90, 120), .init(60, 80, 70, 90)]
        case .elevated: [.init(40, 90, 120, 140), .init(80, 90, 70, 120)]
        case .hypertensionStage1: [.init(40, 100, 140, 160), .init(90, 100, 70, 140)]
        case .hypertensionStage2: [.init(40, 110, 160, 180), .init(100, 110, 70, 160)]
        case .hypertensiveCrisis: [.init(40, 120, 180, 200), .init(110, 120, 70, 180)]
        }
    }
}

private struct RectangleFrame: Hashable, Identifiable {
    var id: Int { hashValue }

    let xStart: Double
    let xEnd: Double
    let yStart: Double
    let yEnd: Double

    init(
        _ xStart: Double,
        _ xEnd: Double,
        _ yStart: Double,
        _ yEnd: Double
    ) {
        self.xStart = xStart
        self.xEnd = xEnd
        self.yStart = yStart
        self.yEnd = yEnd
    }
}

#Preview {
    ScrollView {
        BloodPressureStatusView(
            systolic: 120,
            diastolic: 80,
            lastMonthSystolic: 129,
            lastMonthDiastolic: 76
        )
    }
}
