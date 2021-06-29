//
//  ViewController.swift
//  VitalSignView
//
//  Created by mustafasavassalihoglu@gmail.com on 06/28/2021.
//  Copyright (c) 2021 mustafasavassalihoglu@gmail.com. All rights reserved.
//

import UIKit
import VitalSignView

class ViewController: UIViewController {

    @IBOutlet var ecgVitalSignView:VitalSignView!
    @IBOutlet var randomDataSignView:VitalSignView!
    
    var ecgDataTimer:Timer?
    var randomDataTimer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ECG Data vitalSignView
        ecgVitalSignView.setConfig(VitalSignView.Config.Builder()
                                    .setDataFrequency(hertz: 720.0)
                                    .setVisibleSignTimeInterval(seconds: 6)
                                    .setPaddingVertical(8.0)
                                    .setSignLineWidth(1.0)
                                    .setBackgroundColor(.black)
                                    .setSignColor(.green)
                                    .build())
        ecgVitalSignView.start()
        
        let data = loadEcgData()
        var index = 0
        ecgDataTimer = Timer.scheduledTimer(withTimeInterval: 1.0/720.0, repeats: true){ [unowned self] timer in
            if index >= data.count { index = 0 }
            ecgVitalSignView.sendData(d: data[index] )
            index += 1
        }
        
        
        //Random Data vitalSignView
        randomDataSignView.setConfig(VitalSignView.Config.Builder()
                                        .setDataFrequency(hertz: 1)
                                        .setVisibleSignTimeInterval(seconds: 8)
                                        .setPaddingVertical(4.0)
                                        .setSignLineWidth(2.0)
                                        .setSignColor(.yellow)
                                        .setBackgroundColor(.darkGray)
                                        .build())
        randomDataSignView.start()
        
        
        randomDataTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ [self] timer in
            randomDataSignView.sendData(d: Float.random(in: -1..<1))
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        ecgDataTimer?.invalidate()
        randomDataTimer?.invalidate()
        ecgVitalSignView.invalidate()
        randomDataSignView.invalidate()
    }
    
    
    func loadEcgData() -> [Float] {
       let decoder = JSONDecoder()
       guard
            let url = Bundle.main.url(forResource: "data", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let ecgData = try? decoder.decode([Float].self, from: data)
       else {
            return [Float]()
       }

        return ecgData
    }


}

