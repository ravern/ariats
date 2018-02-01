//
//  MeshNetworkOperation.swift
//  ARIATS
//
//  Created by Ravern Koh on 30/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import Foundation

enum MeshNetworkOperation {
    case joined(String) // contains the token of newly joined member
    case success(String) // contains the destination
    case invalid
    
    init(data: Data) {
        let str = String(data: data, encoding: .utf8)!
        let comps = str.split(separator: "|")
        let id = comps[0]
        let data = comps[1]
        
        switch id {
        case "JOINED": self = .joined(String(data))
        case "SUCCESS": self = .success(String(data))
        default: self = .invalid
        }
    }
    
    var data: Data {
        switch self {
        case .joined(let dest): return "JOINED|\(dest)".data(using: .utf8)!
        case .success(let dest): return "SUCCESS|\(dest)".data(using: .utf8)!
        case .invalid: return "INVALID".data(using: .utf8)!
        }
    }
}
