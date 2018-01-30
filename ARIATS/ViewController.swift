//
//  StudentViewController.swift
//  ARIATS
//
//  Created by Ravern Koh on 29/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var status: UILabel!
    @IBOutlet var name: UITextField!
    
    var isTeacher = false
    var node: MeshNetworkNode!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if name == nil {
            isTeacher = true
        }
    }
    
    @IBAction func takeAttendance(_ sender: UIButton) {
        var name: String?
        var ingress: Int
        
        if isTeacher {
            name = MeshNetworkNodeTeacherID
            ingress = 0
        } else {
            name = self.name.text
            ingress = 1
        }

        if let name = name {
            node = MeshNetworkNode(name: name, delegate: self, ingress: ingress, egress: 3)
            sender.isEnabled = false
        }
    }
}

extension ViewController: MeshNetworkNodeDelegate {
}
