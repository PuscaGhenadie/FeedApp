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
    
    func test_validate_shouldNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.validateCache()
        store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_deletesCacheOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.validateCache()
        store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
    }
    
    func test_load_deletesOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.validateCache()
        store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
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
