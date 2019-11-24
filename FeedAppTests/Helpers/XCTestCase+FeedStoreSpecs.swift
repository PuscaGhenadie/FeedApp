//
//  XCTestCase+FeedStoreSpecs.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 26/05/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversEmptyOnEmptyCache(sut: FeedStore,
                                                     file: StaticString = #file,
                                                     line: UInt = #line) {
        expect(sut, toLoad: .success(nil), file: file, line: line)
    }

    func assertThatRetrievehasNoSideEffectsOnEmptyCache(sut: FeedStore,
                                                     file: StaticString = #file,
                                                     line: UInt = #line) {
        expect(sut, toLoad: .success(nil), file: file, line: line)
    }
    
    func assertThatRetrieveAfterInsertingToEmptyCacheReturnsData(sut: FeedStore,
                                                        file: StaticString = #file,
                                                        line: UInt = #line) {
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        
        insert((insertedFeedImages, insertTimestamp), to: sut)
        
        expect(sut,
               toLoad: .success(CachedFeed(feed: insertedFeedImages, timestamp: insertTimestamp)),
               file: file,
               line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(sut: FeedStore,
                                                           file: StaticString = #file,
                                                           line: UInt = #line) {
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        
        insert((insertedFeedImages, insertTimestamp), to: sut)
        
        expect(sut,
               toLoadTwice: .success(CachedFeed(feed: insertedFeedImages, timestamp: insertTimestamp)),
               file: file,
               line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(sut: FeedStore,
                                                            file: StaticString = #file,
                                                            line: UInt = #line) {
        let firstInsertFeed = anyItems().localModels
        let firstInsertData = Date()
        
        let insertionError = insert((firstInsertFeed, firstInsertData), to: sut)
        XCTAssertNil(insertionError, "Expected insertion to be succesfull",
                     file: file,
                     line: line)
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCache(sut: FeedStore,
                                                            file: StaticString = #file,
                                                            line: UInt = #line) {
        let firstInsertFeed = anyItems().localModels
        let firstInsertData = Date()
        
        insert((firstInsertFeed, firstInsertData), to: sut)
        
        let latesInsertFeed = anyItems().localModels
        let latesInsertDate = Date()
        
        insert((latesInsertFeed, latesInsertDate), to: sut)
        
        expect(sut,
               toLoad: .success(CachedFeed(feed: latesInsertFeed, timestamp: latesInsertDate)),
               file: file,
               line: line)

    }
    
    func assertThatDeleteEmptyCacheStaysEmptyAndDoesNotFail(sut: FeedStore,
                                                          file: StaticString = #file,
                                                          line: UInt = #line) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError,
                     "Expected deletion to not fail",
                     file: file,
                     line: line)
        expect(sut, toLoad: .success(nil), file: file, line: line)
    }

    func assertThatDeleteCacheWithDataLeavesCacheEmpty(sut: FeedStore,
                                                            file: StaticString = #file,
                                                            line: UInt = #line) {
        sut.cache(feed: anyItems().localModels, timeStamp: Date()) { error in
            XCTAssertNil(error,
                         "Expected cache to not fail",
                         file: file,
                         line: line)
        }
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError,
                     "Expected deletion to not fail",
                     file: file,
                     line: line)
        expect(sut, toLoad: .success(nil), file: file, line: line)
    }
    
    func assertThatSideEffectsRunSerially(sut: FeedStore,
                                                         file: StaticString = #file,
                                                         line: UInt = #line) {
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
        XCTAssertEqual(expectations,
                       [exp1, exp2, exp3],
                       "Expected operations to run serially",
                       file: file,
                       line: line)

    }
}

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    internal func deleteCache(from sut: FeedStore) -> Error? {
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
    internal func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date),
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
    
    internal func expect(_ sut: FeedStore,
                         toLoadTwice expectedResult: FeedStore.RetrievalResult,
                        file: StaticString = #file, line: UInt = #line) {
        expect(sut, toLoad: expectedResult, file: file, line: line)
        expect(sut, toLoad: expectedResult, file: file, line: line)
    }
    
    internal func expect(_ sut: FeedStore,
                        toLoad expectedResult: FeedStore.RetrievalResult,
                        file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        
        sut.loadFeed { result in
            switch (expectedResult, result) {
            case (.success(nil), .success(nil)),
                 (.failure, .failure):
                break
            case let (.success(.some(expected)), .success(.some(retrieved))):
                XCTAssertEqual(expected.feed, retrieved.feed, file: file, line: line)
                XCTAssertEqual(expected.timestamp, retrieved.timestamp, file: file, line: line)
            default:
                XCTFail("Expected to load \(expectedResult), got \(result) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
