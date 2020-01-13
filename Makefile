bump:
ifeq ($(VERSION),)
	@$(error VERSION is not defined. Run with `make VERSION=number bump`)
endif
	@echo Bumping the version number to $(VERSION)
	@sed -i '' "s/\"version\": \".*\",/\"version\": \"$(VERSION)\",/" package.json
	@sed -i '' "s/documentation-.*-blue.svg/documentation-$(VERSION)-blue.svg/" README.md
	@sed -i '' "s/versionName \'.*\'/versionName \'$(VERSION)\'/" android/build.gradle
	@sed -i '' "s/## TBD/## $(VERSION) ($(shell date '+%Y-%m-%d'))/" CHANGELOG.md


# Makes a release and pushes to github/npm
release:
ifeq ($(VERSION),)
	@$(error VERSION is not defined. Run with `make VERSION=number release`)
endif
ifneq ($(shell git rev-parse --abbrev-ref HEAD),master)
	@$(error You are not on the master branch)
endif
ifneq ($(shell git diff origin/master..master),)
	@$(error You have unpushed commits on the master branch)
endif
ifneq ($(shell git diff),)
	@$(error You have uncommitted changes)
endif
	@make VERSION=$(VERSION) bump
	@git commit -am "Release v$(VERSION)"
	@git tag v$(VERSION)
	@git push origin master "v$(VERSION)"
	@npm publish

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
	@rsync --delete -al ../bugsnag-cocoa/Source/ cocoa/vendor/bugsnag-cocoa/Source/
	@rsync --delete -al ../bugsnag-cocoa/Configurations/ cocoa/vendor/bugsnag-cocoa/Configurations/
	@rsync --delete -al ../bugsnag-cocoa/iOS/ cocoa/vendor/bugsnag-cocoa/iOS/
	@git status
