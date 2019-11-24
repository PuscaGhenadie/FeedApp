//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 26/05/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInvalidStoreUrl(sut: FeedStore,
                                                        file: StaticString = #file,
                                                        line: UInt = #line) {
        let insertError = insert((anyItems().localModels, Date()), to: sut)
        
        XCTAssertNotNil(insertError,
                        "Expected insert error for inserting at invalid url",
                        file: file,
                        line: line)
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(sut: FeedStore,
                                                          file: StaticString = #file,
                                                          line: UInt = #line) {
        insert((anyItems().localModels, Date()), to: sut)
        
        expect(sut, toLoad: .success(nil), file: file, line: line)
    }
}
