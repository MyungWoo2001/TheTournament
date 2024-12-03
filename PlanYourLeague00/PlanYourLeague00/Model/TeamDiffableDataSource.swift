//
//  TeamDiffableDataSource.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 8/29/24.
//

import UIKit

class TeamDiffableDataSource: UITableViewDiffableDataSource<Section, Team> {

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
