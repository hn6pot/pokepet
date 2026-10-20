# SwiftPM 6.4's default build system fails with the Command Line Tools alone
# ("Unknown error parsing property list"): use the old one, "native".
SWIFT_FLAGS = --build-system native
# Swift Testing ships with the Command Line Tools, but it has to be told where.
FW = $(shell xcode-select -p)/Library/Developer/Frameworks
TEST_FLAGS = $(SWIFT_FLAGS) -Xswiftc -F -Xswiftc $(FW) -Xlinker -F -Xlinker $(FW) -Xlinker -rpath -Xlinker $(FW)

.PHONY: test test-app test-mod run app install uninstall
test: test-app test-mod

# The sprites are not in the repository (Pokémon art belongs to Nintendo / Chunsoft): they are
# downloaded from PMD SpriteCollab, at a pinned commit, the first time something needs them.
sprites/pmd/0004/AnimData.xml:
	python3 -I scripts/fetch_sprites.py

test-app: sprites/pmd/0004/AnimData.xml
	swift test $(TEST_FLAGS) $(if $(FILTER),--filter $(FILTER))

# `claude plugin test` only looks for tests inside the mod's directory, and rejects imports
# that leave it: we assemble a copy of the mod with tests/mod/ inside, in a temporary directory.
# The tests therefore import ../../../hooks/… (the path in that copy).
# The Desktop app embeds its own Claude Code version, older and stricter (2.1.295 refuses
# to pass $ to an imported function): the mod is validated and tested with it too, when the app is there.
DESKTOP_CLAUDE = $(HOME)/Library/Application Support/Claude/claude-code
test-mod:
	@T=$$(mktemp -d) && cp -R mod $$T/mod && mkdir -p $$T/mod/tests && cp -R tests/mod $$T/mod/tests/mod \
	  && claude plugin validate $$T/mod && claude plugin test $$T/mod \
	  && D="$$(ls -d "$(DESKTOP_CLAUDE)"/*/*/claude.app/Contents/MacOS/claude 2>/dev/null | sort -V | tail -1)" \
	  && if [ -n "$$D" ]; then echo "Avec le Claude Code de Desktop : $$D" && "$$D" plugin validate $$T/mod && "$$D" plugin test $$T/mod; \
	     else echo "(app Desktop absente : validation Desktop sautée)"; fi; S=$$?; rm -rf $$T; exit $$S

# Runs the app from the repository, without installing it (Ctrl-C to stop).
run: sprites/pmd/0004/AnimData.xml
	swift build $(SWIFT_FLAGS)
	POKEPET_SPRITES=$(CURDIR)/sprites/pmd .build/debug/Pokepote

# Assembles .build/Poképote.app: the binary, its Info.plist, the sprites, a local signature.
APP_BUILD = .build/Poképote.app
app: sprites/pmd/0004/AnimData.xml
	swift build $(SWIFT_FLAGS) -c release
	rm -rf "$(APP_BUILD)" && mkdir -p "$(APP_BUILD)/Contents/MacOS" "$(APP_BUILD)/Contents/Resources"
	cp .build/release/Pokepote "$(APP_BUILD)/Contents/MacOS/"
	cp packaging/Info.plist "$(APP_BUILD)/Contents/"
	cp -R sprites "$(APP_BUILD)/Contents/Resources/"
	codesign --force --sign - "$(APP_BUILD)"

# Run from the main repository (not a worktree): the mod is installed from this directory.
APP = $(HOME)/Applications/Poképote.app
LABEL = com.hn6pot.pokepote
AGENT = $(HOME)/Library/LaunchAgents/$(LABEL).plist
install: test app
	mkdir -p $(HOME)/Applications $(HOME)/Library/LaunchAgents
	launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null || true
	rm -rf "$(APP)" && cp -R "$(APP_BUILD)" "$(APP)"
	sed 's|@BINARY@|$(APP)/Contents/MacOS/Pokepote|' packaging/$(LABEL).plist > $(AGENT)
	launchctl bootstrap gui/$$(id -u) $(AGENT)
	claude plugin marketplace add $(CURDIR) 2>/dev/null || claude plugin marketplace update pokepet
	claude plugin install pokepet@pokepet --scope user 2>/dev/null || claude plugin update pokepet@pokepet --scope user

uninstall:
	launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null || true
	rm -f $(AGENT)
	rm -rf "$(APP)" $(HOME)/.pokepet
	claude plugin uninstall pokepet@pokepet --scope user 2>/dev/null || true
	claude plugin marketplace remove pokepet 2>/dev/null || true
