//
//  LocalFeedLoader.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 15/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let dateProvider: () -> Date
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, dateProvider: @escaping () -> Date) {
        self.store = store
        self.dateProvider = dateProvider
    }
    
    public func save(feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self = self else { return }
            
            if let deletionError = deletionError {
                completion(deletionError)
            } else {
                self.cache(feed: feed, completion: completion)
            }
        }
    }
    
    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        store.loadFeed { error in
            if let error = error {
                completion(.error(error))
            } else {
                completion(.success([]))
            }
        }
    }
    
    private func cache(feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        self.store.cache(feed: feed.toLocal(), timeStamp: self.dateProvider()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id,
                                    description: $0.description,
                                    location: $0.location,
                                    url: $0.url)}
    }
}
