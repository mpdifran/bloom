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
            let dateRange: DateRange
            switch todo.cadence {
            case .daily:
                dateRange = .trailingDaysFromStartOfToday(1)
            case .weekly:
                dateRange = .trailingDaysFromStartOfToday(7)
            case .never:
                continue
            }

            if await !isToDoComplete(todo: todo, dateRange: dateRange) {
                newRelevantToDos.append(todo)
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
