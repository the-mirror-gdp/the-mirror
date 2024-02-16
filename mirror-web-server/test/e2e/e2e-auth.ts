import { INestApplication } from '@nestjs/common'
import axios from 'axios'
import request from 'supertest'

/**
 * @description Authenticates directly with Google/Firebase
 * @date 2023-03-16 00:09
 */
export async function getFirebaseToken(email: string, password: string) {
  const url = `https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=${'AIzaSyARDm49cUSJrN5h2kv8_SUD7ADZJM4yTuU'}`
  const res = await axios.post(url, {
    email,
    password,
    returnSecureToken: true
  })

  return res.data // firebase {idToken}
}

/**
 *
 * @description The reason we're using the app server here instead of the firebase admin SDK is because we would have to auth TWICE with firebase from the same process since the app itself auths with firebase.
 */
export async function deleteFirebaseTestAccount(
  app: INestApplication,
  email: string
) {
  if (!email) {
    console.error(
      'deleteFirebaseTestAccount FAILED: email is required. This may appear if other tests failed'
    )
    return
  }
  // safety check
  if (email.includes('e2e') && email.includes('@themirror.space')) {
    // can delete
    try {
      await request(app.getHttpServer())
        .post(`/auth/test/delete-test-account`)
        .send({
          email
        })
      console.log(
        'deleteFirebaseTestAccount: Deleted test account with email: ' + email
      )
      return email
    } catch (error) {
      console.warn(error)
    }
  } else {
    console.warn(
      `Attempted to delete a non-e2e account: ${email}. Returning for safety`
    )
    return
  }
}
