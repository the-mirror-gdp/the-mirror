import {
  adjectives,
  animals,
  colors,
  uniqueNamesGenerator
} from 'unique-names-generator'
import supertest from 'supertest'

// this is used to show the logs on a failed test for supertest https://github.com/ladjs/supertest/issues/12#issuecomment-978005355
declare module 'supertest' {
  interface Test {
    _assert(
      this: supertest.Test,
      resError: Error,
      res: supertest.Response,
      fn: Function // TODO should this be typed differently?
    )
  }
}

Object.defineProperties((supertest as any).Test.prototype, {
  _assert: {
    value: (supertest as any).Test.prototype.assert
  },
  assert: {
    value: function (this: supertest.Test, resError, res, fn) {
      this._assert(resError, res, (err, res) => {
        if (err) {
          const originalMessage = err.message
          console.error(originalMessage)

          err.message = `${err.message}\nstatus: ${
            res.status
          }\nresponse: ${JSON.stringify(res.body, null, 2)}`
          // Must update the stack trace as what supertest prints is the stacktrace)
          err.stack = err.stack?.replace(originalMessage, err.message)
        }
        fn.call(this, err, res)
      })
    }
  }
})

export function generateFormattedDate() {
  const currentDate = new Date()
  const year = currentDate.getFullYear()
  const month = String(currentDate.getMonth() + 1).padStart(2, '0')
  const date = String(currentDate.getDate()).padStart(2, '0')
  const hours = String(currentDate.getHours()).padStart(2, '0')
  const minutes = String(currentDate.getMinutes()).padStart(2, '0')
  const seconds = String(currentDate.getSeconds()).padStart(2, '0')
  const ms = String(currentDate.getMilliseconds()).padStart(2, '0')

  const formattedDate = `${year}_${month}_${date}-${hours}-${minutes}-${seconds}-${ms}`

  return formattedDate
}

export function generateRandomE2EEmail() {
  const email = `enge2e+${generateFormattedDate()}@themirror.space`
  return email
}

export function generateRandomName() {
  const randomName = uniqueNamesGenerator({
    dictionaries: [adjectives, colors, animals]
  })
  return randomName
}

export function print(obj: object) {
  return JSON.stringify(obj, null, 2)
}
