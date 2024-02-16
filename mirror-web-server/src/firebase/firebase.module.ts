import { Module, Global, DynamicModule } from '@nestjs/common'
import * as admin from 'firebase-admin'
import { FirebaseAuthenticationService } from './firebase-authentication.service'
import { FirebaseDatabaseService } from './firebase-database.service'

@Global()
@Module({})
export class FirebaseModule {
  static initialize(): DynamicModule {
    const FirebaseProvider = {
      provide: 'FIREBASE',
      useFactory: () => {
        let credential
        if (
          (process.env.NODE_ENV == 'development' ||
            process.env.NODE_ENV == 'test') &&
          !process.env.CI // if CI, we want applicationDefault()
        ) {
          const firebaseCredentials = require(`../../${process.env.FIREBASE_CRED_FILE}`) // eslint-disable-line @typescript-eslint/no-var-requires
          if (process.env.NODE_ENV == 'test' && !firebaseCredentials) {
            throw new Error(
              'Failed to load firebase credentials' + firebaseCredentials
            )
          }
          credential = admin.credential.cert(firebaseCredentials)
        } else {
          credential = admin.credential.applicationDefault()
        }
        const firebaseApp = admin.initializeApp({
          credential,
          databaseURL: process.env.FIREBASE_DB_URL
        })
        return firebaseApp
      }
    }

    return {
      module: FirebaseModule,
      providers: [
        FirebaseProvider,
        FirebaseAuthenticationService,
        FirebaseDatabaseService
      ],
      exports: [
        FirebaseProvider,
        FirebaseAuthenticationService,
        FirebaseDatabaseService
      ]
    }
  }
}
