import AppKit
import PokepetCore

/// The beating heart of the app, two timers:
/// - once per second, reread ~/.pokepet/ and ask the `Companion` what to show;
/// - 60 times per second, advance the animation, the `Rhythm` actions, the stroll and the flash,
///   and decide whether clicks go through.
@MainActor
final class Loops {
    private let window: NSWindow
    private let view: SpriteView
    private let sprites: SpriteSource
    private let preferences: Preferences
    private let stateDirectory: StateDirectory
    private var companion = Companion(launchDate: Date())
    private(set) var appearance: Appearance?

    // The current animation.
    private var current: (movement: Movement, direction: Direction)?
    private var animation: LoadedAnimation?
    private var player = FramePlayer(durations: [1], looping: true)
    private var animationStart = Date()
    private var interludePlaying = false
    private var interludeRemaining = 0
    private var flashStart: Date?

    // The occasional actions (the Rhythm) and the current stroll.
    private var nextAction: Date?
    private var gestures: [Movement] = []
    private var step: Step?
    private var stepStart = Date()
    private var startX: CGFloat = 0
    /// The middle of the window at its place (where it was put, or the default): every stroll comes back here.
    /// The middle, because a resize keeps it in place.
    private var homeMidX: CGFloat?
    /// An animation asked for during a walk (a state change, a click): played once the step is over,
    /// so a stroll is never cut short and always gets back to its place.
    private var pendingPlay: (movement: Movement, times: Int)?
    private var generator = SystemRandomNumberGenerator()
    /// The day's answer count, as last read: where « Un autre Pokémon » starts counting from.
    private(set) var dayResponses = 0
    var dragging = false
    private var lastHover: Hover?

    private var timers: [Timer] = []

    init(window: NSWindow, view: SpriteView, sprites: SpriteSource, preferences: Preferences, stateDirectory: StateDirectory) {
        self.window = window
        self.view = view
        self.sprites = sprites
        self.preferences = preferences
        self.stateDirectory = stateDirectory
    }

    func start() {
        reload()
        placeWindow()
        timers = [
            Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            },
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.reload() }
            },
        ]
    }

    // MARK: Once per second

    private func reload() {
        let now = Date()
        let sessions = stateDirectory.sessions(now: now)
        let responses = DailyCounter.total(stateDirectory.counters(day: PokepetDay.key(now)))
        dayResponses = responses
        let next = companion.update(
            now: now, urgency: MostUrgentState.compute(sessions), responses: responses,
            lastActivity: sessions.map(\.updatedAt).max(), choice: preferences.dailyChoice)
        let speciesChanged = next.species != appearance?.species
        let rhythmChanged = next.display != appearance?.display || next.asleep != appearance?.asleep
        appearance = next
        view.bubble = next.bubble
        if speciesChanged {
            resize()
            gestures = Movement.gestures.filter { sprites.animation($0, species: next.species, direction: .front) != nil }
            current = nil
        }
        if next.flash { flashStart = now }
        if let interlude = next.interlude { play(interlude.movement, times: interlude.times) }
        if rhythmChanged { schedule(now) }
    }

    /// The next action according to the Rhythm; none while it sleeps.
    private func schedule(_ now: Date) {
        guard let appearance else { return }
        nextAction = Rhythm.delay(appearance.display, asleep: appearance.asleep, using: &generator)
            .map { now.addingTimeInterval($0) }
    }

    private func doAction(_ now: Date) {
        guard let appearance else { return }
        switch Rhythm.action(appearance.display, asleep: appearance.asleep, gestures: gestures, using: &generator) {
        case .walk: startStep(now)
        case .gesture(let movement): play(movement, times: 1)
        case .hop: play(.hop, times: 1)
        case nil: break
        }
        schedule(now)
    }

    // MARK: 60 times per second

    private func tick() {
        let now = Date()
        if interludePlaying && player.isFinished(after: now.timeIntervalSince(animationStart)) {
            if interludeRemaining > 1, let movement = current?.movement {
                play(movement, times: interludeRemaining - 1)
            } else {
                interludePlaying = false
                // Without this, a hop (Hop) played once would stay frozen: the base animation may be the same.
                current = nil
            }
        }
        if dragging {
            stopStep()
        } else if !interludePlaying {
            if step != nil {
                advanceStep(now)
            } else if let nextAction, now >= nextAction {
                doAction(now)
            }
        }
        if !interludePlaying {
            let wanted = wantedMovement()
            if current?.movement != wanted.movement || current?.direction != wanted.direction {
                play(wanted.movement, direction: wanted.direction, looping: true)
            }
        }
        // The view is touched only when something changed: it only redraws at that moment.
        if let animation, !animation.images.isEmpty {
            let image = animation.images[min(player.frame(after: now.timeIntervalSince(animationStart)), animation.images.count - 1)]
            if image !== view.image { view.image = image }
        }
        if let flashStart {
            let remaining = max(0, 1 - CGFloat(now.timeIntervalSince(flashStart)) / 0.5)
            view.flash = remaining
            if remaining == 0 { self.flashStart = nil }
        }
        // The "is the mouse on the sprite?" test draws a pixel: only if the mouse,
        // the window or the image moved.
        let state = Hover(mouse: NSEvent.mouseLocation, window: window.frame.origin, image: view.image, bubble: view.bubble)
        if state != lastHover || dragging {
            lastHover = state
            let mouse = view.convert(window.convertPoint(fromScreen: state.mouse), from: nil)
            let passThrough = !(dragging || view.hitsSprite(mouse))
            if window.ignoresMouseEvents != passThrough { window.ignoresMouseEvents = passThrough }
        }
    }

    /// What the hover test depends on.
    private struct Hover: Equatable {
        let mouse: CGPoint
        let window: CGPoint
        let image: CGImage?
        let bubble: Bool

        static func == (a: Hover, b: Hover) -> Bool {
            a.mouse == b.mouse && a.window == b.window && a.image === b.image && a.bubble == b.bubble
        }
    }

    private func wantedMovement() -> (movement: Movement, direction: Direction) {
        if let step, step.offset != 0 { return (.walk, step.offset > 0 ? .right : .left) }
        return (appearance?.base ?? .idle, .front)
    }

    private func play(_ movement: Movement, direction: Direction, looping: Bool) {
        guard let species = appearance?.species else { return }
        animation = sprites.animationOrIdle(movement, species: species, direction: direction)
        player = FramePlayer(durations: animation?.durations ?? [1], looping: looping)
        animationStart = Date()
        current = (movement, direction)
    }

    /// Plays a movement `times` times, then goes back to the base animation.
    private func play(_ movement: Movement, times: Int) {
        if step != nil {
            pendingPlay = (movement, times)
            return
        }
        play(movement, direction: .front, looping: false)
        interludePlaying = true
        interludeRemaining = times
    }

    private func startStep(_ now: Date) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        startX = window.frame.minX
        let home = homeMidX.map { $0 - window.frame.width / 2 } ?? startX
        step = Stroll.nextStep(
            x: startX, home: home, minimum: screen.visibleFrame.minX, maximum: screen.visibleFrame.maxX - window.frame.width,
            using: &generator)
        stepStart = now
    }

    private func advanceStep(_ now: Date) {
        guard let step else { return }
        let progress = step.duration > 0 ? min(now.timeIntervalSince(stepStart) / step.duration, 1) : 1
        window.setFrameOrigin(CGPoint(x: startX + step.offset * progress, y: window.frame.minY))
        if progress >= 1 { stopStep() }
    }

    /// Ends the current step, then plays what was waiting for it.
    private func stopStep() {
        step = nil
        if let pending = pendingPlay {
            pendingPlay = nil
            play(pending.movement, times: pending.times)
        }
    }

    // MARK: Size and position

    /// The window takes the size of the Pokémon's largest image, plus room for the bubble;
    /// the bottom and the middle stay in place.
    private func resize() {
        guard let species = appearance?.species else { return }
        let images = Movement.allCases.compactMap { sprites.animation($0, species: species, direction: .front) }.flatMap(\.images)
        let width = CGFloat(images.map(\.width).max() ?? 32), height = CGFloat(images.map(\.height).max() ?? 32)
        view.scale = CGFloat(preferences.size * Preferences.pointsPerPixel)
        let size = CGSize(width: width * view.scale, height: height * view.scale + view.bubbleHeight)
        let old = window.frame
        window.setFrame(CGRect(origin: CGPoint(x: old.midX - size.width / 2, y: old.minY), size: size), display: true)
    }

    /// At the remembered position if it is on a screen, otherwise at the bottom right of the main screen.
    private func placeWindow() {
        if let position = preferences.position, NSScreen.screens.contains(where: { $0.visibleFrame.contains(position) }) {
            window.setFrameOrigin(position)
            homeMidX = window.frame.midX
        } else {
            placeAtDefault()
        }
    }

    /// The sprite itself 40 points from the right and 47 from the bottom of the main screen (the one with the menu bar).
    private func placeAtDefault() {
        guard let screen = NSScreen.screens.first else { return }
        guard let species = appearance?.species,
              let image = sprites.animation(.idle, species: species, direction: .front)?.images.first,
              let sprite = view.silhouette(of: image)
        else {
            window.setFrameOrigin(CGPoint(x: screen.visibleFrame.maxX - window.frame.width, y: screen.visibleFrame.minY))
            homeMidX = window.frame.midX
            return
        }
        window.setFrameOrigin(DefaultPlacement.origin(usableArea: screen.visibleFrame, spriteInWindow: sprite))
        homeMidX = window.frame.midX
    }

    // MARK: Called by the gestures

    func click() {
        switch ClickRule.action(link: appearance?.link, claudeIsFrontmost: ConversationOpener.claudeIsFrontmost) {
        case .openConversation(let link):
            ConversationOpener.open(link)
        case .hopAndShowClaude:
            play(.hop, times: 1)
            ConversationOpener.showClaude()
        case .hop:
            play(.hop, times: 1)
        }
    }

    func positionChosen() {
        stopStep()
        preferences.position = window.frame.origin
        homeMidX = window.frame.midX
    }

    func changeSize(factor: Double) {
        preferences.size *= factor
        resize()
    }

    /// Draws another lineage for the day (kept until 4 a.m.), and shows it right away.
    func anotherPokemon() {
        guard let shown = appearance?.lineage else { return }
        // The new Pokémon starts from zero: it evolves on the answers counted from now on.
        preferences.dailyChoice = DailyChoice(
            day: PokepetDay.key(Date()), lineage: DailyDraw.other(than: shown, using: &generator),
            startResponses: dayResponses)
        reload()
    }

    /// Forgets the remembered position and goes back to the bottom-right corner.
    func defaultPosition() {
        stopStep()
        preferences.position = nil
        placeAtDefault()
    }

    func normalSize() {
        preferences.size = 1
        resize()
    }
}
