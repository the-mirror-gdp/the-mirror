import * as mixpanelLib from 'mixpanel'
import { Injectable } from '@nestjs/common'
require('dotenv').config()

const mixpanel = mixpanelLib.init(process.env.MIXPANEL_TOKEN, {
  keepAlive: false
})

@Injectable()
export class MixpanelService {}
