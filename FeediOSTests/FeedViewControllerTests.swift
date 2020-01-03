//
//  FeedViewControllerTests.swift
//  FeediOSTests
//
//  Created by Pusca Ghenadie on 24/11/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import XCTest
import UIKit
import FeedApp

final class LoaderSpy: FeedLoader {
    private(set) var loadCount = 0
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
        loadCount += 1
    }
}

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    @objc private func load() {
        loader?.load { _ in }
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        XCTAssertEqual(loader.loadCount, 0)
    }
    
    func test_viewLoaded_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCount, 1)
    }
    
    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        sut.refreshControl?.simulateValueChanged()
        XCTAssertEqual(loader.loadCount, 2)
        
        sut.refreshControl?.simulateValueChanged()
        XCTAssertEqual(loader.loadCount, 3)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(sut)
        return (sut, loader)
    }
}

extension UIRefreshControl {
    func simulateValueChanged() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
