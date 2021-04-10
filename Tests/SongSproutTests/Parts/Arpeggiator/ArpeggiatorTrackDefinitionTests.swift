//  Created by B.T. Franklin on 12/18/20.

import XCTest
import AudioKit
@testable import SongSprout

class ArpeggiatorTrackDefinitionTests: XCTestCase {

    func testMakeNodeAndConnectRoute() {
        let partGenotype = ArpeggiatorPartGenotype(complexity: .veryLow)
        let trackDefinition = ArpeggiatorTrackDefinition(for: partGenotype)
        let partNode = trackDefinition.makeNode()

        let testMixerName = "Test Mixer"
        let mixer = Mixer(name: testMixerName)
        trackDefinition.connectRoute(from: partNode, to: mixer)

        XCTAssertEqual(mixer.connectionTreeDescription,
        """
        AudioKit | ↳Mixer("\(testMixerName)")
        AudioKit |  ↳Mixer("\(trackDefinition.identifier.rawValue) Mixer")
        AudioKit |   ↳Compressor
        AudioKit |    ↳MIDISampler("\(trackDefinition.identifier.rawValue)")
        """)
    }
}
