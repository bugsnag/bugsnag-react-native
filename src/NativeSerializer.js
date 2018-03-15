const allowedMapObjectTypes = [ 'string', 'number', 'boolean' ]

/**
 * Convert an object into a structure with types suitable for serializing
 * across to native code.
 */
const serializeForNativeLayer = (map, maxDepth = 10, depth = 0, seen = new Set()) => {
  seen.add(map)
  const output = {}
  for (const key in map) {
    if (!{}.hasOwnProperty.call(map, key)) continue

    const value = map[key]

    // Checks for `null`, NaN, and `undefined`.
    if ([ undefined, null ].includes(value) || (typeof value === 'number' && isNaN(value))) {
      output[key] = { type: 'string', value: String(value) }
    } else if (typeof value === 'object') {
      if (seen.has(value)) {
        output[key] = { type: 'string', value: '[circular]' }
      } else if (depth === maxDepth) {
        output[key] = { type: 'string', value: '[max depth exceeded]' }
      } else {
        output[key] = { type: 'map', value: serializeForNativeLayer(value, maxDepth, depth + 1, seen) }
      }
    } else {
      const type = typeof value
      if (allowedMapObjectTypes.includes(type)) {
        output[key] = { type: type, value: value }
      } else {
        console.warn(`Could not serialize breadcrumb data for '${key}': Invalid type '${type}'`)
      }
    }
  }
  return output
}

export default serializeForNativeLayer
