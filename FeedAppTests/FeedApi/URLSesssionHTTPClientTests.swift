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
    
    struct UnexpectedValuesRepresntation: Error {}
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.error(error))
            } else {
                completion(.error(UnexpectedValuesRepresntation()))
            }
        }.resume()
    }
}

class URLSesssionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGetRequestWithURL() {
        let url = anyURL()
        
        let exp = expectation(description: "Wait for completion")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let error = anyError()
        let receivedError = resulError(forData: nil, response: nil, error: error)
        XCTAssertEqual(receivedError as NSError?, error)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentations() {
        let anyData = Data(bytes: "any data".utf8)
        let nonHTTPURLResponse = URLResponse(url: anyURL(),
                                             mimeType: nil,
                                             expectedContentLength: 0,
                                             textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(),
                                                 statusCode: 1,
                                                 httpVersion: nil,
                                                 headerFields: nil)
        XCTAssertNotNil(resulError(forData: nil, response: nil, error: nil))
        XCTAssertNotNil(resulError(forData: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resulError(forData: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resulError(forData: anyData, response: nil, error: nil))
        XCTAssertNotNil(resulError(forData: anyData, response: nil, error: anyError()))
        XCTAssertNotNil(resulError(forData: nil, response: nonHTTPURLResponse, error: anyError()))
        XCTAssertNotNil(resulError(forData: nil, response: anyHTTPURLResponse, error: anyError()))
        XCTAssertNotNil(resulError(forData: anyData, response: nonHTTPURLResponse, error: anyError()))
        XCTAssertNotNil(resulError(forData: anyData, response: anyHTTPURLResponse, error: anyError()))
        XCTAssertNotNil(resulError(forData: anyData, response: nonHTTPURLResponse, error: nil))
    }

    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resulError(forData data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var capturedError: Error?
        
        sut.get(from: anyURL()) { result in
            switch result {
            case let .error(error):
                capturedError = error
            default:
                XCTFail("Expected failure but got \(result)", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return capturedError
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
    
    private func anyError() -> NSError {
        return NSError(domain: "error", code: 1)
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
    
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            requestObserver?(request)
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
            requestObserver = nil
            stub = nil
        }
    }
    

}
