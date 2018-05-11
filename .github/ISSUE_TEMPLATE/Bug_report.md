---
name: Bug report
about: Create a report to help us improve the library

---

### Description
<!-- A quick description of what you're trying to accomplish -->

### Issue
<!--
  What went wrong?
-->

### Environment

Library versions:

<!--
  Paste the output of this command into the code block below (use `npm ls`
  instead of `yarn list` if you are using npm):
    yarn list react-native bugsnag-react-native react-native-code-push
-->
```shell

```

- cocoapods version (if any) (`pod -v`):
- iOS/Android version(s):
- simulator/emulator or physical device?:
- debug mode or production?:

- [ ] (iOS only) `[BugsnagReactNative start]` is present in the
  `application:didFinishLaunchingWithOptions:` method in your `AppDelegate`
  class?
- [ ] (Android only) `BugsnagReactNative.start(this)` is present in the
  `onCreate` method of your `MainApplication` class?


<!--
  Below are a few approaches you might take to communicate the issue, in
  descending order of awesomeness. Please choose one and feel free to delete
  the others from this template.
-->
### Example Repo

- [ ] Create a minimal repository that can reproduce the issue after running
  `yarn install` and `react-native run-ios`/`react-native run-android`
- [ ] Link to it here:

### Example code snippet

```js
import { Client, Configuration } from 'bugsnag-react-native';

// (Insert code sample to reproduce the problem)
```

<!-- Error messages, if any -->
<details><summary>Error messages:</summary>

```

```
</details>
