//
//  PinViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation

final class PinViewModel: ObservableObject {
    static let shared = PinViewModel()

    @Published var pins = [ActivityModel]() {
        didSet {
            do {
                let data = try JSONEncoder.main.encode(pins)
                UserDefaults.standard.setValue(data, forKey: "pins")
            } catch {
                print(error)
            }
        }
    }

    private init() { 
        if let data = UserDefaults.standard.value(forKey: "name") as? Data {
            do {
                let pins = try JSONDecoder.main.decode([ActivityModel].self, from: data)
                self.pins = pins
            } catch {
                print(error)
            }
        }
    }
}
