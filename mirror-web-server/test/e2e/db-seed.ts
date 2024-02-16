import { MongoClient, ObjectId } from 'mongodb'
import {
  asset506Seeded,
  asset507MaterialMirrorPublicLibrarySeeded,
  asset508MaterialMirrorPublicLibraryThirdPartySourceSeeded,
  asset509MeshMirrorPublicLibraryThirdPartySourceSeeded,
  asset510WithManagerDefaultRoleSeeded,
  asset511WithManagerDefaultRoleSeeded,
  asset512WithObserverDefaultRoleSeeded,
  asset513WithDiscoverDefaultRoleSeeded,
  asset514WithNoRoleDefaultRoleSeeded
} from '../stubs/asset.model.stub'
import {
  roleStubDefaultManager,
  roleStubDefaultContributor,
  roleStubDefaultObserver,
  roleStubDefaultDiscover,
  roleStubDefaultNoRole,
  roleStubDefaultOwner
} from '../stubs/role.model.stub'
import {
  environmentData,
  environmentId,
  privateSpace4DataGroupOwned,
  privateSpace1DataIndividualOwned,
  privateSpaceOwnerUser,
  privateSpace4OwnerUserGroup,
  publicSpace3Data,
  publicSpace3OwnerUserC,
  publicSpace3OwnerUserId,
  roleForPrivateSpace4GroupOwned,
  roleForPrivateSpaceIndividualOwned,
  roleForPublicSpace3,
  defaultCustomData0ForSpaces,
  space10WithManagerDefaultRole,
  space11WithContributorDefaultRole,
  space12WithObserverDefaultRole,
  space13WithDiscoverDefaultRole,
  space14WithNoRoleDefaultRole,
  space17ForZoneToBeCreated,
  space19ForZoneToBeCreatedWithSpaceVersion,
  space20WithActiveSpaceVersion,
  space18SeededForSeededZone,
  publicSpace21Data
} from '../stubs/space.model.stub'
import {
  spaceObject1InPrivateSpace,
  spaceObject2InPublicManagerSpace,
  spaceObject7ForParentSpaceObjectInManagerSpace,
  spaceObject7ForSeededAsset506
} from '../stubs/spaceObject.model.stub'
import {
  spaceVersion1,
  spaceVersion2ForSpace20WithActiveSpaceVersion
} from '../stubs/spaceVersion.model.stub'
import {
  mockTagAMirrorPublicLibrary,
  mockTagBMirrorPublicLibrary,
  mockTagCMirrorPublicLibraryThirdPartySource
} from '../stubs/tag.model.stub'
import { mockUser0, mockUser1OwnerOfZone } from '../stubs/user.model.stub'
import { zone4UsersPresentSeeded } from '../stubs/zone.model.stub'
import { checkDbUriIsLocalHost } from './e2e-db-util'

export async function seedDatabase(uri: string, dbName: string) {
  const client = new MongoClient(uri as string)
  const db = client.db(dbName)

  if (checkDbUriIsLocalHost(uri)) {
    /**
     * Spaces
     */
    await db.collection('spaces').insertMany([
      {
        ...privateSpace1DataIndividualOwned,
        _id: new ObjectId(privateSpace1DataIndividualOwned._id)
      },
      {
        ...privateSpace4DataGroupOwned,
        _id: new ObjectId(privateSpace4DataGroupOwned._id)
      },
      {
        ...publicSpace3Data,
        _id: new ObjectId(publicSpace3Data._id)
      },
      {
        ...space10WithManagerDefaultRole,
        _id: new ObjectId(space10WithManagerDefaultRole._id)
      },
      {
        ...space11WithContributorDefaultRole,
        _id: new ObjectId(space11WithContributorDefaultRole._id)
      },
      {
        ...space12WithObserverDefaultRole,
        _id: new ObjectId(space12WithObserverDefaultRole._id)
      },
      {
        ...space13WithDiscoverDefaultRole,
        _id: new ObjectId(space13WithDiscoverDefaultRole._id)
      },
      {
        ...space14WithNoRoleDefaultRole,
        _id: new ObjectId(space14WithNoRoleDefaultRole._id)
      },
      {
        ...space17ForZoneToBeCreated,
        _id: new ObjectId(space17ForZoneToBeCreated._id)
      },
      {
        ...space18SeededForSeededZone,
        _id: new ObjectId(space18SeededForSeededZone._id)
      },
      {
        ...space19ForZoneToBeCreatedWithSpaceVersion,
        _id: new ObjectId(space19ForZoneToBeCreatedWithSpaceVersion._id)
      },
      {
        ...space20WithActiveSpaceVersion,
        _id: new ObjectId(space20WithActiveSpaceVersion._id)
      },
      {
        ...publicSpace21Data,
        _id: new ObjectId(publicSpace21Data._id)
      }
    ])

    /**
     * Assets
     */
    await db.collection('assets').insertMany([
      {
        ...asset506Seeded,
        _id: new ObjectId(asset506Seeded._id)
      },
      {
        ...asset507MaterialMirrorPublicLibrarySeeded,
        _id: new ObjectId(asset507MaterialMirrorPublicLibrarySeeded._id)
      },
      {
        ...asset508MaterialMirrorPublicLibraryThirdPartySourceSeeded,
        _id: new ObjectId(
          asset508MaterialMirrorPublicLibraryThirdPartySourceSeeded._id
        )
      },
      {
        ...asset509MeshMirrorPublicLibraryThirdPartySourceSeeded,
        _id: new ObjectId(
          asset509MeshMirrorPublicLibraryThirdPartySourceSeeded._id
        )
      },
      {
        ...asset510WithManagerDefaultRoleSeeded,
        _id: new ObjectId(asset510WithManagerDefaultRoleSeeded._id)
      },
      {
        ...asset511WithManagerDefaultRoleSeeded,
        _id: new ObjectId(asset511WithManagerDefaultRoleSeeded._id)
      },
      {
        ...asset512WithObserverDefaultRoleSeeded,
        _id: new ObjectId(asset512WithObserverDefaultRoleSeeded._id)
      },
      {
        ...asset513WithDiscoverDefaultRoleSeeded,
        _id: new ObjectId(asset513WithDiscoverDefaultRoleSeeded._id)
      },
      {
        ...asset514WithNoRoleDefaultRoleSeeded,
        _id: new ObjectId(asset514WithNoRoleDefaultRoleSeeded._id)
      }
    ])

    /**
     * SpaceObjects
     */
    await db.collection('spaceobjects').insertMany([
      {
        ...spaceObject1InPrivateSpace,
        _id: new ObjectId(spaceObject1InPrivateSpace._id)
      },
      {
        ...spaceObject2InPublicManagerSpace,
        _id: new ObjectId(spaceObject2InPublicManagerSpace._id)
      },
      {
        ...spaceObject7ForSeededAsset506,
        _id: new ObjectId(spaceObject7ForSeededAsset506._id)
      },
      {
        ...spaceObject7ForParentSpaceObjectInManagerSpace,
        _id: new ObjectId(spaceObject7ForParentSpaceObjectInManagerSpace._id)
      }
    ])

    /**
     * Tags
     */
    await db.collection('tags').insertMany([
      {
        ...mockTagAMirrorPublicLibrary,
        _id: new ObjectId(mockTagAMirrorPublicLibrary._id)
      },
      {
        ...mockTagBMirrorPublicLibrary,
        _id: new ObjectId(mockTagBMirrorPublicLibrary._id)
      },
      {
        ...mockTagCMirrorPublicLibraryThirdPartySource,
        _id: new ObjectId(mockTagCMirrorPublicLibraryThirdPartySource._id)
      }
    ])

    /**
     * SpaceVersion
     */
    await db.collection('spaceversions').insertMany([
      {
        ...spaceVersion1,
        _id: new ObjectId(spaceVersion1._id)
      },
      {
        ...spaceVersion2ForSpace20WithActiveSpaceVersion,
        _id: new ObjectId(spaceVersion2ForSpace20WithActiveSpaceVersion._id)
      }
    ])

    /**
     * Zone
     */
    await db.collection('zones').insertMany([
      {
        ...zone4UsersPresentSeeded,
        _id: new ObjectId(zone4UsersPresentSeeded._id)
      }
    ])

    /**
     * CustomData
     */
    await db.collection('customdatas').insertMany([
      {
        ...defaultCustomData0ForSpaces,
        _id: new ObjectId(defaultCustomData0ForSpaces._id)
      }
    ])

    /**
     * Users
     */
    await db.collection('users').insertMany([
      {
        ...publicSpace3OwnerUserC,
        _id: new ObjectId(publicSpace3OwnerUserC._id)
      },
      {
        ...privateSpaceOwnerUser,
        _id: new ObjectId(privateSpaceOwnerUser._id)
      },
      {
        ...mockUser0,
        _id: new ObjectId(mockUser0._id)
      },
      {
        ...mockUser1OwnerOfZone,
        _id: new ObjectId(mockUser1OwnerOfZone._id)
      }
    ])

    /**
     * UserGroups
     */
    await db.collection('usergroups').insertMany([
      {
        ...privateSpace4OwnerUserGroup,
        _id: new ObjectId(privateSpace4OwnerUserGroup._id)
      }
    ])

    /**
     * Roles
     */
    await db.collection('roles').insertMany([
      {
        ...roleForPublicSpace3,
        _id: new ObjectId(roleForPublicSpace3._id)
      },
      {
        ...roleForPrivateSpaceIndividualOwned,
        _id: new ObjectId(roleForPrivateSpaceIndividualOwned._id)
      },
      {
        ...roleForPrivateSpace4GroupOwned,
        _id: new ObjectId(roleForPrivateSpace4GroupOwned._id)
      },
      {
        ...roleStubDefaultOwner,
        _id: new ObjectId(roleStubDefaultOwner._id)
      },
      {
        ...roleStubDefaultManager,
        _id: new ObjectId(roleStubDefaultManager._id)
      },
      {
        ...roleStubDefaultContributor,
        _id: new ObjectId(roleStubDefaultContributor._id)
      },
      {
        ...roleStubDefaultObserver,
        _id: new ObjectId(roleStubDefaultObserver._id)
      },
      {
        ...roleStubDefaultDiscover,
        _id: new ObjectId(roleStubDefaultDiscover._id)
      },
      {
        ...roleStubDefaultNoRole,
        _id: new ObjectId(roleStubDefaultNoRole._id)
      }
    ])

    /**
     * Environments
     */
    await db.collection('environments').insertMany([
      {
        ...environmentData,
        _id: new ObjectId(environmentId)
      }
    ])

    return
  } else {
    console.error('Not running on localhost db; exiting. uri: ' + uri)
    process.exit(1)
  }
}
