import { Batch } from '../../util/dto-generic/batch.dto'
import { UpdateSpaceObjectDto } from './update-space-object.dto'

type PartialSpaceObjectWithId = UpdateSpaceObjectDto & { id: string }

export class UpdateBatchSpaceObjectDto extends Batch<PartialSpaceObjectWithId> {}
