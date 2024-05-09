//
//  ChatMessage.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

struct ChatMessage: Identifiable, Hashable, Equatable {
    let id = UUID().uuidString
    let message: String?
    let supplementReccomendation: [SupplementReccomendationModel]
    let isCurrentUser: Bool
}
