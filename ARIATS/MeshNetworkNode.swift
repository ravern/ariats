//
//  MeshNetworkNode.swift
//  ARIATS
//
//  Created by Ravern Koh on 29/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import MultipeerConnectivity
import Foundation

let MeshNetworkNodeServiceType = "ariats-net"
let MeshNetworkNodeTeacherID = "TEACHER"
let MeshNetworkNodeTeacherSearchDuration = 10
let MeshNetworkNodeTeacherPollInterval = 1
let MeshNetworkNodePeerSearchInterval = 0.5
let MeshNetworkNodeMinimumDuration = 5

// CURRENT BUGS/LIMITATIONS
//     1. If the teacher gets cut off halfway through, the peers connected to the teacher will start
//        connecting to their peers instead as the giveUp() function if called. This causes the network
//        to form cycles and fail.

class MeshNetworkNode: NSObject {
    
    private var name: String!
    var delegate: MeshNetworkNodeDelegate?
    private(set) var ingress = -1
    private(set) var egress = -1
    private var curIngress = 0
    private var curEgress = 0

    private var browser: MCNearbyServiceBrowser!
    private var browserPeers: [MCPeerID] = []
    private var ingressSession: MCSession!
    
    private var advertiser: MCNearbyServiceAdvertiser!
    private var egressSession: MCSession!

    private var hasGivenUp = false
    
    // TEACHER STUFF
    private var students: [(String, Double)] = []
    
    init(name: String, delegate: MeshNetworkNodeDelegate? = nil, ingress: Int, egress: Int) {
        super.init()
        
        self.name = name
        self.delegate = delegate
        self.ingress = ingress
        self.egress = egress
        
        startIngress()
        if name == MeshNetworkNodeTeacherID {
            startEgress()
            
            RunLoop.current.add(Timer(timeInterval: TimeInterval(MeshNetworkNodeTeacherPollInterval), repeats: true) { _ in
                var i = 0
                for (student, time) in self.students {
                    if Int(Date().timeIntervalSince1970 - time) > MeshNetworkNodeMinimumDuration {
                        self.send(session: self.egressSession, peers: self.egressSession.connectedPeers.filter { $0.displayName.nodeDirection == "ingress" }, data: MeshNetworkOperation.success(student).data)
                        self.students.remove(at: i)
                        i -= 1
                    }
                    i += 1
                }
            }, forMode: RunLoopMode.defaultRunLoopMode)
        }

        // Try to search for the teacher for a while
        RunLoop.current.add(Timer(timeInterval: TimeInterval(MeshNetworkNodeTeacherSearchDuration), repeats: false) { _ in
            self.giveUp()
        }, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func startIngress() {
        if ingress > 0 {
            let ingressPeerID = MCPeerID(displayName: "\(name!)-ingress")
            
            ingressSession = MCSession(peer: ingressPeerID, securityIdentity: nil, encryptionPreference: .none)
            ingressSession.delegate = self
            
            browser = MCNearbyServiceBrowser(peer: ingressPeerID, serviceType: MeshNetworkNodeServiceType)
            browser.delegate = self
            browser.startBrowsingForPeers()
            NSLog("ARIATSAPP: Browser started browsing")
            
            delegate?.nodeDidStartSearchingForTeacher(self)
        }
    }
    
    func startEgress() {
        if egress > 0 {
            let egressPeerID = MCPeerID(displayName: "\(name!)-egress")
            
            egressSession = MCSession(peer: egressPeerID, securityIdentity: nil, encryptionPreference: .none)
            egressSession.delegate = self
            
            advertiser = MCNearbyServiceAdvertiser(peer: egressPeerID, discoveryInfo: nil, serviceType: MeshNetworkNodeServiceType)
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            NSLog("ARIATSAPP: Advertiser started advertising")
            
            delegate?.nodeDidStartEgress(self)
        }
    }
    
    func giveUp() {
        if !hasGivenUp && curIngress < ingress {
            // Give up on trying to search for a teacher
            DispatchQueue.main.async {
                self.delegate?.nodeDidGiveUpSearchingForTeacher(self)
            }
            NSLog("ARIATSAPP: Browser gave up on finding a teacher, connecting to peers instead...")

            // Connect to peers instead
            DispatchQueue.main.async {
                RunLoop.current.add(Timer(timeInterval: TimeInterval(MeshNetworkNodePeerSearchInterval), repeats: true) { _ in
                    // Only run if have browser peers
                    guard self.browserPeers.count > 0 else {
                        return
                    }
                    
                    while self.curIngress < self.ingress {
                        self.curIngress += 1
                        
                        // Invite the first peer and requeue
                        let peer = self.browserPeers.removeFirst()
                        self.browser.invitePeer(peer, to: self.ingressSession, withContext: nil, timeout: 5.0)
                        self.browserPeers.append(peer)
                        NSLog("ARIATSAPP: Browser invited \(peer.displayName)")
                    }
                }, forMode: RunLoopMode.defaultRunLoopMode)
            }
        }
        
        hasGivenUp = true
    }
    
    func send(session: MCSession, peers: [MCPeerID], data: Data) {
        guard peers.count != 0 else {
            return
        }

        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch let error {
            NSLog("ARIATSAPP: Session failed to send data due to \(error)")
        }
    }
}

extension MeshNetworkNode: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("ARIATSAPP: Browser failed to start browsing due to \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Don't connect to self
        guard peerID.displayName.nodeName != name.nodeName else {
            return
        }
        
        NSLog("ARIATSAPP: Browser found \(peerID.displayName)")
        
        // Invite immediately if teacher and don't add to buffer
        if peerID.displayName.nodeName == MeshNetworkNodeTeacherID {
            curIngress = ingress
            browser.invitePeer(peerID, to: ingressSession, withContext: nil, timeout: 5.0)
            NSLog("ARIATSAPP: Browser invited \(peerID.displayName)")
            
            return
        }
            
        // Add to buffer
        browserPeers.append(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Don't connect to self
        guard peerID.displayName != name else {
            return
        }
        
        NSLog("ARIATSAPP: Browser lost \(peerID.displayName)")
        
        // Remove from buffer
        if let idx = browserPeers.index(of: peerID) {
            browserPeers.remove(at: idx)
        }
    }
}

extension MeshNetworkNode: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("ARIATSAPP: Advertiser failed to start advertising due to \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept immediately if egress available
        if curEgress < egress {
            curEgress += 1
            invitationHandler(true, egressSession)
            NSLog("ARIATSAPP: Advertiser accepted \(peerID.displayName)")
        } else {
            invitationHandler(false, egressSession)
            NSLog("ARIATSAPP: Advertiser did not accept \(peerID.displayName)")
        }
    }
}

extension MeshNetworkNode: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if session == egressSession && peerID.displayName.nodeDirection == "ingress" {
            if state == .notConnected {
                NSLog("ARIATSAPP: Session (egress) disconnected peer \(peerID.displayName)")
                
                curEgress -= 1
            } else if state == .connected {
                NSLog("ARIATSAPP: Session (egress) connected to peer \(peerID.displayName)")
            }
        } else if session == ingressSession && peerID.displayName.nodeDirection == "egress" {
            if state == .notConnected {
                NSLog("ARIATSAPP: Session (ingress) declined by peer \(peerID.displayName)")
                
                if peerID.displayName.nodeName == MeshNetworkNodeTeacherID {
                    curIngress = 0
                    
                    // Since declined by teacher, connect to peers instead
                    giveUp()
                } else {
                    curIngress -= 1
                }
            } else if state == .connected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.delegate?.node(self, didConnectToPeer: peerID.displayName.nodeName)
                }
                NSLog("ARIATSAPP: Session (ingress) connected to peer \(peerID.displayName)")

                startEgress()
                
                if name != MeshNetworkNodeTeacherID {
                    send(session: ingressSession, peers: ingressSession.connectedPeers.filter { $0.displayName.nodeDirection == "egress" }, data: MeshNetworkOperation.joined(name).data)
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let op = MeshNetworkOperation(data: data)
        NSLog("ARIATSAPP: Session received operation \(op)")
        
        if session == ingressSession {
            if name != MeshNetworkNodeTeacherID {
                if case .success(let name) = op {
                    if self.name == name {
                        // Success!
                        DispatchQueue.main.async {
                            self.delegate?.nodeWasSuccessful(self)
                        }
                        return
                    }
                }
            }
            send(session: egressSession, peers: egressSession.connectedPeers.filter { $0.displayName.nodeDirection == "ingress" }, data: op.data)
        } else if session == egressSession {
            if name == MeshNetworkNodeTeacherID {
                if case .joined(let name) = op {
                    // Add student to state if not already
                    if (self.students.filter { $0.0 == name }).count == 0 {
                        self.students.append((name, Date().timeIntervalSince1970))
                    }
                }
                return
            }
            if ingressSession != nil {
                send(session: ingressSession, peers: ingressSession.connectedPeers.filter { $0.displayName.nodeDirection == "egress" }, data: op.data)
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
}

private extension String {
    
    var nodeName: String {
        return String(split(separator: "-")[0])
    }
    
    var nodeDirection: String {
        return String(split(separator: "-")[1])
    }
}

protocol MeshNetworkNodeDelegate {
    
    func nodeDidStartSearchingForTeacher(_ node: MeshNetworkNode)
    
    func nodeDidGiveUpSearchingForTeacher(_ node: MeshNetworkNode)
    
    func nodeDidStartEgress(_ node: MeshNetworkNode)
    
    func node(_ node: MeshNetworkNode, didConnectToPeer peer: String)
    
    func nodeDidSendToken(_ node: MeshNetworkNode)
    
    func nodeWasSuccessful(_ node: MeshNetworkNode)
}
