//
//  InterfaceController.swift
//  Automatic MVP Attempt 1 WatchKit Extension
//
//  Created by Julien Paid Developer on 9/17/22.
//

import WatchKit
import Foundation
import CoreML
import CoreMotion
import WatchConnectivity
import simd

struct ModelConstants
{
    static let predictionWindowSize = 100
    static let sensorsUpdateInterval = 1.0 / 50.0
    static let stateInLength = 400
}


class InterfaceController: WKInterfaceController, WKExtendedRuntimeSessionDelegate,WCSessionDelegate {
    
    //Curr Data
    var accX : [Double] = []
    var accY : [Double] = []
    var accZ : [Double] = []
    var rotX : [Double] = []
    var rotY : [Double] = []
    var rotZ : [Double] = []
    var degreesList : [Int] = []
    var magnitudeList : [Double] = []
    var headingList : [Double] = []
    var yawList : [Int] = []
    var pitchList : [Int] = []
    
    
    var attitudeList : [CMAttitude] = []
    
    
    //AI Data
    let accelDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let accelDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let accelDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)

    let gyroDataX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gyroDataY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let gyroDataZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    var stateOutput = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)
    
    
    var model = BestModel()
    
    
    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Extended session invalidated")
      
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession){
        print("Extended session started")
        intervalCounter = 0.0
        startRecording()
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended session about to expire")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WC Session is completed")
    }
    
    
   
    
    @IBOutlet var startButton : WKInterfaceButton!
    @IBOutlet var releaseLabel : WKInterfaceLabel!
    
    //Motion
    var motionManager = CMMotionManager()
    var session : WKExtendedRuntimeSession!
    
    
    //Variables
    var isAccelerometer : Bool = false
    var isDeviceMotion : Bool = false
    var paused: Bool = false
    
    
    //Recording
    var timer : Timer?
    let updateInterval = 50.0
    var intervalCounter = 0.0
    

    
    
    //Actions
    @IBAction func startButtonPressed()
    {
        if isDeviceMotion && isAccelerometer
        {
            WKInterfaceDevice().play(.success)
            session = WKExtendedRuntimeSession()
            session.delegate = self
            session.start()
            startButton.setAlpha(0.0)
        }
    }
    
    @IBAction func continueButtonPressed()
    {
        pushController(withName: "HomeInterfaceController", context: "Workout-Ended")
    }
    
    
    func startRecording()
    {
        if isDeviceMotion && isAccelerometer
        {
            timer = Timer(fire: Date(), interval: 1.0/updateInterval, repeats: true, block: { [self] (timer) in
                
                
                    let rotData = motionManager.deviceMotion
                    let accData = motionManager.accelerometerData
                    
                    let accelX = Double(round(100 * (accData?.acceleration.x)! ) / 100)
                    let accelY = Double(round(100 * (accData?.acceleration.y)! ) / 100)
                    let accelZ = Double(round(100 * (accData?.acceleration.z)! ) / 100)
                    let rotatX = Double(round(100 * (rotData?.rotationRate.x)! ) / 100)
                    let rotatY = Double(round(100 * (rotData?.rotationRate.y)! ) / 100)
                    let rotatZ = Double(round(100 * (rotData?.rotationRate.z)! ) / 100)
                    let heading = Double(round(100 * (rotData?.heading)!)/100)
                    
                    let angle = sqrtf(Float(accelX * accelX + accelY * accelY + accelZ * accelZ))
                    let degrees  = Double(round(100 * (Double(acosf(Float(accelZ)/angle)) * 180.0 / Double.pi - 90.0) / 100.0))
                    
                    let magnitude = sqrt(pow(accelX, 2) + pow(accelY, 2) + pow(accelZ, 2))
                
                    let rollR = Double((rotData?.attitude.roll)!)
                    let rollD = rollR * 180 / Double.pi
                    let roundedRoll = Int((Double(round(100 * rollD ) / 100)))
                
                    let pitchR = Double((rotData?.attitude.pitch)!)
                    let pitchD = pitchR * 180 / Double.pi
                    let roundedPitch = Int((Double(round(100 * pitchD ) / 100)))
                
                    let yawR = Double((rotData?.attitude.yaw)!)
                    let yawD = yawR * 180 / Double.pi
                    let roundedYaw = Int((Double(round(100 * yawD ) / 100)))
                
                    
                
               
                    
                    if intervalCounter <= 100
                    {
                        accX.append(accelX)
                        accY.append(accelY)
                        accZ.append(accelZ)
                        rotX.append(rotatX)
                        rotY.append(rotatY)
                        rotZ.append(rotatZ)
                        degreesList.append(roundedRoll)
                        magnitudeList.append(magnitude)
                        headingList.append(heading)
                        yawList.append(roundedYaw)
                        pitchList.append(roundedPitch)
                        attitudeList.append(motionManager.deviceMotion!.attitude)
                    }
                    else if intervalCounter >= 100
                    {
                        accX.remove(at: 0)
                        accY.remove(at: 0)
                        accZ.remove(at: 0)
                        rotX.remove(at: 0)
                        rotY.remove(at: 0)
                        rotZ.remove(at: 0)
                        degreesList.remove(at: 0)
                        magnitudeList.remove(at: 0)
                        headingList.remove(at: 0)
                        pitchList.remove(at: 0)
                        yawList.remove(at: 0)
                        attitudeList.remove(at: 0)
                        
                        pitchList.append(roundedPitch)
                        yawList.append(roundedYaw)
                        headingList.append(heading)
                        accX.append(accelX)
                        accY.append(accelY)
                        accZ.append(accelZ)
                        rotX.append(rotatX)
                        rotY.append(rotatY)
                        rotZ.append(rotatZ)
                        degreesList.append(roundedRoll)
                        magnitudeList.append(magnitude)
                    attitudeList.append(motionManager.deviceMotion!.attitude)
                        
                        
                        wrapIntoML()
                        
                        
                        if Predict() == "Shot"
                        {
                            WKInterfaceDevice().play(.success)
                            
                            
                           let angle = DeriveReleaseAngle()
                            
                            let initialAtt = attitudeList[0]
                            
                            let finalAtt = attitudeList[attitudeList.count - 1]
                            
                            initialAtt.multiply(byInverseOf: finalAtt)
                            
                            print(initialAtt)
                            
                            
                            releaseLabel.setText("Ang: \(angle)")
                    
                            Pause()
                            intervalCounter = 0
                            removeLists()
                        }
                        
                       
                        
                
                }
                
                intervalCounter += 1
                
                if paused
                {
                      intervalCounter = 0
                }
            })
            
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
        }
    }
    
    
    func DeriveReleaseAngle() -> Int
    {
        var streak = 0
        
        for i in 0...magnitudeList.count - 1
        {
            if magnitudeList[i] < 1.2
            {
                streak += 1
            }
            else
            {
                streak = 0
            }
            
            if streak >= 20
            {
                return Int(degreesList[i])
            }
        }
        
        
        return 0
    }
    
  
    
    func Pause()
    {
        paused = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.paused = false
        }
        
    }
         
    
    func removeLists()
    {
        FillAIModelArrays()
        rotX.removeAll()
        rotY.removeAll()
        rotZ.removeAll()
        accX.removeAll()
        accY.removeAll()
        accZ.removeAll()
        magnitudeList.removeAll()
        degreesList.removeAll()
        yawList.removeAll()
        pitchList.removeAll()
        attitudeList.removeAll()
    }
    
    func FillAIModelArrays()
    {
        for i in 0...ModelConstants.predictionWindowSize - 1
        {
            accelDataX[i] = 0 as NSNumber
            accelDataY[i] = 0 as NSNumber
            accelDataZ[i] = 0 as NSNumber
            gyroDataX[i] = 0 as NSNumber
            gyroDataY[i] = 0 as NSNumber
            gyroDataZ[i] = 0 as NSNumber
            stateOutput[i] = 0 as NSNumber
        }
    }
    
    
    func Predict()-> String
    {
       
       let modelPrediction = try! model.prediction(AccelerationX: accelDataX, AccelerationY: accelDataY, AccelerationZ: accelDataZ, RotationX: gyroDataX, RotationY: gyroDataY, RotationZ:gyroDataZ, stateIn: stateOutput)
         
        
        // Update the state vector
        self.stateOutput = modelPrediction.stateOut
        
        
        
        let prob = modelPrediction.labelProbability
        
        
        
        if prob["Shot"]! > 0.95
        {
           return "Shot"
            
        }
        else
        {
            return "Other"
        }
        
        
        
        return ""

    }

     
     
    
    
    func wrapIntoML()
    {
        for i in 0...ModelConstants.predictionWindowSize - 1
        {
            
            accelDataX[i] = accX[i] as NSNumber
            accelDataY[i] = accY[i] as NSNumber
            accelDataZ[i] = accZ[i] as NSNumber
            gyroDataX[i] = rotX[i] as NSNumber
            gyroDataY[i] = rotY[i] as NSNumber
            gyroDataZ[i] = rotZ[i] as NSNumber
        }
    }
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
                
       
        
        
        //check for core motion
        if motionManager.isAccelerometerAvailable
        {
            isAccelerometer = true
        }
        
        if motionManager.isDeviceMotionAvailable
        {
            isDeviceMotion = true
        }
        
        
     
        
        print(isDeviceMotion)
        print(isAccelerometer)
        
        
        if isAccelerometer && isDeviceMotion
        {
            motionManager.startAccelerometerUpdates()
            motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical)
            motionManager.deviceMotionUpdateInterval = 1.0 / 100.0
            motionManager.accelerometerUpdateInterval = 1.0 / 100.0
        }
        
        
        FillAIModelArrays()
        
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
