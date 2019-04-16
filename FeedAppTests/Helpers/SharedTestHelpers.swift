//
//  SharedTestHelpers.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 16/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import Foundation

func anyError() -> NSError {
    return NSError(domain: "error", code: 1)
}

func anyURL() -> URL {
    return URL(string: "https://a-url.com")!
}
