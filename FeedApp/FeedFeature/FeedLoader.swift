//
//  FeedLoader.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 13/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

/// The load feed result returned once the loading is complete
///
/// - success: The loading was successfull, returns with Feed items
/// - error: The loading did fail, returns with an error
public enum LoadFeedResult{
    case success([FeedItem])
    case error(Error)
}

/// The feed loader protocol responsable for loading the feed data
public protocol FeedLoader {
    
    /// Loads the feed data
    ///
    /// - Parameter completion: The load result
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
