//
//  RemoteFeedItem.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 16/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
