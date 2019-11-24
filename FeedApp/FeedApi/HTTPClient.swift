//
//  HTTPClient.swift
//  FeedApp
//
//  Created by Pusca Ghenadie on 14/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>

    func get(from url: URL,
             completion: @escaping (Result) -> Void)
}
