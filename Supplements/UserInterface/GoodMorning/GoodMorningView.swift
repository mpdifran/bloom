//
//  GoodMorningView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI
import AppUI
import AppFoundations

struct GoodMorningView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var selectedSymptoms = Set<String>()
    @State private var selectedUnusualActivities = Set<String>()
    @State private var selectedBedtimeActivities = Set<String>()

    private let symptoms = [
        "Well Rested",
        "Energized",
        "Groggy",
        "Tired",
        "Headache",
        "Confused"
    ]

    private let unusualActivities = [
        "Drank Alcohol",
        "Ate after 10pm",
        "Smoked Weed"
    ]

    private let bedtimeActivities = [
        "Stretched",
        "Took Melatonin",
        "Meditated"
    ]

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Good Morning \(ProfileViewModel.shared.name)!")
                        .font(.title)
                        .fontDesign(.rounded)
                        .bold()
                        .padding(.top)

                    HStack(alignment: .top) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.gray.lighter(by: 0.5), .yellow)

                        VStack(alignment: .leading) {
                            Text("\(DateFormatter.justDateLong.string(from: .now))")
                                .font(.title3)
                                .bold()
                                .fontDesign(.rounded)

                            Text("Some clouds in the morning")

                            Text("H: 25º L: 16º")
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .bold()

                    LazyVGrid(columns: [.init(.adaptive(minimum: 100))], alignment: .center) {
                        ForEach(symptoms, id: \.self) { symptom in
                            SymptomCell(symptom: symptom, isSelected: selectedSymptoms.contains(symptom))
                                .onTapGesture {
                                    if !selectedSymptoms.contains(symptom) {
                                        feedbackGenerator.impactOccurred()
                                    }
                                    selectedSymptoms.toggleMembership(symptom)
                                }
                        }
                    }
                }
            }
            .tint(.blue)

            Section {
                VStack(alignment: .leading) {
                    Text("Did you do anything unusual last night?")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .bold()

                    LazyVGrid(columns: [.init(.adaptive(minimum: 100))], alignment: .center) {
                        ForEach(unusualActivities, id: \.self) { activity in
                            SymptomCell(symptom: activity, isSelected: selectedUnusualActivities.contains(activity))
                                .onTapGesture {
                                    if !selectedUnusualActivities.contains(activity) {
                                        feedbackGenerator.impactOccurred()
                                    }
                                    selectedUnusualActivities.toggleMembership(activity)
                                }
                        }
                    }
                }
            }
            .tint(.indigo)

            Section {
                VStack(alignment: .leading) {
                    Text("Did you do these before bed?")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .bold()

                    LazyVGrid(columns: [.init(.adaptive(minimum: 100))], alignment: .center) {
                        ForEach(bedtimeActivities, id: \.self) { activity in
                            SymptomCell(symptom: activity, isSelected: selectedBedtimeActivities.contains(activity))
                                .onTapGesture {
                                    if !selectedBedtimeActivities.contains(activity) {
                                        feedbackGenerator.impactOccurred()
                                    }
                                    selectedBedtimeActivities.toggleMembership(activity)
                                }
                        }
                    }
                }
            }
            .tint(.pink)
        }
        .listStyle(.plain)
        .shelf {
            Button(action: {
                dismiss()
            }, label: {
                Label("Save", systemImage: "sun.max.fill")
                    .horizontallyCentered()
            })
            .buttonStyle(.tertiary)
        }
        .presentationCompactAdaptation(.fullScreenCover)
        .tint(.blue)
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

#Preview {
    GoodMorningView()
}
