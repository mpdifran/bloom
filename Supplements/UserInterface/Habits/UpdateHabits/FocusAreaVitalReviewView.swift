//
//  FocusAreaVitalReviewView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-04.
//

import SwiftUI
import DataContainer
import AppUI

struct FocusAreaVitalReviewView: View {
    let onContinue: ([VitalModel]) -> Void

    @State private var index = 1
    @State private var vitals = [VitalModel]()
    @State private var presentedSheet: AnyView?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Let's take a look at your Vitals.")
                        .transition(.opacity)
                        .appear(with: 1, currentIndex: index)

                    Text("Here's the Vitals we should focus on this week.")
                        .transition(.opacity)
                        .appear(with: 2, currentIndex: index)
                }
                .onboardingTextStyle()

                Group {
                    ForEachEnumerated(vitals) { (index, vital) in
                        ProposedVitalCell(vital: vital) {
                            presentedSheet = VitalPickerView(
                                excluding: excludingVitalKinds
                            ) { vitalModel in
                                replaceVital(at: index, with: vitalModel)
                            }.asAny
                        }
                        .transition(.scale)
                    }
                }
            }
            .horizontalAlignment(.leading)
            .padding()
        }
        .shelf {
            ProminentButton("Continue") {
                onContinue(vitals)
            }
            .transition(.move(edge: .bottom))
            .appear(with: 3, currentIndex: index)
        }
        .sheet($presentedSheet)
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.selection, trigger: vitals.count)
        .animation(.default, value: index)
        .animation(.bouncy, value: vitals.count)
        .task {
            while index < 2 {
                await advanceIndex()
            }
            await loadVitals()
            await advanceIndex()
        }
    }
}

private extension FocusAreaVitalReviewView {

    var excludingVitalKinds: [VitalModel.Kind] {
        vitals.map { $0.id } + [.bodyComposition, .cycleTracking]
    }

    func replaceVital(at index: Int, with vitalModel: VitalModel) {
        vitals.remove(at: index)
        vitals.insert(vitalModel, at: index)
    }

    func advanceIndex() async {
        await Delay(1700)

        index += 1
    }

    func loadVitals() async {
        let focusVitals = await HabitsFactory.shared.recommendedFocusVitals()
        await Delay(1700)

        for vital in focusVitals {
            await Delay(100)
            self.vitals.append(vital)
        }
    }
}

#Preview {
    FocusAreaVitalReviewView { (_) in

    }
}
