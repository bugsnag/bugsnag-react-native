/* global ErrorUtils, __DEV__ */

import { NativeModules } from 'react-native'
import serializeForNativeLayer from './NativeSerializer'

const NativeClient = NativeModules.BugsnagReactNative

const BREADCRUMB_MAX_LENGTH = 30
const CONSOLE_LOG_METHODS = [ 'log', 'debug', 'info', 'warn', 'error' ].filter(method =>
  typeof console[method] === 'function'
)

/**
 * A Bugsnag monitoring and reporting client
 */
export class Client {
  /**
   * Creates a new Bugsnag client
   */
  constructor (apiKeyOrConfig) {
    if (typeof apiKeyOrConfig === 'string' || typeof apiKeyOrConfig === 'undefined') {
      this.config = new Configuration(apiKeyOrConfig)
    } else if (apiKeyOrConfig instanceof Configuration) {
      this.config = apiKeyOrConfig
    } else {
      throw new Error('Bugsnag: A client must be constructed with an API key or Configuration')
    }

    if (NativeClient) {
      NativeClient.startWithOptions(this.config.toJSON())
      this.handleUncaughtErrors()
      if (this.config.handlePromiseRejections) { this.handlePromiseRejections() }
      if (this.config.consoleBreadcrumbsEnabled) { this.enableConsoleBreadcrumbs() }
    } else {
      throw new Error('Bugsnag: No native client found. Is BugsnagReactNative installed in your native code project?')
    }
  }

  /**
   * Registers a global error handler which sends any uncaught error to
   * Bugsnag before invoking the previous handler, if any.
   */
  handleUncaughtErrors = () => {
    if (ErrorUtils) {
      const previousHandler = ErrorUtils.getGlobalHandler()

      ErrorUtils.setGlobalHandler((error, isFatal) => {
        if (this.config.autoNotify && this.config.shouldNotify()) {
          this.notify(error, null, true, () => {
            if (previousHandler) {
              // Wait 150ms before terminating app, allowing native processing
              // to complete, if any. On iOS in particular, there is no
              // synchronous means ensure a report delivery attempt is
              // completed before invoking callbacks.
              setTimeout(() => {
                previousHandler(error, isFatal)
              }, 150)
            }
          }, new HandledState('error', true, 'unhandledException'))
        } else if (previousHandler) {
          previousHandler(error, isFatal)
        }
      })
    }
  }

  handlePromiseRejections = () => {
    const tracking = require('promise/setimmediate/rejection-tracking')
    const client = this
    tracking.enable({
      allRejections: true,
      onUnhandled: function (id, error) {
        client.notify(error, null, true, null, new HandledState('error', true, 'unhandledPromiseRejection'))
      },
      onHandled: function () {}
    })
  }

  /**
   * Sends an error report to Bugsnag
   * @param error               The error instance to report
   * @param beforeSendCallback  A callback invoked before the report is sent
   *                            so additional information can be added
   * @param postSendCallback    Callback invoked after request is queued
   */
  notify = async (error, beforeSendCallback, blocking, postSendCallback, _handledState) => {
    if (!(error instanceof Error)) {
      console.warn('Bugsnag could not notify: error must be of type Error')
      if (postSendCallback) { postSendCallback(false) }
      return
    }
    if (!this.config.shouldNotify()) {
      if (postSendCallback) { postSendCallback(false) }
      return
    }

    const report = new Report(this.config.apiKey, error, _handledState)
    report.addMetadata('app', 'codeBundleId', this.config.codeBundleId)

    for (const callback of this.config.beforeSendCallbacks) {
      if (callback(report, error) === false) {
        if (postSendCallback) { postSendCallback(false) }
        return
      }
    }
    if (beforeSendCallback) {
      beforeSendCallback(report)
    }

    const payload = report.toJSON()
    payload.blocking = !!blocking

    NativeClient.notify(payload).then(() => {
      if (postSendCallback) {
        postSendCallback()
      }
    })
  }

  setUser = (id, name, email) => {
    const safeStringify = value => {
      try {
        return String(value)
      } catch (e) {
        // calling String() on an object with a null
        // prototype can throw, so tolerate that here
        return undefined
      }
    }

    // the native setUser() fn only accepts strings so coerce each values
    id = safeStringify(id)
    name = safeStringify(name)
    email = safeStringify(email)

    NativeClient.setUser({ id, name, email })
  }

  /**
   * Clear custom user data and reset to the default device identifier
   */
  clearUser = () => {
    NativeClient.clearUser()
  }

  /**
   * Starts tracking a new session. You should disable automatic session tracking via
   * `autoCaptureSessions` if you call this method.
   *
   * You should call this at the appropriate time in your application when you wish to start a
   * session. Any subsequent errors which occur in your application will be reported to
   * Bugsnag and will count towards your application's
   * [stability score](https://docs.bugsnag.com/product/releases/releases-dashboard/#stability-score).
   * This will start a new session even if there is already an existing
   * session; you should call `resumeSession()` if you only want to start a session
   * when one doesn't already exist.
   *
   * @see `resumeSession()`
   * @see `stopSession()`
   * @see `autoCaptureSessions`
   */
  startSession = () => {
    NativeClient.startSession()
  }

  /**
   * Stops tracking a session. You should disable automatic session tracking via
   * `autoCaptureSessions` if you call this method.
   *
   * You should call this at the appropriate time in your application when you wish to stop a
   * session. Any subsequent errors which occur in your application will still be reported to
   * Bugsnag but will not count towards your application's
   * [stability score](https://docs.bugsnag.com/product/releases/releases-dashboard/#stability-score).
   * This can be advantageous if, for example, you do not wish the
   * stability score to include crashes in a background service.
   *
   * @see `startSession()`
   * @see `resumeSession()`
   * @see `autoCaptureSessions`
   */
  stopSession = () => {
    NativeClient.stopSession()
  }

  /**
   * Resumes a session which has previously been stopped, or starts a new session if none exists.
   * If a session has already been resumed or started and has not been stopped, calling this
   * method will have no effect. You should disable automatic session tracking via
   * `autoCaptureSessions` if you call this method.
   *
   * It's important to note that sessions are stored in memory for the lifetime of the
   * application process and are not persisted on disk. Therefore calling this method on app
   * startup would start a new session, rather than continuing any previous session.
   *
   * You should call this at the appropriate time in your application when you wish to resume
   * a previously started session. Any subsequent errors which occur in your application will
   * be reported to Bugsnag and will count towards your application's
   * [stability score](https://docs.bugsnag.com/product/releases/releases-dashboard/#stability-score).
   *
   * @see `startSession()`
   * @see `stopSession()`
   * @see `autoCaptureSessions`
   */
  resumeSession = () => {
    NativeClient.resumeSession()
  }

  /**
   * Leaves a 'breadcrumb' log message. The most recent breadcrumbs
   * are attached to subsequent error reports.
   */
  leaveBreadcrumb = (name, metadata) => {
    if (typeof name !== 'string') {
      console.warn(`Breadcrumb name must be a string, got '${name}'. Discarding.`)
      return
    }

    if (name.length > BREADCRUMB_MAX_LENGTH) {
      console.warn(`Breadcrumb name exceeds ${BREADCRUMB_MAX_LENGTH} characters (it has ${name.length}): ${name}. It will be truncated.`)
    }

    // Checks for both `null` and `undefined`.
    if ([ undefined, null ].includes(metadata)) {
      metadata = {}
    } else if (typeof metadata === 'string') {
      metadata = { 'message': metadata }
    } else if (typeof metadata !== 'object') {
      console.warn(`Breadcrumb metadata must be an object or string, got '${metadata}'. Discarding metadata.`)
      metadata = {}
    }

    const {
      type = 'manual',
      ...breadcrumbMetaData
    } = metadata

    NativeClient.leaveBreadcrumb({
      name,
      type,
      metadata: serializeForNativeLayer(breadcrumbMetaData)
    })
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
      const originalFn = console[method]
      console[method] = (...args) => {
        try {
          this.leaveBreadcrumb('Console', {
            type: 'log',
            severity: /^group/.test(method) ? 'log' : method,
            message: args
              .map(arg => {
                let stringified
                // do the best/simplest stringification of each argument
                try { stringified = String(arg) } catch (e) {}
                // unless it stringifies to [object Object], use the toString() value
                if (stringified && stringified !== '[object Object]') return stringified
                // otherwise attempt to JSON stringify (with indents/spaces)
                try { stringified = JSON.stringify(arg, null, 2) } catch (e) {}
                // any errors, fallback to [object Object]
                return stringified
              })
              .join('\n')
          })
        } catch (error) {
          console.warn(`Unable to serialize console.${method} arguments to Bugsnag breadcrumb.`, error)
        }
        originalFn.apply(console, args)
      }
      console[method]._restore = () => { console[method] = originalFn }
    })
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
  constructor (apiKey) {
    const metadata = require('../package.json')
    this.version = metadata['version']
    this.apiKey = apiKey
    this.delivery = new StandardDelivery()
    this.beforeSendCallbacks = []
    this.notifyReleaseStages = undefined
    this.releaseStage = undefined
    this.appVersion = undefined
    this.codeBundleId = undefined
    this.autoCaptureSessions = true
    this.autoNotify = true
    this.handlePromiseRejections = !__DEV__ // prefer banner in dev mode
    this.consoleBreadcrumbsEnabled = false
    this.automaticallyCollectBreadcrumbs = true
  }

  /**
   * Whether reports should be sent to Bugsnag, based on the release stage
   * configuration
   */
  shouldNotify = () => {
    return !this.releaseStage ||
      !this.notifyReleaseStages ||
      this.notifyReleaseStages.includes(this.releaseStage)
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
    const index = this.beforeSendCallbacks.indexOf(callback)
    if (index !== -1) {
      this.beforeSendCallbacks.splice(index, 1)
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
      sessionsEndpoint: this.delivery.sessionsEndpoint,
      appVersion: this.appVersion,
      autoNotify: this.autoNotify,
      version: this.version,
      autoCaptureSessions: this.autoCaptureSessions,
      automaticallyCollectBreadcrumbs: this.automaticallyCollectBreadcrumbs
    }
  }
}

export class StandardDelivery {
  constructor (endpoint, sessionsEndpoint) {
    this.endpoint = endpoint
    this.sessionsEndpoint = sessionsEndpoint
  }
}

class HandledState {
  constructor (originalSeverity, unhandled, severityReason) {
    this.originalSeverity = originalSeverity
    this.unhandled = unhandled
    this.severityReason = severityReason
  }
}

/**
 * A report generated from an error
 */
export class Report {
  constructor (apiKey, error, _handledState) {
    this.apiKey = apiKey
    this.errorClass = error.constructor.name
    this.errorMessage = error.message
    this.context = undefined
    this.groupingHash = undefined
    this.metadata = {}
    this.stacktrace = error.stack
    this.user = {}

    if (!_handledState || !(_handledState instanceof HandledState)) {
      _handledState = new HandledState('warning', false, 'handledException')
    }

    this.severity = _handledState.originalSeverity
    this._handledState = _handledState
  }

  /**
   * Attach additional diagnostic data to the report. The key/value pairs
   * are grouped into sections.
   */
  addMetadata = (section, key, value) => {
    if (!this.metadata[section]) {
      this.metadata[section] = {}
    }
    this.metadata[section][key] = value
  }

  toJSON = () => {
    if (!this._handledState || !(this._handledState instanceof HandledState)) {
      this._handledState = new HandledState('warning', false, 'handledException')
    }
    // severityReason must be a string, and severity must match the original
    // state, otherwise we assume that the user has modified _handledState
    // in a callback
    const defaultSeverity = this._handledState.originalSeverity === this.severity
    const isValidReason = (typeof this._handledState.severityReason === 'string')
    const severityType = defaultSeverity && isValidReason
      ? this._handledState.severityReason : 'userCallbackSetSeverity'

    // if unhandled not set, user has modified the report in a callback
    // or via notify, so default to false
    const isUnhandled = (typeof this._handledState.unhandled === 'boolean') ? this._handledState.unhandled : false

    return {
      apiKey: this.apiKey,
      context: this.context,
      errorClass: this.errorClass,
      errorMessage: this.errorMessage,
      groupingHash: this.groupingHash,
      metadata: serializeForNativeLayer(this.metadata),
      severity: this.severity,
      stacktrace: this.stacktrace,
      user: this.user,
      defaultSeverity: defaultSeverity,
      unhandled: isUnhandled,
      severityReason: severityType
    }
  }
}
