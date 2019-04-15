//
//  CacheFeedUseCase.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 15/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class LocalFeedLoader {
    let store: FeedStore
    let dateProvider: () -> Date
    
    init(store: FeedStore, dateProvider: @escaping () -> Date) {
        self.store = store
        self.dateProvider = dateProvider
    }
    
    func save(items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] deletionError in
            if deletionError == nil {
                self.store.cache(items: items, timeStamp: self.dateProvider()) { insertionError in
                    completion(insertionError)
                }
            } else {
                completion(deletionError)
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func cache(items: [FeedItem], timeStamp: Date, completion: @escaping InsertionCompletion)
}

class CacheFeedUseCase: XCTestCase {
    
    func test_init_doesNotDeleteCacheOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.commands, [])
    }
    
    func test_save_reqCacheDeletion() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()

        sut.save(items: items) { _ in }
        
        XCTAssertEqual(store.commands, [.deleteCacheItems])
    }
    
    func test_save_doesNotRequestCacheOnDeletionError() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyError()
        
        sut.save(items: items) { _ in }
        store.completeDeleteWith(error: deletionError)
        
        XCTAssertEqual(store.commands, [.deleteCacheItems])
    }
    
    func test_save_reqCacheItemsWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items: items) { _ in }
        store.completeDeleteWithSuccess()
        
        XCTAssertEqual(store.commands, [.deleteCacheItems, .cacheItems(items, timestamp)])
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
        sut.save(items: items) { err in
            capturedError = err
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as NSError?, expectedError, file: file, line: line)
    }

    private func anyFeedItem() -> FeedItem {
      return FeedItem(id: UUID(),
                      description: "any desc",
                      location: "any loc",
                      imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://a-url.com")!
    }
    
    private func anyError() -> NSError {
        return NSError(domain: "error", code: 1)
    }
    
    private class FeedStoreSpy: FeedStore {
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        private(set) var commands = [ReceivedCommands]()
        
        enum ReceivedCommands: Equatable {
            case deleteCacheItems
            case cacheItems([FeedItem], Date)
        }
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            commands.append(.deleteCacheItems)
        }
        
        func cache(items: [FeedItem], timeStamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            commands.append(.cacheItems(items, timeStamp))
        }
        
        func completeDeleteWith(error err: Error, at idx: Int = 0) {
            deletionCompletions[idx](err)
        }
        
        func completeDeleteWithSuccess(idx: Int = 0) {
            deletionCompletions[idx](nil)
        }
        
        func completeInsertionWith(error err: Error, at idx: Int = 0) {
            insertionCompletions[idx](err)
        }
        
        func completeInsertionWithSuccess(idx: Int = 0) {
            insertionCompletions[idx](nil)
        }
    }
}
