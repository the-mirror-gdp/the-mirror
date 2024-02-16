import { IBasis } from './basis.model'
import { IVector3 } from './vector3.model'

export interface ITransform {
  basis: IBasis
  origin: IVector3
}
