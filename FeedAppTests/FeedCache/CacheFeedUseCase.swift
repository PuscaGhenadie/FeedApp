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

    init(store: FeedStore) {
        self.store = store
    }
    
    func save(items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] err in
            if err == nil {
                self.store.cache(items: items)
            }
        }
    }
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
    var cacheItemsCallCount = 0
    typealias DeletionCompletion = (Error?) -> Void
    var completions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        completions.append(completion)
    }
    
    func cache(items: [FeedItem]) {
        cacheItemsCallCount += 1
    }
    
    func completeDeleteWith(error err: Error, at idx: Int = 0) {
        completions[idx](err)
    }
    
    func completeDeleteWithSucess(idx: Int = 0) {
        completions[idx](nil)
    }
}

class CacheFeedUseCase: XCTestCase {
    
    func test_init_doesNotDeleteCacheOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_reqCacheDeletion() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()

        sut.save(items: items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheOnDeletionError() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyError()
        
        sut.save(items: items)
        store.completeDeleteWith(error: deletionError)
        
        XCTAssertEqual(store.cacheItemsCallCount, 0)
    }
    
    func test_save_reqCacheItemsOnSuccessfullDeletion() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items: items)
        store.completeDeleteWithSucess()
        
        XCTAssertEqual(store.cacheItemsCallCount, 1)
    }
    
    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
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
}
