//
//  FeedItemMapper.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 14/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static let OK_200 = 200
    
    static internal func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
            let root = try? JSONDecoder().decode(Root.self, from: data) else {
                throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
