//
//  LoadFeedFromCacheUseCaseTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 16/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.commands, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_returnsErrorOnCacheRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyError()
        
        expect(sut, toCompleteWith: .error(error), when: {
            store.completeRetrieveWithError(error: error)
        })
    }
    
    func test_load_deliversNoImageOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.complteRetrieveWithEmptyCache()
        })
    }
    
    func test_load_deliversCachedImagesOnLessThenSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        expect(sut, toCompleteWith: .success(feed.models), when: {
            store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_deliversNoCachedImagesOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_deliversNoCachedImagesOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        expect(sut, toCompleteWith: .success([]), when: {
            store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrieveWithError(error: anyError())
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_shouldNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.complteRetrieveWithEmptyCache()
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_shouldNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.load { _ in }
        store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_deletesCacheOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.load { _ in }
        store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
    }
    
    func test_load_deletesCacheOnMoreTahnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = anyItems()
        
        sut.load { _ in }
        store.completesRetrieval(with: feed.localModels, timestamp: lessThanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.commands, [.retrieveItems, .deleteCacheItems])
    }
    
    func test_load_doesNotDeliverAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, dateProvider: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        sut = nil
        store.complteRetrieveWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, dateProvider: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
     
        let exp = expectation(description: "Wait for completion")
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.error(receivedError as NSError), .error(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(result)", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func anyError() -> NSError {
        return NSError(domain: "error", code: 1)
    }
    
    private func anyFeedItem() -> FeedImage {
        return FeedImage(id: UUID(),
                         description: "any desc",
                         location: "any loc",
                         url: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
    
    private func anyItems() -> (models: [FeedImage], localModels: [LocalFeedImage]) {
        let items = [anyFeedItem(), anyFeedItem()]
        let localItems = items.map { LocalFeedImage(id: $0.id,
                                                    description: $0.description,
                                                    location: $0.location,
                                                    url: $0.url)}
        return (items, localItems)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day,
                                                     value: days,
                                                     to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .second,
                                                     value: seconds,
                                                     to: self)!
    }
}
