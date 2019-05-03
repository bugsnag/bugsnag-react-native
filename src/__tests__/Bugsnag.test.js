/* global jest, beforeEach, test, expect */

beforeEach(() => {
  // ensure freshly mocked clients in each test
  jest.resetModules()

  // mock globals set by RN at runtime
  global.__DEV__ = true
  global.ErrorUtils = {
    setGlobalHandler: jest.fn(),
    getGlobalHandler: jest.fn()
  }
})

test('constructor(): throws if called with bad input', () => {
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: null }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')

  // non-string and non-undefined value as config/api key
  expect(() => new Client(1)).toThrowError(/API key/)

  // missing BugsnagReactNative bindings
  expect(() => new Client('API_KEY')).toThrowError(/BugsnagReactNative/)
})

test('constructor(): works if everything is ok', () => {
  const mockStart = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: mockStart } }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')
  expect(c).toBeTruthy()
  expect(mockStart).toHaveBeenCalledWith(expect.objectContaining({ apiKey: 'API_KEY' }))
  expect(global.ErrorUtils.getGlobalHandler).toHaveBeenCalled()
  expect(global.ErrorUtils.setGlobalHandler).toHaveBeenCalled()
})

test('handleUncaughtErrors(): error handler calls notify(…) correctly', () => {
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn() } }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')

  // get the function that the client passed to the global error handler
  const handler = global.ErrorUtils.setGlobalHandler.mock.calls[0][0]

  c.notify = jest.fn()
  handler(new Error('boom!'), false)

  expect(c.notify).toHaveBeenCalledWith(expect.any(Error), null, true, expect.any(Function), {
    originalSeverity: 'error',
    severityReason: 'unhandledException',
    unhandled: true
  })
})

test('handlePromiseRejections(): error handler calls notify(…) correctly', () => {
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn() } }
  }), { virtual: true })

  const Promise = require('promise/setimmediate')
  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  config.handlePromiseRejections = true
  const c = new Client(config)

  c.notify = jest.fn()
  Promise.reject(new Error('boom!'))

  // promise rejection handler has a 2 second delay before running, so check after minimum viable timeout
  // https://github.com/then/promise/blob/7f33b7bccf07a2da37569095c53d91bea7dbd226/src/rejection-tracking.js#L54
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      try {
        expect(c.notify).toHaveBeenCalledWith(expect.any(Error), null, true, null, {
          originalSeverity: 'error',
          severityReason: 'unhandledPromiseRejection',
          unhandled: true
        })
      } catch (e) {
        reject(e)
      }
      resolve()
    }, 2001)
  })
})

test('shouldNotify(): returns true/false in the correct situations', () => {
  jest.mock('react-native', () => ({ NativeModules: {} }), { virtual: true })
  const { Configuration } = require('../Bugsnag')
  const c = new Configuration('API_KEY')
  expect(c.shouldNotify()).toEqual(true)
  c.notifyReleaseStages = [ 'production', 'staging' ]
  expect(c.shouldNotify()).toEqual(true)
  c.releaseStage = [ 'testing' ]
  expect(c.shouldNotify()).toEqual(false)
})

test('notify(): Non-error does not get reported', () => {
  const mockNotify = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify
      }
    }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')

  c.notify(1)
  c.notify(1, null, true)
  expect(mockNotify).toHaveBeenCalledTimes(0)
})

test('notify(): Runs non-blocking by default', () => {
  const mockNotify = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify
      }
    }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')

  c.notify(new Error('boom!'))
  expect(mockNotify).toHaveBeenCalledWith(
    expect.objectContaining({
      apiKey: 'API_KEY',
      blocking: false,
      errorClass: 'Error',
      errorMessage: 'boom!',
      severity: 'warning',
      unhandled: false,
      severityReason: 'handledException'
    })
  )
})

test('notify(): Runs in a blocking state when specified', () => {
  const mockNotify = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify
      }
    }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')

  c.notify(new Error('nb boom!'), null, true)
  expect(mockNotify).toHaveBeenCalledWith(
    expect.objectContaining({
      apiKey: 'API_KEY',
      blocking: true,
      errorClass: 'Error',
      errorMessage: 'nb boom!',
      severity: 'warning',
      unhandled: false,
      severityReason: 'handledException'
    })
  )
})

test('notify(): supplying unhandled state as param changes payload', () => {
  const mockNotify = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify
      }
    }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')

  // send unhandled state
  c.notify(new Error('nb boom!'), null, true, null, {
    originalSeverity: 'warning',
    unhandled: false,
    severityReason: 'handledException'
  })
  expect(mockNotify).toHaveBeenCalledWith(
    expect.objectContaining({
      blocking: true,
      severity: 'warning',
      unhandled: false,
      severityReason: 'handledException'
    })
  )

  // mutate severity
  c.notify(new Error('Mutate Severity'), report => { report.severity = 'info' }, true, null, {
    originalSeverity: 'warning',
    unhandled: false,
    severityReason: 'handledException'
  })
  expect(mockNotify).toHaveBeenCalledWith(
    expect.objectContaining({
      blocking: true,
      severity: 'info',
      severityReason: 'userCallbackSetSeverity'
    })
  )
})

test('notify(): doesn’t call native notify() when shouldNotify() returns false', () => {
  const mockNotify = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify
      }
    }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  const c = new Client(config)

  // replace shouldNotify with a function that always returns false
  config.shouldNotify = () => false

  // non-blocking
  c.notify(new Error('boom!'))
  expect(mockNotify).toHaveBeenCalledTimes(0)

  // blocking
  c.notify(new Error('nb boom!'), null, true)
  expect(mockNotify).toHaveBeenCalledTimes(0)
})

test('leaveBreadcrumb(): calls the native leaveBreadcrumb method correctly', () => {
  const mockLeaveBreadcrumb = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn(), leaveBreadcrumb: mockLeaveBreadcrumb } }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  const c = new Client(config)

  // reject name=String, metadata=undefined
  c.leaveBreadcrumb(1)
  expect(mockLeaveBreadcrumb).toHaveBeenCalledTimes(0)
  mockLeaveBreadcrumb.mockClear()

  // accept name=String, metadata=undefined
  c.leaveBreadcrumb('menu_expand')
  expect(mockLeaveBreadcrumb).toHaveBeenCalledWith({
    name: 'menu_expand',
    type: 'manual',
    metadata: {}
  })
  mockLeaveBreadcrumb.mockClear()

  // accept name=String, metadata=String
  c.leaveBreadcrumb('menu_expand', 'via longpress')
  expect(mockLeaveBreadcrumb).toHaveBeenCalledWith({
    name: 'menu_expand',
    type: 'manual',
    metadata: { message: { type: 'string', value: 'via longpress' } }
  })
  mockLeaveBreadcrumb.mockClear()

  // discard name=String, metadata=Number
  c.leaveBreadcrumb('menu_expand', 1)
  expect(mockLeaveBreadcrumb).toHaveBeenCalledWith({
    name: 'menu_expand',
    type: 'manual',
    metadata: {}
  })
  mockLeaveBreadcrumb.mockClear()
})

test('leaveBreadcrumb(): support setting "type" via metadata', () => {
  const mockLeaveBreadcrumb = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn(), leaveBreadcrumb: mockLeaveBreadcrumb } }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  const c = new Client(config)

  c.leaveBreadcrumb('menu_expand', { type: 'UI', buttonClass: 'submit' })
  expect(mockLeaveBreadcrumb).toHaveBeenCalledWith({
    name: 'menu_expand',
    type: 'UI',
    metadata: { buttonClass: { type: 'string', value: 'submit' } }
  })
  mockLeaveBreadcrumb.mockClear()
})

test('{enable|disable}ConsoleBreadCrumbs(): wraps/unwraps console methods and calls leaveBreadcrumb appropriately', () => {
  const mockLeaveBreadcrumb = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn(), leaveBreadcrumb: mockLeaveBreadcrumb } }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  const c = new Client(config)

  console.log('don’t mind me cluttering up the test output!')
  expect(mockLeaveBreadcrumb).toHaveBeenCalledTimes(0)

  c.enableConsoleBreadcrumbs()
  console.log('and me ;)')
  expect(mockLeaveBreadcrumb).toHaveBeenCalledTimes(1)

  c.disableConsoleBreadCrumbs()
  console.log('me also')
  expect(mockLeaveBreadcrumb).toHaveBeenCalledTimes(1)
})

test('config.consoleBreadcrumbsEnabled=true: causes console breadcrumbs to be enabled', () => {
  const mockLeaveBreadcrumb = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn(), leaveBreadcrumb: mockLeaveBreadcrumb } }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  config.consoleBreadcrumbsEnabled = true
  const c = new Client(config)

  console.warn('check 1, 2')
  expect(mockLeaveBreadcrumb).toHaveBeenCalledTimes(1)

  // because global side effects, ensure console wrapping is
  // switched off for the next test ¯\_(ツ)_/¯
  c.disableConsoleBreadCrumbs()
})

test('{enable|disable}ConsoleBreadCrumbs(): gracefully handles serialization edge-cases', () => {
  const mockLeaveBreadcrumb = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn(), leaveBreadcrumb: mockLeaveBreadcrumb } }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  config.consoleBreadcrumbsEnabled = true
  const c = new Client(config)

  const circular = {}
  circular.ref = circular

  console.log('undefined cannot have toString() called on it', undefined)
  console.warn('neither can null', null)
  console.error('and objects with circular refs cannot be passed to JSON.stringify()', circular)
  expect(mockLeaveBreadcrumb).toHaveBeenCalledTimes(3)

  // because global side effects, ensure console wrapping is
  // switched off for the next test ¯\_(ツ)_/¯
  c.disableConsoleBreadCrumbs()
})

test('setUser(): attempts to stringify non-strings and tolerates errors', () => {
  const mockSetUser = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn(), setUser: mockSetUser } }
  }), { virtual: true })
  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  const c = new Client(config)
  c.setUser('123', 'Jim', 'jim@bugsnag.com')
  c.setUser(4, 'Jim', 'jim@bugsnag.com')
  c.setUser(null, 'Jim', 'jim@bugsnag.com')
  c.setUser(Object.create(null), 'Jim', 'jim@bugsnag.com')
  expect(mockSetUser).toHaveBeenCalledTimes(4)
  expect(mockSetUser.mock.calls[0][0]).toEqual({ id: '123', name: 'Jim', email: 'jim@bugsnag.com' })
  expect(mockSetUser.mock.calls[1][0]).toEqual({ id: '4', name: 'Jim', email: 'jim@bugsnag.com' })
  expect(mockSetUser.mock.calls[2][0]).toEqual({ id: 'null', name: 'Jim', email: 'jim@bugsnag.com' })
  expect(mockSetUser.mock.calls[3][0]).toEqual({ name: 'Jim', email: 'jim@bugsnag.com' })
})
