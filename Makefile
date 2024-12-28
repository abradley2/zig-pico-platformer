PicoHopper.app: zig-out/bin/zig-game
	mkdir -p PicoHopper.app/Contents/MacOS
	mkdir -p PicoHopper.app/Contents/Resources
	cp Info.plist PicoHopper.app/Contents
	cp -r assets PicoHopper.app/Contents/Resources
	cp -r levels PicoHopper.app/Contents/Resources
	cp zig-out/bin/zig-game PicoHopper.app/Contents/MacOS/PicoHopper
	zip -r PicoHopper-osx.zip PicoHopper.app

clean:
	rm -rf ./.zig-cache
	rm -rf zig-out
	rm PicoHopper-osx.zip
	rm -rf PicoHopper.app

zig-out/bin/zig-game:
	zig build --release=fast