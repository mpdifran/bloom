//
//  ProgramsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI
import AppUI

struct ProgramsView: View {

    @State private var presentedSheet: AnyView?

    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .font(.title2)
                            .foregroundStyle(.coreSleep)

                        Text("Sleep Program")
                            .font(.title2)
                            .bold()
                    }

                    Text("Analyze your sleep quality night over night and make incremental improvements to get a better night's rest.")

                    Button(action: {
                        presentedSheet = SleepProgramConfigurationView().asAny
                    }, label: {
                        HStack {
                            Spacer()
                            Text("Start Program")
                            Spacer()
                        }
                    })
                    .buttonStyle(.tertiary)
                    .tint(.coreSleep)
                }
            }
            .navigationTitle("Programs")
            .sheet($presentedSheet)
        }
        .tabItem {
            Label("Programs", systemImage: "list.bullet.clipboard")
        }
    }
}

#Preview {
    TabView {
        ProgramsView()
    }
}
