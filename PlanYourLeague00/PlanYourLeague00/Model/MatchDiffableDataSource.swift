//
//  MatchDiffableDataSource.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 10/5/24.
//

import UIKit

class MatchDiffableDataSource: UITableViewDiffableDataSource<Int, Match> {

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
