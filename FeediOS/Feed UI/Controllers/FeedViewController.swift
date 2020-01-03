//
//  test.swift
//  FeediOS
//
//  Created by Pusca, Ghenadie on 1/3/20.
//  Copyright © 2020 Pusca Ghenadie. All rights reserved.
//

import UIKit
import FeedApp

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var refreshControler: FeedRefreshViewController?
    var tableModel = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }
    
    convenience init(refreshController: FeedRefreshViewController) {
        self.init()
        self.refreshControler = refreshController
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = refreshControler?.view
        
        tableView.prefetchDataSource = self
        refreshControler?.refresh()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(forRow: indexPath).view()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellController(forRow: indexPath).cancelLoad()
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(forRow: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelCellControllerlLoad)
    }
    
    private func cancelCellControllerlLoad(forRowAt indexPath: IndexPath) {
        tableModel[indexPath.row].cancelLoad()
    }
    
    private func cellController(forRow indexPath: IndexPath) -> FeedImageCellController {
        return tableModel[indexPath.row]
    }
}
