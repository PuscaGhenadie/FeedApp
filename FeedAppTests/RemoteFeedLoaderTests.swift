//
//  FeedAppTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 13/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotLoad() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut,
               toCompleteWithError: .connectivity) {
                let error = NSError(domain: "error", code: 100, userInfo: nil)
                client.complete(withError: error)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut,
                   toCompleteWithError: .invalidData, action: {
                    client.complete(withStatusCode: code, idx: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .invalidData) {
            let invalidJSON = Data(bytes: "inv json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSON() {
        let (sut, client) = makeSUT()

        var results = [RemoteFeedLoader.Result]()
        sut.load { result in
            results.append(result)
        }
        
        let emptyListJSON = Data(bytes: "{\"items\": []}".utf8)
        client.complete(withStatusCode: 200, data: emptyListJSON)
        
        XCTAssertEqual(results, [.success([])])
    }

    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, file: StaticString = #file, line: UInt = #line, action: () -> Void) {
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        XCTAssertEqual(capturedResults, [.error(error)], file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {

        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(withError error: Error, idx: Int = 0) {
            messages[idx].completion(.error(error))
        }
        
        func complete(withStatusCode statusCode: Int,
                      data: Data = Data(),
                      idx: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[idx],
                                           statusCode: statusCode,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[idx].completion(.success(data, response))
        }
    }
}
