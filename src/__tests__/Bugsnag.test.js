beforeEach(() => {
  // ensure freshly mocked clients in each test
  jest.resetModules()

  // mock globals set by RN at runtime
  global.__DEV__ = false
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
  expect(c.notify).toHaveBeenCalledWith(expect.any(Error), expect.any(Function), false, expect.any(Function))
})

test('handlePromiseRejections(): error handler calls notify(…) correctly', () => {
  jest.mock('react-native', () => ({
    NativeModules: { BugsnagReactNative: { startWithOptions: jest.fn() } }
  }), { virtual: true })

  const { Client, Configuration } = require('../Bugsnag')
  const config = new Configuration('API_KEY')
  config.handlePromiseRejections = true
  const c = new Client(config)

  c.notify = jest.fn()
  Promise.reject(new Error('pboom!'))
  // promise rejection handler has a slight async delay before running, so check after minimal timeout
  setTimeout(() => expect(c.notify).toHaveBeenCalledWith(expect.any(Error)))
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

test('notify(): calls the correct native notify/notifyBlocking method', () => {
  const mockNotify = jest.fn()
  const mockNotifyBlocking = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify,
        notifyBlocking: mockNotifyBlocking
      }
    }
  }), { virtual: true })

  const { Client } = require('../Bugsnag')
  const c = new Client('API_KEY')

  // called with non-error
  c.notify(1)
  c.notify(1, null, true)
  expect(mockNotify).toHaveBeenCalledTimes(0)
  expect(mockNotifyBlocking).toHaveBeenCalledTimes(0)

  // non-blocking
  c.notify(new Error('boom!'))
  expect(mockNotify).toHaveBeenCalledWith(
    expect.objectContaining({ apiKey: 'API_KEY', errorClass: 'Error', errorMessage: 'boom!', severity: 'warning' })
  )

  // blocking
  c.notify(new Error('nb boom!'), null, true)
  expect(mockNotifyBlocking).toHaveBeenCalledWith(
    expect.objectContaining({ apiKey: 'API_KEY', errorClass: 'Error', errorMessage: 'nb boom!', severity: 'warning' }),
    true,
    undefined
  )
})

test('notify(): doesn’t call native notify/notifyBlocking when shouldNotify() returns false', () => {
  const mockNotify = jest.fn()
  const mockNotifyBlocking = jest.fn()
  jest.mock('react-native', () => ({
    NativeModules: {
      BugsnagReactNative: {
        startWithOptions: jest.fn(),
        notify: mockNotify,
        notifyBlocking: mockNotifyBlocking
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
  expect(mockNotifyBlocking).toHaveBeenCalledTimes(0)
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
