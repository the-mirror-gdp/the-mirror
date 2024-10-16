import { redirect } from 'next/navigation'

/**
 * Redirects to a specified path with an encoded message as a query parameter.
 * @param {('error' | 'success')} type - The type of message, either 'error' or 'success'.
 * @param {string} path - The path to redirect to.
 * @param {string} message - The message to be encoded and added as a query parameter.
 * @returns {never} This function doesn't return as it triggers a redirect.
 */
export function encodedRedirect(
  type: 'error' | 'success',
  path: string,
  message: string
) {
  return redirect(`${path}?${type}=${encodeURIComponent(message)}`)
}

/**
 * Used for forms since useFormArray from rhf isn't feasible with shadcn. Example
 * const obj = {
  local_position: [1, 2, 3]
// Output: { local_positionX: 1, local_positionY: 2, local_positionZ: 3 }
 */
export function convertVecNumbersToIndividual(
  obj: {
    [key: string]: [number, number, number]
  } & any,
  key = 'local_position'
) {
  // const [x, y, z, w] = obj[key] // w code is here for later, just not tested
  const [x, y, z] = obj[key]

  // Construct the new keys dynamically
  const val = {
    [`${key}X`]: x,
    [`${key}Y`]: y,
    [`${key}Z`]: z
  }
  // if (w !== undefined) {
  //   val[`${key}W`] = w
  // }

  return val
}

// export function convertIndividualToVecNumbers(
//   obj: { [key: string]: number } & any,
//   key = 'local_position'
// ) {
//   // Find the base key (like 'local_position') by looking at the first key before the 'X', 'Y', 'Z' suffix.
//   const baseKey = key.replace(/[XYZ]$/, '')

//   if (typeof obj[`${baseKey}X`] == 'string') {
//     debugger
//   }
//   // Reconstruct the array from individual components
//   const vec: [number, number, number, number?] = [
//     obj[`${baseKey}X`],
//     obj[`${baseKey}Y`],
//     obj[`${baseKey}Z`]
//   ]
//   if (obj[`${baseKey}W`] !== undefined) {
//     vec.push(obj[`${baseKey}W`])
//   }

//   const val = {
//     [baseKey]: vec
//   }
//   debugger
//   return val
// }
