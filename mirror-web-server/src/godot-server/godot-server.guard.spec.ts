import { Logger } from '@nestjs/common'
import { GodotServerGuard } from './godot-server.guard'

describe('GodotServerGuard', () => {
  it('should be defined', () => {
    expect(new GodotServerGuard(new Logger())).toBeDefined()
  })
})
