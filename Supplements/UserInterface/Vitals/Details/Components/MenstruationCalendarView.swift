//
//  MenstruationCalendarView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-12.
//

import SwiftUI

struct MenstruationCalendarView: View {
    let cycles: [MenstrualCycle]

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
                Spacer()
                Text("\(referenceDate, formatter: DateFormatter.fullMonthAndYear)")
                Spacer()
                Button {
                    referenceDate = Calendar.current.date(byAdding: .month, value: 1, to: referenceDate) ?? .now
                } label: {
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.mutedPink)
                }
            }
            .bold()
            .padding(.horizontal)

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
                    DayCapsule(dayNumber: "", isHighlighted: false)
                        .opacity(0)
                }

                // Actual days of the month
                ForEach(daysInMonth, id: \.self) { date in
                    DayCapsule(
                        dayNumber: "\(Calendar.current.component(.day, from: date))",
                        isHighlighted: isDayHighlighted(date: date)
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

    func isDayHighlighted(date: Date) -> Bool {
        cycles.contains { cycle in
            cycle.samples.contains { sample in
                Calendar.current.isDate(date, inSameDayAs: sample.startDate)
            }
        }
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

struct DayCapsule: View {
    let dayNumber: String
    let isHighlighted: Bool

    var body: some View {
        Capsule()
            .fill(.background.secondary)
            .aspectRatio(0.7, contentMode: .fit)
            .overlay {
                VStack {
                    Circle()
                        .fill(isHighlighted ? AnyShapeStyle(.mutedPink) : AnyShapeStyle(.background.tertiary))
                        .overlay {
                            Text(dayNumber)
                                .font(.subheadline)
                                .foregroundStyle(isHighlighted ? .white : .text)
                                .bold()
                        }
                    Spacer()
                }
                .padding(4)
            }
    }
}

#Preview("DayCapsule") {
    VStack {
        HStack {
            DayCapsule(dayNumber: "1", isHighlighted: true)
            DayCapsule(dayNumber: "2", isHighlighted: false)
            DayCapsule(dayNumber: "3", isHighlighted: true)
            DayCapsule(dayNumber: "4", isHighlighted: false)
            DayCapsule(dayNumber: "5", isHighlighted: true)
            DayCapsule(dayNumber: "6", isHighlighted: false)
            DayCapsule(dayNumber: "7", isHighlighted: true)
        }
        .padding()
        Spacer()
    }
    .background {
        Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
    }
}

#Preview {
    VStack {
        MenstruationCalendarView(cycles: [])
        Spacer()
    }
    .background {
        Rectangle()
            .fill(.background.secondary)
            .ignoresSafeArea()
    }
}
