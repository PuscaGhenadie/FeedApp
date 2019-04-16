//
//  CacheValidationUseCaseTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 16/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class CacheValidationUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.commands, [])
    }
    
    func test_validate_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrieveWithError(error: anyError())
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
    }
    
    func test_validate_shouldNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.complteRetrieveWithEmptyCache()
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_validate_shouldNotDeleteCacheOnNonExpiredCache() {
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.validateCache()
        store.completesRetrieval(with: feed.localModels, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_deletesCacheOnCacheExpiration() {
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.validateCache()
        store.completesRetrieval(with: feed.localModels, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
    }
    
    func test_load_deletesOnExpiredCache() {
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.validateCache()
        store.completesRetrieval(with: feed.localModels, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
    }
    
    func test_validate_doesNotDeleteCacheAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, dateProvider: Date.init)
        
        sut?.validateCache()
        sut = nil
        store.completeRetrieveWithError(error: anyError())
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, dateProvider: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
