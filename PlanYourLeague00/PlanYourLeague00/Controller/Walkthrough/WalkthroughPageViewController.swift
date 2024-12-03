//
//  WalkthroughPageViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/4/24.
//

import UIKit

protocol WalkthroughPageviewControllerDelegate: AnyObject {
    func didUpdatePageIndex(currentIndex:Int)
}

class WalkthroughPageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dataSource = self
        delegate = self
        
        // Create the first walkthrough screen
        if let startingViewController = contentViewController(at: 0) {
            setViewControllers([startingViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    weak var walkthroughDelegate: WalkthroughPageviewControllerDelegate?
    
    var pageHeadings = ["CREATE YOUR OWN LEAGUE", "EASILY MANAGEMENT", "SHARE TO OTHERS"]
    var pageImages = ["onboarding-1","onboarding-2","onboarding-3"]
    var pageSubHeadings = ["Turn your league idea to real league","Magage you data with intelligent system", "Share your league to others to make it more popular"]
    var currentIndex = 0
    
    func forwardPage() {
        currentIndex += 1
        if let nextViewController = contentViewController(at: currentIndex) {
            setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
        }
    }
}

extension WalkthroughPageViewController: UIPageViewControllerDataSource{
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! WalkthroughContentViewController).index
        index += 1
        
        return contentViewController(at: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! WalkthroughContentViewController).index
        index -= 1
        
        return contentViewController(at: index)
    }
    
    func contentViewController(at index: Int) -> WalkthroughContentViewController? {
        if index < 0 || index >= pageHeadings.count {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let pageContentViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughContentViewController") as? WalkthroughContentViewController {
            pageContentViewController.heading = pageHeadings[index]
            pageContentViewController.subHeading = pageSubHeadings[index]
            pageContentViewController.imageFile = pageImages[index]
            pageContentViewController.index = index
            
            return pageContentViewController
            
        }
        return nil
    }
}

extension WalkthroughPageViewController: UIPageViewControllerDelegate{
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let contentViewController = pageViewController.viewControllers?.first as? WalkthroughContentViewController {
                currentIndex = contentViewController.index
                walkthroughDelegate?.didUpdatePageIndex(currentIndex: contentViewController.index)
            }
        }
    }
}

