import { NativeModules } from 'react-native';

const NativeClient = NativeModules.BugsnagReactNative;

const BREADCRUMB_MAX_LENGTH = 30;

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
          this.notify(error, report => {report.severity = 'error'}, !!NativeClient.notifyBlocking, () => {
            if (previousHandler) {
              previousHandler(error, isFatal);
            }
          });
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
      onUnhandled: function(id, error) { client.notify(error); },
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
  notify = async (error, beforeSendCallback, blocking, postSendCallback) => {
    if (!(error instanceof Error)) {
      console.warn('Bugsnag could not notify: error must be of type Error');
      return;
    }
    if (!this.config.shouldNotify()) {
      return;
    }

    const report = new Report(this.config.apiKey, error);
    report.addMetadata('app', 'codeBundleId', this.config.codeBundleId);

    for (callback of this.config.beforeSendCallbacks) {
      if (callback(report, error) === false) {
        return;
      }
    }
    if (beforeSendCallback) {
      beforeSendCallback(report);
    }

    if (blocking) {
      NativeClient.notifyBlocking(report.toJSON(), blocking, postSendCallback);
    } else {
      NativeClient.notify(report.toJSON());
      if (postSendCallback)
        postSendCallback();
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

/**
 * A report generated from an error
 */
export class Report {

  constructor(apiKey, error) {
    this.apiKey = apiKey;
    this.errorClass = error.constructor.name;
    this.errorMessage = error.message;
    this.context = undefined;
    this.groupingHash = undefined;
    this.metadata = {};
    this.severity = 'warning';
    this.stacktrace = error.stack;
    this.user = {};
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
    return {
      apiKey: this.apiKey,
      context: this.context,
      errorClass: this.errorClass,
      errorMessage: this.errorMessage,
      groupingHash: this.groupingHash,
      metadata: typedMap(this.metadata),
      severity: this.severity,
      stacktrace: this.stacktrace,
      user: this.user
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

    // Checks for both `null` and `undefined`.
    if (value == undefined) {
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
