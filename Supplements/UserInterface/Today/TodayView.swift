//
//  TodayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-01.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer

@MainActor
struct TodayView: View {

    @Query var habits: [Habit]
    @Query var nutritionHabits: [Habit]

    init() {
        let rawCaloriesMetric = TargetMetric.calories.rawValue
        let rawProteinMetric = TargetMetric.proteinIntake.rawValue

        _habits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil &&
                habit.rawTargetMetric != rawProteinMetric &&
                habit.rawTargetMetric != rawCaloriesMetric
            },
            sort: \Habit.startDate,
            order: .reverse
        )
        _nutritionHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil &&
                habit.rawTargetMetric == rawProteinMetric ||
                habit.rawTargetMetric == rawCaloriesMetric
            },
            sort: \Habit.startDate,
            order: .reverse
        )
    }

    @ObservedObject private var habitsViewModel = HabitsViewModel.shared
    private var reportViewModel = ReportCoordinatorViewModel.shared
    @ObservedObject private var toDoManager = ToDoManager.shared

    @Environment(TabController.self) private var tabController: TabController

    @State private var presentedFullScreen: AnyView?
    @State private var presentedSheet: AnyView?

    @AppStorage("TodayView.showWeightWidget") private var showWeightWidget: Bool = true
    @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some View {
        @Bindable var tabController = tabController // Hopefully Apple fixes this in the future.

        NavigationStack {
            ScrollView {
                VStack {
                    TodaysDateView()
                        .padding(.bottom)

                    TimelineView(.everyMinute) { context in
                        if Calendar.current.isMorning(date: .now) || danieleMode {
                            ReportCell(kind: .morning)
                                .transition(.scale)
                                .onTapGesture {
                                    presentedFullScreen = GoodMorningView().asAny
                                }
                        }
                        if reportViewModel.shouldShowEveningReport() || danieleMode {
                            ReportCell(kind: .evening)
                                .transition(.scale)
                                .onTapGesture {
                                    presentedFullScreen = EveningReportView().asAny
                                }
                        }
                        if habitsViewModel.shouldUpdateSuggestedHabits || danieleMode {
                            GoalReviewCell()
                                .transition(.scale)
                                .onTapGesture {
                                    presentedFullScreen = NewUpdateHabitView().asAny
                                }
                        }
                    }

                    if computedShowWeightWidget {
                        NavigationLink {
                            BodyCompositionDetailsView()
                        } label: {
                            BodyWeightTodayWidgetView()
                        }
                        .buttonStyle(.plain)
                    }

                    if showNutritionWidget {
                        SectionTitleView("Nutrition")
                            .padding(.horizontal)

                        NutritionHabitTodayWidgetView()
                    }

                    if habits.isNotEmpty {
                        SectionTitleView("Habits")
                            .padding(.horizontal)

                        ForEach(habits) { habit in
                            NavigationLink {
                                HabitDetailsView(habit: habit)
                            } label: {
                                HabitDailyUpdateCell(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if toDoManager.relevantToDos.isNotEmpty {
                        SectionTitleView("To Do")
                            .padding(.horizontal)

                        ForEach(toDoManager.relevantToDos) { todo in
                            ToDoActionCell(
                                title: todo.kind.name,
                                subtitle: todo.cadence.name,
                                systemImage: todo.kind.systemImage,
                                isComplete: toDoManager.completedToDoKinds.contains(todo.kind),
                                vitalKind: todo.vitalKind
                            )
                            .tint(todo.kind.color)
                            .onTapGesture {
                                presentedSheet = todo.kind.sheetToPresent
                            }
                        }
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Configure", systemImage: "gear") {
                        presentedSheet = TodayConfigureView().asAny
                    }
                }
            }
            .sheet($presentedSheet)
            .fullScreenCover($presentedFullScreen)
            .fullScreenCover(isPresented: $tabController.showMorningReport) {
                GoodMorningView()
            }
            .fullScreenCover(isPresented: $tabController.showEveningReport) {
                EveningReportView()
            }
        }
        .tabItem {
            Label("Today", systemImage: "calendar.badge.checkmark")
        }
        .onAppear {
            habitsViewModel.checkUpdateSuggestedHabits()
            Task {
                await toDoManager.recalculateToDos()
            }
        }
    }
}

private extension TodayView {

    var computedShowWeightWidget: Bool {
        guard showWeightWidget else { return false }

        switch HealthManager.shared.healthGoal {
        case .loseWeight, .gainWeight, .maintainWeight: return true
        default: return false
        }
    }

    var showNutritionWidget: Bool {
        guard showNutritionTodayWidget else { return false }

        return nutritionHabits.isNotEmpty
    }
}

#Preview {
    TabView {
        TodayView()
    }
    .environment(TabController())
}
