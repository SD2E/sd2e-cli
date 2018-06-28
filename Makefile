# Authors: Matthew Vaughn, John Fonner, and Jorge Alarcon Ochoa
#
# Building the sd2e-cli application requires configuration values present in
# the file configuration.rc (there is an example of what this file is
# supposed to look like in config/sample.configuration.rc). 
# To build get the template simply run `make init`.
#
# To make a tarball make `dist`.
# To make a tarball and push an official release by means of a git tag make 
# `release`.

-include configuration.rc

sdk_version := $(shell cat VERSION)
api_version := v2
api_release := 2.2.5

PREFIX := $(HOME)

TENANT_NAME := $(TENANT_NAME)
TENANT_KEY := $(TENANT_KEY)
TENANT_SCRIPT_NS := $(TENANT_SCRIPT_NS)
TENANT_DOCKER_DOCKER_FILE := $(TENANT_DOCKERFILE)
TENANT_DOCKER_TAG := $(TENANT_DOCKER_TAG)
SDK_GIT_REPO := $(TENANT_SDK_REPO)

OBJ := $(MAKE_OBJ)
SOURCES = customize

# Local installation
SED = ''

all: $(SOURCES)

init:
	@echo " + Creating config files. Don't forget to customize them!"
	build/config.sh

submodules: git-test
	@echo " + Configuring submodules..."
	build/submodules.sh

customize: submodules
	@echo " + Customizing..."
	build/customize.sh "$(OBJ)"

extras: customize configuration.rc
	@echo " + Syncing tenant-specific extensions..."
	test -d extras/.git && cd extras && git pull origin master
	@echo " + Building tenant-specific extensions..."
	test -f extras/Makefile && make -C extras

# Package a tarball for public release.
dist: all configuration.rc
	tar -czf "$(OBJ).tgz" $(OBJ)
	rm -rf $(OBJ)
	@echo "Ready for release. "

# Package application and push a tag. 
release: dist
	@echo "Releasing $(TENANT_NAME) v$(sdk_version) for Science API $(api_release)"
	git tag -a "v$(sdk_version)" -m "Release $(MAKE_OBJ) version v$(sdk_version)"
	git push origin "v$(sdk_version)"


test:
	@echo "Not tests implemented"


clean:
	rm -rf $(OBJ)
	test -f extras/Makefile && make -C extras

distclean: clean
	build/config.sh delete


install: $(OBJ)
	@echo "Installing in $(PREFIX)/$(OBJ)"
	@echo "Ensure that $(PREFIX)/$(OBJ)/bin is in your PATH."
	cp -fr $(OBJ) $(PREFIX)

uninstall:
	@echo "Uninstalling $(PREFIX)/$(OBJ)"
	test -d $(PREFIX)/$(OBJ) && rm -rf $(PREFIX)/$(OBJ)

update: clean git-test
	$(command) git pull
	@echo "Now, run make && make install"


# Application tests
sed-test:
	@echo "Checking for BSD sed..."
	if [[ "`uname`" =~ "Darwin" ]]; then SED = " ''"; echo "Detected: Changing -i behavior."; fi

git-test:
	@$(command) git --version


# Docker image
docker: customize
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) build

docker-release: docker
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) release

docker-clean:
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) clean
