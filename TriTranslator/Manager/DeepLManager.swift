//
//  DeepLManager.swift
//  TriTranslator
//
//  Created by Carlos Reyes on 7/20/25.
//

import Foundation

class DeepLManager {
    
    private var components: URLComponents
    private var request: URLRequest
    
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
            "Authorization" : "DeepL-Auth-Key \(Secrets.deeplAPIKey)",
            "Content-Type" : "application/json"
        ]
    }
    
    func translate(sourceText: String, targetLang: String) async throws -> Translation? {
        print("starting translation")
        
        let deepLRequestObject = DeepLRequestTranslation(text: [sourceText], target_lang: targetLang)
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
    
    static func getLanguages() {
        // TODO
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
