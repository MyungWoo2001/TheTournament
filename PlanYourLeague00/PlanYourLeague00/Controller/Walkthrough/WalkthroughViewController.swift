//
//  WalkthroughViewController.swift
//  PlanYourLeague00
//
//  Created by Myung Woo on 9/4/24.
//

import UIKit

class WalkthroughViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    var walkthroughPageViewController: WalkthroughPageViewController?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        if let pageViewController = destination as? WalkthroughPageViewController {
            walkthroughPageViewController = pageViewController
            walkthroughPageViewController?.walkthroughDelegate = self
        }
    }
    
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet var nextButton: UIButton! {
        didSet {
            nextButton.layer.cornerRadius = 25.0
            nextButton.clipsToBounds = true
        }
    }
    @IBOutlet var skipButton: UIButton!
    
    @IBAction func skipButtonTapped(sender: UIButton){
        UserDefaults.standard.set(true,forKey: "walkthroughDone")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonTapped(sender: UIButton){
        if let index = walkthroughPageViewController?.currentIndex {
            switch index {
            case 0...1: 
                walkthroughPageViewController?.forwardPage()
            case 2:
                UserDefaults.standard.set(true, forKey: "walkthroughDone")
                dismiss(animated: true, completion: nil)
            default: break
            }
        }
        updateUI()
    }
    
    func updateUI(){
        if let index = walkthroughPageViewController?.currentIndex {
            switch index{
            case 0...1:
                nextButton.setTitle("NEXT", for: .normal)
                skipButton.isHidden = false
            case 2:
                nextButton.setTitle("GET STARTED", for: .normal)
                skipButton.isHidden = true
            default: break
            }
            
            pageControl.currentPage = index
        }
    }
}

extension WalkthroughViewController: WalkthroughPageviewControllerDelegate{
    func didUpdatePageIndex(currentIndex: Int) {
        updateUI()
    }
}
