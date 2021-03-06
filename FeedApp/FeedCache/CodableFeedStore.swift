//
//  CodableFeedStore.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 26/05/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private struct CacheData: Codable {
        let feed: [CacheFeedImage]
        let date: Date
        
        var feedImages: [LocalFeedImage] {
            return feed.map { $0.localFeedImage }
        }
    }
    
    private struct CacheFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(feedImage: LocalFeedImage) {
            id = feedImage.id
            description = feedImage.description
            location = feedImage.location
            url = feedImage.url
        }
        
        var localFeedImage: LocalFeedImage {
            return LocalFeedImage(id: id,
                                  description: description,
                                  location: location,
                                  url: url)
        }
    }
    
    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)queue",
        qos: .userInitiated,
        attributes: .concurrent)
    
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func loadFeed(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            completion(Result {
                guard let data = try? Data(contentsOf: storeURL) else {
                    return nil
                }
                
                let cache = try JSONDecoder().decode(CacheData.self, from: data)
                return CachedFeed(feed: cache.feedImages, timestamp: cache.date)
            })
        }
    }
    
    public func cache(feed: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            completion(Result {
                let cacheData = CacheData(feed: feed.map { CacheFeedImage(feedImage: $0) }, date: timeStamp)
                let encodedData = try JSONEncoder().encode(cacheData)
                try encodedData.write(to: storeURL)
                return ()
            })
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async(flags: .barrier) {
            completion(Result {
                guard FileManager.default.fileExists(atPath: storeURL.path) else {
                    return ()
                }
                
                try FileManager.default.removeItem(at: storeURL)
            })
        }
    }
}
