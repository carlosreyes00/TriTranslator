import Foundation

final class URLProtocolStub: URLProtocol {
    typealias RequestHandler = (URLRequest) throws -> (URLResponse, Data)

    private static let lock = NSLock()
    private static var storedRequestHandler: RequestHandler?

    static func setRequestHandler(_ requestHandler: RequestHandler?) {
        lock.lock()
        storedRequestHandler = requestHandler
        lock.unlock()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        let requestHandler = Self.storedRequestHandler
        Self.lock.unlock()

        guard let requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(
                    domain: "URLProtocolStub",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No request handler was installed."]
                )
            )
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
