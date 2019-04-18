//
//  CodableFeedStoreTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 18/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class CodableFeedStore {
    private struct CacheData: Codable {
        let feed: [CacheFeedImage]
        let date: Date
        
        var feedImages: [LocalFeedImage] {
            return feed.map { $0.localFeedImage }
        }
    }

    private struct CacheFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(feedImage: LocalFeedImage) {
            id = feedImage.id
            description = feedImage.description
            location = feedImage.location
            url = feedImage.url
        }
        
        var localFeedImage: LocalFeedImage {
            return LocalFeedImage(id: id,
                                  description: description,
                                  location: location,
                                  url: url)
        }
    }
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func loadFeed(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL),
        let cacheData = try? JSONDecoder().decode(CacheData.self, from: data) else {
            return completion(.empty)
        }
        
        completion(.found(cacheData.feedImages, cacheData.date))
    }
    
    func cache(feed: [LocalFeedImage], timeStamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let cacheData = CacheData(feed: feed.map { CacheFeedImage(feedImage: $0) }, date: timeStamp)
        let encodedData = try! JSONEncoder().encode(cacheData)
        try! encodedData.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    func test_retrieve_emptyCacheReturnsEmpty() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for completion")
        sut.loadFeed { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for completion")
        sut.loadFeed { firstResult in
            sut.loadFeed { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected empty result, got \(firstResult) and \(secondResult)")
                }
                
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_afterInsertingToEmptyCaches_returnsData() {
        let sut = makeSUT()
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        let exp = expectation(description: "Wait for completion")
        
        sut.cache(feed: insertedFeedImages,
                  timeStamp: insertTimestamp) { insertError in
                    XCTAssertNil(insertError)
                    sut.loadFeed { loadResult in
                        switch loadResult {
                        case let .found(loadFeedImages, loadTimestamp):
                            XCTAssertEqual(insertedFeedImages, loadFeedImages)
                            XCTAssertEqual(insertTimestamp, loadTimestamp)
                        default:
                            XCTFail("Expected get feed images, got \(loadResult) instead")
                        }
                        
                        exp.fulfill()
                    }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> CodableFeedStore {
        return CodableFeedStore(storeURL: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
