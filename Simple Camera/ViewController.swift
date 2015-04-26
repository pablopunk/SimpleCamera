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
    var captureDevice : AVCaptureDevice? // La camara que usamos
    var backCaptureDevice  : AVCaptureDevice? // Back camera
    var frontCaptureDevice : AVCaptureDevice? // Front camera
    var captureOutput : AVCaptureStillImageOutput? // Para la captura
    let screenWidth = UIScreen.mainScreen().bounds.size.width // ancho de la pantalla
    let screenHeight = UIScreen.mainScreen().bounds.size.height // largo de la pantalla
    
    var currentFocus:CGFloat = 0.5 // para controlar el enfoque (de 0 a 1)
    let stepFocus:CGFloat = 50.0 // Cuan rapido aumentas y disminuyes
    
    var currentISO:CGFloat = 100 // para controlar el ISO (de minimo a maximo)
    var currentTimeVal:Int64 = 4 // tiempo
    var timeScale:Int32 = 60     // escala
    let stepISO:CGFloat = 0.2// Cuan rapido aumentas y disminuyes
    var maxISO:CGFloat = 0.0 // Maximo ISO
    var minISO:CGFloat = 0.0 // Minimo ISO
    var maxFocus:CGFloat = 1 // Maximo Foco
    var minFocus:CGFloat = 0 // Minimo Foco
    var minTimeValue:Int64 = 1; // Minimo tiempo
    var maxTimeValue:Int64 = 1; // Maximo tiempo
    
    var flasheoV = UIView() // vista del flasheo
    var buttonsView = UIView() // vista de botones
    var botonFlash = UIButton() // boton del flash
    var buttonsSize : CGFloat = 40.0 // tamanho de los botones por defecto (se cambia en la ejecucion)
    
    var isoBar : UIView!          // barra de indicador de ISO
    var focoBar   : UIView!       // barra de indicador de foco
    var barraSize : CGFloat = 3.0 // tamanho de las barras indicadoras
    var colorIso  : UIColor = UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 0.7)
    var colorFoco : UIColor = UIColor(red: 255/255, green: 150/255, blue: 0/255, alpha: 0.7)
    
    var lockForTouch : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        configurarListeners() // listeners
        configurarSession() // sesion
        configurarVista() // vistas
    }
    
    func configurarListeners() { // Para reconocer gestos, etc
        // Reconocer el single tap
        var tapgesture = UITapGestureRecognizer(target: self, action: "tapDetected")
        self.view.addGestureRecognizer(tapgesture)
//        // Reconocer el long press
//        var longpressgesture = UILongPressGestureRecognizer(target: self, action: "longPressDetected")
//        self.view.addGestureRecognizer(longpressgesture)
    }
    
    func configurarSession() { // Settings de la sesion de la captura
        let devices = AVCaptureDevice.devices() // Dispositivos disponibles
        
        for device in devices { // Loop through all the capture devices on this phone
            if (device.hasMediaType(AVMediaTypeVideo)) { // Make sure this particular device supports video
                if(device.position == AVCaptureDevicePosition.Back) { // back camera
                    backCaptureDevice = device as? AVCaptureDevice
                } else if (device.position == AVCaptureDevicePosition.Front) {
                    frontCaptureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        // Por defecto tenemos la camara trasera
        captureDevice = backCaptureDevice
        
        if captureDevice != nil { // si hemos encontrado un dispositivo de video
            beginSession()
        } else {
            // no hay dispositivos de video
        }

    }
    
    func configurarVista() {
        // Flashear pantalla
        flasheoV = UIView(frame: CGRectMake(0, 0, screenWidth, screenHeight))
        flasheoV.alpha = 0.0
        flasheoV.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(flasheoV)
        
        // Botones
        buttonsSize = screenWidth/6.0
        buttonsView = UIView(frame: CGRectMake(screenWidth-buttonsSize, 0, buttonsSize, screenHeight))
        //buttonsView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(buttonsView)
        
        // Boton flash
        botonFlash = UIButton(frame: CGRectMake(0, 25, buttonsSize, buttonsSize))
        botonFlash.alpha = 0.5
        botonFlash.setBackgroundImage(UIImage(named: "flash off.png"), forState: .Normal)
        //botonFlash.backgroundColor = UIColor.whiteColor()
        botonFlash.addTarget(self, action: "changeFlash", forControlEvents:.TouchUpInside)
        buttonsView.addSubview(botonFlash)
        
        // Brillo y Foco
        //isoBar = UIView(frame: CGRectMake(0, screenHeight-barraSize, screenWidth*(currentISO/maxISO), barraSize))
        isoBar = UIView(frame: CGRectMake(0, screenHeight-barraSize, screenWidth, barraSize))
        isoBar.backgroundColor = colorIso
        //focoBar = UIView(frame: CGRectMake(0, 0, screenWidth*(currentFocus/maxFocus), barraSize))
        focoBar = UIView(frame: CGRectMake(0, 0, screenWidth, barraSize))
        focoBar.backgroundColor = colorFoco
        self.view.addSubview(isoBar)
        self.view.addSubview(focoBar)
        
    }
    
    func beginSession() { // Empezar la sesion
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        configureDevice() // Configuraciones de camara
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        
        // configurar la salida
        captureOutput = AVCaptureStillImageOutput()
        var settings: [String: String] = [AVVideoCodecJPEG : AVVideoCodecKey]
        captureOutput?.outputSettings = settings
        captureSession.addOutput(captureOutput)
        
        //
        captureSession.startRunning()
    }
    
    func configureDevice() { // Configurar la camara
        if let device = captureDevice {
            if device.isFocusModeSupported(AVCaptureFocusMode.Locked) { // Soporta el enfoque manua
                device.lockForConfiguration(nil)
                device.focusMode = .Locked
                device.unlockForConfiguration()
            }
            minISO = CGFloat(device.activeFormat.minISO) // Valor maximo de ISO
            maxISO = CGFloat(device.activeFormat.maxISO) // Valor minimo de ISO
            minTimeValue = device.activeFormat.minExposureDuration.value
            maxTimeValue = device.activeFormat.maxExposureDuration.value
            focusTo(Float(currentFocus))
            exposeTo(Float(currentISO))
        }
    }
    
    func focusTo(value : Float) { // Cambia el enfoque
        if let device = captureDevice {
            if device.isFocusModeSupported(AVCaptureFocusMode.Locked) { // Soporta el enfoque manual
                if(device.lockForConfiguration(nil)) {
                    device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in
                        //
                    })
                    device.unlockForConfiguration()
                }
            }
        }
    }
    
    func exposeTo(value : Float) { // Cambia el enfoque
        if let device = captureDevice {
            if(device.lockForConfiguration(nil)) {
                // 
                device.setExposureModeCustomWithDuration(CMTimeMake(calcularTime(value),timeScale), ISO: value, completionHandler: { (time) -> Void in
                    //
                })
                device.unlockForConfiguration()
            }
        }
    }
    
    func calcularTime(iso: Float) -> Int64 { // Calcular tiempo de exposicion segun el ISO
        var tiempo = iso / Float(maxISO - minISO) * (Float(minTimeValue)-1) + Float(maxTimeValue)
        return Int64(tiempo)
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
    }
    
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        var touch = touches.first as! UITouch
        var cambio = touch.locationInView(self.view).x / screenWidth
        var prevLocation = touch.previousLocationInView(self.view).x / screenWidth
        let touchLocation = touch.locationInView(self.view)
        
        lock() // bloquear el boton de la camara
        
        if touchLocation.y < (screenHeight/2.0) { // Parte izquierda de la pantalla
            
            focoBar.frame = CGRectMake(0, 0, screenWidth*(currentFocus/maxFocus), barraSize)
            
            calcularEnfoque(prevLocation, conCambio: cambio)
            
        } else { // Parte derecha de la pantalla
            
            isoBar.frame = CGRectMake(0, screenHeight-barraSize, screenWidth*((currentISO-minISO)/(maxISO-minISO)), barraSize)
             
            calcularISO(prevLocation, conCambio: cambio)
        }
        
        unlockForTouch() // desbloquearlo
        
    }
    
    // Detectar el single tap -> SACAR FOTO
    func tapDetected() {
        if (!self.lockForTouch) { // si no estoy cambiando los parametros (iso, foco)
            flashScreen()       // flash en la pantalla
            sacarFoto()         // guardar la foto
        }
    }
    
    // Desbloquear el candado para poder sacar fotos
    func unlockForTouch() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        // abro un nuevo hilo que espere un tiempo para desbloquear el candado
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                // espero un tiempo para el desbloqueo
                var timer = NSTimer.scheduledTimerWithTimeInterval(0.7, target: self, selector: Selector("unlock"), userInfo: nil, repeats: false)
            }
        }
    }

    // funcion para el desbloqueo con timer
    func unlock() {
        self.lockForTouch = false
    }
    
    // funcion para el bloqueo
    func lock() {
        self.lockForTouch = true
    }
    
    // funcion de sacar foto
    func sacarFoto() {
        if let output = captureOutput {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { // Otro hilo para no colgar la UI
                
                output.captureStillImageAsynchronouslyFromConnection(output.connectionWithMediaType(AVMediaTypeVideo)){
                    (imageSampleBuffer : CMSampleBuffer!, _) in
                    
                    if imageSampleBuffer != nil {
                        var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        var image = UIImage(data: imageData)
                        var deviceorientation = UIDevice.currentDevice().orientation
                        var imageSave = UIImage()
                        
                        switch(deviceorientation.rawValue) {
                        case 1: // Portrait
                            imageSave = UIImage(CGImage: image?.CGImage, scale: CGFloat(1.0), orientation: .Right)!
                        case 2: // Portrait al reves
                            imageSave = UIImage(CGImage: image?.CGImage, scale: CGFloat(1.0), orientation: .Left)!
                        case 3: // Landscape izq
                            imageSave = UIImage(CGImage: image?.CGImage, scale: CGFloat(1.0), orientation: .Up)!
                        case 4: // Landscape der
                            imageSave = UIImage(CGImage: image?.CGImage, scale: CGFloat(1.0), orientation: .Down)!
                        default:
                            print(" -> Error al reconocer device orientation")
                        }
                        UIImageWriteToSavedPhotosAlbum(imageSave, self, nil, nil)
                    }
                }
            }
        }
    }
    
//    // Long press -> cambiar camara
//    func longPressDetected() {
//        if let device = captureDevice {
//            captureSession.removeInput(AVCaptureDeviceInput(device: captureDevice, error: nil))
//            if device.position == AVCaptureDevicePosition.Back { // De back a front
//                captureDevice = frontCaptureDevice
//                botonFlash.hidden = true // ocultamos el flash
//                configureDevice()
//                beginSession()
//            } else { // de front a back
//                if frontCaptureDevice != nil {
//                    captureDevice = backCaptureDevice
//                    botonFlash.hidden = false // mostramos el flash
//                    configureDevice()
//                    beginSession()
//                }
//            }
//        }
//    }
    
    // Al sacar la foto, sale un flash en la pantalla
    func flashScreen() {
        flasheoV.alpha = 1.0;
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.6);
        flasheoV.alpha = 0.0;
        UIView.commitAnimations()
    }
    
    // Cambiar el estado del flash
    func changeFlash() {
        if let device = captureDevice {
            if device.flashMode == AVCaptureFlashMode.On {
                setFlashOff() // Apagar
                botonFlash.setBackgroundImage(UIImage(named: "flash off.png"), forState: .Normal)
            } else {
                setFlashOn() // Encender
                botonFlash.setBackgroundImage(UIImage(named: "flash on.png"), forState: .Normal)
            }
        }
    }
    
    // Encender el flash
    func setFlashOn() {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.flashMode = AVCaptureFlashMode.On;
            device.unlockForConfiguration()
        }
    }
    
    // Apagar el flash
    func setFlashOff() {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.flashMode = AVCaptureFlashMode.Off;
            device.unlockForConfiguration()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

