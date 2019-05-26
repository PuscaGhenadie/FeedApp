//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 26/05/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversFailureOnRetrievalError(sut: FeedStore,
                                                           file: StaticString = #file,
                                                           line: UInt = #line) {
        expect(sut,
               toLoad: .failure(anyError()),
               file: file,
               line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnRetrievalError(sut: FeedStore,
                                                            file: StaticString = #file,
                                                            line: UInt = #line) {
        expect(sut,
               toLoadTwice: .failure(anyError()),
               file: file,
               line: line)
    }
}
