//
//  DetectTextViewController.swift
//  TechPractice
//
//  Created by 清家蒼一朗 on 2018/11/01.
//  Copyright © 2018年 清家蒼一朗. All rights reserved.
//
import UIKit
import AVFoundation
import ImageIO
import Vision

extension CGImagePropertyOrientation {
    public init?(_ orientation: UIImageOrientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        }
    }
}

class VisualizeRectanglesView: UIView {
    var rectangles: [CGRect] = []{
        didSet{
            setNeedsDisplay()
        }
    }
        
    var characterRectangles:[VNRectangleObservation] = []{
        didSet{
            setNeedsDisplay()
        }
    }
        
    private func convertedPoint(point: CGPoint, to size:CGSize) -> CGPoint{
        return CGPoint(x: point.x * size.width, y: (1.0 - point.y) * size.height)
    }
        
    private func convertedRect(rect: CGRect, to size: CGSize) -> CGRect{
        return CGRect(x: rect.minX * size.width, y: (1.0 - rect.maxY) * size.height, width: rect.width * size.width, height: rect.height * size.height)
    }
        
    override func draw(_ rect: CGRect) {
        backgroundColor = UIColor.clear
            
        UIColor.blue.setStroke()
            
        for rect in characterRectangles{
            let path = UIBezierPath()
            path.lineWidth = 2
            path.move(to: convertedPoint(point: rect.topLeft, to: frame.size))
            path.addLine(to: convertedPoint(point: rect.topRight, to: frame.size))
            path.addLine(to: convertedPoint(point: rect.bottomRight, to: frame.size))
            path.addLine(to: convertedPoint(point: rect.bottomLeft, to: frame.size))
            path.addLine(to: convertedPoint(point: rect.topLeft, to: frame.size))
            path.close()
            path.stroke()
        }
            
        UIColor.red.setStroke()
            
        for rect in rectangles{
            let path = UIBezierPath(rect: convertedRect(rect: rect, to: frame.size))
            path.lineWidth = 2
            path.stroke()
        }
    }
}

class DetectTextViewController: UIViewController{
    @IBOutlet weak var imageView: UIImageView!
    private let visualizeRectanglesView = VisualizeRectanglesView(frame: CGRect.zero)
    private var session: AVCaptureSession?
        
    @IBAction func moveToARView(_ sender: Any) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "ARPracticeBoard") as! ARViewController
        present(nextVC as UIViewController, animated: true)
    }
    @IBAction func moveToMLView(_ sender: Any) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "MLPracticeBoard") as! MLViewController
        present(nextVC as UIViewController, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(visualizeRectanglesView)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupAndStartAVCaptureSession()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        session?.stopRunning()
        super.viewWillDisappear(animated)
    }
        
    private func setupAndStartAVCaptureSession(){
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSession.Preset.photo
            
        let device = AVCaptureDevice.default(for: .video)
        let input = try! AVCaptureDeviceInput(device: device!)
        session?.addInput(input)
            
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session?.addOutput(output)
        session?.startRunning()
    }
}
    
extension DetectTextViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    private func imageFrameOnViewController(uiImage: UIImage) -> CGRect {
        let imageAspectRatio = uiImage.size.width / uiImage.size.height
        let viewAspectRatio = imageView.bounds.width / imageView.bounds.height
        if imageAspectRatio > viewAspectRatio {
            let ratio = imageView.bounds.width / uiImage.size.width
            return CGRect(
                x: imageView.frame.minX + 0,
                y: imageView.frame.minY + (imageView.bounds.height - ratio * uiImage.size.height) * 0.5,
                width: imageView.bounds.width,
                height: ratio * uiImage.size.height)
        } else {
            let ratio = view.bounds.height / uiImage.size.height
            return CGRect(
                x: imageView.frame.minX + (imageView.bounds.width - ratio * uiImage.size.width) * 0.5,
                y: imageView.frame.minY + 0,
                width: ratio * uiImage.size.width,
                height: imageView.bounds.height)
        }
    }
    func sampleBufferToUIImage(sampleBuffer: CMSampleBuffer, with orientation: UIInterfaceOrientation) -> UIImage {
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let quartzImage = context?.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly)
        
        // rear カメラの sampleBuffer は landscapeRight の向きなので、ここで orientation を補正
        if orientation == .landscapeLeft {
            return UIImage(cgImage: quartzImage!, scale: 1.0, orientation: .down)
        } else if orientation == .landscapeRight {
            return UIImage(cgImage: quartzImage!, scale: 1.0, orientation: .up)
        } else {
            return UIImage(cgImage: quartzImage!, scale: 1.0, orientation: .right)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let uiImage = sampleBufferToUIImage(sampleBuffer: sampleBuffer, with: UIApplication.shared.statusBarOrientation)
        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        let ciImage = CIImage(image: uiImage)!
        
        // UI の変更はメインスレッドで実行
        DispatchQueue.main.async { [weak self] in
            if let frame = self?.imageFrameOnViewController(uiImage: uiImage) {
                self?.imageView.image = uiImage
                self?.visualizeRectanglesView.frame = frame
            }
        }
        
        // orientation を必ず設定すること
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation(rawValue: UInt32(orientation!.rawValue))!)
        let request = VNDetectTextRectanglesRequest() { request, error in
            // テキストブロックの矩形を取得
            let rects = request.results?.flatMap { result -> [CGRect] in
                guard let observation = result as? VNTextObservation else { return [] }
                return [observation.boundingBox]
                } ?? []
            // 文字ごとの矩形を取得
            let characterRects = request.results?.flatMap { result -> [VNRectangleObservation] in
                guard let observation = result as? VNTextObservation else { return [] }
                return observation.characterBoxes ?? []
                } ?? []
            
            // UI の変更はメインスレッドで実行
            DispatchQueue.main.async { [weak self] in
                self?.visualizeRectanglesView.rectangles = rects
                self?.visualizeRectanglesView.characterRectangles = characterRects
            }
        }
        request.reportCharacterBoxes = true
        
        try! handler.perform([request])
    }
}

