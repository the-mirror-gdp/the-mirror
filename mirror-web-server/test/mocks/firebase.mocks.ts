import { FirebaseModule } from '../../src/firebase/firebase.module'

export const firebaseAdminMock = () => {
  return FirebaseModule.initialize()
  // return FirebaseAdminModule.forRootAsync({
  //   useFactory: () => ({
  //     credential:
  //       process.env.NODE_ENV == NODE_ENV.DEVELOPMENT
  //         ? admin.credential.cert(
  //             require(`../${process.env.FIREBASE_CRED_FILE}`)
  //           )
  //         : admin.credential.applicationDefault(),
  //     databaseURL: process.env.FIREBASE_DB_URL
  //   })
  // })
}
