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
        refreshControl?.beginRefreshing()
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestsFeed() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCount, 0, "Expected not to trigger load before view is loaded")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCount, 1, "Expected to trigger load once view is loaded")
        
        sut.simulatedUserIniatedReload()
        XCTAssertEqual(loader.loadCount, 2, "Expected to trigger load on user initiated reload")
        
        sut.simulatedUserIniatedReload()
        XCTAssertEqual(loader.loadCount, 3, "Expected to trigger load on another user initiated reload")
    }
    
    func test_viewLoaded_showsLoadingIndicator() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected to show loading indicator once view is loaded")
        
        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected to hide loading indicator once loading completed after view is loaded")
        
        sut.simulatedUserIniatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected to show loading indicator on user initiated reload")
        
        loader.completeLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected to hide loading indicator once loading completed after user initiated relaod")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    final class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        var loadCount: Int {
            return completions.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeLoading(at idx: Int = 0) {
            completions[idx](.success([]))
        }
    }
}

extension FeedViewController {
    func simulatedUserIniatedReload() {
        refreshControl?.simulateValueChanged()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing ?? false
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
