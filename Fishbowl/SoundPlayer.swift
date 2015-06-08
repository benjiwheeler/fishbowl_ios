//
//  SoundPlayer.swift
//  Fishbowl
//
//  Created by Benjamin Wheeler on 6/5/15.
//  Copyright (c) 2015 wheeler. All rights reserved.
//

import Foundation
import AVFoundation

class SoundPlayer {
    static let sharedInstance = SoundPlayer()
    static let NUM_SIMULTANEOUS_IDENTICAL_SOUNDS: Int = 5
    var soundPlayers = Dictionary<String, AVAudioPlayer>()
    class SimultaneousSoundPlayer {
        var soundPlayers: [AVAudioPlayer] = []
        var curPlayerIndex: Int?
        var minTimeApart: Double?
        var lastTimePlayed: NSDate?
        init(var player: AVAudioPlayer? = nil, var minTimeApartParam: Double? = 0.05) {
            if player != nil {
                addPlayer(player!)
            }
            minTimeApart = minTimeApartParam
        }
        func increment() {
            if curPlayerIndex == nil {
                curPlayerIndex = 0
            } else {
                ++curPlayerIndex!
            }
            if (curPlayerIndex >= soundPlayers.count) {
                curPlayerIndex! -= soundPlayers.count
            }
        }
        func addPlayer(player: AVAudioPlayer) {
            soundPlayers.append(player)
            increment()
        }
        func enoughTimeHasPassed() -> Bool {
            if let timeElapsed = lastTimePlayed?.timeIntervalSinceNow {
                // note that timeElapsed will be negative.
                return (-1.0 * timeElapsed) > minTimeApart // both are Doubles
            } else { // lastTimePlayed was nil, so it's never been set
                return true
            }
        }
        func play() -> Void {
            if (enoughTimeHasPassed() && curPlayerIndex != nil && soundPlayers.count > 0 && curPlayerIndex < soundPlayers.count) {
                // this line not in an if because can't be out of range
                let curPlayer: AVAudioPlayer = soundPlayers[curPlayerIndex!]
                increment()
                // play current player
                curPlayer.play()
                lastTimePlayed = NSDate()
            }
        }
    }
    var simultaneousSoundPlayers = Dictionary<String, SimultaneousSoundPlayer>()

    init() {
        // session stuff here?
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
    }

    func soundFileURL(name: String, var filetype: String? = nil) -> NSURL? {
        var path: String?
        var filetypesToTry: [String] = ["caf", "aiff", "aif", "wav"]
        if (filetype != nil) {
            filetypesToTry.insert(filetype!, atIndex: 0)
        }
        for thisFiletype in filetypesToTry {
            path = NSBundle.mainBundle().pathForResource(name, ofType: thisFiletype)
            if (path != nil) { break }
        }
        if (path == nil) { return nil }
        return NSURL(fileURLWithPath: path!)
    }

    func addSound(name: String, var filetype: String? = nil) -> Bool {
        if let soundFileURL = soundFileURL(name, filetype: filetype) {
            let newSoundPlayer = AVAudioPlayer(contentsOfURL: soundFileURL, error: nil)
            newSoundPlayer.prepareToPlay()
            soundPlayers[name] = newSoundPlayer
            return true
        }
        return false
    }

    func addSimultaneousSound(name: String, var filetype: String? = nil, var minTimeApart: Double? = 0.05) -> Bool {
        if let soundFileURL = soundFileURL(name, filetype: filetype) {
            simultaneousSoundPlayers[name] = SimultaneousSoundPlayer(minTimeApartParam: minTimeApart)
            //        simultaneousSoundPlayers.updateValue(SimultaneousSoundPlayer(), forKey:name)
            NSLog("there are \(simultaneousSoundPlayers.count) players")
            for var i = 0; i < SoundPlayer.NUM_SIMULTANEOUS_IDENTICAL_SOUNDS; ++i {
                let newSoundPlayer = AVAudioPlayer(contentsOfURL: soundFileURL, error: nil)
                newSoundPlayer.prepareToPlay()
                simultaneousSoundPlayers[name]?.addPlayer(newSoundPlayer)
                NSLog("simultaneousSoundPlayers[name] is \(simultaneousSoundPlayers[name])")
            }
            return true
        }
        return false
    }
    
    func playSound(name: String) -> Void {
        if let soundPlayer = soundPlayers[name] {
            soundPlayer.play()
        } else if let soundPlayer = simultaneousSoundPlayers[name] {
            soundPlayer.play()
        }
    }
}
