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
            node = MeshNetworkNode(name: name, delegate: self, ingress: ingress, egress: 1)
            sender.isEnabled = false
        }
    }
}

extension ViewController: MeshNetworkNodeDelegate {

    func nodeDidStartSearchingForTeacher(_ node: MeshNetworkNode) {
        status.text = "Searching for teacher..."
    }
    
    func nodeDidGiveUpSearchingForTeacher(_ node: MeshNetworkNode) {
        status.text = "Teacher not available, connecting to peers..."
    }
    
    func nodeDidStartEgress(_ node: MeshNetworkNode) {
        if isTeacher {
            status.text = "Listening for connections..."
        }
    }
    
    func node(_ node: MeshNetworkNode, didConnectToPeer peer: String) {
        if peer == MeshNetworkNodeTeacherID {
            status.text = "Connected to Teacher!"
        } else {
            status.text = "Connected to \(peer)!"
        }
    }
    
    func nodeDidSendToken(_ node: MeshNetworkNode) {
        status.text = "Taking attendance..."
    }
    
    func nodeDidGetAcknowledged(_ node: MeshNetworkNode) {
        status.text = "Attendance taken!"
        view.backgroundColor = .green
    }
}
