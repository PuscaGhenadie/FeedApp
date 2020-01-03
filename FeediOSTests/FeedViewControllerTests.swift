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

final class FeedViewController: UIViewController {
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader?.load { _ in }
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        XCTAssertEqual(loader.loadCount, 0)
    }
    
    func test_viewLoaded_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCount, 1)
    }
}
