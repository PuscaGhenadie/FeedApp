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
}
