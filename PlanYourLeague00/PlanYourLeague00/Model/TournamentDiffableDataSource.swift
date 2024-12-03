//
//  TournamentDiffableDataSource.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 11/11/24.
//

import UIKit

enum Section{
    case all
}

class TournamentDiffableDataSource: UITableViewDiffableDataSource<Section, Tournament> {

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
