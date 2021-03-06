//
//  CacheFeedUseCase.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 15/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class CacheFeedUseCase: XCTestCase {
    
    func test_init_doesNotDeleteCacheOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.commands, [])
    }
    
    func test_save_reqCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(feed: anyItems().models) { _ in }
        
        XCTAssertEqual(store.commands, [.deleteCacheItems])
    }
    
    func test_save_doesNotRequestCacheOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyError()
        
        sut.save(feed: anyItems().models) { _ in }
        store.completeDeleteWith(error: deletionError)
        
        XCTAssertEqual(store.commands, [.deleteCacheItems])
    }
    
    func test_save_reqCacheItemsWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (items, localItems) = anyItems()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(feed: items) { _ in }
        store.completeDeleteWithSuccess()
        
        XCTAssertEqual(store.commands, [.deleteCacheItems, .cacheItems(localItems, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let deletionError = anyError()
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeleteWith(error: deletionError)
        })
    }
    
    func test_save_failsOnInsertionError() {
        let insertionError = anyError()
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeleteWithSuccess()
            store.completeInsertionWith(error: insertionError)
        })
    }
    
    func test_save_succedesOnSuccessfullCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeleteWithSuccess()
            store.completeInsertionWithSuccess()
        })
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, dateProvider: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(feed: anyItems().models) { receivedResults.append($0) }
        
        sut = nil
        store.completeDeleteWith(error: anyError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterDeallocation() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, dateProvider: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(feed: anyItems().models) { receivedResults.append($0) }
        
        store.completeDeleteWithSuccess()
        sut = nil
        store.completeInsertionWith(error: anyError())
        
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
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWithError expectedError: NSError?,
                        when action: () -> Void,
                        file: StaticString = #file, line: UInt = #line) {
        let items = [anyFeedItem(), anyFeedItem()]
        
        let exp = expectation(description: "Wait for completion")
        var capturedError: Error?
        sut.save(feed: items) { result in
            if case let .failure(error) = result {
                capturedError = error
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as NSError?, expectedError, file: file, line: line)
    }
}
