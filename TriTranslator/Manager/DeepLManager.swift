//
//  DeepLManager.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import Foundation

enum DeepLManagerError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case requestFailed(URLError.Code)
    case httpError(statusCode: Int)
    case invalidRequestData
    case invalidResponseData
    case emptySourceText
    case emptyTranslations
    case emptyLanguages
    case missingRequiredLanguages

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "The translation service is not configured. Add a DeepL API key and try again."
        case .invalidURL, .invalidResponse:
            return "The translation service returned an unexpected response. Please try again."
        case .requestFailed(let code):
            switch code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "You appear to be offline. Check your connection and try again."
            case .timedOut:
                return "The translation request timed out. Please try again."
            default:
                return "The translation service could not be reached. Please try again."
            }
        case .httpError(let statusCode):
            switch statusCode {
            case 401, 403:
                return "DeepL rejected the app's credentials. Check the API configuration."
            case 429:
                return "Too many translation requests were sent. Wait a moment and try again."
            case 456:
                return "The DeepL usage limit has been reached."
            case 500..<600:
                return "DeepL is temporarily unavailable. Please try again later."
            default:
                return "DeepL could not complete the request (error \(statusCode))."
            }
        case .invalidRequestData:
            return "The translation request could not be prepared. Please try again."
        case .invalidResponseData:
            return "DeepL returned data the app could not read. Please try again."
        case .emptySourceText:
            return "Enter some text to translate."
        case .emptyTranslations:
            return "DeepL returned no translation. Please try again."
        case .emptyLanguages:
            return "DeepL returned no available languages. Please try again."
        case .missingRequiredLanguages:
            return "DeepL did not return the app's default languages. Please try again."
        }
    }
}

final class DeepLManager {
    typealias LanguageCacheLoader = () -> [DeepLLanguage]
    typealias LanguageCacheSaver = ([DeepLLanguage]) -> Void

    private enum Secrets {
        static var deeplAPIKey: String {
            Bundle.main.object(forInfoDictionaryKey: "DEEPL_API_KEY") as? String ?? ""
        }
    }

    private let session: URLSession
    private let apiKey: String
    private let loadCachedLanguages: LanguageCacheLoader
    private let saveCachedLanguages: LanguageCacheSaver

    convenience init() {
        self.init(
            session: .shared,
            apiKey: Secrets.deeplAPIKey,
            loadCachedLanguages: DeepLLanguage.loadLanguagesFromDisk,
            saveCachedLanguages: DeepLLanguage.saveLanguagesToDisk
        )
    }

    init(
        session: URLSession,
        apiKey: String,
        loadCachedLanguages: @escaping LanguageCacheLoader,
        saveCachedLanguages: @escaping LanguageCacheSaver
    ) {
        self.session = session
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.loadCachedLanguages = loadCachedLanguages
        self.saveCachedLanguages = saveCachedLanguages
    }

    func translate(
        sourceText: String,
        sourceLang: String? = nil,
        targetLang: String
    ) async throws -> Translation {
        try Task.checkCancellation()
        try validateAPIKey()

        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepLManagerError.emptySourceText
        }

        let translateURL = try makeURL(path: "/v2/translate")
        var request = URLRequest(url: translateURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = requestHeaders(contentType: "application/json")

        let requestTranslation = DeepLRequestTranslation(
            text: [sourceText],
            source_lang: sourceLang,
            target_lang: targetLang
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestTranslation)
        } catch {
            throw DeepLManagerError.invalidRequestData
        }

        let data = try await responseData(for: request)
        let responseTranslation: DeepLResponseTranslation

        do {
            responseTranslation = try JSONDecoder().decode(DeepLResponseTranslation.self, from: data)
        } catch {
            throw DeepLManagerError.invalidResponseData
        }

        guard !responseTranslation.translations.isEmpty else {
            throw DeepLManagerError.emptyTranslations
        }

        return Translation(
            requestTranslation: requestTranslation,
            responseTranslation: responseTranslation,
            createdAt: .now
        )
    }

    func getLanguages(forceRefresh: Bool = false) async throws -> [DeepLLanguage] {
        try Task.checkCancellation()

        if !forceRefresh {
            let cachedLanguages = loadCachedLanguages()
            if !cachedLanguages.isEmpty {
                return cachedLanguages
            }
        }

        try validateAPIKey()

        let languagesURL = try makeURL(
            path: "/v2/languages",
            queryItems: [URLQueryItem(name: "type", value: "target")]
        )
        var request = URLRequest(url: languagesURL)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = requestHeaders()

        let data = try await responseData(for: request)
        let languages: [DeepLLanguage]

        do {
            languages = try JSONDecoder().decode([DeepLLanguage].self, from: data)
        } catch {
            throw DeepLManagerError.invalidResponseData
        }

        guard !languages.isEmpty else {
            throw DeepLManagerError.emptyLanguages
        }

        saveCachedLanguages(languages)
        return languages
    }

    private func validateAPIKey() throws {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepLManagerError.missingAPIKey
        }
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api-free.deepl.com"
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw DeepLManagerError.invalidURL
        }

        return url
    }

    private func requestHeaders(contentType: String? = nil) -> [String: String] {
        var headers = ["Authorization": "DeepL-Auth-Key \(apiKey)"]
        if let contentType {
            headers["Content-Type"] = contentType
        }
        return headers
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        try Task.checkCancellation()

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if error.code == .cancelled {
                throw CancellationError()
            }
            throw DeepLManagerError.requestFailed(error.code)
        } catch {
            throw DeepLManagerError.requestFailed(.unknown)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepLManagerError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw DeepLManagerError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }
}
