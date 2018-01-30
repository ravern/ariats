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
let MeshNetworkNodePeerSearchDuration = 3

class MeshNetworkNode: NSObject {
    
    private var name: String!
    var delegate: MeshNetworkNodeDelegate!
    private(set) var ingress = -1
    private(set) var egress = -1
    private var curIngress = 0
    private var curEgress = 0

    private var browser: MCNearbyServiceBrowser!
    private var browserPeers: [MCPeerID] = []
    private var ingressSession: MCSession!
    
    private var advertiser: MCNearbyServiceAdvertiser!
    private var egressSession: MCSession!

    init(name: String, delegate: MeshNetworkNodeDelegate? = nil, ingress: Int, egress: Int) {
        super.init()
        
        self.name = name
        self.delegate = delegate
        self.ingress = ingress
        self.egress = egress
        
        startIngress()
        if name == MeshNetworkNodeTeacherID {
            startEgress()
        }

        // Try to search for the teacher for a while
        RunLoop.current.add(Timer(timeInterval: TimeInterval(MeshNetworkNodeTeacherSearchDuration), repeats: false) { _ in
            // Give up on trying to search for a teacher
            NSLog("ARIATSAPP: Browser gave up on finding a teacher, connecting to peers instead...")
            
            // Connect to peers instead
            RunLoop.current.add(Timer(timeInterval: TimeInterval(MeshNetworkNodePeerSearchDuration), repeats: true) { _ in
                // Only run if have browser peers
                guard self.browserPeers.count > 0 else {
                    return
                }
                
                while self.curIngress < ingress {
                    self.curIngress += 1

                    // Invite the first peer and requeue
                    let peer = self.browserPeers.removeFirst()
                    self.browser.invitePeer(peer, to: self.ingressSession, withContext: nil, timeout: 5.0)
                    self.browserPeers.append(peer)
                    NSLog("ARIATSAPP: Browser invited \(peer.displayName)")
                }
            }, forMode: RunLoopMode.defaultRunLoopMode)
        }, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func startIngress() {
        if ingress > 0 {
            let ingressPeerID = MCPeerID(displayName: name)
            
            ingressSession = MCSession(peer: ingressPeerID, securityIdentity: nil, encryptionPreference: .none)
            ingressSession.delegate = self
            
            browser = MCNearbyServiceBrowser(peer: ingressPeerID, serviceType: MeshNetworkNodeServiceType)
            browser.delegate = self
            browser.startBrowsingForPeers()
            NSLog("ARIATSAPP: Browser started browsing")
        }
    }
    
    func startEgress() {
        if egress > 0 {
            let egressPeerID = MCPeerID(displayName: name)
            
            egressSession = MCSession(peer: egressPeerID, securityIdentity: nil, encryptionPreference: .none)
            egressSession.delegate = self
            
            advertiser = MCNearbyServiceAdvertiser(peer: egressPeerID, discoveryInfo: nil, serviceType: MeshNetworkNodeServiceType)
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            NSLog("ARIATSAPP: Advertiser started advertising")
        }
        
    }
}

extension MeshNetworkNode: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("ARIATSAPP: Browser failed to start browsing due to \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Don't connect to self
        guard peerID.displayName != name else {
            return
        }
        
        NSLog("ARIATSAPP: Browser found \(peerID.displayName)")
        
        // Invite immediately if teacher and don't add to buffer
        if peerID.displayName == MeshNetworkNodeTeacherID {
            curIngress = ingress
            browser.invitePeer(peerID, to: ingressSession, withContext: nil, timeout: 5.0)
            NSLog("ARIATSAPP: Browser invited \(peerID.displayName)")
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
        if session == egressSession {
            if state == .notConnected {
                curEgress -= 1
                NSLog("ARIATSAPP: Session (egress) disconnected peer \(peerID.displayName)")
            } else if state == .connected {
                NSLog("ARIATSAPP: Session (egress) connected to peer \(peerID.displayName)")
            }
        } else if session == ingressSession {
            if state == .notConnected {
                if peerID.displayName == MeshNetworkNodeTeacherID {
                    curIngress = 0
                } else {
                    curIngress -= 1
                }
                NSLog("ARIATSAPP: Session (ingress) declined by peer \(peerID.displayName)")
            } else if state == .connected {
                startEgress()
                NSLog("ARIATSAPP: Session (ingress) connected to peer \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
}

protocol MeshNetworkNodeDelegate {
}
