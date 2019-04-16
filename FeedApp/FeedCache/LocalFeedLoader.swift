//
//  LocalFeedLoader.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 15/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

final class FeedCachePolicy {
    private let dateProvider: () -> Date
    let calendar = Calendar(identifier: .gregorian)
    
    private var maxCacheAgeInDays: Int {
        return 7
    }
    
    public init(dateProvider: @escaping () -> Date) {
        self.dateProvider = dateProvider
    }
    
    public func validate(_ timestamp: Date) -> Bool {
        
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return dateProvider() < maxCacheAge
    }
}

public final class LocalFeedLoader {
    private let store: FeedStore
    private let cachePolicy: FeedCachePolicy
    private let dateProvider: () -> Date
    
    public init(store: FeedStore, dateProvider: @escaping () -> Date) {
        self.store = store
        self.dateProvider = dateProvider
        self.cachePolicy = FeedCachePolicy(dateProvider: dateProvider)
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

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
    
    private func cache(feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        self.store.cache(feed: feed.toLocal(), timeStamp: self.dateProvider()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        store.loadFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                completion(.error(error))
            case let .found(localFeedImages, timestamp) where self.cachePolicy.validate(timestamp):
                completion(.success(localFeedImages.toModels()))
            case .empty, .found:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.loadFeed { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case let .found(_, timestamp) where !self.cachePolicy.validate(timestamp):
                self.store.deleteCachedFeed { _ in }
            case .empty, .found: break
            }
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

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id,
                               description: $0.description,
                               location: $0.location,
                               url: $0.url)}
    }
}
