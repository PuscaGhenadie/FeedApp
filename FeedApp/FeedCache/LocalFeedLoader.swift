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
    
    public init(store: FeedStore, dateProvider: @escaping () -> Date) {
        self.store = store
        self.dateProvider = dateProvider
    }
    
    public func save(items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self = self else { return }
            
            if let deletionError = deletionError {
                completion(deletionError)
            } else {
                self.cache(items: items, completion: completion)
            }
        }
    }
    
    private func cache(items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        self.store.cache(items: items.toLocal(), timeStamp: self.dateProvider()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        return map { LocalFeedItem(id: $0.id,
                                   description: $0.description,
                                   location: $0.location,
                                   imageURL: $0.imageURL)}
    }
}
