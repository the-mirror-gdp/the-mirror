import { PipelineStage } from 'mongoose'
export type MongoObjectIdString = string

// The intent for these is to increase static typing usage for more safety, e.g. to ensure a spaceId isn't inputted where a userId should be.
export type SpaceId = string
export type SpaceObjectId = string
export type SpaceVersionId = string
export type MaterialInstanceId = string
export type AssetId = string
export type UserId = string
export type UserGroupId = string
export type UserEntityActionId = string
export type TagId = string
export type UserFeedbackItemId = string
export type ZoneId = string
export type MirrorDBRecordId = string
export type PurchaseOptionId = string
/**
 * @description SCALER UUID
 */
export type ScalerContainerUuid = string
/**
 * @description alias for ZoneId, but to be clear that it's a Mongo ObjectId and NOT a UUID
 */
export type MongoZoneId = string
export type CustomDataId = string
export type SpaceVariablesDataId = string
export type BlockId = string

export type EntityId =
  | SpaceId
  | SpaceObjectId
  | AssetId
  | UserId
  | TagId
  | UserFeedbackItemId
  | UserGroupId
  | ZoneId
  | CustomDataId
  | BlockId

/**
 * @description After hours of debugging, this is how you have to $match query for an id that could be either an ObjectId or a String. We need to standardize this at some point. Mongoose automatically casts strings<>ObjectIds, but an aggregation pipeline does not.
 * @date 2023-05-04 00:36
 */
export function aggregationMatchId(
  idToMatch: string,
  key = '$_id'
): PipelineStage {
  return {
    $match: {
      $expr: {
        $or: [
          {
            $eq: [key, { $toObjectId: idToMatch }]
          },
          {
            $eq: [key, idToMatch]
          }
        ]
      }
    }
  }
}
