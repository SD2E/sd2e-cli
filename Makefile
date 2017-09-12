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
CLI_GIT_REPO := $(AGAVE_CLI_REPO)
CLI_GIT_BRANCH := $(AGAVE_CLI_BRANCH)
CLI_GIT_LOCALNAME := $(AGAVE_CLI_LOCALNAME)
OBJ := $(MAKE_OBJ)
SOURCES = customize

# Local installation
SED = ''

all: $(SOURCES)

.SILENT: init
init:
	echo "Creating config files. Don't forget to customize them!"
	cp sample.VERSION VERSION.X ; \
	cp sample.requirements.txt requirements.txt.X ; \
	cp sample.Dockerfile Dockerfile ; \
	cp sample.CHANGELOG.md CHANGELOG.md ; \
	cp sample.configuration.rc configuration.rc ;\
	cp sample._config.yml _config.yml ;\
	cp sample.CNAME CNAME

.SILENT: cli
cli: git-test
	echo "Syncing base CLI source..."
	echo "$(CLI_GIT_LOCALNAME)"
	if [ $$? -eq 0 ] ; then echo "Now, run make && make install."; exit 0; fi \
	if [ -d $(CLI_GIT_LOCALNAME) ]; then \
		echo "OK" \
	fi \
	if [ -d "$(CLI_GIT_LOCALNAME)" ]; then
		echo "Wow"
	fi

.SILENT: pip
pip: git-test
	pip install --user -r requirements.txt

.SILENT: customize
customize: pip cli
	echo "Customizing..."
	cp -fr src/templates $(OBJ)/
	cp -fr src/scripts/* $(OBJ)/bin/
	cp VERSION $(OBJ)/SDK-VERSION
	sed -e 's|$${TENANT_NAME}|$(TENANT_NAME)|g' \
		-e 's|$${TENANT_KEY}|$(TENANT_KEY)|g' \
		-e 's|$${api_version}|$(api_version)|g' \
		-e 's|$${api_release}|$(api_release)|g' \
		-e 's|$${sdk_version}|$(sdk_version)|g' \
		$(OBJ)/bin/$(TENANT_INFO) > $(OBJ)/bin/$(TENANT_INFO).edited
	mv $(OBJ)/bin/$(TENANT_INFO).edited $(OBJ)/bin/$(TENANT_INFO)
	find $(OBJ)/bin -type f ! -name '*.sh' -exec chmod a+rx {} \;


.SILENT: test
test:
	echo "Not implemented"

.PHONY: clean
clean:
	rm -rf $(OBJ) cli

.SILENT: install
install: $(OBJ)
	cp -fr $(OBJ) $(PREFIX)
	rm -rf $(OBJ)
	echo "Installed in $(PREFIX)/$(OBJ)"
	echo "Ensure that $(PREFIX)/$(OBJ)/bin is in your PATH."

.SILENT: uninstall
uninstall:
	if [ -d $(PREFIX)/$(OBJ) ];then rm -rf $(PREFIX)/$(OBJ); echo "Uninstalled $(PREFIX)/$(OBJ)."; exit 0; fi

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
	rm -rf cli
	echo "Ready for release. "

.SILENT: release
release:
	git diff-index --quiet HEAD
	if [ $$? -ne 0 ]; then echo "You have unstaged changes. Please commit or discard then re-run make clean && make release."; exit 0; fi
	git tag -a "v$(sdk_version)" -m "$(TENANT_NAME) SDK $(sdk_version). Requires Agave API $(api_version)/$(api_release)."
	git push origin "v$(sdk_version)"

