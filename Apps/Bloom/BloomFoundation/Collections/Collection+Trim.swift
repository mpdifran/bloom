//
//  Collection+Trim.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import Foundation

public extension BidirectionalCollection where Self: RangeReplaceableCollection {
  
  func trim(where elementFilter: (Element) -> Bool) -> Self {
    guard !isEmpty else { return self }
    
    var startIndex = self.startIndex
    var endIndex = self.index(before: self.endIndex)
    
    // Trim elements from the start
    while startIndex < endIndex && elementFilter(self[startIndex]) {
      startIndex = self.index(after: startIndex)
    }
    
    // Trim elements from the end
    while endIndex > startIndex && elementFilter(self[endIndex]) {
      endIndex = self.index(before: endIndex)
    }
    
    return Self(self[startIndex...endIndex])
  }
}
