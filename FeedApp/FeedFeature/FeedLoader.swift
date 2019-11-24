//
//  FeedLoader.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 13/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

/// The feed loader protocol responsable for loading the feed data
public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>

    /// Loads the feed data
    ///
    /// - Parameter completion: The load result
    func load(completion: @escaping (Result) -> Void)
}
