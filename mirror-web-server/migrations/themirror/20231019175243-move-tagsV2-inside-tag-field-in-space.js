const MIGRATION_SCRIPT_NAME =
  '20231019175243-move-tagsV2-inside-tag-field-in-space'
const PREVIOUS_TAGSV2_KEY = `previousTagsV2-move-tagsV2-inside-tag-field-in-space`

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript_${MIGRATION_SCRIPT_NAME}`
    const previousTagsV2Key = `migrationScript_${PREVIOUS_TAGSV2_KEY}`

    const pipeline = [
      {
        $match: {
          tagsV2: { $exists: true }
        }
      },
      {
        $set: {
          [previousTagsV2Key]: '$tagsV2'
        }
      },
      {
        $unset: 'tagsV2'
      },
      {
        $lookup: {
          from: 'tags',
          localField: previousTagsV2Key,
          foreignField: '_id',
          as: 'tagsData'
        }
      },
      {
        $unwind: '$tagsData'
      },
      {
        $group: {
          _id: '$_id',
          newTags: {
            $push: {
              name: '$tagsData.name',
              type: '$tagsData.__t',
              thirdPartySourceHomePageUrl: {
                $ifNull: ['$tagsData.thirdPartySourceHomePageUrl', null]
              }
            }
          },
          [migrationScriptKey]: { $first: true },
          [previousTagsV2Key]: { $first: '$tagsData._id' }
        }
      },
      {
        $set: {
          tags: {
            $function: {
              body: getTags.toString(),
              args: ['$newTags'],
              lang: 'js'
            }
          }
        }
      }
    ]

    const aggregationCursor = spacesCollection.aggregate(pipeline)

    const bulkOps = []

    const newMigrationsScriptKey = migrationScriptKey.replace('_', '.')
    const newPreviousTagsV2Key = previousTagsV2Key.replace('_', '.')

    await aggregationCursor.forEach((space) => {
      bulkOps.push({
        updateOne: {
          filter: { _id: space._id },
          update: [
            {
              $set: {
                tags: space.tags,
                [newMigrationsScriptKey]: true,
                [newPreviousTagsV2Key]: '$tagsV2'
              }
            },
            {
              $unset: ['tagsV2']
            }
          ]
        }
      })
    })

    if (bulkOps.length > 0) {
      await spacesCollection.bulkWrite(bulkOps)
    }

    await spacesCollection.updateMany(
      { $or: [{ tagsV2: { $exists: true } }, { tags: { $type: 'array' } }] },
      [
        {
          $set: {
            [newMigrationsScriptKey]: true,
            [newPreviousTagsV2Key]: []
          }
        },
        { $unset: ['tagsV2', 'tags'] }
      ]
    )
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`
    const previousTagsV2Key = `migrationScript.${PREVIOUS_TAGSV2_KEY}`

    await spacesCollection.updateMany(
      {
        $and: [
          { [migrationScriptKey]: { $exists: true } },
          { [previousTagsV2Key]: { $exists: true } }
        ]
      },
      [
        {
          $set: {
            tagsV2: `$${previousTagsV2Key}`
          }
        },
        {
          $unset: ['tags', migrationScriptKey, previousTagsV2Key]
        }
      ]
    )
  }
}

//TagType: 'ThemeTag' | 'ThirdPartyTag' ...
//tagAndType: {name: string, type: TagType, thirdPartySourceHomePageUrl?: string}[]
function getTags(tagsAndTypes) {
  const tags = {}

  for (const tagAndType of tagsAndTypes) {
    switch (tagAndType.type) {
      case 'ThirdPartySourceTag':
        if (tags.thirdParty) {
          tags.thirdParty.push({
            name: tagAndType.name,
            thirdPartySourceHomePageUrl: tagAndType.thirdPartySourceHomePageUrl
          })
        } else {
          tags.thirdParty = [
            {
              name: tagAndType.name,
              thirdPartySourceHomePageUrl:
                tagAndType.thirdPartySourceHomePageUrl
            }
          ]
        }
        break

      case 'UserGeneratedTag':
        if (tags.userGenerated) {
          tags.userGenerated.push(tagAndType.name)
        } else {
          tags.userGenerated = [tagAndType.name]
        }
        break

      case 'SpaceGenreTag':
        if (tags.spaceGenre) {
          tags.spaceGenre.push(tagAndType.name)
        } else {
          tags.spaceGenre = [tagAndType.name]
        }
        break

      case 'MaterialTag':
        if (tags.material) {
          tags.material.push(tagAndType.name)
        } else {
          tags.material = [tagAndType.name]
        }
        break

      case 'ThemeTag':
        if (tags.theme) {
          tags.theme.push(tagAndType.name)
        } else {
          tags.theme = [tagAndType.name]
        }
        break

      case 'AIGeneratedByTMTag':
        if (tags.aiGenerated) {
          tags.aiGenerated.push(tagAndType.name)
        } else {
          tags.aiGenerated = [tagAndType.name]
        }
        break
    }
  }

  return tags
}
