//
//  ToDoManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-10.
//

import SwiftUI
import HealthKit

final class ToDoManager: ObservableObject {
    static let shared = ToDoManager()

    @Published var relevantToDos = [ToDoModel]()
    @Published var completedToDoKinds = Set<ToDoModel.Kind>()
    @Published var allToDos = [ToDoModel]() {
        didSet {
            if let data = try? JSONEncoder.main.encode(allToDos) {
                UserDefaults.group.set(data, forKey: "ToDoManager.allToDos")
            }
            Task {
                await recalculateToDos()
            }
        }
    }

    @Published var todoCalculationDate: Date? {
        didSet {
            UserDefaults.group.set(todoCalculationDate, forKey: "ToDoManager.todoCalculationDate")
        }
    }

    private init() {
        if let date = UserDefaults.group.object(forKey: "ToDoManager.todoCalculationDate") as? Date {
            self.todoCalculationDate = date
        }
        if let data = UserDefaults.group.data(forKey: "ToDoManager.allToDos") {
            allToDos = (try? JSONDecoder.main.decode([ToDoModel].self, from: data)) ?? []
        }

        populateAllToDos()
        observeToDos()
    }

    private var observationHandlers = [HKObserverQueryHandle]()
}

extension ToDoManager {

    func observeToDos() {
        var newHandlers = [HKObserverQueryHandle]()

        for todo in allToDos {
            let observationHandler = HealthManager.shared.healthStore.observeChanges(
                sampleTypes: todo.kind.sampleTypes,
                startDate: Calendar.current.startOfDay(for: .now)
            ) { [weak self] in

                guard let self else { return }

                if await self.isToDoComplete(todo: todo, dateRange: .today()) == true {
                    await MainActor.run {
                        self.completedToDoKinds.insert(todo.kind)
                    }
                } else {
                    await MainActor.run {
                        self.completedToDoKinds.remove(todo.kind)
                    }
                }
            }
            newHandlers.append(observationHandler)
        }

        self.observationHandlers = newHandlers
    }

    func recalculateToDos() async {
        if let todoCalculationDate {
            if Calendar.current.isDateInToday(todoCalculationDate) {
                return
            }
        }

        var newRelevantToDos = [ToDoModel]()

        for todo in allToDos {
            switch todo.cadence {
            case .daily:
                newRelevantToDos.append(todo)
            case .everySunday:
                if Calendar.current.weekday(for: .now) == .sunday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .sunday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everyMonday:
                if Calendar.current.weekday(for: .now) == .monday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .monday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everyTuesday:
                if Calendar.current.weekday(for: .now) == .tuesday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .tuesday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everyWednesday:
                if Calendar.current.weekday(for: .now) == .wednesday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .wednesday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everyThursday:
                if Calendar.current.weekday(for: .now) == .thursday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .thursday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everyFriday:
                if Calendar.current.weekday(for: .now) == .friday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .friday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everySaturday:
                if Calendar.current.weekday(for: .now) == .saturday {
                    newRelevantToDos.append(todo)
                } else {
                    let dateRange = DateRange.startOfWeekdayToStartOfToday(weekday: .saturday)
                    if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                        newRelevantToDos.append(todo)
                    }
                }
            case .everySevenDays:
                if await !isToDoComplete(todo: todo, dateRange: .trailingDaysFromStartOfToday(6)) {
                    newRelevantToDos.append(todo)
                }
            case .never:
                break
            }
        }

        await MainActor.run {
            self.relevantToDos = newRelevantToDos
        }
    }

    func isToDoComplete(todo: ToDoModel, dateRange: DateRange) async -> Bool {
        for sampleType in todo.kind.sampleTypes {
            let samples = (try? await HealthManager.shared.healthStore.fetchSamples(
                for: sampleType,
                dateRange: dateRange
            )) ?? []

            if samples.isEmpty {
                return false
            }
        }
        return true
    }

    func populateAllToDos() {
        if !allToDos.contains(where: { $0.kind == .logWeight }) {
            allToDos.append(.init(kind: .logWeight, cadence: .never))
        }
        if !allToDos.contains(where: { $0.kind == .logBloodPressure }) {
            allToDos.append(.init(kind: .logBloodPressure, cadence: .never))
        }
    }
}
