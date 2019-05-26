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
        
        completion(.found(feed: cacheData.feedImages, timestamp: cacheData.date))
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
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        removeCacheArtifacts()
    }
    
    func test_retrieve_emptyCacheReturnsEmpty() {
        let sut = makeSUT()
        
        expect(sut, toLoad: .empty)
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
        sut.cache(feed: insertedFeedImages, timeStamp: insertTimestamp) { insertError in
            XCTAssertNil(insertError, "Expected to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        expect(sut, toLoad: .found(feed: insertedFeedImages, timestamp: insertTimestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        let exp = expectation(description: "Wait for completion")
        
        sut.cache(feed: insertedFeedImages,
                  timeStamp: insertTimestamp) { insertError in
                    XCTAssertNil(insertError)
                    sut.loadFeed { firstResult in
                        sut.loadFeed { secondResult in
                            switch (firstResult, secondResult) {
                            case let (.found(firstFound), .found(secondFound)):
                                XCTAssertEqual(firstFound.feed, insertedFeedImages)
                                XCTAssertEqual(firstFound.timestamp, insertTimestamp)
                                
                                XCTAssertEqual(secondFound.feed, insertedFeedImages)
                                XCTAssertEqual(secondFound.timestamp, insertTimestamp)
                            default:
                                XCTFail("""
                                           Expected retrieving twice from non empty cache to deliver same
                                           found result with feed \(insertedFeedImages) and timestamp \(insertTimestamp),
                                           got \(firstResult) and \(secondResult) instead
                                    """)
                            }
                            
                            exp.fulfill()
                        }
                    }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: CodableFeedStore,
                        toLoad expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")

        sut.loadFeed { result in
            switch (expectedResult, result) {
            case (.empty, .empty):
                break
            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(expected.feed, retrieved.feed, file: file, line: line)
                XCTAssertEqual(expected.timestamp, retrieved.timestamp, file: file, line: line)
            default:
                XCTFail("Expected to load \(expectedResult), got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func setupEmptyStoreState() {
        removeCacheArtifacts()
    }
    
    private func clearCacheAfterTests() {
        removeCacheArtifacts()
    }
    
    private func removeCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
