//
//  StudentViewController.swift
//  ARIATS
//
//  Created by Ravern Koh on 29/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import UIKit

class StudentViewController: UIViewController {
    
    @IBOutlet var status: UILabel!
    @IBOutlet var name: UITextField!
    
    var node: MeshNetworkNode!
    var node2: MeshNetworkNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        node = MeshNetworkNode(name: "Node1")
        node2 = MeshNetworkNode(name: "Node2")
    }
    
    @IBAction func takeAttendance(_ sender: UIButton) {
    }
}
