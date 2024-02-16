import { Injectable } from '@nestjs/common'
import * as admin from 'firebase-admin'
import { Inject } from '@nestjs/common'
import * as jwt from 'jsonwebtoken'

@Injectable()
export class FirebaseAuthenticationService {
  constructor(@Inject('FIREBASE') private firebase: admin.app.App) {}

  async getUser(uid: string): Promise<admin.auth.UserRecord> {
    try {
      return await this.firebase.auth().getUser(uid)
    } catch (error) {
      throw error
    }
  }

  async getUserByEmail(email: string): Promise<admin.auth.UserRecord> {
    try {
      return await this.firebase.auth().getUserByEmail(email)
    } catch (error) {
      throw error
    }
  }

  createCustomToken(uid: string, additionalClaims?: object): Promise<string> {
    return new Promise((resolve, reject) => {
      try {
        const payload = { uid, ...additionalClaims }
        const serviceAccount = require(`../../${process.env.FIREBASE_CRED_FILE}`)

        jwt.sign(
          payload,
          serviceAccount.private_key,
          { algorithm: 'RS256', expiresIn: '1h' },
          (err, token) => {
            if (err) {
              reject(err)
            } else {
              resolve(token)
            }
          }
        )
      } catch (error) {
        reject(error)
      }
    })
  }

  async createUser(
    properties: admin.auth.CreateRequest
  ): Promise<admin.auth.UserRecord> {
    try {
      return await this.firebase.auth().createUser(properties)
    } catch (error) {
      throw error
    }
  }

  async updateUser(
    uid: string,
    properties: admin.auth.UpdateRequest
  ): Promise<admin.auth.UserRecord> {
    try {
      return await this.firebase.auth().updateUser(uid, properties)
    } catch (error) {
      throw error
    }
  }

  async deleteUser(uid: string): Promise<void> {
    try {
      await this.firebase.auth().deleteUser(uid)
    } catch (error) {
      throw error
    }
  }

  async verifyIdToken(
    idToken: string,
    checkRevoked?: boolean
  ): Promise<admin.auth.DecodedIdToken> {
    try {
      return await this.firebase.auth().verifyIdToken(idToken, checkRevoked)
    } catch (error) {
      throw error
    }
  }
}
