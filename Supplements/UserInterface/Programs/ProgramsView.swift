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
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                sleepProgramSection
            }
            .navigationTitle("Programs")
            .sheet($presentedSheet)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
                .bold()
            }
        }
        .tabItem {
            Label("Programs", systemImage: "list.bullet.clipboard")
        }
    }
}

private extension ProgramsView {

    var sleepProgramSection: some View {
        Section {
            SleepProgramCell(presentedSheet: $presentedSheet)
        }
    }
}

#Preview {
    TabView {
        ProgramsView()
    }
}
