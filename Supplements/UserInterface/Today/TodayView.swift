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

    @Query var suggestedHabits: [Habit]
    @Query var userHabits: [Habit]

    init() {
        _suggestedHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil && habit.isSuggested
            },
            sort: \Habit.startDate,
            order: .reverse
        )
        _userHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil && !habit.isSuggested
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

    @AppStorage("TodayView.showNutritionTodayWidget") private var showNutritionTodayWidget: Bool = true
    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some View {
        @Bindable var tabController = tabController // Hopefully Apple fixes this in the future.

        NavigationStack {
            ScrollView {
                VStack {
                    TimelineView(.everyMinute) { context in
                        if Calendar.current.isMorning(date: .now) || danieleMode {
                            ReportCell(kind: .morning)
                                .onTapGesture {
                                    presentedFullScreen = GoodMorningView().asAny
                                }
                                .padding(.bottom)
                        }
                        if reportViewModel.shouldShowEveningReport() || danieleMode {
                            ReportCell(kind: .evening)
                                .onTapGesture {
                                    presentedFullScreen = EveningReportView().asAny
                                }
                                .padding(.bottom)
                        }
                        if habitsViewModel.shouldUpdateSuggestedHabits || danieleMode {
                            GoalReviewCell()
                                .onTapGesture {
                                    presentedFullScreen = NewUpdateHabitView().asAny
                                }
                        }
                    }

                    if showNutritionWidget {
                        NutritionHabitTodayWidgetView()
                    }

                    if suggestedHabits.isNotEmpty {
                        SectionTitleView("Focus Areas")
                            .padding(.horizontal)

                        ForEach(suggestedHabits) { habit in
                            NavigationLink {
                                HabitDetailsView(habit: habit)
                            } label: {
                                HabitDailyUpdateCell(habit: habit)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if userHabits.isNotEmpty {
                        SectionTitleView("Habits")
                            .padding(.horizontal)

                        ForEach(userHabits) { habit in
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
                                isComplete: toDoManager.completedToDoKinds.contains(todo.kind)
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
            .gradientRootBackground()
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

    var showNutritionWidget: Bool {
        guard showNutritionTodayWidget else { return false }

        let allHabits = userHabits + suggestedHabits
        return allHabits.contains(where: {
            $0.targetMetric == .calories || $0.targetMetric == .proteinIntake
        })
    }
}

#Preview {
    TabView {
        TodayView()
    }
    .environment(TabController())
}
