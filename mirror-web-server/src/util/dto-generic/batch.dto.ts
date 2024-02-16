import { IsNotEmpty } from 'class-validator'

export class Batch<T> {
  @IsNotEmpty()
  batch: T[]
}
