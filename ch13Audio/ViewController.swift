//
//  ViewController.swift
//  ch13Audio
//
//  Created by 김규리 on 2022/01/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    var audioPlayer : AVAudioPlayer! // AVAudioPlayer 인스턴스 변수
    var audioFile : URL! // 재생할 오디오의 파일명 변수
    let MAX_VOLUME : Float = 10.0 // 최대 볼륨, 실수형 상수
    var progressTimer : Timer! // 타이머를 위한 변수
    
    let timePlayerSelector: Selector = #selector(ViewController.updatePlayTime) // 재생 타이머를 위한 상수 추가
    let timeRecordSelector: Selector = #selector(ViewController.updateRecordTime) // 녹음 타이머를 위한 상수 추가

    @IBOutlet var pvProgressPlay: UIProgressView!
    
    @IBOutlet var lblCurrentTime: UILabel!
    @IBOutlet var lblEndTime: UILabel!
    @IBOutlet var btnPlay: UIButton!
    @IBOutlet var btnPause: UIButton!
    @IBOutlet var btnStop: UIButton!
    
    @IBOutlet var slVolume: UISlider!
    
    // 녹음
    @IBOutlet var btnRecord: UIButton!
    @IBOutlet var lblRecordTime: UILabel!
    
    var audioRecorder : AVAudioRecorder! // audioRecorder 인스턴스 추가
    var isRecordMode = false // 처음엔 재생모드로
    //
    
    @IBOutlet var imgView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imgView.image = UIImage(named: "stop.png")
        
        // 녹음 모드인지 아닌지
        selectAudioFile()
        if !isRecordMode { // 재생모드 이면
            initplay()
            btnRecord.isEnabled = false // 녹음 버튼들 비활성화
            lblRecordTime.isEnabled = false //
        } else { // 녹음모드 이면
            initRecord()
        }
    }
    
    // 모드에 따라 파일 선택
    func selectAudioFile() {
        if !isRecordMode { // 재생 모드(녹음모드가 아닐 때) : 재생파일 실행
            audioFile = Bundle.main.url(forResource: "Sicilian_Breeze", withExtension: "mp3") // 오디오 파일명 변수 설정
        } else { // 녹음 모드 : 새 파일 recordFile.m4a 생성
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }
        
    }
    
    // 녹음 함수
    func initRecord() {
        // 녹음에 대한 설정
        let recordSettings = [
            AVFormatIDKey : NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000, // 비트율
            AVNumberOfChannelsKey : 2, // 오디오 채널
            AVSampleRateKey : 44100.0 // 샘플률
        ] as [String : Any]
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self
        
        slVolume.value = 1.0
        audioPlayer.volume = slVolume.value
        lblEndTime.text = convertNSTimeInterval2String(0)
        lblCurrentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(false, pause: false, stop: false)
        
        let session = AVAudioSession.sharedInstance() // AVAudioSession 인스턴스 session 생성
        do { // 카테고리 설정
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("Error-setCategory : \(error)")
        }
        do { // 액티브 설정
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive : \(error)")
        }
    }
    
    
    
    // 재생 함수
    func initplay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile) // try 오류 발생 가능 코드
        } catch let error as NSError { // catch 오류 패턴
            print("Error-initPlay : \(error)")
        }

        slVolume.maximumValue = MAX_VOLUME // 최대 볼륨 초기화
        slVolume.value = 1.0 // 슬라이더의 볼륨 초기화
        pvProgressPlay.progress = 0 // 프로그래스 뷰 진행을 0으로 초기화
        
        audioPlayer.delegate = self //
        audioPlayer.prepareToPlay() // prepareToPlay 실행
        audioPlayer.volume = slVolume.value // 슬라이더 볼륨 값으로 오디오플레이어 볼륨 초기화
        
        lblEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        lblCurrentTime.text = convertNSTimeInterval2String(0)
        
        // play 빼고 모두 비활성화
        setPlayButtons(true, pause: false, stop: false)
//        btnPlay.isEnabled = true
//        btnPause.isEnabled = false
//        btnStop.isEnabled = false
    }
    
    // play pause stop 버튼의 동작 여부 설정 함수
    func setPlayButtons(_ play:Bool, pause:Bool, stop:Bool){
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    // "재생시간 : TimeInterval 값을 받아 문자열로 반환하는 함수"
    func convertNSTimeInterval2String(_ time :TimeInterval) -> String {
        let min = Int(time/60) // 재생 시간을 60으로 나눈 몫 : 분
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) // 재생 시간을 60으로 나눈 나머지 : 초
        let strTime = String(format: "%02d:%02d", min, sec) // 이 형태의 문자열로 변환해 strTime에 저장
        
        return strTime // strTime 반환
    }
    
    // play 버튼 함수
    @IBAction func btnPlayAudio(_ sender: UIButton) {
        audioPlayer.play()
        imgView.image = UIImage(named: "play.png")
        setPlayButtons(false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true) // 0.1초 간격으로 타이머 생성
    }
    
    // 재생 시간을 레이블과 프로그레스 뷰에 나타냄
    @objc func updatePlayTime() {
        lblCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime) // 재생 시간을 레이블에 나타냄
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration) // 프로그레스 뷰에 나타냄
    }
    
    // pause 버튼 함수
    @IBAction func btnPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        imgView.image = UIImage(named: "pause.png")
        setPlayButtons(true, pause: false, stop: true)
    }
    
    // stop 버튼 함수
    @IBAction func btnStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        imgView.image = UIImage(named: "stop.png")
        audioPlayer.currentTime = 0 // 정지하면 현재시간을 0으로 보냄
        lblCurrentTime.text = convertNSTimeInterval2String(0) // 재생시간을 00:00으로 초기화
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate() // 타이머 무효화
    }
    
    // 슬라이더에 볼륨값 대입
    @IBAction func slChangeVolume(_ sender: UISlider) {
        audioPlayer.volume = slVolume.value
        
        print(slVolume.value)
    }
    
    // 오디오 재생이 끝나면 맨 처음 상태로 돌아가는 함수
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate() // 타이머 무효화
        setPlayButtons(true, pause: false, stop: false)
    }
    
    // 녹음
    @IBAction func swRecordMode(_ sender: UISwitch) {
        if sender.isOn { // 녹음 모드
            audioPlayer.stop() // 재생멈춤
            audioPlayer.currentTime = 0
            lblRecordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            btnRecord.isEnabled = true
            lblRecordTime.isEnabled = true
        } else { // 재생 모드
            isRecordMode = false
            btnRecord.isEnabled = false
            lblRecordTime.isEnabled = false
            lblRecordTime.text = convertNSTimeInterval2String(0) // 녹음시간 초기화
        }
        
        selectAudioFile() // 오디오파일 선택, 모드에 따라 초기화할 함수 호출
        if !isRecordMode {
            initplay()
        } else {
            initRecord()
        }
    }
    
    @IBAction func btnRecord(_ sender: UIButton) {
        if (sender as AnyObject).titleLabel?.text == "Record" { // 버튼 이름이 Record 이면
            audioRecorder.record() // 녹음 시작
            imgView.image = UIImage(named: "record.png")
            (sender as AnyObject).setTitle("Stop", for: UIControl.State()) // 버튼 이름을 Stop으로 바꿈
            // 녹음 시간 표시 위한 타이머 설정
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else { // 버튼 이름이 stop 이면
            audioRecorder.stop() // 녹음 멈춤
            progressTimer.invalidate() // 타이머 무효화
            (sender as AnyObject).setTitle("Record", for: UIControl.State()) // 버튼 이름을 Record로 바꿈
            btnPlay.isEnabled = true // play버튼만 활성화 하고
            initplay() // 방금 녹음한 파일로 재생을 초기화
        }
    }
    
    @objc func updateRecordTime() {
        lblRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime) // 재생 시간을 레이블에 나타냄
    }
}

