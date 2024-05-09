//
//  ChatMessage.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let message: String
    let isCurrentUser: Bool
}
