//
//  AdminUserToken.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-01-22.
//

import Foundation
import Vapor
import Fluent

final class AdminUserToken: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "admin_user_id")
    var user: AdminUser

    init() { }

    init(id: UUID = UUID(),
         value: String,
         userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

extension AdminUserToken: ModelTokenAuthenticatable {
    static let valueKey = \AdminUserToken.$value
    static let userKey = \AdminUserToken.$user

    var isValid: Bool { true }
}
