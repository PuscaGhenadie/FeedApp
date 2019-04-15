//
//  FeedLoader.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 13/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

public enum LoadFeedResult{
    case success([FeedItem])
    case error(Error)
}

/// The feed loader protocol responsable for loading the feed data
public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
