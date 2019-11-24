//
//  RemoteFeedLoader.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 13/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {    
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = FeedLoader.Result

    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data, response):
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        do {
            let remoteItems = try FeedItemsMapper.map(data, response)
            return .success(remoteItems.toItems())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toItems() -> [FeedImage] {
        return map { FeedImage(id: $0.id,
                              description: $0.description,
                              location: $0.location,
                              url: $0.image)}
    }
}
