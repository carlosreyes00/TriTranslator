import FirebaseFirestore
import XCTest
@testable import TriTranslator

final class SafetyRegressionTests: XCTestCase {
    func testLanguagePairSelectsRequiredDefaults() throws {
        let english = DeepLLanguage(language: "EN-US", name: "English (American)")
        let french = DeepLLanguage(language: "FR", name: "French")

        let pair = try DeepLLanguagePair(
            languages: [french, english],
            firstCode: "EN-US",
            secondCode: "FR"
        )

        XCTAssertEqual(pair.first, english)
        XCTAssertEqual(pair.second, french)
    }

    func testLanguagePairRejectsMissingRequiredDefault() {
        let languages = [DeepLLanguage(language: "EN-US", name: "English (American)")]

        do {
            _ = try DeepLLanguagePair(
                languages: languages,
                firstCode: "EN-US",
                secondCode: "FR"
            )
            XCTFail("Expected the missing-language error, but selection succeeded.")
        } catch let error as DeepLManagerError {
            XCTAssertEqual(error, .missingRequiredLanguages)
        } catch {
            XCTFail("Expected DeepLManagerError, but received \(error).")
        }
    }

    func testHistoryEncodesBothResultsInOneDocument() throws {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let record = Translation(
            sourceText: "Hola",
            sourceLanguage: "ES",
            translations: [
                .init(targetLanguage: "EN-US", text: "Hello"),
                .init(targetLanguage: "FR", text: "Bonjour")
            ],
            createdAt: createdAt
        )

        let document = try Firestore.Encoder().encode(record)

        XCTAssertEqual(Set(document.keys), ["sourceText", "sourceLanguage", "translations", "createdAt"])
        XCTAssertEqual(document["sourceText"] as? String, "Hola")
        XCTAssertEqual(document["sourceLanguage"] as? String, "ES")
        let results = try XCTUnwrap(document["translations"] as? [[String: String]])
        XCTAssertEqual(results, [
            ["targetLanguage": "EN-US", "text": "Hello"],
            ["targetLanguage": "FR", "text": "Bonjour"]
        ])

        let decoded = try Firestore.Decoder().decode(
            Translation.self,
            from: document,
            in: Firestore.firestore().document("users/test-user/translations/test-history")
        )
        XCTAssertEqual(decoded.id, "test-history")
        XCTAssertEqual(decoded.sourceText, record.sourceText)
        XCTAssertEqual(decoded.sourceLanguage, record.sourceLanguage)
        XCTAssertEqual(decoded.translations, record.translations)
        XCTAssertEqual(decoded.createdAt, createdAt)
        XCTAssertTrue(decoded.hasDisplayContent)
    }

    func testHistoryDecodesStoredResultsInOrderEvenWithSameTargetLanguage() throws {
        let document: [String: Any] = [
            "sourceText": "Hola",
            "sourceLanguage": "ES",
            "translations": [
                ["targetLanguage": "EN-US", "text": "Hello"],
                ["targetLanguage": "EN-US", "text": "Hi"]
            ],
            "createdAt": Timestamp(date: Date(timeIntervalSince1970: 1_700_000_000))
        ]

        let record = try Firestore.Decoder().decode(
            Translation.self,
            from: document,
            in: Firestore.firestore().document("users/test-user/translations/test-history")
        )

        XCTAssertEqual(record.translations.map(\.text), ["Hello", "Hi"])
        XCTAssertTrue(record.hasDisplayContent)
    }

    func testIncompleteHistoryRecordsHaveNoDisplayContent() {
        let completeResults: [Translation.Result] = [
            .init(targetLanguage: "EN-US", text: "Hello"),
            .init(targetLanguage: "FR", text: "Bonjour")
        ]
        let records = [
            makeTranslation(sourceText: "", results: completeResults),
            makeTranslation(results: []),
            makeTranslation(results: [completeResults[0]]),
            makeTranslation(results: [completeResults[0], .init(targetLanguage: "FR", text: "")])
        ]

        for record in records {
            XCTAssertFalse(record.hasDisplayContent)
        }
    }

    private func makeTranslation(
        sourceText: String = "Hola",
        results: [Translation.Result]
    ) -> Translation {
        Translation(
            sourceText: sourceText,
            sourceLanguage: "ES",
            translations: results,
            createdAt: .now
        )
    }
}
