//
//  DeepLManager.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import Foundation
import SwiftUI

@preconcurrency
class DeepLManager: ObservableObject {
    
    private var components: URLComponents
    private var request: URLRequest
    
    @Published var languages: [DeepLLanguage]
    
    init() {
        components = URLComponents()
        components.scheme = "https"
        components.host = "api-free.deepl.com"
        components.path = "/v2/translate"
        
        guard let url = components.url else {
            fatalError("Unable to form URL from components.")
        }
        
        request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Authorization" : "DeepL-Auth-Key \(Secrets.deeplAPIKey)"
        ]
        
        languages = []
    }
    
    func translate(sourceText: String, sourceLang: String? = nil, targetLang: String) async throws -> Translation? {
        print("starting translation")
        
        let deepLRequestObject = DeepLRequestTranslation(text: [sourceText], source_lang: sourceLang, target_lang: targetLang)
        request.httpBody = try JSONEncoder().encode(deepLRequestObject)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as! HTTPURLResponse).statusCode == 200 else {
            print("HTTP Response: \((response as! HTTPURLResponse).statusCode)")
            return nil
        }
        
        let deeplResponseObject = try JSONDecoder().decode(DeepLResponseTranslation.self, from: data)
        
        print("finishing translation")
        print("\(deeplResponseObject)")
        
        return Translation(requestTranslation: deepLRequestObject, responseTranslation: deeplResponseObject, createdAt: Date.now)
    }
    
//    func getLanguages() async throws {
//        var retriesAttempt = 1
//        
//        print("started retrieving languages from API")
//        
//        let languageUrl = URL(string: "https://api-free.deepl.com/v2/languages?type=target")
//        
//        guard let languageUrl = languageUrl else {
//            print("error creating language URL")
//            return
//        }
//        
//        var languageRequest = URLRequest(url: languageUrl)
//        languageRequest.httpMethod = "GET"
//        languageRequest.allHTTPHeaderFields = [
//            "Authorization" : "DeepL-Auth-Key \(Secrets.deeplAPIKey)",
//            "Content-Type" : "application/json"
//        ]
//        
////        let (data, response) = try await URLSession.shared.data(for: languageRequest)
//        
//        // retrying
//        var (data, response): (Data, URLResponse) = (Data(), URLResponse())
//        while retriesAttempt > 0 && (response as? HTTPURLResponse)?.statusCode != 200 {
//            (data, response) = try await URLSession.shared.data(for: languageRequest)
//            print("status code was \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
//            retriesAttempt -= 1
//        }
//        // retrying
//        
////        guard (response as! HTTPURLResponse).statusCode == 200 else {
////            print("Getting HTTP Response: \((response as! HTTPURLResponse).statusCode)")
////            return nil
////        }
//        
//        var languages: [DeepLLanguage] = .init()
//        do {
//            languages = try JSONDecoder().decode([DeepLLanguage].self, from: data)
//            if languages.count > 0 {
//                DeepLLanguage.saveLanguages(languages: languages)
//            }
//        } catch {
//            print("error from decoding data: ")
//            print(error.localizedDescription)
//        }
//        
//        print("returning languages")
//        DispatchQueue.main.async { [self] in
//            self.languages = languages
//        }
//    }
    
    private enum Secrets {
        static var deeplAPIKey: String {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "DEEPL_API_KEY") as? String else {
                print("deepl api key not found in Secrets file")
                return ""
            }
            
            return key
        }
    }
}
