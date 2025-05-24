//
//  StreamJSONBufferTests.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-23.
//

@testable import App
import XCTVapor
import Testing
import BloomModel

@Suite("StreamJSONBufferTests")
struct StreamJSONBufferTests {

  var sut = StreamJSONBuffer()
  let userID = UserIdentifier("1234")

  @Test(arguments: [
    ("123456", 2, [1, 1, 1], ["12", "34", "56"]),
    ("12```json{}```34", 2, [1, 2, 3], ["12", "{}", "34"]),
    ("1234567```json{}```8901234", 7, [1, 2, 3, 3], ["1234567", "{}", "89", "01234"]),
    ("1234567```json{}```89", 7, [1, 2, 3], ["1234567", "{}", "89"]),
    ("1234567```json{}```89", 4, [1, 1, 2, 3, 3], ["1234", "567", "{}", "8", "9"]),
    ("123456```json{}```7890", 2, [1, 1, 1, 2, 3, 3], ["12", "34", "56", "{}", "78", "90"])
  ])
  func checkChunkingIndices(
    inputMessage: String,
    chunkLength: Int,
    expectedIndices: [Int],
    expectedData: [String]
  ) async {
    let length = inputMessage.count

    var filteredData = [StreamJSONBuffer.FilteredData]()
    for offset in stride(from: 0, to: length, by: chunkLength) {
      let end = min(offset + chunkLength, length)
      let startIndex = inputMessage.index(inputMessage.startIndex, offsetBy: offset)
      let endIndex = inputMessage.index(inputMessage.startIndex, offsetBy: end)
      let chunk = String(inputMessage[startIndex..<endIndex])

      let data = await sut.filter(chunk, for: userID)
      filteredData.append(contentsOf: data)
    }

    let indices = filteredData.compactMap {
      switch $0 {
      case .chunk(let index, _):
        return index
      case .json(let index, _):
        return index
      case .collectingJSON, .streamingText:
        return nil
      }
    }
    let data = filteredData.compactMap {
      switch $0 {
      case .chunk(_, let chunk):
        return chunk
      case .json(_, let json):
        return json
      case .collectingJSON, .streamingText:
        return nil
      }
    }

    #expect(indices == expectedIndices)
    #expect(data == expectedData)
  }

  @Test
  func checkCollectingJSONState() async {
    let inputMessage = "1234```json{...}```5678"
    let chunkLength = 2
    let length = inputMessage.count

    var filteredData = [StreamJSONBuffer.FilteredData]()
    for offset in stride(from: 0, to: length, by: chunkLength) {
      let end = min(offset + chunkLength, length)
      let startIndex = inputMessage.index(inputMessage.startIndex, offsetBy: offset)
      let endIndex = inputMessage.index(inputMessage.startIndex, offsetBy: end)
      let chunk = String(inputMessage[startIndex..<endIndex])

      let data = await sut.filter(chunk, for: userID)
      filteredData.append(contentsOf: data)
    }

    let expectedResult: [StreamJSONBuffer.FilteredData] = [
      .chunk(1, "12"),
      .chunk(1, "34"),
      .collectingJSON,
      .json(2, "{...}"),
      .streamingText,
      .chunk(3, "5"),
      .chunk(3, "67"),
      .chunk(3, "8")
    ]

    #expect(filteredData == expectedResult)
  }

  @Test(arguments: [
    ("123456", [1], ["123456"]),
    ("12```json{}```34", [1, 2, 3], ["12", "{}", "34"]),
    ("1234567```json{}```8901234", [1, 2, 3], ["1234567", "{}", "8901234"]),
    ("1234567```json{}```89", [1, 2, 3], ["1234567", "{}", "89"]),
    ("123456```json{}```7890", [1, 2, 3], ["123456", "{}", "7890"])
  ])
  func checkFullMessageParsing(
    inputMessage: String,
    expectedIndices: [Int],
    expectedData: [String]
  ) async throws {
    let partitions = await sut.processCompletedMessage(inputMessage, for: userID)

    let indices = partitions.map {
      switch $0 {
      case .text(let index, _):
        return index
      case .json(let index, _):
        return index
      }
    }
    let data = partitions.map {
      switch $0 {
      case .text(_, let text):
        return text
      case .json(_, let json):
        return json
      }
    }

    #expect(indices == expectedIndices)
    #expect(data == expectedData)
  }
}
