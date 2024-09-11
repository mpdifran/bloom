//
//  TodayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-01.
//

import SwiftUI
import AppUI

struct TodayView: View {

    @ObservedObject private var viewModel = TodayViewModel.shared
    @ObservedObject private var goalsViewModel = GoalsViewModel.shared
    @ObservedObject private var reportCoordinator = ReportCoordinator.shared
    @ObservedObject private var toDoManager = ToDoManager.shared

    @EnvironmentObject private var tabController: TabController

    @State private var presentedFullScreen: AnyView?
    @State private var presentedSheet: AnyView?

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some View {
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
                        if reportCoordinator.shouldShowEveningReport() || danieleMode {
                            ReportCell(kind: .evening)
                                .onTapGesture {
                                    presentedFullScreen = EveningReportView().asAny
                                }
                                .padding(.bottom)
                        }
                    }

                    if goalsViewModel.goals.isNotEmpty {
                        Text("Goals")
                            .bold()
                            .padding(.horizontal)
                            .zStackAlignment(.leading)
                        
                        ForEachEnumeratedNoID(goalsViewModel.goals) { (index, goals) in
                            if let goal = goals.first {
                                NavigationLink {
                                    GoalDetailsView(goals: $goalsViewModel.goals[index])
                                } label: {
                                    GoalDailyUpdateCell(goal: goal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if goalsViewModel.habits.isNotEmpty {
                        Text("Habits")
                            .bold()
                            .padding(.horizontal)
                            .zStackAlignment(.leading)
                            .padding(.top)

                        ForEachEnumerated(goalsViewModel.habits) { (index, habit) in
//                            NavigationLink {
//                                Text("TODO")
//                            } label: {
                                HabitDailyUpdateCell(habit: habit)
//                            }
//                            .buttonStyle(.plain)
                        }
                    }

                    if toDoManager.relevantToDos.isNotEmpty {
                        Text("To Do")
                            .bold()
                            .padding(.horizontal)
                            .zStackAlignment(.leading)
                            .padding(.top)

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
            Task {
                await goalsViewModel.checkForUpdateGoals()
            }
            Task {
                await toDoManager.recalculateToDos()
            }
        }
    }
}

#Preview {
    TabView {
        TodayView()
    }
    .environmentObject(TabController())
}
