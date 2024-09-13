//
//  SleepProgramCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-05.
//

import SwiftUI

struct SleepProgramCell: View {

    @Binding var presentedSheet: AnyView?

    @ObservedObject private var sleepProgramCoordinator = SleepProgramCoordinator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)

                Text("Sleep Program")
                    .font(.title2)
                    .bold()

                Spacer()

                if sleepProgramCoordinator.startDate != nil {
                    Text("Active")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .bold()
                }
            }

            Text("Analyze your sleep quality night over night and make incremental improvements to get a better night's rest.")
                .font(.subheadline)

            if let startDate = sleepProgramCoordinator.startDate {
                VStack {
                    TimelineView(.periodic(from: .now, by: 7200)) { context in
                        Text("Started \(startDate, formatter: DateFormatter.justRelativeDateMedium)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .horizontallyCentered()
                    }
                    
                    Button(action: {
                        presentedSheet = SleepProgramConfigurationView().asAny
                    }, label: {
                        Text("Configure Program")
                            .expandHorizontally()
                    })
                    .buttonStyle(.primary)
                }
            } else {
                Button(action: {
                    presentedSheet = SleepProgramSetupView(onSetup: {
                        Delay(300) {
                            presentedSheet = SleepProgramConfigurationView().asAny
                        }
                    }).asAny
                }, label: {
                    Text("Start Program")
                        .expandHorizontally()
                })
                .buttonStyle(.primary)
            }
        }
        .tint(.coreSleep)
    }
}

#Preview {
    List {
        SleepProgramCell(presentedSheet: .constant(nil))
    }
}
