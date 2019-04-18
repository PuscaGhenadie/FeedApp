//
//  CodableFeedStoreTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 18/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class CodableFeedStore {
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
    private let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    func loadFeed(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL),
        let cacheData = try? JSONDecoder().decode(CacheData.self, from: data) else {
            return completion(.empty)
        }
        
        completion(.found(cacheData.feedImages, cacheData.date))
    }
    
    func cache(feed: [LocalFeedImage], timeStamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let cacheData = CacheData(feed: feed.map { CacheFeedImage(feedImage: $0) }, date: timeStamp)
        let encodedData = try! JSONEncoder().encode(cacheData)
        try! encodedData.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrieve_emptyCacheReturnsEmpty() {
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for completion")
        sut.loadFeed { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result)")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for completion")
        sut.loadFeed { firstResult in
            sut.loadFeed { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected empty result, got \(firstResult) and \(secondResult)")
                }
                
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_afterInsertingToEmptyCaches_returnsData() {
        let sut = CodableFeedStore()
        let insertedFeedImages = anyItems().localModels
        let insertTimestamp = Date()
        let exp = expectation(description: "Wait for completion")
        
        sut.cache(feed: insertedFeedImages,
                  timeStamp: insertTimestamp) { insertError in
                    XCTAssertNil(insertError)
                    sut.loadFeed { loadResult in
                        switch loadResult {
                        case let .found(loadFeedImages, loadTimestamp):
                            XCTAssertEqual(insertedFeedImages, loadFeedImages)
                            XCTAssertEqual(insertTimestamp, loadTimestamp)
                        default:
                            XCTFail("Expected get feed images, got \(loadResult) instead")
                        }
                        
                        exp.fulfill()
                    }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
