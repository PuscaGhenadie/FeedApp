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
        let refreshControler = FeedRefreshViewController(feedLoader: feedLoader)
        let feedController = FeedViewController(refreshController: refreshControler)
        
        refreshControler.onRefresh = { [weak feedController] feed in
            feedController?.tableModel = feed.map { model in
                FeedImageCellController(model: model, imageLoader: imageLoader)
            }
        }
        
        return feedController
    }
}
