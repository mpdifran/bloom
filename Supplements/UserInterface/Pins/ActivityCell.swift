//
//  ActivityCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI

struct ActivityCell: View {
    let activityModel: ActivityModel

    @ObservedObject private var pinViewModel = PinViewModel.shared

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                HStack {
                    if let symbolName = activityModel.sfSymbolName {
                        Image(systemName: symbolName)
                            .font(.title)
                    }

                    VStack(alignment: .leading) {
                        Text(activityModel.activityName)
                            .bold()

                        Text("\(activityModel.distanceToUserInMeters / 1000, specifier: "%.1f") km away")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(activityModel.reasonForActivity)
                    .font(.subheadline)

                Link(destination: activityModel.urlToBookActivity, label: {
                    Label("Open in Safari", systemImage: "arrow.up.forward.app.fill")
                        .foregroundStyle(.white)
                        .bold()
                })
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            Button(action: {
                if pinViewModel.pins.contains(activityModel) {
                    pinViewModel.pins.removeAll(where: { $0 == activityModel})
                } else {
                    pinViewModel.pins.insert(activityModel, at: 0)
                }
                feedbackGenerator.impactOccurred()
            }, label: {
                Image(systemName: pinViewModel.pins.contains(activityModel) ? "pin.fill" : "pin")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .contentTransition(.symbolEffect)
            })
            .buttonStyle(.plain)
        }
        .animation(.bouncy, value: pinViewModel.pins.contains(activityModel))
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

#Preview {
    List {
        ActivityCell(
            activityModel: .init(
                activityName: "Waterloo Tennis Club",
                reasonForActivity: "User likes tennis.",
                sfSymbolName: "figure.tennis",
                urlToBookActivity: URL(string: "https://www.clubinterconnect.com/waterlootennis/")!,
                distanceToUserInMeters: 2300
            )
        )
    }
}
