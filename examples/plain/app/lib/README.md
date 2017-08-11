Here we add a second package.json so we can easily import our configured
bugsnag client instance from anywhere in the app without a bunch of `../../` in
the path.

```javascript
import bugsnag from 'lib/bugsnag';
bugsnag.notify(new Error('test error'));
```
