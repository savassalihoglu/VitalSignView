//
//  VitalSignView.swift
//  Pods-VitalSignView_Example
//
//  Created by Savaş Salihoğlu on 29.06.2021.
//

import UIKit

@IBDesignable public class VitalSignView : UIView {
    
    @IBInspectable var signColor:UIColor = .green{
        didSet{
            config.signColor = signColor
        }
    }
    @IBInspectable var singBackgroundColor:UIColor = .black {
        didSet{
            config.backgroundColor = singBackgroundColor
            cursorColor = singBackgroundColor
        }
    }
    @IBInspectable var cursorColor:UIColor = .black {
        didSet{
            config.cursorColor = cursorColor
        }
    }
    @IBInspectable var signLineWidth:CGFloat = 1{
        didSet{
            config.signLineWidth = signLineWidth
        }
    }
    @IBInspectable var paddingVertical:CGFloat = 8.0{
        didSet{
            config.paddingVertical = paddingVertical
        }
    }
    @IBInspectable var dataFrequency:Double = 1.0{
        didSet{
            config.dataFrequency = dataFrequency
        }
    }
    @IBInspectable var visibleSignTimeInterval:Double = 1{
        didSet{
            config.visibleSignTimeInterval = visibleSignTimeInterval
        }
    }
    
    
    private var config = Config(){
        didSet{
            setup()
        }
    }
    
    private let ups:Double = 60
    private var slipFrequency:Double = 1.0
    
    private var oneDataWidth:CGFloat = 0.0
    private var cursorStepWidth:CGFloat = 0
    private var cursorWidth:CGFloat = 0
    private var verticalMaxHeight:CGFloat = 0.0
    
    private var maxDataCount:Int = 0
    private var currentDataIndex:Int = 0
    private var maxCursorStepCount:Int = 0
    private var currentCursorIndex:Int = 0
    
    private var timer:Timer?
    private let queue = DispatchQueue(label: "vitalsign.serial.queue")
    private var data:[Float] = [Float]()
    private var receivedData = [Float]()
    
    private var signDrawingLayer: CAShapeLayer?
    private var cursorDrawingLayer:CAShapeLayer?
    
    private var dataAmount = 0
    private var subLayers = [CAShapeLayer]()
    private var correctionOffset = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    
    func setup(){
        clipsToBounds = true
        maxDataCount = Int(config.dataFrequency*config.visibleSignTimeInterval)
        oneDataWidth = frame.size.width / CGFloat(maxDataCount)
        slipFrequency = ups/config.dataFrequency
        cursorStepWidth = oneDataWidth / CGFloat(slipFrequency)
        cursorWidth = .maximum(oneDataWidth,frame.size.width/12.0)
        maxCursorStepCount = Int(Double(maxDataCount) * slipFrequency )
        verticalMaxHeight = (frame.size.height - config.paddingVertical) / 2.0
        backgroundColor = config.backgroundColor
        data.removeAll()
        data.append(contentsOf: Array.init(repeating: 0, count: Int(maxDataCount)))
    }
    
    public func start(){
        invalidate()
        if ups >= config.dataFrequency {
            upsGreaterThenDataFrequency()
        }else{
            dataFrequencyGreaterThenUps()
        }
    }
    public func invalidate(){
        timer?.invalidate()
        layer.sublayers?.forEach{
            $0.removeFromSuperlayer()
        }
    }
    public func setConfig(_ config:Config){
        self.config = config
    }
    
    public func sendData(d:Float){
        queue.sync { [unowned self] in
            if d >= -1 && d <= 1 {
                receivedData.append(d)
            }
        }
    }
    
    public override func draw(_ layer: CALayer, in ctx: CGContext) {
        
        let signDrawingLayer = self.signDrawingLayer ?? CAShapeLayer()
        let cursorDrawingLayer = self.cursorDrawingLayer ?? CAShapeLayer()
        
        signDrawingLayer.contentsScale = UIScreen.main.scale
        cursorDrawingLayer.contentsScale = UIScreen.main.scale
        
        let signLinePath = UIBezierPath()
        
        (currentDataIndex-dataAmount-correctionOffset..<currentDataIndex).enumerated().forEach{ (i,j) in
            if j < data.count {
                if i == 0 {
                    signLinePath.move(to: CGPoint(x: CGFloat(j+2)*oneDataWidth, y: (frame.size.height/2.0 ) - (verticalMaxHeight*CGFloat( j < 0 ? 0 : data[j] )) ))
                }else{
                    signLinePath.addLine(to: CGPoint(x: CGFloat(j+2)*oneDataWidth , y: (frame.size.height/2.0) - (verticalMaxHeight*CGFloat(j < 0 ? 0 : data[j])) ))
                }
            }
            
        }
        signDrawingLayer.path = signLinePath.cgPath
        signDrawingLayer.lineWidth = config.signLineWidth
        signDrawingLayer.lineCap = .round
        signDrawingLayer.strokeColor = config.signColor.cgColor
        
        
        let cursorPath=UIBezierPath(rect: CGRect(x: (CGFloat(currentCursorIndex) * cursorStepWidth) , y: 0, width: cursorWidth, height: self.frame.height))
        cursorDrawingLayer.path = cursorPath.cgPath
        cursorDrawingLayer.lineCap = .round
        cursorDrawingLayer.fillColor = config.cursorColor.cgColor
        
        
        if self.signDrawingLayer == nil {
            self.signDrawingLayer = signDrawingLayer
            layer.addSublayer(signDrawingLayer)
        }
        
    
        if self.cursorDrawingLayer == nil {
            self.cursorDrawingLayer = cursorDrawingLayer
            self.cursorDrawingLayer?.zPosition = CGFloat(maxCursorStepCount) * 2.0
            layer.addSublayer(cursorDrawingLayer)
        }
        
    }
    
    func updateFlattenedLayer() {
        guard let drawingLayer = signDrawingLayer,
              let optionalDrawing = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(
                NSKeyedArchiver.archivedData(withRootObject: drawingLayer, requiringSecureCoding: false))
                as? CAShapeLayer else { return }
        self.layer.addSublayer(optionalDrawing)
    }
    
    func dataFrequencyGreaterThenUps(){
        
        correctionOffset = 2
        currentDataIndex = maxDataCount
        var lastDataIndex = 0
        var lastValue:Float = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/ups, repeats: true) { [unowned self] timer in
            
            if currentCursorIndex >= maxCursorStepCount {
                currentCursorIndex = 0
                lastDataIndex = 0
                
            }
            currentCursorIndex += 1
            queue.sync {
                currentDataIndex = Int((Double(currentCursorIndex) / slipFrequency))
                if lastDataIndex > currentDataIndex {
                    currentDataIndex = lastDataIndex
                 }
                if currentDataIndex >= data.count { currentDataIndex = 0 }
                
                if currentDataIndex > lastDataIndex {
                    if Double((currentDataIndex-lastDataIndex))/Double(maxDataCount) > 0.1 {
                        lastValue = 0
                    }
                    for i in lastDataIndex..<currentDataIndex  {
                        data[i] = lastValue
                    }
                }
                
                receivedData.forEach {
                    data[currentDataIndex] = $0
                    currentDataIndex += 1
                    if currentDataIndex >= data.count { currentDataIndex = 0 }
                }
                
                dataAmount = receivedData.count
                lastValue = receivedData.last ?? 0
                receivedData.removeAll()
                
                lastDataIndex = currentDataIndex
            }
            if layer.sublayers?.count ?? 0 >= maxCursorStepCount {
                if  layer.sublayers?.count ?? 0 > 2 {
                    layer.sublayers?[2].removeFromSuperlayer()
                }
            }
            layer.setNeedsDisplay()
            updateFlattenedLayer()
        }
    }
    func upsGreaterThenDataFrequency(){
        
        correctionOffset = 1
        
        var lastDataSendTime:Double = Date().timeIntervalSince1970
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/ups, repeats: true) { [unowned self] timer in
            
            if lastDataSendTime + (1.0 / config.dataFrequency) <= Date().timeIntervalSince1970 {
                lastDataSendTime = Date().timeIntervalSince1970
                currentDataIndex += 1
                if currentDataIndex >= data.count { currentDataIndex = 0 }
                currentCursorIndex = Int(Double(currentDataIndex) * slipFrequency)
                queue.sync {
                    data[currentDataIndex] = receivedData.last ?? 0
                    dataAmount = 1
                    receivedData.removeAll()
                }
            }
            
            if currentCursorIndex >= maxCursorStepCount {
                currentCursorIndex = 0
            }
            currentCursorIndex += 1
            
            if layer.sublayers?.count ?? 0 >= maxCursorStepCount - Int(slipFrequency) {
                if  layer.sublayers?.count ?? 0 > 2 {
                    layer.sublayers?[2].removeFromSuperlayer()
                }
            }
            layer.setNeedsDisplay()
            updateFlattenedLayer()
        
        }
    }
    
    

    public class Config {
        
        var signColor:UIColor = .green
        var backgroundColor:UIColor = .black
        var cursorColor:UIColor = .black
        var paddingVertical:CGFloat = 8
        var signLineWidth:CGFloat = 1.0
        var dataFrequency:Double = 1
        var visibleSignTimeInterval:Double = 1
        
        init(){
            
        }
        
        init(builder:Builder){
            signColor = builder.signColor ?? UIColor.green
            backgroundColor = builder.backgroundColor ?? UIColor.black
            cursorColor = builder.cursorColor ?? backgroundColor
            paddingVertical = builder.paddingVertical ?? 8
            signLineWidth = builder.signLineWidth ?? signLineWidth
            dataFrequency = builder.dataFrequency ?? 1
            visibleSignTimeInterval = builder.visibleSignTimeInterval ?? 1
        }
        
        public class Builder {
            
            var signColor:UIColor?
            var backgroundColor:UIColor?
            var cursorColor:UIColor?
            var signLineWidth:CGFloat?
            var paddingVertical:CGFloat?
            var dataFrequency:Double?
            var visibleSignTimeInterval:Double?
            
            public init(){
                
            }
            
            public func build()->Config {
                return Config(builder: self)
            }
            
            public func setSignColor(_ color:UIColor)->Builder{
                signColor = color
                return self
            }
            public func setBackgroundColor(_ color:UIColor)->Builder{
                backgroundColor = color
                return self
            }
            public func setCursorColor(_ color:UIColor)->Builder{
                cursorColor = color
                return self
            }
            public func setSignLineWidth(_ width:CGFloat)->Builder{
                signLineWidth = width
                return self
            }
            public func setPaddingVertical(_ padding:CGFloat)->Builder{
                paddingVertical = padding
                return self
            }
            public func setDataFrequency(hertz:Double)->Builder{
                dataFrequency = hertz
                return self
            }
            public func setVisibleSignTimeInterval(seconds:Double)->Builder{
                visibleSignTimeInterval = seconds
                return self
            }
            
        }
    }
}


