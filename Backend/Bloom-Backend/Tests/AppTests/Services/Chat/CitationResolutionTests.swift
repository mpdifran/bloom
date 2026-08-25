//
//  CitationResolutionTests.swift
//  Bloom-Backend
//

@testable import App
import XCTVapor
import Testing
import BloomModel

/// Covers mapping a citation's offsets onto the message partition it belongs to.
///
/// The model reports citations as ranges into its whole output, but the text is split on
/// ```` ```json ```` fences before anything is sent - so the offsets have to be resolved against
/// the partitions, and an offset that lands in the wrong block attaches a source to the wrong
/// message.
@Suite("CitationResolution")
struct CitationResolutionTests {

  @Test("A citation lands in the block containing its offset")
  func citationLandsInCorrectBlock() {
    let text = "Creatine is well studied.\n\n```json\n{\"a\":1}\n```\n\nDrink water too."
    let partitions: [StreamJSONBuffer.CompletedPartitions] = [
      .text(1, "Creatine is well studied."),
      .json(2, "{\"a\":1}"),
      .text(3, "Drink water too."),
    ]

    let ranges = ChatService.textPartitionRanges(in: text, partitions: partitions)
    #expect(ranges.count == 2)

    // An offset inside the first sentence belongs to block 1, not to the trailing text.
    #expect(ChatService.partitionIndex(containing: 5, in: ranges) == 1)

    // An offset inside the trailing text belongs to block 3 - the JSON block sits between them,
    // so a naive count would be off by one here.
    let trailingOffset = text.range(of: "Drink water")!.lowerBound.utf16Offset(in: text)
    #expect(ChatService.partitionIndex(containing: trailingOffset, in: ranges) == 3)
  }

  @Test("An offset past the end resolves to nothing rather than trapping")
  func outOfRangeOffsetIsSafe() {
    let text = "Short answer."
    let partitions: [StreamJSONBuffer.CompletedPartitions] = [.text(1, "Short answer.")]
    let ranges = ChatService.textPartitionRanges(in: text, partitions: partitions)

    // A range past the end must not crash, and must not be silently attributed to a real block.
    #expect(ChatService.partitionIndex(containing: 9_999, in: ranges) == nil)
    #expect(ChatService.partitionIndex(containing: -1, in: ranges) == nil)
  }

  @Test("Offsets are UTF-16, so non-ASCII text does not drift")
  func offsetsAreUTF16() {
    // The API reports UTF-16 code units. Counting Characters instead drifts on anything outside
    // the basic plane, and Bud answers in five languages.
    let text = "Café — naïve 🌱 answer here."
    let partitions: [StreamJSONBuffer.CompletedPartitions] = [.text(1, text)]
    let ranges = ChatService.textPartitionRanges(in: text, partitions: partitions)

    let expectedEnd = text.utf16.count
    #expect(ranges.first?.range.upperBound == expectedEnd)
    #expect(ChatService.partitionIndex(containing: expectedEnd - 1, in: ranges) == 1)
  }

  @Test("A repeated paragraph matches its own occurrence, not the first")
  func repeatedTextMatchesInOrder() {
    // The scan uses each match as the floor for the next, so identical blocks don't collapse onto
    // the same range.
    let text = "Same line.\n\n```json\n{}\n```\n\nSame line."
    let partitions: [StreamJSONBuffer.CompletedPartitions] = [
      .text(1, "Same line."),
      .json(2, "{}"),
      .text(3, "Same line."),
    ]

    let ranges = ChatService.textPartitionRanges(in: text, partitions: partitions)

    #expect(ranges.count == 2)
    #expect(ranges[0].range.lowerBound < ranges[1].range.lowerBound)
    #expect(ranges[0].partitionIndex == 1)
    #expect(ranges[1].partitionIndex == 3)
  }
}

/// Covers the deterministic half of the citation filter - the part that runs before any database
/// lookup and catches what a seeded blocklist is worst at.
@Suite("WebDomainDeterministicFilter")
struct WebDomainDeterministicFilterTests {

  @Test("Plain https pages on ordinary hosts pass")
  func ordinaryPagesPass() {
    #expect(!WebDomainService.failsDeterministicChecks(URL(string: "https://nih.gov/study")!))
    #expect(!WebDomainService.failsDeterministicChecks(URL(string: "https://some-restaurant.ca/menu")!))
  }

  @Test(arguments: [
    "http://nih.gov/insecure",           // not https
    "https://example.xxx/page",          // adult TLD
    "https://something.click/spam",      // abuse-heavy TLD
    "https://freepornsite.example/x",    // adult host fragment
    "https://ok.example/a(b)c",          // parentheses break markdown rendering
  ])
  func unacceptableURLsAreRejected(_ raw: String) {
    #expect(WebDomainService.failsDeterministicChecks(URL(string: raw)!))
  }

  @Test("The never-block list survives the heuristics")
  func neverBlockedWins() {
    // reddit.com would otherwise be fine, but the point of the list is that a heuristic can't
    // take out a whole category of ordinary question.
    #expect(!WebDomainService.failsDeterministicChecks(URL(string: "https://reddit.com/r/nutrition")!))
  }

  @Test("Hosts normalize to the key everything is stored under")
  func hostNormalization() {
    #expect(WebDomainService.normalizedHost(from: URL(string: "https://WWW.Example.COM/x")!) == "example.com")
    #expect(WebDomainService.normalizedHost(from: URL(string: "https://sub.example.com/x")!) == "sub.example.com")
  }

  @Test("Display names read like a brand, not a hostname")
  func displayNames() {
    #expect(WebDomainService.displayName(forHost: "tripadvisor.ca") == "Tripadvisor")
    #expect(WebDomainService.displayName(forHost: "bbc.co.uk") == "Bbc")
    #expect(WebDomainService.displayName(forHost: "nih.gov") == "Nih")
  }
}

/// Covers parsing the public hosts-format blocklist used to seed the domain table.
@Suite("WebDomainBlocklistSeeding")
struct WebDomainBlocklistSeedingTests {

  @Test("Hosts-format lines parse, comments and scaffolding are ignored")
  func parsesHostsFormat() {
    let list = """
      # Title: some blocklist
      # comment line

      0.0.0.0 badsite.example
      0.0.0.0 www.another.example
      0.0.0.0 localhost
      0.0.0.0 0.0.0.0
      malformed-line
      """

    let hosts = Set(SeedWebDomainBlocklistCommand.parseHosts(from: list, limit: nil))

    #expect(hosts.contains("badsite.example"))
    // www. is stripped, so the key matches what citation filtering looks up.
    #expect(hosts.contains("another.example"))
    #expect(!hosts.contains("www.another.example"))
    #expect(!hosts.contains("localhost"))
    #expect(!hosts.contains("0.0.0.0"))
    #expect(hosts.count == 2)
  }

  @Test("A list cannot block a domain on the never-block list")
  func neverBlockedSurvivesSeeding() {
    // A bad or over-broad list entry must not be able to take out wikipedia or a reviews site.
    let list = "0.0.0.0 wikipedia.org\n0.0.0.0 reddit.com\n0.0.0.0 fine-to-block.example"
    let hosts = Set(SeedWebDomainBlocklistCommand.parseHosts(from: list, limit: nil))

    #expect(!hosts.contains("wikipedia.org"))
    #expect(!hosts.contains("reddit.com"))
    #expect(hosts.contains("fine-to-block.example"))
  }

  @Test("The limit stops early, for smoke tests against the real list")
  func limitApplies() {
    let list = (1...50).map { "0.0.0.0 site\($0).example" }.joined(separator: "\n")
    #expect(SeedWebDomainBlocklistCommand.parseHosts(from: list, limit: 10).count == 10)
  }
}

/// Covers the prompt describing web search only when the tool is actually attached.
@Suite("WebSearchPromptGating")
struct WebSearchPromptGatingTests {

  @Test("The base prompt says nothing about searching the web")
  func basePromptDoesNotMentionSearch() {
    // It used to. With the tool gated but the prompt unconditional, the assistant was told it
    // could search on every request - including the ones where it had no such tool - so it
    // answered as though it had searched, confidently and with no citations.
    #expect(!String.Prompt.chatAssistant.contains("Searching the web"))
    #expect(!String.Prompt.chatAssistant.contains("search the web"))
  }

  @Test("The web search clause exists separately, to be appended with the tool")
  func searchClauseIsItsOwnConstant() {
    #expect(String.Prompt.webSearch.contains("search the web"))
    // It also has to forbid the model attributing sources itself. Left to its own devices it
    // writes "(example.com)" into the prose, which then appears alongside the chip built from the
    // same citation - the source shown twice, once as text and once as UI.
    // It has to ask for inline citations rather than forbid them: the links the model writes are
    // what the user actually taps, and they are the same links while streaming and once finished -
    // so nothing rearranges itself when the reply lands.
    #expect(String.Prompt.webSearch.contains("Cite what you found inline"))
    #expect(String.Prompt.webSearch.contains("markdown link"))
  }
}

/// Covers the web search clause not undermining the health data tool.
@Suite("WebSearchPromptDoesNotShadowHealthTool")
struct WebSearchPromptHealthToolTests {

  @Test("The clause points at the health tool rather than claiming the data is already held")
  func doesNotClaimToAlreadyHaveHealthData() {
    // The first wording said not to search for the user's health data "which you already have".
    // It is not already held - it arrives by calling the tool - so the model could skip the call
    // and then report it could not read the data at all.
    #expect(!String.Prompt.webSearch.contains("which you already have"))
    #expect(String.Prompt.webSearch.contains(String.Function.queryUserHealthData))
  }

  @Test("The base prompt still describes the health tool independently of search")
  func healthToolSurvivesWithoutSearch() {
    // Whatever the search clause says, querying health data has to work when search is off.
    #expect(String.Prompt.chatAssistant.contains(String.Function.queryUserHealthData))
  }
}

/// Covers turning a classifier answer into a verdict.
///
/// The mapping is deliberately asymmetric, and the asymmetry is the point: blocking a legitimate
/// site is a worse failure than showing an unjudged one, because the seeded list and the
/// deterministic filter already catch the obvious cases without a model's help.
@Suite("WebDomainVerdictMapping")
struct WebDomainVerdictMappingTests {

  private func verdict(
    _ category: WebDomainReputation.Category,
    _ confidence: Double,
    domain: String = "example.com"
  ) -> WebDomainReputation.Verdict {
    WebDomainClassifier.decide(
      WebDomainClassification(
        domain: domain,
        category: category,
        confidence: confidence,
        reason: "test",
        siteName: nil
      ),
      domain: domain
    ).verdict
  }

  @Test("Unambiguous categories block, but only when the model is confident")
  func confidentBadCategoriesBlock() {
    #expect(verdict(.adult, 0.95) == .blocked)
    #expect(verdict(.gambling, 0.85) == .blocked)
    #expect(verdict(.illegal, 0.9) == .blocked)
    #expect(verdict(.malwareOrSpam, 0.8) == .blocked)
  }

  @Test("An unconfident bad guess is allowed rather than parked")
  func unconfidentBadCategoriesAllow() {
    // There is no human backstop, so the alternative to allowing is blocking on a guess. The
    // seeded list and the deterministic filter have already had their say by this point.
    #expect(verdict(.adult, 0.6) == .allowed)
    #expect(verdict(.gambling, 0.79) == .allowed)
  }

  @Test("Editorial quality never blocks, however confident the model is")
  func lowQualityHealthNeverBlocks() {
    // A nano model asked to judge health credibility flags legitimate supplement retailers and
    // mainstream wellness sections.
    #expect(verdict(.lowQualityHealth, 0.99) == .allowed)
    #expect(verdict(.lowQualityHealth, 0.5) == .allowed)
  }

  @Test("Ordinary and unrecognized sites are both allowed")
  func safeAndUnknownAllowed() {
    #expect(verdict(.safe, 0.9) == .allowed)
    // The case that drove this: small businesses the model simply does not recognize. Low
    // confidence must not cost a real site its citation.
    #expect(verdict(.safe, 0.4) == .allowed)
    #expect(verdict(.unknown, 0.9) == .allowed)
  }

  @Test("Nothing the classifier decides can produce a review verdict")
  func neverParksForReview() {
    for category in WebDomainReputation.Category.allCases {
      for confidence in [0.0, 0.4, 0.75, 0.9, 1.0] {
        #expect(verdict(category, confidence) != .needsReview)
      }
    }
  }

  @Test("A never-blocked domain survives any verdict the classifier reaches")
  func neverBlockedCannotBeDemoted() {
    #expect(verdict(.adult, 0.99, domain: "wikipedia.org") == .allowed)
    #expect(verdict(.malwareOrSpam, 0.99, domain: "reddit.com") == .allowed)
  }
}

@Suite("WebSearchUserLocation")
struct WebSearchUserLocationTests {

  @Test("A location with nothing in it is treated as absent")
  func emptyLocationIsEmpty() {
    #expect(SocketMessage.UserLocation().isEmpty)
    // Timezone alone is still worth sending - it points the search at the right part of the world
    // when there is no fix at all.
    #expect(!SocketMessage.UserLocation(timezone: "America/Toronto").isEmpty)
    #expect(!SocketMessage.UserLocation(city: "Kitchener").isEmpty)
  }

  @Test("The wire format carries a city and no way to express anything narrower")
  func encodesOnlyCoarseFields() throws {
    let location = SocketMessage.UserLocation(
      city: "Kitchener",
      region: "Ontario",
      country: "CA",
      timezone: "America/Toronto"
    )

    let data = try JSONEncoder().encode(location)
    let json = try #require(
      try JSONSerialization.jsonObject(with: data) as? [String: Any]
    )

    #expect(Set(json.keys) == ["city", "region", "country", "timezone"])
    #expect(json["city"] as? String == "Kitchener")

    // There is no field for a street, a postal code or a coordinate, so no amount of client change
    // can send one without also changing this type.
    for narrower in ["latitude", "longitude", "street", "thoroughfare", "postalCode", "subLocality"] {
      #expect(json[narrower] == nil)
    }
  }

  @Test("A round trip survives, including the fields a device could not resolve")
  func roundTripsWithMissingFields() throws {
    let location = SocketMessage.UserLocation(city: nil, region: nil, country: "CA", timezone: "Europe/Amsterdam")
    let decoded = try JSONDecoder().decode(
      SocketMessage.UserLocation.self,
      from: try JSONEncoder().encode(location)
    )
    #expect(decoded == location)
  }

  @Test("A request from a client that predates this decodes with no location")
  func legacyRequestHasNoLocation() throws {
    // The field has to keep meaning "don't localize the search" forever, the same as protocolVersion.
    let json = """
      {"text":"hi","imageFileIDs":[],"userInfo":"{}"}
      """
    let request = try JSONDecoder().decode(
      SocketMessage.MessageRequest.self,
      from: try #require(json.data(using: .utf8))
    )
    #expect(request.userLocation == nil)
    #expect(request.protocolVersion == nil)
  }
}
