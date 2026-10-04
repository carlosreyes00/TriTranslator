import Foundation
import XCTest
@testable import TriTranslator

final class DeepLManagerTests: XCTestCase {
    private var sessions = [URLSession]()

    override func setUp() {
        super.setUp()
        URLProtocolStub.setRequestHandler(nil)
    }

    override func tearDown() {
        URLProtocolStub.setRequestHandler(nil)
        sessions.forEach { $0.invalidateAndCancel() }
        sessions = []
        super.tearDown()
    }

    func testTranslateBuildsRequestAndReturnsTranslation() async throws {
        URLProtocolStub.setRequestHandler { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api-free.deepl.com/v2/translate")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "DeepL-Auth-Key test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try Self.bodyData(for: request)
            let decodedRequest = try JSONDecoder().decode(DeepLRequestTranslation.self, from: body)
            XCTAssertEqual(decodedRequest.text, ["Hello"])
            XCTAssertNil(decodedRequest.source_lang)
            XCTAssertEqual(decodedRequest.target_lang, "FR")

            return (
                try Self.httpResponse(for: request, statusCode: 200),
                Data(#"{"translations":[{"text":"Bonjour","detected_source_language":"EN"}]}"#.utf8)
            )
        }

        let translation = try await makeManager(apiKey: "  test-key\n").translate(
            sourceText: "Hello",
            targetLang: "FR"
        )

        XCTAssertEqual(translation.requestTranslation.text, ["Hello"])
        XCTAssertEqual(translation.responseTranslation.translations.first?.text, "Bonjour")
        XCTAssertEqual(
            translation.responseTranslation.translations.first?.detected_source_language,
            "EN"
        )
    }

    func testTranslateRejectsBlankAPIKeyBeforeRequesting() async {
        let manager = makeManager(apiKey: "   ")

        await assertManagerError(.missingAPIKey) {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
        }
    }

    func testTranslateRejectsWhitespaceOnlySourceText() async {
        let manager = makeManager()

        await assertManagerError(.emptySourceText) {
            _ = try await manager.translate(sourceText: "  \n ", targetLang: "FR")
        }
    }

    func testTranslateMapsTransportFailure() async {
        URLProtocolStub.setRequestHandler { _ in
            throw URLError(.notConnectedToInternet)
        }
        let manager = makeManager()

        await assertManagerError(.requestFailed(.notConnectedToInternet)) {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
        }
    }

    func testTranslatePreservesCancellation() async {
        URLProtocolStub.setRequestHandler { _ in
            throw URLError(.cancelled)
        }
        let manager = makeManager()

        do {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
            XCTFail("Expected cancellation, but the operation succeeded.")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Expected CancellationError, but received \(error).")
        }
    }

    func testTranslateRejectsNonHTTPResponse() async {
        URLProtocolStub.setRequestHandler { request in
            let url = try XCTUnwrap(request.url)
            return (URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), Data())
        }
        let manager = makeManager()

        await assertManagerError(.invalidResponse) {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
        }
    }

    func testTranslateRejectsHTTPError() async {
        URLProtocolStub.setRequestHandler { request in
            (try Self.httpResponse(for: request, statusCode: 429), Data())
        }
        let manager = makeManager()

        await assertManagerError(.httpError(statusCode: 429)) {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
        }
    }

    func testTranslateRejectsMalformedResponse() async {
        URLProtocolStub.setRequestHandler { request in
            (try Self.httpResponse(for: request, statusCode: 200), Data("not-json".utf8))
        }
        let manager = makeManager()

        await assertManagerError(.invalidResponseData) {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
        }
    }

    func testTranslateRejectsEmptyTranslations() async {
        URLProtocolStub.setRequestHandler { request in
            (
                try Self.httpResponse(for: request, statusCode: 200),
                Data(#"{"translations":[]}"#.utf8)
            )
        }
        let manager = makeManager()

        await assertManagerError(.emptyTranslations) {
            _ = try await manager.translate(sourceText: "Hello", targetLang: "FR")
        }
    }

    func testGetLanguagesUsesNonemptyCacheWithoutRequesting() async throws {
        let cachedLanguages = [DeepLLanguage(language: "FR", name: "French")]
        let manager = makeManager(cachedLanguages: cachedLanguages)

        let languages = try await manager.getLanguages()

        XCTAssertEqual(languages, cachedLanguages)
    }

    func testGetLanguagesFetchesAndCachesLanguages() async throws {
        var savedLanguages = [DeepLLanguage]()
        URLProtocolStub.setRequestHandler { request in
            XCTAssertEqual(request.url?.scheme, "https")
            XCTAssertEqual(request.url?.host, "api-free.deepl.com")
            XCTAssertEqual(request.url?.path, "/v2/languages")
            XCTAssertEqual(URLComponents(url: request.url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?.queryItems?.first?.name, "type")
            XCTAssertEqual(URLComponents(url: request.url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "target")
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "DeepL-Auth-Key test-key")

            return (
                try Self.httpResponse(for: request, statusCode: 200),
                Data(#"[{"language":"EN-US","name":"English (American)"},{"language":"FR","name":"French"}]"#.utf8)
            )
        }
        let manager = makeManager { savedLanguages = $0 }

        let languages = try await manager.getLanguages()

        XCTAssertEqual(languages.map(\.language), ["EN-US", "FR"])
        XCTAssertEqual(savedLanguages.map(\.language), ["EN-US", "FR"])
    }

    func testGetLanguagesForceRefreshBypassesCache() async throws {
        URLProtocolStub.setRequestHandler { request in
            (
                try Self.httpResponse(for: request, statusCode: 200),
                Data(#"[{"language":"EN-US","name":"English (American)"}]"#.utf8)
            )
        }
        let cachedLanguages = [DeepLLanguage(language: "FR", name: "French")]
        let manager = makeManager(cachedLanguages: cachedLanguages)

        let languages = try await manager.getLanguages(forceRefresh: true)

        XCTAssertEqual(languages.map(\.language), ["EN-US"])
    }

    func testGetLanguagesRejectsEmptyResponse() async {
        URLProtocolStub.setRequestHandler { request in
            (try Self.httpResponse(for: request, statusCode: 200), Data("[]".utf8))
        }
        let manager = makeManager()

        await assertManagerError(.emptyLanguages) {
            _ = try await manager.getLanguages()
        }
    }

    func testGetLanguagesRejectsMalformedResponse() async {
        URLProtocolStub.setRequestHandler { request in
            (try Self.httpResponse(for: request, statusCode: 200), Data("not-json".utf8))
        }
        let manager = makeManager()

        await assertManagerError(.invalidResponseData) {
            _ = try await manager.getLanguages()
        }
    }

    func testGetLanguagesRejectsHTTPError() async {
        URLProtocolStub.setRequestHandler { request in
            (try Self.httpResponse(for: request, statusCode: 503), Data())
        }
        let manager = makeManager()

        await assertManagerError(.httpError(statusCode: 503)) {
            _ = try await manager.getLanguages()
        }
    }

    private func makeManager(
        apiKey: String = "test-key",
        cachedLanguages: [DeepLLanguage] = [],
        saveCachedLanguages: @escaping ([DeepLLanguage]) -> Void = { _ in }
    ) -> DeepLManager {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        sessions.append(session)

        return DeepLManager(
            session: session,
            apiKey: apiKey,
            loadCachedLanguages: { cachedLanguages },
            saveCachedLanguages: saveCachedLanguages
        )
    }

    private func assertManagerError(
        _ expectedError: DeepLManagerError,
        operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expectedError), but the operation succeeded.", file: file, line: line)
        } catch let error as DeepLManagerError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected \(expectedError), but received \(error).", file: file, line: line)
        }
    }

    private static func httpResponse(
        for request: URLRequest,
        statusCode: Int
    ) throws -> HTTPURLResponse {
        let url = try XCTUnwrap(request.url)
        return try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
        )
    }

    private static func bodyData(for request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        let stream = try XCTUnwrap(request.httpBodyStream)
        stream.open()
        defer { stream.close() }

        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)

        while true {
            let bytesRead = stream.read(&buffer, maxLength: buffer.count)
            if bytesRead < 0 {
                throw stream.streamError ?? URLError(.cannotDecodeContentData)
            }
            if bytesRead == 0 {
                break
            }
            body.append(contentsOf: buffer.prefix(bytesRead))
        }

        return body
    }
}
