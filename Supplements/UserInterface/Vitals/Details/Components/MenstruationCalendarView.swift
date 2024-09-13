//
//  MenstruationCalendarView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import SwiftUI
import Metal

struct MenstruationCalendarView: View {
    let menstruationSummary: MenstrualSummary?

    @State private var referenceDate = Date.now

    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        let daysInMonth = generateDays()
        let firstWeekday = firstWeekdayOfMonth()

        VStack {
            HStack {
                Button {
                    referenceDate = Calendar.current.date(byAdding: .month, value: -1, to: referenceDate) ?? .now
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.mutedPink)
                }
                .frame(square: 44)
                Spacer()
                Text("\(referenceDate, formatter: DateFormatter.fullMonthAndYear)")
                Spacer()
                Button {
                    referenceDate = Calendar.current.date(byAdding: .month, value: 1, to: referenceDate) ?? .now
                } label: {
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.mutedPink)
                }
                .frame(square: 44)
            }
            .bold()

            // Days of the week headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Days of the month grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                // Empty slots for the days before the first day of the month
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    DayCapsule(
                        dayNumber: "",
                        highlightKind: .none,
                        isToday: false
                    )
                    .opacity(0)
                }

                // Actual days of the month
                ForEach(daysInMonth, id: \.self) { date in
                    DayCapsule(
                        dayNumber: "\(Calendar.current.component(.day, from: date))",
                        highlightKind: highlightKind(for: date),
                        isToday: Calendar.current.isDateInToday(date)
                    )
                    .transition(.scale)
                }
            }
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut, value: referenceDate)
    }
}

private extension MenstruationCalendarView {

    var cycles: [MenstrualCycle] {
        menstruationSummary?.menstrualCycles ?? []
    }

    func highlightKind(for date: Date) -> DayCapsule.HighlightKind {
        let isPeriodDate = cycles.contains { cycle in
            cycle.samples.contains { sample in
                Calendar.current.isDate(date, inSameDayAs: sample.startDate)
            }
        }
        if isPeriodDate {
            return .full
        }

        guard let predictedPeriodDate = menstruationSummary?.nextPredictedPeriodDate else { return .none }

        if let difference = Calendar.current.dateComponents([.day], from: date, to: predictedPeriodDate).day {
            if date < predictedPeriodDate, difference <= 3, difference > 0 {
                return .fadedPartial
            }

            let averageMenstruation = menstruationSummary?.averageMenstruationDays ?? 5

            if difference <= 0, difference > -(averageMenstruation - 1) {
                return .partial
            } else if difference <= -(averageMenstruation - 1), difference > -(averageMenstruation + 1) {
                return .fadedPartial
            }
        }

        return isPeriodDate ? .full : .none
    }

    func generateDays() -> [Date] {
        guard
            let startDate = Calendar.current.startOfMonth(for: referenceDate),
            let range = Calendar.current.range(of: .day, in: .month, for: startDate)
        else { return [] }

        return range.compactMap { day -> Date? in
            Calendar.current.startOfDayInMonth(for: referenceDate, day: day)
        }
    }

    func firstWeekdayOfMonth() -> Int {
        guard
            let startDate = Calendar.current.startOfMonth(for: referenceDate)
        else { return 0 }

        return Calendar.current.component(.weekday, from: startDate) - 1
    }
}

extension DayCapsule {
    enum HighlightKind {
        case none
        case full
        case partial
        case fadedPartial
    }
}

struct DayCapsule: View {
    let dayNumber: String
    let highlightKind: HighlightKind
    let isToday: Bool

    var body: some View {
        Capsule()
            .fill(.background.secondary)
            .aspectRatio(0.7, contentMode: .fit)
            .overlay {
                if isToday {
                    Capsule()
                        .stroke(.mutedPink, lineWidth: 2)
                        .aspectRatio(0.7, contentMode: .fit)
                }
            }
            .overlay {
                VStack {
                    Group {
                        switch highlightKind {
                        case .none:
                            Circle()
                                .fill(.background.tertiary)
                        case .full:
                            Circle()
                                .fill(.mutedPink)
                        case .partial:
                            Circle()
                                .fill(ShaderLibrary.Stripes(
                                    .float(2),
                                    .colorArray([
                                        .mutedPink,
                                        .mutedPink.opacity(0.6)
                                    ])
                                ))
                                .rotationEffect(.degrees(-45))
                        case .fadedPartial:
                            Circle()
                                .fill(ShaderLibrary.Stripes(
                                    .float(2),
                                    .colorArray([
                                        .mutedPink.opacity(0.5),
                                        .mutedPink.opacity(0.2)
                                    ])
                                ))
                                .rotationEffect(.degrees(-45))
                        }
                    }
                    .overlay {
                        Text(dayNumber)
                            .font(.subheadline)
                            .foregroundStyle(highlightKind == .none ? .text : .white)
                            .bold()
                    }
                    Spacer()
                }
                .padding(6)
            }
    }
}

#Preview("DayCapsule") {
    VStack {
        HStack {
            DayCapsule(dayNumber: "1", highlightKind: .none, isToday: false)
            DayCapsule(dayNumber: "2", highlightKind: .full, isToday: false)
            DayCapsule(dayNumber: "3", highlightKind: .fadedPartial, isToday: false)
            DayCapsule(dayNumber: "4", highlightKind: .partial, isToday: false)
            DayCapsule(dayNumber: "5", highlightKind: .partial, isToday: false)
            DayCapsule(dayNumber: "6", highlightKind: .fadedPartial, isToday: true)
            DayCapsule(dayNumber: "7", highlightKind: .none, isToday: false)
        }
        .padding()
        Spacer()
    }
}

#Preview {
    VStack {
        MenstruationCalendarView(
            menstruationSummary: .init(
                menstrualCycles: []
            )
        )
        Spacer()
    }
}
