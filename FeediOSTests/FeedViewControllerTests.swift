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
        XCTAssertEqual(loader.feedRequestsCount, 0, "Expected not to trigger load before view is loaded")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.feedRequestsCount, 1, "Expected to trigger load once view is loaded")
        
        sut.simulatedUserIniatedReload()
        XCTAssertEqual(loader.feedRequestsCount, 2, "Expected to trigger load on user initiated reload")
        
        sut.simulatedUserIniatedReload()
        XCTAssertEqual(loader.feedRequestsCount, 3, "Expected to trigger load on another user initiated reload")
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
    
    func test_feedImageView_loadsImagURLWhenVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        XCTAssertEqual(loader.loadedFeedImages, [], "Expected no image URL requests until view becomes visible")
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedFeedImages, [image0.url], "Expected first image URL requests once first view is visible")
        
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedFeedImages, [image0.url, image1.url], "Expected first image URL requests once first view is visible")
    }
    
    func test_feedImageView_cancellsImageRequestOnceViewIsNoMoreVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        XCTAssertEqual(loader.cancelledImageUrls, [], "Expected no image URL requests until view becomes visible")
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageUrls, [image0.url], "Expected first image URL requests once first view is visible")
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageUrls, [image0.url, image1.url], "Expected first image URL requests once first view is visible")
    }

    func test_feedImageViewLoadingIndicator_isCorrectlyShownWhileLoadingTheImage() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true, "Expected to show loading indicator for the first image while the image is loading")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected to show loading indicator for the second image while the image is loading")
        
        loader.completeImageLoading(at: 0, withResult: .success(Data()))
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected to not show loading indicator for the first image once image is loaded")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected to show loading indicator for the second image while the image is loading")
        
        loader.completeImageLoading(at: 1, withResult: .success(Data()))
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected to not change image loading indicator once second image is loaded")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false, "Expected to not show loading indicator for the second image once image is loaded")
    }
    
    func test_feedImageView_rendersImageOnImageLoaded() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        
        XCTAssertEqual(view0?.renderedImage, .none, "Expected to not render the first image while the image is loading")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected to not renderthe second image while the image is loading")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(at: 0, withResult: .success(imageData0))
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected to render the first image once image is loaded")
        XCTAssertEqual(view1?.renderedImage, .none, "Expected to not render the second image while the image is loading")
        
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(at: 1, withResult: .success(imageData1))
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected to not change the first image once second image is loaded")
        XCTAssertEqual(view1?.renderedImage, imageData1, "Expected to render the second image once image is loaded")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnImageLoadError() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected to not show the retry action while the first image is loading")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected to not show the retry action while the second image is loading")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(at: 0, withResult: .success(imageData0))
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected to not show the retry action once the first image is loaded successfully")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected to not change the retry action state once the first image is loaded")
        
        loader.completeImageLoading(at: 1, withResult: .failure(anyError()))
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected to not change the retry action state once the second image failed to load")
        XCTAssertEqual(view1?.isShowingRetryAction, true, "Expected to show the retry action once the second image load failed")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0]), at: 0)
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
    
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected to not show the retry action while the first image is loading")
        
        let invalidImageData = Data("invalid image data".utf8)
        loader.completeImageLoading(at: 0, withResult: .success(invalidImageData))
        XCTAssertEqual(view0?.isShowingRetryAction, true, "Expected to show retry action on invalid image data")
    }
    
    func test_feedImageViewRetryAction_retriesImageLoad() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        
        XCTAssertEqual(loader.loadedFeedImages, [image0.url, image1.url], "Expected two image requests for the two visible views")
        
        loader.completeImageLoading(at: 0, withResult: .failure(anyError()))
        loader.completeImageLoading(at: 1, withResult: .failure(anyError()))
        XCTAssertEqual(loader.loadedFeedImages, [image0.url, image1.url], "Expected to not trigger any requests on fail")
        
        view0?.simulateRetryAction()
        XCTAssertEqual(loader.loadedFeedImages, [image0.url, image1.url, image0.url], "Expected another request for the first image on retry")
        
        view1?.simulateRetryAction()
        XCTAssertEqual(loader.loadedFeedImages, [image0.url, image1.url, image0.url, image1.url], "Expected another request for the second image on retry")
    }
    
    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)

        sut.simulateImageViewNearVisible(at: 0)
        sut.simulateImageViewNearVisible(at: 1)
        
        sut.simulateImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageUrls, [image0.url], "Expected to preload first image once the first image view is near visible")
        sut.simulateImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageUrls, [image0.url, image1.url], "Expected to preload first image once the first image view is near visible")
    }
    
    func test_feedImageView_cancellsImageURLPreloadingWhenNotNearVisibleAnymoare() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeLoading(withResult: .success([image0, image1]), at: 0)
        XCTAssertEqual(loader.loadedFeedImages, [], "Expected no image requests until the views are near visible")
        
        sut.simulateImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedFeedImages, [image0.url], "Expected to preload first image once the first image view is near visible")
        
        sut.simulateImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedFeedImages, [image0.url, image1.url], "Expected to preload second image once the second image view is near visible")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(feedLoader: loader, imageLoader: loader)
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
    
    final class LoaderSpy: FeedLoader, FeedImageDataLoader {
        
        // MARK: -  Feed loader
        private var feedRequests = [(FeedLoader.Result) -> Void]()
        var feedRequestsCount: Int {
            feedRequests.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            feedRequests.append(completion)
        }
        
        func completeLoading(withResult result: FeedLoader.Result = .success([]), at idx: Int = 0) {
            feedRequests[idx](result)
        }
        
        // MARK: - Image loader
        
        private struct TaskSpy: FeedImageDataLoaderTask {
            let cancelCallback: () -> Void
            
            func cancel() {
                cancelCallback()
            }
        }

        private var imageRequests = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
        var loadedFeedImages: [URL] {
            imageRequests.map { $0.url }
        }
        var cancelledImageUrls = [URL]()
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return TaskSpy { [weak self] in
                self?.cancelledImageUrls.append(url)
            }
        }
        
        func completeImageLoading(at index: Int, withResult result: FeedImageDataLoader.Result) {
            imageRequests[index].completion(result)
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
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }
    
    func simulateFeedImageViewNotVisible(at row: Int) {
        let view = feedImageView(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImageSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
    }
    
    func simulateImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImageSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateImageViewNotNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImageSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing ?? false
    }
    
    var numberOfRenderedFeedImageViews: Int {
        tableView.numberOfRows(inSection: feedImageSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
         let ds = tableView.dataSource
         let index = IndexPath(row: row, section: feedImageSection)
         return ds?.tableView(tableView, cellForRowAt: index)
     }
}

private extension FeedImageCell {
    func simulateRetryAction() {
        imageRetryButton.simulateTap()
    }
    
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var isShowingRetryAction: Bool {
        !imageRetryButton.isHidden
    }
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
    
    var isShowingImageLoadingIndicator: Bool {
        imageContainer.isShimmering
    }
    
    var renderedImage: Data? {
        feedImageView.image?.pngData()
    }
}

extension UIControl {
    func simulateTap() {
        simulateAction(event: .touchUpInside)
    }
    
    func simulateValueChanged() {
        simulateAction(event: .valueChanged)
    }
    
    func simulateAction(event: UIControl.Event) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: event)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}

extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
         UIGraphicsBeginImageContext(rect.size)
         let context = UIGraphicsGetCurrentContext()!
         context.setFillColor(color.cgColor)
         context.fill(rect)
         let img = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         return img!
    }
}
