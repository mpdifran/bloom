//
//  ToDoManager.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-10.
//

import SwiftUI
@preconcurrency import HealthKit
import BloomFoundation
import DataContainer
import Algorithms
import CoreHealth

@MainActor
final class ToDoManager: ObservableObject {
    static let shared = ToDoManager()

    @Published var relevantToDos = [ToDoModel]()
    @Published var completedToDoKinds = Set<ToDoModel.Kind>()
    @Published var userAddableToDos = [ToDoModel]() {
        didSet {
            if let data = try? JSONEncoder.main.encode(userAddableToDos) {
                UserDefaults.group.set(data, forKey: "ToDoManager.allToDos")
            }
            Task {
                await recalculateToDos()
            }
        }
    }
    @Published var systemSuggestedToDos = [ToDoModel]() {
        didSet {
            if let data = try? JSONEncoder.main.encode(systemSuggestedToDos) {
                UserDefaults.group.set(data, forKey: "ToDoManager.systemSuggestedToDos")
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
            userAddableToDos = (try? JSONDecoder.main.decode([ToDoModel].self, from: data)) ?? []
        }
        if let data = UserDefaults.group.data(forKey: "ToDoManager.systemSuggestedToDos") {
            let todos = (try? JSONDecoder.main.decode([ToDoModel].self, from: data)) ?? []
            systemSuggestedToDos = todos.uniqued(on: { $0.kind })
        }

        populateUserAddableToDos()
        observeToDos()
    }

    private var observationHandlers = [HKObserverQueryHandle]()
}

extension ToDoManager {

    func recalculateToDos() async {
        if let todoCalculationDate {
            if Calendar.current.isDateInToday(todoCalculationDate) {
                return
            }
        }

        var newRelevantToDos = [ToDoModel]()

        let allPossibleToDos = systemSuggestedToDos + userAddableToDos

        for todo in allPossibleToDos {
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
            case .everyThreeDays:
                if await !isToDoComplete(todo: todo, dateRange: .trailingDaysFromStartOfToday(3)) {
                    newRelevantToDos.append(todo)
                }
            case .everySevenDays:
                if await !isToDoComplete(todo: todo, dateRange: .trailingDaysFromStartOfToday(7)) {
                    newRelevantToDos.append(todo)
                }
            case .never:
                break
            }
        }

        let newRelevantToDosConstant = newRelevantToDos

        await MainActor.run {
            self.relevantToDos = newRelevantToDosConstant
            self.observeToDos()
        }
    }

    func set(cadence: ToDoModel.Cadence, for kind: ToDoModel.Kind, vitalKind: VitalModel.Kind?) {
        if let index = userAddableToDos.firstIndex(where: { $0.kind == kind }) {
            userAddableToDos[index].cadence = cadence
        } else if let index = systemSuggestedToDos.firstIndex(where: { $0.kind == kind }) {
            systemSuggestedToDos[index].cadence = cadence
        } else {
            // We're just going to assume this is the system adding this because I'm tired.
            let todo = ToDoModel(kind: kind, cadence: cadence, vitalKind: vitalKind)
            systemSuggestedToDos.append(todo)
        }
    }

    func apply(proposedToDos: [ProposedToDo]) {
        // Turn off any existing ones first
        for systemToDo in systemSuggestedToDos {
            set(cadence: .never, for: systemToDo.kind, vitalKind: nil)
        }

        // Set the new system ones.
        for proposedToDo in proposedToDos {
            set(
                cadence: proposedToDo.todoCadence,
                for: proposedToDo.todoKind,
                vitalKind: proposedToDo.vitalKind
            )
        }
    }
}

private extension ToDoManager {

    func observeToDos() {
        var newHandlers = [HKObserverQueryHandle]()

        let allPossibleToDos = systemSuggestedToDos + userAddableToDos

        for todo in allPossibleToDos {
            let observationHandler = HealthManager.shared.healthStore.observeChanges(
                sampleTypes: todo.kind.sampleTypes,
                startDate: Calendar.current.startOfDay(for: .now)
            ) { [weak self] in

                guard let self else { return }

                if await self.isToDoComplete(todo: todo, dateRange: .today()) == true {
                    _ = await MainActor.run {
                        self.completedToDoKinds.insert(todo.kind)
                    }
                } else {
                    _ = await MainActor.run {
                        self.completedToDoKinds.remove(todo.kind)
                    }
                }
            }
            newHandlers.append(observationHandler)
        }

        self.observationHandlers = newHandlers
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

    func populateUserAddableToDos() {
        var todos = [ToDoModel]()
        if let todo = userAddableToDos.first(where: { $0.kind == .logWeight }) {
            todos.append(todo)
        } else {
            todos.append(ToDoModel(kind: .logWeight, cadence: .never, vitalKind: nil))
        }
        if let todo = userAddableToDos.first(where: { $0.kind == .logBloodPressure }) {
            todos.append(todo)
        } else {
            todos.append(ToDoModel(kind: .logBloodPressure, cadence: .never, vitalKind: nil))
        }

        userAddableToDos = todos
    }
}
