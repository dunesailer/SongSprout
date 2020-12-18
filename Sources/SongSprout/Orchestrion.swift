//  Created by B.T. Franklin on 12/8/19.

import Foundation
import AudioKit

public class Orchestrion {

    public enum PlaybackState {
        case initialized
        case stopped
        case playing
        case paused
    }

    public static let shared = Orchestrion()

    public var tempo: Double {
        didSet {
            if tempo != oldValue {
                sequencer?.tempo = tempo
                UserDefaults.standard.set(tempo, forKey: "tempo")
            }
        }
    }

    public var volume: Volume {
        didSet {
            if volume != oldValue {
                mainMixer.volume = volume.mixerValue
                UserDefaults.standard.set(volume.userValue, forKey: "volume")
            }
        }
    }

    public var playbackState: PlaybackState {
        get {
            if !(sequencer?.isPlaying ?? false) && internalPlaybackState == .playing {
                internalPlaybackState = .stopped
            }

            return internalPlaybackState
        }
    }

    private let engine = AudioEngine()
    private let mainMixer: Mixer

    private var sequencer: Sequencer?
    private var song: Song?
    private var internalPlaybackState: PlaybackState

    // Singleton can only be instantiated by self
    private init() {
        UserDefaults.standard.register(defaults: [
            "tempo" : 120.0,
            "volume":   0.5
        ])

        tempo = UserDefaults.standard.double(forKey: "tempo")
        volume = Volume(userValue: UserDefaults.standard.double(forKey: "volume"))

        mainMixer = Mixer(name: "Orchestrion Mixer")
        let compressor = Compressor(mainMixer)

        let filterBand1 = EqualizerFilter(compressor, centerFrequency: 32, bandwidth: 44.7, gain: 1.3)
        let filterBand2 = EqualizerFilter(filterBand1, centerFrequency: 64, bandwidth: 70.8, gain: 1.1)
        let filterBand3 = EqualizerFilter(filterBand2, centerFrequency: 125, bandwidth: 141, gain: 0.8)
        let filterBand4 = EqualizerFilter(filterBand3, centerFrequency: 250, bandwidth: 282, gain: 0.8)
        let filterBand5 = EqualizerFilter(filterBand4, centerFrequency: 500, bandwidth: 562, gain: 1.1)
        let filterBand6 = EqualizerFilter(filterBand5, centerFrequency: 1_000, bandwidth: 1_112, gain: 1.3)

        engine.output = filterBand6

        do {
            try engine.start()
            _ = MIDI.sharedInstance.client
        } catch {
            print("Error while starting AudioKit: \(error)")
        }

        MIDI.sharedInstance.addListener(OrchestrionMIDIListener())
        mainMixer.volume = volume.mixerValue

        internalPlaybackState = .initialized
    }

    public func prepare(_ genotype: MusicalGenotype?) {

        internalPlaybackState = .initialized

        mainMixer.removeAllInputs()
        sequencer = Sequencer()

        // Build all the playback infrastructure for the current genotype
        if let genotype = genotype {
            self.song = Song(from: genotype)
            song!.createNodesAndTracks(to: mainMixer, in: sequencer!)
        } else {
            self.song = nil
        }

        sequencer!.loopEnabled = false
    }

    public func play() {
        guard let song = self.song else {
            internalPlaybackState = .initialized
            return
        }

        sequencer?.tempo = tempo

        switch playbackState {
        case .initialized:
            song.populateTracks()
            sequencer?.playFromStart()

        case .stopped:
            sequencer?.playFromStart()

        case .paused:
            sequencer?.play()

        default:
            fatalError("Received play command while in unsupported state: \(playbackState)")
        }

        internalPlaybackState = .playing

        print(engine.connectionTreeDescription)
    }

    public func stop() {
        if let sequencer = sequencer {
            internalPlaybackState = .stopped
            sequencer.stop()
            for track in sequencer.tracks {
                track.stopPlayingNotes()
            }
            sequencer.rewind()
        }
    }
}