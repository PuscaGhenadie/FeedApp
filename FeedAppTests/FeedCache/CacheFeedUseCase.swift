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
    
    func save(items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] err in
            if err == nil {
                self.store.cache(items: items, timeStamp: self.dateProvider())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    var completions = [DeletionCompletion]()
    
    private(set) var commands = [ReceivedCommands]()
    
    enum ReceivedCommands: Equatable {
        case deleteCacheItems
        case cacheItems([FeedItem], Date)
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completions.append(completion)
        commands.append(.deleteCacheItems)
    }
    
    func cache(items: [FeedItem], timeStamp: Date) {
        commands.append(.cacheItems(items, timeStamp))
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
        
        XCTAssertEqual(store.commands, [])
    }
    
    func test_save_reqCacheDeletion() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()

        sut.save(items: items)
        
        XCTAssertEqual(store.commands, [.deleteCacheItems])
    }
    
    func test_save_doesNotRequestCacheOnDeletionError() {
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyError()
        
        sut.save(items: items)
        store.completeDeleteWith(error: deletionError)
        
        XCTAssertEqual(store.commands, [.deleteCacheItems])
    }
    
    func test_save_reqCacheItemsWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items: items)
        store.completeDeleteWithSucess()
        
        XCTAssertEqual(store.commands, [.deleteCacheItems, .cacheItems(items, timestamp)])
    }
    
    func test_save_callsSaveAfterSuccessfulDeletion() {
        let timestamp = Date()
        let items = [anyFeedItem(), anyFeedItem()]
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items: items)
        store.completeDeleteWithSucess()
        
        XCTAssertEqual(store.commands, [.deleteCacheItems, .cacheItems(items, timestamp)])
    }
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, dateProvider: currentDate)
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
