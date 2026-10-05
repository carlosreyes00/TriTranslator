import XCTest
@testable import TriTranslator

final class TranslationIdentityTests: XCTestCase {
    func testVersionOneIdentityRemainsStableAcrossReleases() throws {
        XCTAssertEqual(try record().historyDocumentID(),
                       "v1_71dff53c17cea03deb8a5ced81abb8f4acadee304e999882ef97c1639037512d")
    }

    func testIdentityIgnoresTimestampAndDocumentID() throws {
        let first = record()
        var second = record(createdAt: Date(timeIntervalSince1970: 999))
        second.id = "another-document"
        XCTAssertEqual(try first.historyDocumentID(), try second.historyDocumentID())
    }

    func testIdentityIgnoresTargetOrderWithoutChangingDisplayOrder() throws {
        let first = record()
        let second = record(results: Array(first.translations.reversed()))
        XCTAssertEqual(try first.historyDocumentID(), try second.historyDocumentID())
        XCTAssertEqual(second.translations.first?.targetLanguage, "FR")
    }

    func testIdentityNormalizesUnicodeAndSurroundingWhitespace() throws {
        let first = record(source: "Café", results: [
            .init(targetLanguage: "EN-US", text: "Coffee"),
            .init(targetLanguage: "FR", text: "Café")
        ])
        let second = record(source: " \nCafe\u{301}\t", results: [
            .init(targetLanguage: "EN-US", text: " Coffee\n"),
            .init(targetLanguage: "FR", text: "Cafe\u{301}")
        ])
        XCTAssertEqual(try first.historyDocumentID(), try second.historyDocumentID())
        XCTAssertEqual(second.sourceText, " \nCafe\u{301}\t")
    }

    func testIdentityPreservesMeaningfulSourceDifferences() throws {
        let pairs = [
            ("Hello", "hello"), ("café", "cafe"), ("Hello", "Hello!"),
            ("Pay 10", "Pay 100"), ("I can attend", "I can't attend"),
            ("a b", "a  b"), ("a b", "a\nb")
        ]
        for (first, second) in pairs {
            XCTAssertNotEqual(try record(source: first).historyDocumentID(),
                              try record(source: second).historyDocumentID())
        }
    }

    func testIdentityIncludesSourceLanguageTargetLanguageAndResultText() throws {
        let original = try record().historyDocumentID()
        let variants = [
            record(sourceLanguage: "PT"),
            record(results: [.init(targetLanguage: "EN-GB", text: "Hello"),
                             .init(targetLanguage: "FR", text: "Bonjour")]),
            record(results: [.init(targetLanguage: "EN-US", text: "Hi"),
                             .init(targetLanguage: "FR", text: "Bonjour")]),
            record(results: [.init(targetLanguage: "EN-US", text: "Hello"),
                             .init(targetLanguage: "FR", text: "Salut")]),
            record(results: [.init(targetLanguage: "FR", text: "Hello"),
                             .init(targetLanguage: "EN-US", text: "Bonjour")])
        ]
        for variant in variants {
            XCTAssertNotEqual(original, try variant.historyDocumentID())
        }
    }

    func testRepeatedTargetLanguagesRetainAllResults() throws {
        let results: [Translation.Result] = [
            .init(targetLanguage: "EN-US", text: "Hello"),
            .init(targetLanguage: "EN-US", text: "Hi")
        ]
        XCTAssertEqual(try record(results: results).historyDocumentID(),
                       try record(results: Array(results.reversed())).historyDocumentID())
        XCTAssertNotEqual(try record(results: results).historyDocumentID(),
                          try record(results: [results[0], results[0]]).historyDocumentID())
        XCTAssertNotEqual(try record(results: [results[0]]).historyDocumentID(),
                          try record(results: [results[0], results[0]]).historyDocumentID())
    }

    func testIdentityPreservesFieldBoundaries() throws {
        XCTAssertNotEqual(try record(source: "b|c", sourceLanguage: "a").historyDocumentID(),
                          try record(source: "c", sourceLanguage: "a|b").historyDocumentID())
    }

    private func record(
        source: String = "Hola",
        sourceLanguage: String = "ES",
        results: [Translation.Result] = [
            .init(targetLanguage: "EN-US", text: "Hello"),
            .init(targetLanguage: "FR", text: "Bonjour")
        ],
        createdAt: Date = Date(timeIntervalSince1970: 0)
    ) -> Translation {
        Translation(sourceText: source, sourceLanguage: sourceLanguage,
                    translations: results, createdAt: createdAt)
    }
}
