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
ifeq ($(VERSION),)
	@$(error VERSION is not defined. Run with `make VERSION=number release`)
endif
	make VERSION=$(VERSION) bump && git commit -am "v$(VERSION)" && git tag v$(VERSION) \
	&& git push origin && git push --tags && npm publish

upgrade_vendor:
ifeq ($(ANDROID_VERSION),)
	@$(error ANDROID_VERSION is not defined. Run with `make ANDROID_VERSION=number IOS_VERSION=number upgrade_vendor`)
endif
	@sed -i '' "s/bugsnag-android:.*\'/bugsnag-android:$(ANDROID_VERSION)\'/" android/build.gradle

ifeq ($(IOS_VERSION),)
	@$(error IOS_VERSION is not defined. Run with `make ANDROID_VERSION=number IOS_VERSION=number upgrade_vendor`)
endif
	@git -C ../bugsnag-cocoa fetch
	@git -C ../bugsnag-cocoa checkout v$(IOS_VERSION)
	@rsync --delete -al ../bugsnag-cocoa/Source cocoa/vendor/bugsnag-cocoa/Source
	@rsync --delete -al ../bugsnag-cocoa/iOS cocoa/vendor/bugsnag-cocoa/iOS
	@git status
