# Matthew Vaughn
# Aug 27, 2017

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
	@echo "Creating config files. Don't forget to customize them!"
	build/config.sh

submodules: git-test
	@echo "Configuring submodules"
	build/submodules.sh

cli-base: submodules
	@echo "Syncing core CLI sources..."
	cd tacc-cli-base ; \
	git pull origin master ; \
	cd ../abaco-cli ; \
	git pull origin master
    

customize: cli-base
	@echo "Customizing..."
	build/customize.sh "$(OBJ)"
	#find $(OBJ)/bin -type f ! -name '*.sh' ! -name '*.py' -exec chmod a+rx {} \;

extras: customize configuration.rc
	@echo "Syncing tenant-specific extensions..."
	test -d extras/.git && cd extras && git pull origin master
	@echo "Building tenant-specific extensions..."
	test -f extras/Makefile && make -C extras

# Pakcage tgz for public release
.SILENT: dist
dist: all
	tar -czf "$(OBJ).tgz" $(OBJ)
	rm -rf $(OBJ)
	echo "Ready for release. "

release: dist
	@echo "Releasing $(TENANT_NAME) v$(sdk_version) for Science API $(api_release)"
	git tag -a "v$(sdk_version)" -m "Release $(MAKE_OBJ) version v$(sdk_version)"
	git push origin "v$(sdk_version)"


test:
	@echo "Not tests implemented"

.PHONY: clean
clean:
	rm -rf $(OBJ)
	if [ -f "extras/Makefile" ]; then \
		cd extras ; \
		make clean ; \
	fi

.PHONY: pristine
pristine: clean
	build/config.sh delete

.SILENT: install
install: $(OBJ)
	cp -fr $(OBJ) $(PREFIX)
	rm -rf $(OBJ)
	echo "Installed in $(PREFIX)/$(OBJ)"
	echo "Ensure that $(PREFIX)/$(OBJ)/bin is in your PATH."

.SILENT: uninstall
uninstall:
	if [ -d $(PREFIX)/$(OBJ) ]; then rm -rf $(PREFIX)/$(OBJ); echo "Uninstalled $(PREFIX)/$(OBJ)."; exit 0; fi

.SILENT: update
update: clean git-test
	git pull
	if [ $$? -eq 0 ] ; then echo "Now, run make && make install."; exit 0; fi


# Application tests
sed-test:
	@echo "Checking for BSD sed..."
	if [[ "`uname`" =~ "Darwin" ]]; then SED = " ''"; echo "Detected: Changing -i behavior."; fi

git-test:
	@command git --version


# Docker image
docker: customize
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) build

docker-release: docker
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) release

docker-clean:
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) clean
