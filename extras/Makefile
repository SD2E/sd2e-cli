
_DEST := $(MAKE_OBJ)
SOURCES = extras

all:
	echo "Building extras..."
	./build.sh "artifacts"

install: all
	echo "Installing extras..."
	rsync --exclude=".*" --exclude=".*/" -azp ./artifacts/ ../$(MAKE_OBJ)

clean:
	rm -rf "artifacts"
