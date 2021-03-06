//  Created by B.T. Franklin on 12/18/20.

import XCTest
import AudioKit
@testable import SongSprout

class DrumsTrackDefinitionTests: XCTestCase {

    func testMakeNodeAndConnectRoute() {
        let partGenotype = DrumsPartGenotype(complexity: .veryLow)
        let trackDefinition = DrumsTrackDefinition(for: partGenotype)
        let partNode = trackDefinition.makeNode()

        let testMixerName = "Test Mixer"
        let mixer = Mixer(name: testMixerName)
        trackDefinition.connectRoute(from: partNode, to: mixer)

        let engine = AudioEngine()
        engine.output = mixer
        do {
            try engine.start()
        } catch {
            print("AudioKit Engine failed to start: \(error)")
            return
        }

        XCTAssertTrue(mixer.connectionTreeDescription.hasPrefix(
        """
        AudioKit | ↳Mixer("\(testMixerName)")
        AudioKit |  ↳Mixer("\(trackDefinition.identifier.rawValue) Mixer")
        AudioKit |   ↳DryWetMixer
        AudioKit |    ↳MIDISampler("\(trackDefinition.identifier.rawValue)")
        """))

        // Middle is indeterminate, because different reverbs can be selected

        XCTAssertTrue(mixer.connectionTreeDescription.hasSuffix("AudioKit |     ↳MIDISampler(\"\(trackDefinition.identifier.rawValue)\")"))
    }
}
