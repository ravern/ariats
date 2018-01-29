//
//  ViewController.swift
//  ARIATS
//
//  Created by Ravern Koh on 28/1/18.
//  Copyright © 2018 Team Name. All rights reserved.
//

import UIKit
import BluetoothKit

class ViewController: UIViewController {
    
    let dataServiceUUID = UUID(uuidString: "24182491-8A25-47F1-9CBE-72C0FD42EF9F")!
    let dataServiceCharacteristicUUID = UUID(uuidString: "0A006ED0-BC5F-4AAA-841B-838E7905561D")!
    let localName = "ARIATS"
    
    var central: BKCentral!
    var peripheral: BKPeripheral!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializePeripheral()
        initializeCentral()
    }
    
    func initializePeripheral() {
        peripheral = BKPeripheral()
        let peripheralConfiguration = BKPeripheralConfiguration(
            dataServiceUUID: dataServiceUUID,
            dataServiceCharacteristicUUID: dataServiceCharacteristicUUID,
            localName: localName
        )
        do {
            try peripheral.startWithConfiguration(peripheralConfiguration)
        } catch let error {
            print(error)
        }
    }
    
    func initializeCentral() {
        central = BKCentral()
        central.addAvailabilityObserver(self)
        let centralConfiguration = BKConfiguration(
            dataServiceUUID: dataServiceUUID,
            dataServiceCharacteristicUUID: dataServiceCharacteristicUUID
        )
        do {
            try central.startWithConfiguration(centralConfiguration)
        } catch let error {
            print(error)
        }
    }
}

extension ViewController: BKAvailabilityObserver {
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability) {
        switch availability {
        case .available:
            central.scanContinuouslyWithChangeHandler({ (changes, discovery) in
                print("Changes: \(changes)")
                print("Discovery: \(discovery)")
            }, stateHandler: { (state) in
                print("State: \(state)")
            }, errorHandler: { (error) in
                print("Error: \(error)")
            })
        case .unavailable(let cause):
            print(cause)
        }
    }
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause) {
    }
}
