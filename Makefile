bump:
ifeq ($(VERSION),)
	@$(error VERSION is not defined. Run with `make VERSION=number bump`)
endif
	@echo Bumping the version number to $(VERSION)
	@sed -i '' "s/\"version\": \".*\",/\"version\": \"$(VERSION)\",/" package.json
	@sed -i '' "s/documentation-.*-blue.svg/documentation-$(VERSION)-blue.svg/" README.md
	@sed -i '' "s/versionName \'.*\'/versionName \'$(VERSION)\'/" android/build.gradle


# Makes a release and pushes to github/npm
release:
ifeq ($(VERSION),)g
	@$(error VERSION is not defined. Run with `make VERSION=number release`)
endif
	make VERSION=$(VERSION) bump && git commit -am "v$(VERSION)" && git tag v$(VERSION) \
	&& git push origin && git push --tags && npm publish
