//
//  SocketMessage.Query+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-02.
//

import BloomModel
import BloomFoundation

extension SocketMessage.Query {

  var dateRange: DateRange {
    DateRange(startDate, endDate)
  }
}
