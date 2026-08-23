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
    #expect(String.Prompt.webSearch.contains("Never attribute sources"))
    #expect(String.Prompt.webSearch.contains("shown twice"))
  }
}

/// Covers resolving a citation to a paragraph within its block.
///
/// This is what puts a chip beside the claim it supports rather than in a heap at the end of the
/// message, so an off-by-one here attributes a source to the wrong sentence.
@Suite("CitationParagraphResolution")
struct CitationParagraphResolutionTests {

  private func block(_ content: String, start: Int = 0) -> ChatService.PartitionRange {
    ChatService.PartitionRange(
      partitionIndex: 1,
      range: start..<(start + content.utf16.count),
      content: content
    )
  }

  @Test("Each paragraph claims the offsets inside it")
  func offsetsMapToTheirParagraph() {
    let content = "First para.\n\nSecond para here.\n\nThird one."
    let range = block(content)

    #expect(ChatService.paragraphIndex(forUTF16Offset: 2, in: range) == 0)

    let second = content.range(of: "Second")!.lowerBound.utf16Offset(in: content)
    #expect(ChatService.paragraphIndex(forUTF16Offset: second, in: range) == 1)

    let third = content.range(of: "Third")!.lowerBound.utf16Offset(in: content)
    #expect(ChatService.paragraphIndex(forUTF16Offset: third, in: range) == 2)
  }

  @Test("Offsets are relative to the block, not the whole message")
  func offsetsAreBlockRelative() {
    // A block that starts partway through the model's output - anything after a ```json fence -
    // still resolves correctly, because the offset is reduced by the block's own start.
    let content = "Alpha.\n\nBeta."
    let range = block(content, start: 500)

    #expect(ChatService.paragraphIndex(forUTF16Offset: 502, in: range) == 0)

    let beta = 500 + content.range(of: "Beta")!.lowerBound.utf16Offset(in: content)
    #expect(ChatService.paragraphIndex(forUTF16Offset: beta, in: range) == 1)
  }

  @Test("An offset past the end lands on the final paragraph rather than trapping")
  func pastEndClampsToLast() {
    let range = block("One.\n\nTwo.\n\nThree.")
    #expect(ChatService.paragraphIndex(forUTF16Offset: 9_999, in: range) == 2)
  }

  @Test("List items separated by a single newline each get their own index")
  func listItemsAreSeparateUnits() {
    // The regression this changed for. Splitting on blank lines made an eight-item list one unit,
    // so every citation in it stacked at the end instead of sitting beside its own item.
    let content = """
      - The Crazy Canuck — comfort food.
      - Bauer Kitchen — seasonal dishes.
      - Copper Branch — plant-forward bowls.
      """
    let range = block(content)

    for (expected, needle) in [(0, "Crazy"), (1, "Bauer"), (2, "Copper")] {
      let offset = content.range(of: needle)!.lowerBound.utf16Offset(in: content)
      #expect(ChatService.paragraphIndex(forUTF16Offset: offset, in: range) == expected)
    }
  }

  @Test("Blank lines are skipped, so indices match what the client renders")
  func blankLinesDoNotConsumeAnIndex() {
    // The client drops blank lines when it splits. If the server counted them the two would
    // disagree and every chip after the first blank line would attach one claim too late.
    let content = "Intro line.\n\n- First item.\n- Second item."
    let range = block(content)

    let first = content.range(of: "First")!.lowerBound.utf16Offset(in: content)
    let second = content.range(of: "Second")!.lowerBound.utf16Offset(in: content)

    #expect(ChatService.paragraphIndex(forUTF16Offset: 2, in: range) == 0)
    #expect(ChatService.paragraphIndex(forUTF16Offset: first, in: range) == 1)
    #expect(ChatService.paragraphIndex(forUTF16Offset: second, in: range) == 2)
  }

  @Test("A single-paragraph message puts everything on paragraph zero")
  func singleParagraph() {
    let content = "Just the one paragraph, no blank lines."
    let range = block(content)
    #expect(ChatService.paragraphIndex(forUTF16Offset: 0, in: range) == 0)
    #expect(ChatService.paragraphIndex(forUTF16Offset: content.utf16.count - 1, in: range) == 0)
  }
}

/// Covers removing attributions the model writes into its own prose.
///
/// Cases taken from a real reply: the model was told plainly not to attribute sources and did it
/// anyway, so the text has to be cleaned rather than merely discouraged.
@Suite("InlineAttributionStripping")
struct InlineAttributionStrippingTests {

  @Test("A parenthesised markdown link is removed with its parentheses")
  func removesParenthesisedMarkdownLink() {
    let input = "- The Crazy Canuck — classic comfort food and big portions. ([tripadvisor.com](https://www.tripadvisor.com/x))"
    let output = ChatService.strippingInlineAttributions(from: input)

    #expect(output == "- The Crazy Canuck — classic comfort food and big portions.")
  }

  @Test("A parenthesised bare host is removed")
  func removesBareHost() {
    let input = "Bauer Kitchen — seasonal, locally sourced dishes. (restaurantji.com)"
    #expect(ChatService.strippingInlineAttributions(from: input) == "Bauer Kitchen — seasonal, locally sourced dishes.")
  }

  @Test("Several attributions in one parenthesis go together")
  func removesGroupedAttributions() {
    let input = "Great spot. ([tripadvisor.com](https://a.com), [yelp.com](https://b.com))"
    #expect(ChatService.strippingInlineAttributions(from: input) == "Great spot.")
  }

  @Test("Ordinary parentheses survive")
  func leavesProseAlone() {
    // The whole risk of doing this with a regex: over-matching real writing.
    let inputs = [
      "Bauer Kitchen — upscale-casual (solid for dinner).",
      "Wildcraft Grill — creative menu and cocktails (good for a treat night).",
      "You hit 80% of your protein goal (nice work).",
      "Zone 2 training (also called base training) builds endurance.",
    ]
    for input in inputs {
      #expect(ChatService.strippingInlineAttributions(from: input) == input)
    }
  }

  @Test("A whole list is cleaned line by line, and the lines survive")
  func cleansAListWithoutCollapsingIt() {
    let input = """
      - The Crazy Canuck — comfort food. ([tripadvisor.com](https://a.com))
      - Bauer Kitchen — seasonal dishes (solid for dinner). (restaurantji.com)
      - Copper Branch — plant-forward bowls.
      """
    let output = ChatService.strippingInlineAttributions(from: input)

    #expect(output == """
      - The Crazy Canuck — comfort food.
      - Bauer Kitchen — seasonal dishes (solid for dinner).
      - Copper Branch — plant-forward bowls.
      """)
    // Line count has to hold: the citation indices are counted per line on both sides.
    #expect(output.components(separatedBy: "\n").count == 3)
  }
}
