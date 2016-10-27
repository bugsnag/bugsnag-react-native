import { NativeModules } from 'react-native';


const NativeClient = NativeModules.BugsnagReactNative;

/**
 * A Bugsnag monitoring and reporting client
 */
export class Client {

  /**
   * Creates a new Bugsnag client
   */
  constructor(apiKeyOrConfig) {
    if (apiKeyOrConfig.constructor === String) {
      this.config = new Configuration(apiKeyOrConfig);
    } else if (apiKeyOrConfig instanceof Configuration) {
      this.config = apiKeyOrConfig;
    } else {
      throw new Error('Bugsnag: A client must be constructed with an API key or Configuration');
    }

    if (NativeClient) {
      NativeClient.startWithOptions(this.config.toJSON());
      this.handleUncaughtErrors();
    } else {
      throw new Error('Bugsnag: No native client found. Is BugsnagReactNative installed in your native code project?');
    }
  }

  /**
   * Registers a global error handler which sends any uncaught error to
   * Bugsnag before invoking the previous handler, if any.
   */
  handleUncaughtErrors() {
    if (ErrorUtils) {
      const previousHandler = ErrorUtils._globalHandler;
      const bugsnag = this;

      ErrorUtils.setGlobalHandler(function(error, isFatal) {
        if (bugsnag.config.autoNotify) {
          bugsnag.notify(error, function(report) {
            report.severity = 'error';
          });
        }

        if (previousHandler) {
          previousHandler(error, isFatal);
        }
      });
    }
  }

  /**
   * Sends an error report to Bugsnag
   */
  async notify(error, beforeSendCallback) {
    if (!this.config.shouldNotify()) {
      return;
    }
    const report = new Report(this.config.apiKey, error);

    if (!(error instanceof Error)) {
      console.warn('Bugsnag could not notify: error must be of type Error');
      return;
    }

    for (callback in this.config.beforeSendCallbacks) {
      if (callback(report) === false) {
        return;
      }
    }
    if (beforeSendCallback !== undefined) {
      beforeSendCallback(report);
    }

    NativeClient.notify(report.toJSON());
  }

  setUser(id, name, email) {
    NativeClient.setUser({id: id, name: name, email: email });
  }

  /**
   * Leaves a 'breadcrumb' log message. The most recent breadcrumbs
   * are attached to subsequent error reports.
   */
  leaveBreadcrumb(name, metadata) {
    if (name.constructor !== String) {
      console.warn('Breadcrumb name must be a String');
      return;
    }
    if (metadata == undefined) {
      metadata = {};
    }
    if (metadata.constructor === String) {
      metadata = {'message': metadata };
    }
    if (!metadata instanceof Map) {
      console.warn('Breadcrumb metadata is not a Map or String');
      return;
    }
    let type = metadata['type'] || 'manual';
    delete metadata['type'];
    NativeClient.leaveBreadcrumb({
      name: name,
      type: type,
      metadata: typedMap(metadata)
    });
  }
}

/**
 * Configuration options for a Bugsnag client
 */
export class Configuration {

  constructor(apiKey) {
    const metadata = require('../package.json')
    this.version = metadata['version'];
    this.apiKey = apiKey;
    this.delivery = new StandardDelivery()
    this.beforeSendCallbacks = [];
    this.notifyReleaseStages = undefined;
    this.releaseStage = undefined;
    this.autoNotify = true;
  }

  /**
   * Whether reports should be sent to Bugsnag, based on the release stage
   * configuration
   */
  shouldNotify() {
    return !this.releaseStage
        || !this.notifyReleaseStages
        || this.notifyReleaseStages.contains(this.releaseStage);
  }

  /**
   * Adds a function which is invoked after an error is reported but before
   * it is sent to Bugsnag. The function takes a single parameter which is
   * an instance of Report.
   */
  registerBeforeSendCallback(callback) {
    this.beforeSendCallbacks.add(callback)
  }

  /**
   * Remove a callback from the before-send pipeline
   */
  unregisterBeforeSendCallback(callback) {
    this.beforeSendCallbacks.remove(callback);
  }

  /**
   * Remove all callbacks invoked before reports are sent to Bugsnag
   */
  clearBeforeSendCallbacks() {
    this.beforeSendCallbacks = []
  }

  toJSON() {
    return {
      apiKey: this.apiKey,
      releaseStage: this.releaseStage,
      notifyReleaseStages: this.notifyReleaseStages,
      endpoint: this.delivery.endpoint,
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
  addMetadata(section, key, value) {
    if (!this.metadata[section]) {
      this.metadata[section] = {};
    }
    this.metadata[section][key] = value;
  }

  toJSON() {
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
    const value = map[key];
    if (value instanceof Map || value instanceof Object) {
      output[key] = {type: 'map', value: typedMap(value)};
    } else {
      const type = typeof value;
      if (allowedMapObjectTypes.includes(type)) {
        output[key] = {type: type, value: value};
      }
    }
  }
  return output;
}
