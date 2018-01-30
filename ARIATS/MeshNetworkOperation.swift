//
//  MeshNetworkOperation.swift
//  ARIATS
//
//  Created by Ravern Koh on 30/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import Foundation

enum MeshNetworkOperation {
    case tokenRequest
    case token(String) // contains the token
    case acknowledge(String) // contains the destination
    case invalid
    
    init(data: Data) {
        let str = String(data: data, encoding: .utf8)!
        let comps = str.split(separator: "|")
        
        switch comps[0] {
        case "TOKREQ": self = .tokenRequest
        case "TOK": self = .token(String(comps[1]))
        case "ACK": self = .acknowledge(String(comps[1]))
        default: self = .invalid
        }
    }
    
    var data: Data {
        switch self {
        case .tokenRequest: return "TOKREQ".data(using: .utf8)!
        case .token(let token): return "TOK|\(token)".data(using: .utf8)!
        case .acknowledge(let dest): return "ACK|\(dest)".data(using: .utf8)!
        case .invalid: return "TOKREQ".data(using: .utf8)!
        }
    }
}
