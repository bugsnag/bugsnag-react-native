import { NativeModules } from 'react-native';

const NativeClient = NativeModules.BugsnagReactNative;

const BREADCRUMB_MAX_LENGTH = 30;
const CONSOLE_LOG_METHODS = [ 'log', 'debug', 'info', 'warn', 'error' ].filter(method =>
  typeof console[method] === 'function'
);


/**
 * A Bugsnag monitoring and reporting client
 */
export class Client {

  /**
   * Creates a new Bugsnag client
   */
  constructor(apiKeyOrConfig) {
    if (typeof apiKeyOrConfig === 'string' || typeof apiKeyOrConfig === 'undefined') {
      this.config = new Configuration(apiKeyOrConfig);
    } else if (apiKeyOrConfig instanceof Configuration) {
      this.config = apiKeyOrConfig;
    } else {
      throw new Error('Bugsnag: A client must be constructed with an API key or Configuration');
    }

    if (NativeClient) {
      NativeClient.startWithOptions(this.config.toJSON());
      this.handleUncaughtErrors();
      if (this.config.handlePromiseRejections)
        this.handlePromiseRejections();
      if (this.config.consoleBreadcrumbsEnabled)
        this.enableConsoleBreadcrumbs();
    } else {
      throw new Error('Bugsnag: No native client found. Is BugsnagReactNative installed in your native code project?');
    }
  }

  /**
   * Registers a global error handler which sends any uncaught error to
   * Bugsnag before invoking the previous handler, if any.
   */
  handleUncaughtErrors = () => {
    if (ErrorUtils) {
      const previousHandler = ErrorUtils.getGlobalHandler();

      ErrorUtils.setGlobalHandler((error, isFatal) => {
        if (this.config.autoNotify && this.config.shouldNotify()) {
          this.notify(error, null, !!NativeClient.notifyBlocking, (queued) => {
            if (previousHandler) {
              previousHandler(error, isFatal);
            }
          }, new HandledState('error', true, 'unhandledException'));
        } else if (previousHandler) {
          previousHandler(error, isFatal);
        }
      });
    }
  }

  handlePromiseRejections = () => {
    const tracking = require('promise/setimmediate/rejection-tracking'),
          client = this;
    tracking.enable({
      allRejections: true,
      onUnhandled: function(id, error) {
        client.notify(error, null, false, null, new HandledState('error', true, 'unhandledPromiseRejection'));
      },
      onHandled: function() {}
    });
  }

  /**
   * Sends an error report to Bugsnag
   * @param error               The error instance to report
   * @param beforeSendCallback  A callback invoked before the report is sent
   *                            so additional information can be added
   * @param blocking            When true, blocks the native thread execution
   *                            until complete. If unspecified, sends the
   *                            request asynchronously
   * @param postSendCallback    Callback invoked after request is queued
   */
  notify = async (error, beforeSendCallback, blocking, postSendCallback, _handledState) => {
    if (!(error instanceof Error)) {
      console.warn('Bugsnag could not notify: error must be of type Error');
      if (postSendCallback)
        postSendCallback(false);
      return;
    }
    if (!this.config.shouldNotify()) {
      if (postSendCallback)
        postSendCallback(false);
      return;
    }

    const report = new Report(this.config.apiKey, error, _handledState);
    report.addMetadata('app', 'codeBundleId', this.config.codeBundleId);

    for (callback of this.config.beforeSendCallbacks) {
      if (callback(report, error) === false) {
        if (postSendCallback)
          postSendCallback(false);
        return;
      }
    }
    if (beforeSendCallback) {
      beforeSendCallback(report);
    }

    const payload = report.toJSON();
    if (blocking && NativeClient.notifyBlocking) {
      NativeClient.notifyBlocking(payload, blocking, postSendCallback);
    } else {
      NativeClient.notify(payload);
      if (postSendCallback)
        postSendCallback(true);
    }
  }

  setUser = (id, name, email) => {
    NativeClient.setUser({id, name, email});
  }

  /**
   * Clear custom user data and reset to the default device identifier
   */
  clearUser = () => {
    NativeClient.clearUser();
  }

  /**
   * Leaves a 'breadcrumb' log message. The most recent breadcrumbs
   * are attached to subsequent error reports.
   */
  leaveBreadcrumb = (name, metadata) => {
    if (typeof name !== 'string') {
      console.warn(`Breadcrumb name must be a string, got '${name}'. Discarding.`);
      return;
    }

    if (name.length > BREADCRUMB_MAX_LENGTH) {
      console.warn(`Breadcrumb name exceeds ${BREADCRUMB_MAX_LENGTH} characters (it has ${name.length}): ${name}. It will be truncated.`);
    }

    // Checks for both `null` and `undefined`.
    if (metadata == undefined) {
      metadata = {};
    } else if (typeof metadata === 'string') {
      metadata = { 'message': metadata };
    } else if (typeof metadata !== 'object') {
      console.warn(`Breadcrumb metadata must be an object or string, got '${metadata}'. Discarding metadata.`);
      metadata = {};
    }

    let type = metadata['type'] || 'manual';
    const breadcrumbMetaData = { ...metadata };
    delete breadcrumbMetaData['type'];

    NativeClient.leaveBreadcrumb({
      name,
      type,
      metadata: typedMap(breadcrumbMetaData)
    });
  }

  /**
   * Wraps all console log functions with a function that will leave a breadcrumb for
   * each call, while continuing to call through to the original.
   *
   *   !!! Warning !!!
   *   This will cause all log messages to originate from Bugsnag, rather than the
   *   actual callsite of the log function in your source code.
   */
  enableConsoleBreadcrumbs = () => {
    CONSOLE_LOG_METHODS.forEach(method => {
      const originalFn = console[method];
      console[method] = (...args) => {
        this.leaveBreadcrumb('Console', {
          type: 'log',
          severity: /^group/.test(method) ? 'log' : method,
          message: args
            .map(arg => {
              // do the best/simplest stringification of each argument
              let stringified = arg.toString()
              // unless it stringifies to [object Object], use the toString() value
              if (stringified !== '[object Object]') return stringified
              // otherwise attempt to JSON stringify (with indents/spaces)
              try { stringified = JSON.stringify(arg, null, 2) } catch (e) {}
              // any errors, fallback to [object Object]
              return stringified
            })
            .join('\n')
        });
        console[method]._restore = () => { console[method] = originalFn }
        originalFn.apply(console, args);
      }
    });
  }

  disableConsoleBreadCrumbs = () => {
    CONSOLE_LOG_METHODS.forEach(method => {
      if (typeof console[method]._restore === 'function') console[method]._restore()
    })
  }
}


/**
 * Configuration options for a Bugsnag client
 */
export class Configuration {

  constructor(apiKey) {
    const metadata = require('../package.json');
    this.version = metadata['version'];
    this.apiKey = apiKey;
    this.delivery = new StandardDelivery();
    this.beforeSendCallbacks = [];
    this.notifyReleaseStages = undefined;
    this.releaseStage = undefined;
    this.appVersion = undefined;
    this.codeBundleId = undefined;
    this.autoNotify = true;
    this.handlePromiseRejections = !__DEV__; // prefer banner in dev mode
    this.consoleBreadcrumbsEnabled = false;
  }

  /**
   * Whether reports should be sent to Bugsnag, based on the release stage
   * configuration
   */
  shouldNotify = () => {
    return !this.releaseStage ||
      !this.notifyReleaseStages ||
      this.notifyReleaseStages.includes(this.releaseStage);
  }

  /**
   * Adds a function which is invoked after an error is reported but before
   * it is sent to Bugsnag. The function takes a single parameter which is
   * an instance of Report.
   */
  registerBeforeSendCallback = (callback) => {
    this.beforeSendCallbacks.push(callback)
  }

  /**
   * Remove a callback from the before-send pipeline
   */
  unregisterBeforeSendCallback = (callback) => {
    const index = this.beforeSendCallbacks.indexOf(callback);
    if (index != -1) {
      this.beforeSendCallbacks.splice(index, 1);
    }
  }

  /**
   * Remove all callbacks invoked before reports are sent to Bugsnag
   */
  clearBeforeSendCallbacks = () => {
    this.beforeSendCallbacks = []
  }

  toJSON = () => {
    return {
      apiKey: this.apiKey,
      codeBundleId: this.codeBundleId,
      releaseStage: this.releaseStage,
      notifyReleaseStages: this.notifyReleaseStages,
      endpoint: this.delivery.endpoint,
      appVersion: this.appVersion,
      version: this.version
    };
  }
}

export class StandardDelivery {
  constructor(endpoint) {
    this.endpoint = endpoint || 'https://notify.bugsnag.com';
  }
}

class HandledState {
  constructor(originalSeverity, unhandled, severityReason) {
    this.originalSeverity = originalSeverity;
    this.unhandled = unhandled;
    this.severityReason = severityReason;
  }
}

/**
 * A report generated from an error
 */
export class Report {

  constructor(apiKey, error, _handledState) {
    this.apiKey = apiKey;
    this.errorClass = error.constructor.name;
    this.errorMessage = error.message;
    this.context = undefined;
    this.groupingHash = undefined;
    this.metadata = {};
    this.stacktrace = error.stack;
    this.user = {};

    if (!_handledState) {
      _handledState = new HandledState('warning', false, 'handledException');
    }

    this.severity = _handledState.originalSeverity;
    this._handledState = _handledState;
  }

  /**
   * Attach additional diagnostic data to the report. The key/value pairs
   * are grouped into sections.
   */
  addMetadata = (section, key, value) => {
    if (!this.metadata[section]) {
      this.metadata[section] = {};
    }
    this.metadata[section][key] = value;
  }

  toJSON = () => {
    const defaultSeverity = this._handledState.originalSeverity === this.severity;
    const severityType = defaultSeverity ?
     this._handledState.severityReason : 'userCallbackSetSeverity';

    return {
      apiKey: this.apiKey,
      context: this.context,
      errorClass: this.errorClass,
      errorMessage: this.errorMessage,
      groupingHash: this.groupingHash,
      metadata: typedMap(this.metadata),
      severity: this.severity,
      stacktrace: this.stacktrace,
      user: this.user,
      defaultSeverity: defaultSeverity,
      unhandled: this._handledState.unhandled,
      severityReason: severityType
    }
  }
}

const allowedMapObjectTypes = ['string', 'number', 'boolean'];

/**
 * Convert an object into a structure with types suitable for serializing
 * across to native code.
 */
const typedMap = function(map) {
  const output = {};
  for (const key in map) {
    if (!{}.hasOwnProperty.call(map, key)) continue;

    const value = map[key];

    // Checks for `null`, NaN, and `undefined`.
    if (value == undefined || (typeof value === 'number' && isNaN(value))) {
      output[key] = {type: 'string', value: String(value)}
    } else if (typeof value === 'object') {
      output[key] = {type: 'map', value: typedMap(value)};
    } else {
      const type = typeof value;
      if (allowedMapObjectTypes.includes(type)) {
        output[key] = {type: type, value: value};
      } else {
        console.warn(`Could not serialize breadcrumb data for '${key}': Invalid type '${type}'`);
      }
    }
  }
  return output;
}
