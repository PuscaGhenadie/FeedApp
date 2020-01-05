//
//  FeedViewModel.swift
//  FeediOS
//
//  Created by Pusca, Ghenadie on 1/5/20.
//  Copyright © 2020 Pusca Ghenadie. All rights reserved.
//

import FeedApp

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void
    
    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            
            self?.onLoadingStateChange?(false)
        }
    }
}
