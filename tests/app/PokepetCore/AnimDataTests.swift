import Foundation
import Testing
@testable import PokepetCore

/// The repository's real sprites: tests/app/PokepetCore → root.
let spritesDirectory = URL(filePath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appending(path: "sprites/pmd")

@Test("lit le vrai AnimData de Salamèche")
func parsesCharmandersRealAnimData() throws {
    let data = try Data(contentsOf: spritesDirectory.appending(path: "0004/AnimData.xml"))
    let idle = try #require(AnimData.parse(data)["Idle"])
    #expect(idle.sheet == "Idle")
    #expect(idle.width == 32)
    #expect(idle.height == 40)
    #expect(!idle.durations.isEmpty)
}

@Test("une copie reprend la planche et les durées de l'original")
func copyReusesTheOriginalSheetAndDurations() throws {
    let xml = """
    <AnimData><Anims>
      <Anim><Name>Shoot</Name><Index>1</Index><FrameWidth>40</FrameWidth><FrameHeight>48</FrameHeight>
        <Durations><Duration>2</Duration><Duration>4</Duration></Durations></Anim>
      <Anim><Name>SpAttack</Name><Index>2</Index><CopyOf>Shoot</CopyOf></Anim>
    </Anims></AnimData>
    """
    let copy = try #require(AnimData.parse(Data(xml.utf8))["SpAttack"])
    #expect(copy == PMDAnimation(name: "SpAttack", sheet: "Shoot", width: 40, height: 48, durations: [2, 4]))
}

@Test("un XML cassé ne donne rien")
func brokenXMLGivesNothing() {
    #expect(AnimData.parse(Data("<AnimData><Anims>".utf8)).isEmpty)
}

@Test("une animation sans taille est ignorée")
func animationWithoutSizeIsIgnored() {
    let xml = "<AnimData><Anims><Anim><Name>Idle</Name><Durations><Duration>2</Duration></Durations></Anim></Anims></AnimData>"
    #expect(AnimData.parse(Data(xml.utf8))["Idle"] == nil)
}
