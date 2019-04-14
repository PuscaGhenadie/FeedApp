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
               toCompleteWithResult: .error(.connectivity)) {
                let error = NSError(domain: "error", code: 100, userInfo: nil)
                client.complete(withError: error)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut,
                   toCompleteWithResult: .error(.invalidData), action: {
                    let json = makeItemsJSON([])
                    client.complete(withStatusCode: code, data: json, idx: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .error(.invalidData)) {
            let invalidJSON = Data(bytes: "inv json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }

    func test_load_deliversItemsOn200HTTPResponseValidJSON() {
        let (sut, client) = makeSUT()
        
        let (item1, item1JSON) = makeItem(id: UUID(),
                                          imageURL: URL(string: "https://a-url.com")!)

        let (item2, item2JSON) = makeItem(id: UUID(),
                                          description: "a desc",
                                          location: "a loc",
                                          imageURL: URL(string: "https://another-url.com")!)
    
        
        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            client.complete(withStatusCode: 200, data: makeItemsJSON([item1JSON, item2JSON]))
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: Data())
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://given-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject,  file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated", file: file, line: line)
        }
    }
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (item: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id,
                             description: description,
                             location: location,
                             imageURL: imageURL)
        let itemJSON = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
            ].reduce(into: [String: Any](), { (acc, e) in
                if let value = e.value { acc[e.key] = value }
            })
        
        return (item, itemJSON)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        return try! JSONSerialization.data(withJSONObject: ["items": items])
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, file: StaticString = #file, line: UInt = #line, action: () -> Void) {
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(items), .success(expectedItems)):
                XCTAssertEqual(items, expectedItems, file: file, line: line)
            case let (.error(error), .error(expectedError)):
                XCTAssertEqual(error, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(result) insted", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
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
                      data: Data,
                      idx: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[idx],
                                           statusCode: statusCode,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[idx].completion(.success(data, response))
        }
    }
}
