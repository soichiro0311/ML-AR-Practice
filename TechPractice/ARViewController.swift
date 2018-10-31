//
//  ViewController.swift
//  ARTest
//
//  Created by 清家蒼一朗 on 2018/10/30.
//  Copyright © 2018年 清家蒼一朗. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        self.sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        self.sceneView.showsStatistics = true
        // Run the view's session
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @IBAction func moveToMLView(_ sender: Any) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "MLPracticeBoard") as! MLViewController
        present(nextVC as UIViewController, animated: true)
    }
    
    @IBAction func moveToDetectTextView(_ sender: Any) {
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "DetectTextPracticeBoard") as! DetectTextViewController
        present(nextVC as UIViewController, animated: true)
    }
    // 画面タップ時にタップされた場所に3Dモデルを配置する
    @IBAction func tapped(_ sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        print(sceneView)
        // タップされた位置のARアンカーを探す
        let hitTest = sceneView.hitTest(tapLocation, types: [.featurePoint])
        if !hitTest.isEmpty {
            // タップした箇所が取得できていればitemを追加
            self.addItem(hitTestResult: hitTest.first!)
        }
    }
    
    /// 3Dモデル配置メソッド
    func addItem(hitTestResult: ARHitTestResult) {
        // アセットより、シーンを作成
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // ノード作成
        let node = (scene.rootNode.childNode(withName: "ship", recursively: false))!
        
        // 現実世界の座標を取得
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        
        // アイテムの配置
        node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        //カメラの正面を向くようにアイテムを配置
        node.eulerAngles = self.sceneView.pointOfView!.eulerAngles
        self.sceneView.scene.rootNode.addChildNode(node)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        self.sceneView.autoenablesDefaultLighting = true
        sceneView.session.run(configuration)
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

