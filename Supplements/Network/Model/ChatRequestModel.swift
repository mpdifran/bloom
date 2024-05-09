//
//  ChatRequestModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

struct ChatRequestModel: Codable {
    let question: String
//    let userInfo: UserInfoModel?
}

struct UserInfoModel: Codable {
    let bodyWeight: Double?
}
