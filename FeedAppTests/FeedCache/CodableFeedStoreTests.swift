//
//  CodableFeedStoreTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 18/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

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
        let storeUrl = testSpecificStoreURL()
        let sut = makeSUT(url: storeUrl)

        try! "invalidData".write(to: storeUrl, atomically: false, encoding: .utf8)

        expect(sut, toLoad: .failure(anyError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnError() {
        let storeUrl = testSpecificStoreURL()
        let sut = makeSUT(url: storeUrl)
        
        try! "invalidData".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        expect(sut, toLoadTwice: .failure(anyError()))
    }

    func test_insert_overridesPreviouslyInsertedCache() {
        let sut = makeSUT()
        let firstInsertFeed = anyItems().localModels
        let firstInsertData = Date()
        
        insert((firstInsertFeed, firstInsertData), to: sut)
        
        let latesInsertFeed = anyItems().localModels
        let latesInsertDate = Date()
        
        insert((latesInsertFeed, latesInsertDate), to: sut)
        
        expect(sut, toLoad: .found(feed: latesInsertFeed, timestamp: latesInsertDate))
    }
    
    func test_insert_deliversErrorOnInvalidStoreUrl() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(url: invalidStoreURL)
        
        let insertError = insert((anyItems().localModels, Date()), to: sut)
        
        XCTAssertNotNil(insertError, "Expected insert error for inserting at invalid url")
    }

    func test_delete_emptyCacheStaysEmptyAndDoesNotFail() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected deletion to not fail")
        expect(sut, toLoad: .empty)
    }
    
    func test_delete_cacheWithDataLeavesCacheEmpty() {
        let sut = makeSUT()
        sut.cache(feed: anyItems().localModels, timeStamp: Date()) { error in
            XCTAssertNil(error, "Expected cache to not fail")
        }
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected deletion to not fail")
        expect(sut, toLoad: .empty)
    }
    
    func test_delete_returnsErrorOnDeleteOfNoPermissionURL() {
        let noPermissionsURL = cachesDirectory()
        let sut = makeSUT(url: noPermissionsURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected deletion fail")
    }

    func test_sideEffects_runSerially() {
        let sut = makeSUT()
        
        var expectations = [XCTestExpectation]()

        let exp1 = expectation(description: "Op 1")
        sut.cache(feed: anyItems().localModels, timeStamp: Date()) { _ in
            expectations.append(exp1)
            exp1.fulfill()
            
        }
        
        let exp2 = expectation(description: "Op 2")
        sut.deleteCachedFeed { _ in
            expectations.append(exp2)
            exp2.fulfill()
        }
        
        let exp3 = expectation(description: "Op 3")
        sut.cache(feed: anyItems().localModels, timeStamp: Date()) { _ in
            expectations.append(exp3)
            exp3.fulfill()
            
        }
        
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(expectations, [exp1, exp2, exp3], "Expected operations to run serially")
    }
    // MARK: - Helpers
    
    private func makeSUT(url: URL? = nil,
                         file: StaticString = #file,
                         line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: url ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for completion")
        var capturedError: Error?
        sut.deleteCachedFeed { error in
            capturedError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        return capturedError
    }

    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date),
                        to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for completion")
        var capturedError: Error?
        sut.cache(feed: cache.feed, timeStamp: cache.timestamp) { insertError in
            capturedError = insertError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        return capturedError
    }

    private func expect(_ sut: FeedStore,
                        toLoadTwice expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file, line: UInt = #line) {
        expect(sut, toLoad: expectedResult, file: file, line: line)
        expect(sut, toLoad: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: FeedStore,
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
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
