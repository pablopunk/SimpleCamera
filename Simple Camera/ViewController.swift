//
//  ViewController.swift
//  Simple Camera
//
//  Created by Pablo Varela on 22/1/15.
//  Copyright (c) 2015 Pablo Varela. All rights reserved.
//

import UIKit
import AVFoundation // para la camara

class ViewController: UIViewController {
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice? // Para guardar el dispositivo que usamos
    let screenWidth = UIScreen.mainScreen().bounds.size.width // ancho de la pantalla
    let screenHeight = UIScreen.mainScreen().bounds.size.height // largo de la pantalla
    
    var currentFocus:CGFloat = 0.5 // para controlar el enfoque (de 0 a 1)
    let stepFocus:CGFloat = 50.0 // Cuan rapido aumentas y disminuyes
    
    var currentISO:CGFloat = 100 // para controlar el ISO (de minimo a maximo)
    var currentTimeVal:Int64 = 4 // tiempo
    var timeScale:Int32 = 60     // escala
    var currentTime:CMTime = CMTimeMake(0, 60); // (tiempo, escala)
    let stepISO:CGFloat = 0.1 // Cuan rapido aumentas y disminuyes
    var maxISO:CGFloat = 0.0 // Maximo ISO
    var minISO:CGFloat = 0.0 // Minimo ISO
    var minTime:CMTime = CMTimeMake(0, 60); // Minimo tiempo
    var maxTime:CMTime = CMTimeMake(0, 60); // Maximo tiempo
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let devices = AVCaptureDevice.devices() // Dispositivos disponibles
        
        for device in devices { // Loop through all the capture devices on this phone
            if (device.hasMediaType(AVMediaTypeVideo)) { // Make sure this particular device supports video
                if(device.position == AVCaptureDevicePosition.Back) { // back camera
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        if captureDevice != nil { // si hemos encontrado un dispositivo de video
            beginSession()
        } else {
            // no hay dispositivos de video
        }
    }
    
    func beginSession() { // Empezar la captura
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        configureDevice() // Configuraciones de camara
        focusTo(Float(currentFocus))
        exposeTo(Float(currentISO))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
    }
    
    func configureDevice() { // Configurar la camara
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = .Locked
            device.unlockForConfiguration()
            minISO = CGFloat(device.activeFormat.minISO) // Valor maximo de ISO
            maxISO = CGFloat(device.activeFormat.maxISO) // Valor minimo de ISO
            minTime = device.activeFormat.minExposureDuration
            maxTime = device.activeFormat.maxExposureDuration
            currentTime = CMTimeMake(currentTimeVal, timeScale);
        }
    }
    
    func focusTo(value : Float) { // Cambia el enfoque
        if let device = captureDevice {
            if(device.lockForConfiguration(nil)) {
                device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
                    //
                })
                device.unlockForConfiguration()
            }
        }
    }
    
    func exposeTo(value : Float) { // Cambia el enfoque
        if let device = captureDevice {
            if(device.lockForConfiguration(nil)) {
                if (value < Float(currentISO)) { // Disminuye ISO?
                    
                } else { // Aumenta ISO?
                    
                }
                device.setExposureModeCustomWithDuration(currentTime, ISO: value, completionHandler: { (time) -> Void in
                    //
                })
                device.unlockForConfiguration()
            }
        }
    }
    
    func calcularEnfoque(prevLocation: CGFloat, conCambio cambio: CGFloat) {
        var checkbounds: CGFloat
        
        if prevLocation < cambio { // Enfocar mas lejos
            checkbounds = currentFocus + (cambio / stepFocus)
        } else { // Enfocar mas cerca
            checkbounds = currentFocus - (cambio / stepFocus)
        }
        
        if checkbounds > 1.0 { // enfoque maximo
            currentFocus = 1.0
        } else if checkbounds < 0.0 { // enfoque minimo
            currentFocus = 0.0
        } else { // enfoque medio
            currentFocus = checkbounds
        }
        focusTo(Float(currentFocus))
    }
    
    func calcularISO(prevLocation: CGFloat, conCambio cambio: CGFloat) {
        var checkbounds: CGFloat
        
        if prevLocation < cambio { // subir ISO
            checkbounds = currentISO + (cambio / stepISO)
        } else { // bajar ISO
            checkbounds = currentISO - (cambio / stepISO)
        }
        
        if checkbounds > maxISO { // ISO maximo
            currentISO = maxISO
        } else if checkbounds < minISO { // ISO minimo
            currentISO = minISO
        } else { // ISO medio
            currentISO = checkbounds
        }
        exposeTo(Float(currentISO))
        println(currentISO)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        var touch = touches.anyObject() as UITouch
        var cambio = touch.locationInView(self.view).x / screenWidth
        var prevLocation = touch.previousLocationInView(self.view).x / screenWidth
        
        if touch.locationInView(self.view).y < (screenHeight/2.0) { // Parte izquierda de la pantalla
            calcularEnfoque(prevLocation, conCambio: cambio)
        } else { // Parte derecha de la pantalla
            calcularISO(prevLocation, conCambio: cambio)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

