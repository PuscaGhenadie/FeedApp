//
//  CodableFeedStoreTests.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 18/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import FeedApp

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSepcs {
    
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        removeCacheArtifacts()
    }
    
    func test_retrieve_emptyCacheReturnsEmpty() {
        assertThatRetrieveDeliversEmptyOnEmptyCache(sut: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        assertThatRetrievehasNoSideEffectsOnEmptyCache(sut: makeSUT())
    }
    
    func test_retrieve_afterInsertingToEmptyCaches_returnsData() {
        assertThatRetrieveAfterInsertingToEmptyCacheReturnsData(sut: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(sut: makeSUT())
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeUrl = testSpecificStoreURL()
        let sut = makeSUT(url: storeUrl)

        try! "invalidData".write(to: storeUrl, atomically: false, encoding: .utf8)

        assertThatRetrieveDeliversFailureOnRetrievalError(sut: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnError() {
        let storeUrl = testSpecificStoreURL()
        let sut = makeSUT(url: storeUrl)
        
        try! "invalidData".write(to: storeUrl, atomically: false, encoding: .utf8)
        
        assertThatRetrieveHasNoSideEffectsOnRetrievalError(sut: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        assertThatInsertDeliversNoErrorOnEmptyCache(sut: makeSUT())
    }

    func test_insert_overridesPreviouslyInsertedCache() {
        assertThatInsertOverridesPreviouslyInsertedCache(sut: makeSUT())
    }
    
    func test_insert_deliversErrorOnInvalidStoreUrl() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(url: invalidStoreURL)
        assertThatInsertDeliversErrorOnInvalidStoreUrl(sut: sut)
    }
    
    func test_insert_noSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(url: invalidStoreURL)
        
        assertThatInsertHasNoSideEffectsOnInsertionError(sut: sut)
    }

    func test_delete_emptyCacheStaysEmptyAndDoesNotFail() {
        assertThatDeleteEmptyCacheStaysEmptyAndDoesNotFail(sut: makeSUT())
    }
    
    func test_delete_cacheWithDataLeavesCacheEmpty() {
        assertThatDeleteCacheWithDataLeavesCacheEmpty(sut: makeSUT())
    }
    
    func test_delete_returnsErrorOnDeleteOfNoPermissionURL() {
        let noPermissionsURL = cachesDirectory()
        let sut = makeSUT(url: noPermissionsURL)
        
        assertThatDeleteReturnsErrorOnDeleteOfNoPermissionURL(sut: sut)
    }
    
    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noPermissionsURL = cachesDirectory()
        let sut = makeSUT(url: noPermissionsURL)
        
        assertThatDeleteHasNoSideEffectsOnDeletionError(sut: sut)
    }

    func test_sideEffects_runSerially() {
        assertThatSideEffectsRunSerially(sut: makeSUT())
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL? = nil,
                         file: StaticString = #file,
                         line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: url ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func setupEmptyStoreState() {
        removeCacheArtifacts()
    }
    
    private func clearCacheAfterTests() {
        removeCacheArtifacts()
    }
    
    private func removeCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
