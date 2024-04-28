//
//  ContentView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI

struct ContentView: View {

    @State private var searchText = ""
    @State private var hasAppeared = false
    @State private var presentedNavigationView: AnyView?

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                if hasAppeared {
                    LazyVGrid(columns: [.init(.adaptive(minimum: 150, maximum: 250))], content: {
                        FocusAreaCell(focusArea: .muscleGainAndExercisePerformance)
                            .roundedBackground()
                            .transition(.scale)
                            .onTapGesture {
                                presentedNavigationView = FocusAreaView(focusArea: .muscleGainAndExercisePerformance).asAny
                            }
                        FocusAreaCell(focusArea: .sleepBetter)
                            .roundedBackground()
                            .transition(.scale)
                            .onTapGesture {
                                presentedNavigationView = FocusAreaView(focusArea: .sleepBetter).asAny
                            }
                        FocusAreaCell(focusArea: .brainHealth)
                            .roundedBackground()
                            .transition(.scale)
                            .onTapGesture {
                                presentedNavigationView = FocusAreaView(focusArea: .brainHealth).asAny
                            }
                        FocusAreaCell(focusArea: .anxiety)
                            .roundedBackground()
                            .transition(.scale)
                            .onTapGesture {
                                presentedNavigationView = FocusAreaView(focusArea: .anxiety).asAny
                            }
                    })
                    .padding(.horizontal)
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .bold()
                        .fontDesign(.rounded)

                    TextField("", text: $searchText, prompt: Text("How can I help you?"))
                        .font(.title3)
                        .fontDesign(.rounded)
                        .bold()
                        .submitLabel(.go)
                }
                .padding(.vertical, 8)
                .roundedBackground()
                .padding()
            }
            .navigationTitle("Vitadex")
            .navigationDestination($presentedNavigationView)
        }
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
    }
}

#Preview {
    ContentView()
}
