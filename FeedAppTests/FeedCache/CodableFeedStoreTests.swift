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
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let cache = try JSONDecoder().decode(CacheData.self, from: data)
            completion(.found(feed: cache.feedImages, timestamp: cache.date))
        } catch {
            completion(.failure(error))
        }
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
        
        expect(sut, toLoadTwice: .empty)
    }
    
    func test_retrieve_afterInsertingToEmptyCaches_returnsData() {
        let sut = makeSUT()
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        
        insert((insertedFeedImages, insertTimestamp), to: sut)

        expect(sut, toLoad: .found(feed: insertedFeedImages, timestamp: insertTimestamp))
    }
    
    func test_retrieve_deliversFoundOnNoneEmptyCache() {
        let sut = makeSUT()
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        
        insert((insertedFeedImages, insertTimestamp), to: sut)
        expect(sut, toLoadTwice: .found(feed: insertedFeedImages, timestamp: insertTimestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let sut = makeSUT()

        try! "invalidData".write(to: testSpecificStoreURL(), atomically: false, encoding: .utf8)

        expect(sut, toLoad: .failure(anyError()))
    }
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
        let exp = expectation(description: "Wait for completion")
        sut.cache(feed: cache.feed, timeStamp: cache.timestamp) { insertError in
            XCTAssertNil(insertError, "Expected to insert successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: CodableFeedStore,
                        toLoadTwice expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file, line: UInt = #line) {
        expect(sut, toLoad: expectedResult, file: file, line: line)
        expect(sut, toLoad: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: CodableFeedStore,
                        toLoad expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")

        sut.loadFeed { result in
            switch (expectedResult, result) {
            case (.empty, .empty),
                 (.failure, .failure):
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
