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
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.commands, [.retrieveItems])
    }
    
    func test_load_returnsErrorOnCacheRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyError()
        
        let exp = expectation(description: "Wait for completion")
        var capturedError: Error?
        sut.load { error in
            capturedError = error
            exp.fulfill()
        }
        
        store.completeRetrieveWithError(error: error)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedError as NSError?, error)
    }
    
    
    // MARK: - Helpers

    private func anyError() -> NSError {
        return NSError(domain: "error", code: 1)
    }

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, dateProvider: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}
