//
//  FeedUIComposer.swift
//  FeediOS
//
//  Created by Pusca, Ghenadie on 1/3/20.
//  Copyright © 2020 Pusca Ghenadie. All rights reserved.
//

import Foundation
import FeedApp

public class FeedUIComposer {
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshControler = FeedRefreshViewController(viewModel: feedViewModel)
        let feedController = FeedViewController(refreshController: refreshControler)
        feedViewModel.onFeedLoad = adaptFeedToCellContrllers(forwardingTo: feedController, imageLoader: imageLoader)
        
        return feedController
    }
    
    private static func adaptFeedToCellContrllers(forwardingTo controller: FeedViewController, imageLoader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        { [weak controller] feed in
            controller?.tableModel = feed.map { model in
                FeedImageCellController(model: model, imageLoader: imageLoader)
            }
        }
    }
}
