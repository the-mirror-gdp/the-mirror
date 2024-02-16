import { Injectable } from '@nestjs/common'
import * as admin from 'firebase-admin'
import { Inject } from '@nestjs/common'

@Injectable()
export class FirebaseDatabaseService {
  constructor(@Inject('FIREBASE') private firebase: admin.app.App) {}

  ref(path: string): admin.database.Reference {
    return this.firebase.database().ref(path)
  }
}
