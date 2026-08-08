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

    func testCompleteTranslationProvidesDisplayContent() {
        let translation = makeTranslation(
            requestText: ["Hola"],
            response: DeepLResponseTranslation(
                translations: [
                    .init(text: "Hello", detected_source_language: "ES")
                ]
            )
        )

        XCTAssertEqual(
            translation.displayContent,
            TranslationDisplayContent(
                sourceLanguage: "ES",
                sourceText: "Hola",
                targetLanguage: "EN-US",
                translatedText: "Hello"
            )
        )
    }

    func testIncompleteHistoryRecordsHaveNoDisplayContent() {
        let records = [
            makeTranslation(requestText: [], response: nil),
            makeTranslation(requestText: ["Hola"], response: nil),
            makeTranslation(
                requestText: ["Hola"],
                response: DeepLResponseTranslation(translations: [])
            )
        ]

        for record in records {
            XCTAssertNil(record.displayContent)
        }
    }

    private func makeTranslation(
        requestText: [String],
        response: DeepLResponseTranslation?
    ) -> Translation {
        Translation(
            requestTranslation: DeepLRequestTranslation(
                text: requestText,
                source_lang: nil,
                target_lang: "EN-US"
            ),
            responseTranslation: response,
            createdAt: .now
        )
    }
}
