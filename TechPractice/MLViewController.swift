//
//  ViewController.swift
//  CoreMLApp
//
//  Created by 清家蒼一朗 on 2018/10/31.
//  Copyright © 2018年 清家蒼一朗. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class MLViewController: UIViewController{
    
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        startCapture()
    }
    
    @IBAction func moveToARView(_ sender: Any) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "ARPracticeBoard") as! ARViewController
        present(nextVC as UIViewController, animated: true)
    }
    // ページ遷移を行う
    @IBAction func moveToDetectTextView(_ sender: Any) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "DetectTextPracticeBoard") as! DetectTextViewController
        present(nextVC as UIViewController, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 画像解析を始める
    private func startCapture(){
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video),let input = try? AVCaptureDeviceInput(device: captureDevice) , captureSession.canAddInput(input) else {
            assertionFailure("Error: デバイス追加に失敗しました")
            return
        }
        
        captureSession.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        
        guard  captureSession.canAddOutput(output) else {
            assertionFailure("Error: 出力デバイス追加に失敗しました")
            return
        }
        captureSession.addOutput(output)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        captureSession.startRunning()
    }
}
extension MLViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            assertionFailure("Error: バッファの変換に失敗しました")
            return
        }
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else{
            assertionFailure("Error: CoreMLモデルの初期化に失敗しました")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] (request: VNRequest, error: Error?) in guard let results = request.results as? [VNClassificationObservation] else {return}
            
            let displayText = results.prefix(3).compactMap{"\(Int($0.confidence * 100))% \($0.identifier.components(separatedBy: ", ")[0])" }.joined(separator: "\n")
              DispatchQueue.main.async {
                self?.textView!.text = displayText
              }
            
           
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}



