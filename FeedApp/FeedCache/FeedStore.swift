//
//  FeedStore.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 15/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

public enum CachedFeed {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
}

public protocol FeedStore {
    typealias RetrievalResult = Result<CachedFeed, Error>

    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalResult) -> Void
    
    /// The completion handler can be invoked on any thread, the client
    /// should handle the completion thread
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func cache(feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion)
    func loadFeed(completion: @escaping RetrievalCompletion)
}
