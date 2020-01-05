//
//  FeedImageCellController.swift
//  FeediOS
//
//  Created by Pusca, Ghenadie on 1/3/20.
//  Copyright © 2020 Pusca Ghenadie. All rights reserved.
//

import UIKit
import FeedApp

final class FeedImageViewModel {
    typealias Observer<T> = (T) -> Void
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    
    init(model: FeedImage,
         imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    var location: String? {
        model.location
    }
    
    var description: String? {
        model.description
    }
    
    var isLocationHidden: Bool {
        model.location == nil
    }

    var onImageLoadingStateChange: Observer<Bool>?
    var onImageLoaded: Observer<UIImage?>?
    
    func loadImage() {
        onImageLoadingStateChange?(true)
        task = imageLoader.loadImageData(from: model.url) { [weak self] result in
            let data = try? result.get()
            let image = data.map(UIImage.init) ?? nil
            self?.onImageLoaded?(image)
            self?.onImageLoadingStateChange?(false)
        }
    }
    
    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
final class FeedImageCellController {
    private let viewModel: FeedImageViewModel
    
    init(viewModel: FeedImageViewModel) {
        self.viewModel = viewModel
    }

    func view() -> UITableViewCell {
        let cell = binded(FeedImageCell())
        viewModel.loadImage()
        return cell
    }
    
    
    func preload() {
        viewModel.loadImage()
    }

    func cancelLoad() {
        viewModel.cancelLoad()
    }
    
    private func binded(_ view: FeedImageCell) -> FeedImageCell {
        view.locationContainer.isHidden = viewModel.isLocationHidden
        view.locationLabel.text = viewModel.location
        view.descriptionLabel.text = viewModel.description
        view.feedImageView.image = nil
        view.imageRetryButton.isHidden = true
        
        view.onRetry = viewModel.loadImage
        viewModel.onImageLoadingStateChange = { [weak view] isLoading in
            view?.imageContainer.isShimmering = isLoading
        }
        
        viewModel.onImageLoaded = { [weak view] image in
            view?.feedImageView.image = image
            view?.imageRetryButton.isHidden = image != nil
        }
        
        return view
    }
}
