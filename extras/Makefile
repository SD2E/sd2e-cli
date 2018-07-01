SOURCES = extras

all:

install: all
	@echo " + Installing extras..."
	rsync --exclude=".*" --exclude=".*/" -azp ./src/bin/ ../$(MAKE_OBJ)

clean:
	rm -rf artifacts
