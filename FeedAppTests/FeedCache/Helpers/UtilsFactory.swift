//
//  UtilsFactoru.swift
//  FeedAppTests
//
//  Created by Pusca Ghenadie on 16/04/2019.
//  Copyright © 2019 Pusca Ghenadie. All rights reserved.
//

import FeedApp

func anyFeedItem() -> FeedImage {
    return FeedImage(id: UUID(),
                     description: "any desc",
                     location: "any loc",
                     url: anyURL())
}

func anyItems() -> (models: [FeedImage], localModels: [LocalFeedImage]) {
    let items = [anyFeedItem(), anyFeedItem()]
    let localItems = items.map { LocalFeedImage(id: $0.id,
                                                description: $0.description,
                                                location: $0.location,
                                                url: $0.url)}
    return (items, localItems)
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -7)
    }

    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day,
                                                     value: days,
                                                     to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .second,
                                                     value: seconds,
                                                     to: self)!
    }
}
