//
//  LeagueStandHeaderView.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/29/24.
//

import UIKit

class LeagueStandHeaderView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBOutlet var leagueNameLabel: UILabel!{
        didSet {
            leagueNameLabel.numberOfLines = 0
        }
    }

}
