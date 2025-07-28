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
    
    func translate(sourceText: String, sourceLang: String? = nil, targetLang: String) async throws -> Translation? {
        print("Starting translation")
        
        let translateURL = createURLwith(scheme: "https", host: "api-free.deepl.com", path: "/v2/translate")!
        
        var translateURLrequest = URLRequest(url: translateURL)
        translateURLrequest.httpMethod = "POST"
        translateURLrequest.allHTTPHeaderFields = [
            "Authorization" : "DeepL-Auth-Key \(Secrets.deeplAPIKey)",
            "Content-Type" : "application/json"
        ]
        
        let deepLRequestObject = DeepLRequestTranslation(text: [sourceText], source_lang: sourceLang, target_lang: targetLang)
        translateURLrequest.httpBody = try JSONEncoder().encode(deepLRequestObject)
        
        let (data, response) = try await URLSession.shared.data(for: translateURLrequest)
        
        guard (response as! HTTPURLResponse).statusCode == 200 else {
            print("HTTP Response: \((response as! HTTPURLResponse).statusCode)")
            return nil
        }
        
        let deeplResponseObject = try JSONDecoder().decode(DeepLResponseTranslation.self, from: data)
        
        print("Finishing translation")
        print("\(deeplResponseObject)")
        
        return Translation(requestTranslation: deepLRequestObject, responseTranslation: deeplResponseObject, createdAt: Date.now)
    }
    
    func getLanguages() async throws -> [DeepLLanguage] {
        
        // try to retrieve languages from disk
        var languages = DeepLLanguage.loadLanguagesFromDisk()
        
        if languages.count > 0 {
            return languages
        }
        
        print("Started retrieving languages from DeepL API")
        
        // api-free.deepl.com/v2/languages?type=target
        guard let languagesUrl = createURLwith(scheme: "https", host: "api-free.deepl.com", path: "/v2/languages")?.appending(queryItems: [URLQueryItem(name: "type", value: "target")]) else {
            print("error creating language URL")
            return []
        }
        
        var languagesRequest = URLRequest(url: languagesUrl)
        languagesRequest.httpMethod = "GET"
        languagesRequest.allHTTPHeaderFields = [
            "Authorization" : "DeepL-Auth-Key \(Secrets.deeplAPIKey)",
            "Content-Type" : "application/json"
        ]
                
        let (data, response) = try await URLSession.shared.data(for: languagesRequest)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Error getting Languages from API. Status code was: \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
            return []
        }
        
        do {
            languages = try JSONDecoder().decode([DeepLLanguage].self, from: data)
            if languages.count > 0 {
                DeepLLanguage.saveLanguagesToDisk(languages: languages)
                return languages
            }
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
        }
        
        return []
    }
    
    private func createURLwith(scheme: String, host: String, path: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        
        return components.url
    }
    
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
