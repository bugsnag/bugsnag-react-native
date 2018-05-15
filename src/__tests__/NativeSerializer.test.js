/* global test, expect */

import serializeForNativeLayer from '../NativeSerializer'

test('serializeForNativeLayer converts arrays, objects, strings, numbers and booleans', () => {
  expect(serializeForNativeLayer({
    arr: [ 0, 1, 2 ],
    obj: {
      a: 'a',
      b: 'b',
      c: 'c'
    },
    x: 10,
    y: 'str',
    yes: false
  })).toEqual({
    arr: {
      type: 'map',
      value: {
        '0': { type: 'number', value: 0 },
        '1': { type: 'number', value: 1 },
        '2': { type: 'number', value: 2 }
      }
    },
    obj: {
      type: 'map',
      value: {
        a: { type: 'string', value: 'a' },
        b: { type: 'string', value: 'b' },
        c: { type: 'string', value: 'c' }
      }
    },
    x: { type: 'number', value: 10 },
    y: { type: 'string', value: 'str' },
    yes: { type: 'boolean', value: false }
  })
})

test('serializeForNativeLayer handles circular structures', () => {
  const objA = {}
  objA.ref = objA

  // this tests the top level object being referred to as a node
  expect(serializeForNativeLayer(objA)).toEqual({ ref: { type: 'string', value: '[circular]' } })

  const objB = {}
  objB.leafA = {}
  objB.leafB = {}
  objB.leafA.ref = objB.leafB
  objB.leafB.ref = objB.leafA

  // this tests subtrees referring to eachother
  expect(serializeForNativeLayer(objB)).toEqual({
    leafA: {
      type: 'map',
      value: {
        ref: {
          type: 'map',
          value: {
            ref: { type: 'string', value: '[circular]' }
          }
        }
      }
    },
    leafB: { type: 'string', value: '[circular]' }
  })
})

test('serializeForNativeLayer handles deep nesting', () => {
  const nesty = {
    zero: {
      one: {
        two: {
          three: {
            four: {
              five: { six: { seven: { eight: { nine: { ten: { eleven: 'TOO_DEEP!' } } } } } }
            }
          }
        }
      }
    }
  }
  expect(serializeForNativeLayer(nesty)).toEqual({
    zero: {
      type: 'map',
      value: {
        one: {
          type: 'map',
          value: {
            two: {
              type: 'map',
              value: {
                three: {
                  type: 'map',
                  value: {
                    four: {
                      type: 'map',
                      value: {
                        five: {
                          type: 'map',
                          value: {
                            six: {
                              type: 'map',
                              value: {
                                seven: {
                                  type: 'map',
                                  value: {
                                    eight: {
                                      type: 'map',
                                      value: {
                                        nine: {
                                          type: 'map',
                                          value: {
                                            ten: { type: 'string', value: '[max depth exceeded]' }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  })
})

test('serializeForNativeLayer handles error objects', () => {
  const err = new Error('Oh no')
  const serialized = serializeForNativeLayer(err)
  expect(serialized['message']).toEqual({
    type: 'string',
    value: 'Oh no'
  })
  expect(serialized['stack']['type']).toEqual('string')
  expect(serialized['stack']['value'].length).toBeGreaterThan(0)
  expect(serialized['name']).toEqual({
    type: 'string',
    value: 'Error'
  })
})
