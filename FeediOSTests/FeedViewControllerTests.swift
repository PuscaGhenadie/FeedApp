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
        refreshControl?.beginRefreshing()
        load()
    }
    
    @objc private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
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
    
    func test_userInitiatedReload_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        sut.simulatedUserIniatedReload()
        XCTAssertEqual(loader.loadCount, 2)
        
        sut.simulatedUserIniatedReload()
        XCTAssertEqual(loader.loadCount, 3)
    }
    
    func test_viewLoaded_showsLoadingIndicator() {
        let (sut, _) = makeSUT()

        sut.loadViewIfNeeded()
        
        XCTAssertTrue(sut.refreshControl?.isRefreshing == true)
    }
    
    func test_feedLoaded_hidesLoadingIndicator() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertTrue(sut.refreshControl?.isRefreshing == true)
        loader.completeLoading()
        XCTAssertTrue(sut.refreshControl?.isRefreshing == false)
    }
    
    func test_userInitiatedReload_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.simulatedUserIniatedReload()
        
        XCTAssertTrue(sut.refreshControl?.isRefreshing == true)
    }
    
    func test_userInitiatedReload_hidesLoadingIndicatorOnLoadCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulatedUserIniatedReload()
        loader.completeLoading()
        XCTAssertTrue(sut.refreshControl?.isRefreshing == false)
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
        
        func completeLoading() {
            completions[0](.success([]))
        }
    }
}

extension FeedViewController {
    func simulatedUserIniatedReload() {
        refreshControl?.simulateValueChanged()
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
