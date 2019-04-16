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
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, dateProvider: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private class FeedStoreSpy: FeedStore {
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        private(set) var commands = [ReceivedCommands]()
        
        enum ReceivedCommands: Equatable {
            case deleteCacheItems
            case cacheItems([LocalFeedImage], Date)
        }
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            commands.append(.deleteCacheItems)
        }
        
        func cache(feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            commands.append(.cacheItems(feed, timeStamp))
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
