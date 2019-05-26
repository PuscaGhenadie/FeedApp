//
//  FeedStoreSpecs.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 26/05/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_emptyCacheReturnsEmpty()
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    func test_retrieve_afterInsertingToEmptyCaches_returnsData()
    func test_retrieve_deliversFoundOnNoneEmptyCache()
    
    func test_insert_overridesPreviouslyInsertedCache()
    
    
    func test_delete_emptyCacheStaysEmptyAndDoesNotFail()
    func test_delete_cacheWithDataLeavesCacheEmpty()
    
    
    func test_sideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnError()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInvalidStoreUrl()
    func test_insert_noSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_returnsErrorOnDeleteOfNoPermissionURL()
    func test_delete_hasNoSideEffectsOnDeletionError()
}

typealias FailableFeedStoreSepcs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
