//
//  LocationManagerViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI
import CoreLocation

@MainActor @Observable
final class LocationManagerViewModel {
    static let shared = LocationManagerViewModel()

    private(set) var currentLocation: CLLocation?

    private init() {
        observeChanges()
    }

    private var tasks = [Task<Void, Never>]()
}

private extension LocationManagerViewModel {

    func observeChanges() {
        tasks.append(Task.detached {
            for await location in await LocationManager.shared.$currentLocation {
                await MainActor.run {
                    self.currentLocation = location
                }
            }
        })
    }
}
