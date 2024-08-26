//
//  PreviewModelContainer.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import SwiftData

extension View {

    @ViewBuilder
    func previewModelContainer(for forTypes: [any PersistentModel.Type]) -> some View {
        Group {
            if let container = container(for: forTypes) {
                self.modelContainer(container)
            } else {
                self
            }
        }
    }

    private func container(for forTypes: [any PersistentModel.Type]) -> ModelContainer? {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let schema = Schema(forTypes)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print(error)
        }
        return nil
    }
}



