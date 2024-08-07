//
//  PreferencesView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-06.
//

import SwiftUI

struct PreferencesView: View {

    @ObservedObject private var healthManager = HealthManager.shared

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some View {
        List {
            appInfoSection
            femaleSection
            healthPermissionsSection
            developerSection
        }
        .safeAreaInset(edge: .top) {
            Rectangle()
                .fill(.thickMaterial)
                .ignoresSafeArea()
                .frame(height: 0)
        }
        .tabItem {
            Label("Preferences", systemImage: "slider.horizontal.below.square.and.square.filled")
        }
    }
}

private extension PreferencesView {

    var appInfoSection: some View {
        Section {
            LabeledContent("App Version", value: appVersion ?? "Unknown")
        } header: {
            VStack {
                Image(.bloomAppIcon)
                    .resizable()
                    .frame(square: 150)
                Text("Bloom")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.text)
            }
            .padding(.bottom)
            .horizontallyCentered()
            .textCase(.none)
        }
    }

    @ViewBuilder
    var femaleSection: some View {
        if healthManager.healthStore.sex() == .female {
            Section("Health Context") {
                Toggle("Is Breastfeeding", isOn: healthManager.$isBreastfeeding)
                Toggle("Is Pregnant", isOn: healthManager.$isPregnant)
            }
        }
    }

    @ViewBuilder
    var healthPermissionsSection: some View {
        if healthManager.authStatus == .shouldRequest {
            Section("HealthKit") {
                Button(action: {
                    Task {
                        await healthManager.requestAccessIfNeeded()
                    }
                }, label: {
                    LabeledContent("HealthKit Permissions") {
                        Image(systemName: "arrow.up.forward.app.fill")
                    }
                })
                .buttonStyle(.plain)
            }
        }
    }

    var developerSection: some View {
        Section("Developer") {
            Toggle("Daniele Mode", isOn: $danieleMode)
        }
    }
}

private extension PreferencesView {

    var appVersion: String? {
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }

        if let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(versionString) (\(buildString))"
        }
        return versionString
    }
}

#Preview {
    TabView {
        PreferencesView()
    }
}
