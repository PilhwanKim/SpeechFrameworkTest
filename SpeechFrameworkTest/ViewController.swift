//
//  ViewController.swift
//  SpeechFrameworkTest
//
//  Created by 김필환 on 2017. 2. 6..
//  Copyright © 2017년 김필환. All rights reserved.
//

import UIKit
import Speech
import NaverSpeech

class ViewController: UIViewController ,SFSpeechRecognizerDelegate, NSKRecognizerDelegate{
    
    @IBOutlet var recordingButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet weak var siriTextView: UITextView!
    @IBOutlet weak var naverTextView: UITextView!
    
    private let audioEngine:AVAudioEngine = AVAudioEngine()
    
    // Apple Speech
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-kr"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Naver Speech
    private let ClientID = "710CwSWlxkzXAQdSa6CV"
    private let nskSpeechRecognizer: NSKRecognizer

    required init?(coder aDecoder: NSCoder) { // NSKRecognizer를 초기화 하는데 필요한 NSKRecognizerConfiguration을 생성
        let configuration = NSKRecognizerConfiguration(clientID: ClientID)
        configuration?.canQuestionDetected = true
        self.nskSpeechRecognizer = NSKRecognizer(configuration: configuration)
        super.init(coder: aDecoder)
        self.nskSpeechRecognizer.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if (authStatus != SFSpeechRecognizerAuthorizationStatus.authorized) {
                return
            }
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restriced on this device")
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation {
                self.recordingButton.isEnabled = isButtonEnabled
            }
            
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        if available {
            recordingButton.isEnabled = true
        } else {
            recordingButton.isEnabled = false
        }
    }
    
    func recognizer(_ aRecognizer: NSKRecognizer!, didReceive aResult: NSKRecognizedResult!) {
        if let result = aResult.results.first as? String {
            print("Final result: \(result)")
            self.naverTextView.text = result
        }
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceivePartialResult aResult: String!) {
        print("Partial result: \(aResult)")
        self.naverTextView.text = aResult
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil,
                let formattedString = result?.bestTranscription.formattedString {
                self.siriTextView.text = formattedString
                print(formattedString)
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordingButton.isEnabled = true
            }
        })
        
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        nskSpeechRecognizer.start(with: .korean)
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        siriTextView.text = "Say something, I'm listening!"
        
    }

    @IBAction func recordAudio(_ sender: Any) {
        stopButton.isEnabled = true
        recordingButton.isEnabled = false
        startRecording()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        nskSpeechRecognizer.stop()
        stopButton.isEnabled = false
        recordingButton.isEnabled = true
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }

}

