//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 26/05/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteReturnsErrorOnDeleteOfNoPermissionURL(sut: FeedStore,
                                                               file: StaticString = #file,
                                                               line: UInt = #line) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected deletion fail", file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(sut: FeedStore,
                                                         file: StaticString = #file,
                                                         line: UInt = #line) {
        deleteCache(from: sut)
        
        expect(sut, toLoad: .success(nil), file: file, line: line)
    }
}
