//
//  URLSesssionHTTPClient.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 14/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        let url = URL(string: "https://b-url.com")!
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.error(error))
            }
        }.resume()
    }
}

class URLSesssionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: "error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let sut = URLSessionHTTPClient()
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .error(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error \(error) but got \(result)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }

    // MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
    
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
    }
    

}
