# Matthew Vaughn
# Aug 27, 2017

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

.SILENT: init
init:
	echo "Creating config files. Don't forget to customize them!"
	build/config.sh

.SILENT: submodules
submodules: git-test
	echo "Configuring submodules"
	build/submodules.sh

.SILENT: cli-base
cli-base: submodules
	echo "Syncing core CLI sources..."
	cd tacc-cli-base ; \
	git pull origin master

.SILENT: extras
extras: cli-base
	echo "Syncing tenant-specific extensions..."
	if [ -d "extras" ]; then \
		cd extras ; \
		if [ -d ".git" ]; then \
			git pull origin master ; \
		fi ; \
	fi
	echo "Building tenant-specific extensions..."
	if [ -f "extras/Makefile" ]; then \
		cd extras ; \
		make all ; \
	fi

.SILENT: customize
customize: cli-base extras
	echo "Customizing..."
	build/customize.sh "$(OBJ)"
	#find $(OBJ)/bin -type f ! -name '*.sh' ! -name '*.py' -exec chmod a+rx {} \;

.SILENT: test
test:
	echo "Not implemented"

.PHONY: clean
clean:
	rm -rf $(OBJ)

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
.SILENT: sed-test
sed-test:
	echo "Checking for BSD sed..."
	if [[ "`uname`" =~ "Darwin" ]]; then SED = " ''"; echo "Detected: Changing -i behavior."; fi

.SILENT: git-test
git-test:
	echo "Verifying that git is installed..."
	GIT_INFO=`git --version > /dev/null`
	if [ $$? -ne 0 ] ; then echo "Git not found or unable to be executed. Exiting." ; exit 1 ; fi
	git --version

# Docker image
docker: customize
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) build

docker-release: docker
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) release

docker-clean:
	build/docker.sh $(TENANT_DOCKER_TAG) $(sdk_version) clean

# Github release
.SILENT: dist
dist: all
	tar -czf "$(OBJ).tgz" $(OBJ)
	rm -rf $(OBJ)
	echo "Ready for release. "

.SILENT: release
release:
	git diff-index --quiet HEAD
	if [ $$? -ne 0 ]; then echo "You have unstaged changes. Please commit or discard then re-run make clean && make release."; exit 0; fi
	git tag -a "v$(sdk_version)" -m "$(TENANT_NAME) SDK $(sdk_version). Requires Agave API $(api_version)/$(api_release)."
	git push origin "v$(sdk_version)"

