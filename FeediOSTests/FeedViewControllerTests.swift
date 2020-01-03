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
import FeediOS

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
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected to show loading indicator once view is loaded")
        
        loader.completeLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected to hide loading indicator once loading completed after view is loaded with success")
        
        sut.simulatedUserIniatedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected to show loading indicator on user initiated reload")
        
        loader.completeLoading(withResult: .failure(anyError()), at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected to hide loading indicator once loading with error after user initiated relaod")
    }
    
    func test_loadFeedCompletion_rendersSuccessfyllyLoadedItems() {
        let image0 = makeImage(description: "desc", location: "loca")
        let image1 = makeImage(description: nil, location: "loca1")
        let image2 = makeImage(description: "desc2", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        loader.completeLoading(withResult: .success([image0]), at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.simulatedUserIniatedReload()
        loader.completeLoading(withResult: .success([image0, image1, image2, image3]), at: 1)
        assertThat(sut, isRendering: [image0, image1, image2, image3])
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = makeImage(description: "desc", location: "loca")
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0]), at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.simulatedUserIniatedReload()
        loader.completeLoading(withResult: .failure(anyError()), at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        guard sut.numberOfRenderedFeedImageViews == feed.count else {
            return XCTFail("Expected to render \(feed.count) images, instead \(sut.numberOfRenderedFeedImageViews) are rendered", file: file, line: line)
        }
        
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasConfiguredViewFor: image, at: index, file: file, line: line)
        }
    }

    private func assertThat(_ sut: FeedViewController, hasConfiguredViewFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let view = sut.feedImageView(at: index)
        guard let feedImageCell = view as? FeedImageCell else {
            return XCTFail("Expected to show \(FeedImageCell.self), instead \(String(describing: view)) is shown", file: file, line: line)
        }
        
        let shouldLocationBeVisible = (image.location != nil)
        XCTAssertEqual(feedImageCell.isShowingLocation, shouldLocationBeVisible, "Expected to show location for image view at index \(index)", file: file, line: line)
        XCTAssertEqual(feedImageCell.locationText,
                       image.location,
                       "Expected location text to be \(image.location), instead it is \(feedImageCell.locationText)",
            file: file,
            line: line)
        XCTAssertEqual(feedImageCell.descriptionText,
                       image.description,
                       "Expected description text to be \(image.description), instead it is \(feedImageCell.descriptionText)",
                       file: file,
                       line: line)
    }
    
    final class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        var loadCount: Int {
            return completions.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeLoading(withResult result: FeedLoader.Result = .success([]), at idx: Int = 0) {
            completions[idx](result)
        }
    }
    
    private func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "http://any-url.com")!) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }
}

extension FeedViewController {
    private var feedImageSection: Int { 0 }
    
    func simulatedUserIniatedReload() {
        refreshControl?.simulateValueChanged()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing ?? false
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView.numberOfRows(inSection: feedImageSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        return tableView.dataSource?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: feedImageSection))
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
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
