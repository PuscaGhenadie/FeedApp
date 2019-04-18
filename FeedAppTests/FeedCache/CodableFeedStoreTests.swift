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
    func loadFeed(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}
class CodableFeedStoreTests: XCTestCase {
    
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
}
