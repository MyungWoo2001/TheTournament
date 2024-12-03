//
//  TournamentVieưController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 11/3/24.
//

import UIKit
import CloudKit

class LeagueDetailViewController: UIViewController,UITabBarDelegate {
    
    var tournament: CKRecord!
    var league: CKRecord!
    var tournamentAccess: Bool!
    
    @IBOutlet var tabBar: UITabBar!
    @IBOutlet var tournamentView: UIView!
    
    var infoTabNav: UINavigationController!
    var standTabNav: UINavigationController!
    var matchesTabNav: UINavigationController!
    
    var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tabBar.delegate = self
        
        let standItem = UITabBarItem(title: "Stand", image: UIImage(systemName: "list.number"), tag: 0)
        let matchesItem = UITabBarItem(title: "Match", image: UIImage(systemName: "sportscourt"), tag: 1)
                
        tabBar.items = [standItem, matchesItem]
        
        tabBar.selectedItem = standItem
        switchToViewController(at: 0)
        
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            switch item.tag {
            case 0:
                switchToViewController(at: 0)
            case 1:
                switchToViewController(at: 1)
            default:
                break
            }
        }
    
    private func switchToViewController(at index: Int) {
        
        // Xóa view controller hiện tại nếu có
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        
        // Khởi tạo và hiển thị view controller mới
        let storyboard = UIStoryboard(name: "Tournament", bundle: nil)
        switch index {
        case 0:
            standTabNav = storyboard.instantiateViewController(withIdentifier: "StandTabNavigationController") as? UINavigationController
            if let standViewController = standTabNav.viewControllers.first as? LeagueStandViewController {
                standViewController.tournament = self.tournament
                standViewController.league = self.league
                standViewController.tournamentAccess = self.tournamentAccess
            }
            currentViewController = standTabNav
        case 1:
            matchesTabNav = storyboard.instantiateViewController(withIdentifier: "MatchesTabNavigationController") as? UINavigationController
            if let matchesViewController = matchesTabNav.viewControllers.first as? LeagueMatchesTableViewController {
                matchesViewController.tournament = self.tournament
                matchesViewController.league = self.league
                matchesViewController.tournamentAccess = self.tournamentAccess
            }
            currentViewController = matchesTabNav
        default:
            return
        }
        
        // Thêm view controller mới vào main view
        guard let newVC = currentViewController else { return }
        addChild(newVC)
        tournamentView.addSubview(newVC.view)
        newVC.view.frame = tournamentView.bounds
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newVC.didMove(toParent: self)

    }

}
