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
        init() {}
        func addPlayer(player: AVAudioPlayer) {
            soundPlayers.append(player)
        }
        func play() -> Void {
            if (curPlayerIndex != nil && soundPlayers.count > 0 && curPlayerIndex < soundPlayers.count) {
                // this line not in an if because can't be out of range
                let curPlayer: AVAudioPlayer = soundPlayers[curPlayerIndex!]
                // increment and mod index so it'll point to next player
                ++curPlayerIndex!
                if (curPlayerIndex >= soundPlayers.count) {
                    curPlayerIndex! -= soundPlayers.count
                }
                // play current player
                curPlayer.play()
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
        var filetypesToTry: [String] = ["aiff", "aif", "wav"]
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

    func addSimultaneousSound(name: String, var filetype: String? = nil) -> Bool {
        if let soundFileURL = soundFileURL(name, filetype: filetype) {
            simultaneousSoundPlayers[name] = SimultaneousSoundPlayer()
            for var i = 0; i < SoundPlayer.NUM_SIMULTANEOUS_IDENTICAL_SOUNDS; ++i {
                let newSoundPlayer = AVAudioPlayer(contentsOfURL: soundFileURL, error: nil)
                newSoundPlayer.prepareToPlay()
                simultaneousSoundPlayers[name]?.addPlayer(newSoundPlayer)
            }
            return true
        }
        return false
    }
    
    func playSound(name: String) -> Void {
        if let soundPlayer = soundPlayers[name] {
            soundPlayer.play()
        }
    }
}
