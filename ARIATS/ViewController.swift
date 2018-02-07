//
//  StudentViewController.swift
//  ARIATS
//
//  Created by Ravern Koh on 29/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var name: UITextField!
    @IBOutlet var status: UIButton!
    @IBOutlet var studentsTable: UITableView!
    
    var isTeacher = false
    var node: MeshNetworkNode!
    
    var students: [String] = []

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

    func nodeDidStartSearchingForTeacher(_ node: MeshNetworkNode) {
        status.setTitle("Searching for teacher...", for: .normal)
    }
    
    func nodeDidGiveUpSearchingForTeacher(_ node: MeshNetworkNode) {
        status.setTitle("Searching for peers...", for: .normal)
    }
    
    func nodeDidStartEgress(_ node: MeshNetworkNode) {
        if isTeacher {
            status.setTitle("Taking attendance...", for: .normal)
        }
    }
    
    func node(_ node: MeshNetworkNode, didConnectToPeer peer: String) {
        if isTeacher {
            students.append(peer)
            studentsTable.reloadData()
        } else {
            if peer == MeshNetworkNodeTeacherID {
                status.setTitle("Connected to Teacher!", for: .normal)
            } else {
                status.setTitle("Connected to \(peer)!", for: .normal)
            }
        }
    }
    
    func nodeDidSendToken(_ node: MeshNetworkNode) {
        status.setTitle("Taking attendance...", for: .normal)
    }
    
    func nodeWasSuccessful(_ node: MeshNetworkNode) {
        status.setTitle("Attendance taken!", for: .normal)
        status.backgroundColor = .green
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        (cell.viewWithTag(1) as! UILabel).text = students[indexPath.row]
        return cell
    }
}
