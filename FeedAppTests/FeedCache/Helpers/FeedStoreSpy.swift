//
//  FeedStoreSpy.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 16/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import FeedApp

class FeedStoreSpy: FeedStore {
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()
    
    private(set) var commands = [ReceivedCommands]()
    
    enum ReceivedCommands: Equatable {
        case deleteCacheItems
        case cacheItems([LocalFeedImage], Date)
        case retrieveItems
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        commands.append(.deleteCacheItems)
    }
    
    func cache(feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        commands.append(.cacheItems(feed, timeStamp))
    }
    
    func loadFeed(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        commands.append(.retrieveItems)
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
    
    func completeRetrieveWithError(error err: Error, at idx: Int = 0) {
        retrievalCompletions[idx](.failure(err))
    }
    
    func complteRetrieveWithEmptyCache(at idx: Int = 0) {
        retrievalCompletions[idx](.empty)
    }
    
    func completesRetrieval(with feed: [LocalFeedImage], timestamp: Date, at idx: Int = 0) {
        retrievalCompletions[idx](.found(feed, timestamp))
    }
}
