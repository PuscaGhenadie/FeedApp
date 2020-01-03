//
//  FeedImageCell.swift
//  FeediOS
//
//  Created by Pusca, Ghenadie on 1/3/20.
//  Copyright © 2020 Pusca Ghenadie. All rights reserved.
//

import UIKit

public class FeedImageCell: UITableViewCell {
    public let locationContainer = UIView()
    public let locationLabel = UILabel()
    public let descriptionLabel = UILabel()
    public let imageContainer = UIView()
    public let feedImageView = UIImageView()

    private(set) public lazy var imageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    var onRetry: (() -> Void)?
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
}
