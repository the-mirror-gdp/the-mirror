import {
  ContainerStatusResponse,
  CONTAINER_STATE
} from '../../src/zone/space-manager-external.service'
import { ZONE_MODE } from '../../src/zone/zone.schema'
import { vi } from 'vitest'

export const spaceManagerExternalServiceMock = {
  createZoneServer: vi.fn(
    async (
      spaceId: string,
      mode = ZONE_MODE.BUILD
    ): Promise<ContainerStatusResponse> => ({
      uuid: '84cdf6d4-552b-4a82-8ad1-e8d144702de6',
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      url: 'sample-url',
      space_id: '6483cd6e30306618972d856a', // dummy id
      space_version: '6483cd7abff4f6ebadea90ce', // dummy id
      space_mode: ZONE_MODE.BUILD,
      server_id: 'sample-server-id',
      gd_server_version: '5.3.1'
    })
  ),
  getZoneServerStatus: vi.fn(
    async (uuid: string): Promise<ContainerStatusResponse> => ({
      uuid: '3032ed76-ccd5-4091-9e53-9bd5fe024fe7',
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      server_id: 'sample-server-id',
      url: 'sample-url',
      space_id: '6483cd6e30306618972d856a', // dummy id
      space_version: '6483cd7abff4f6ebadea90ce', // dummy id
      space_mode: ZONE_MODE.BUILD,
      gd_server_version: '5.3.1'
    })
  ),
  getOrCreateHealthyZoneContainerForPlaySpaceVersion: vi.fn(
    async (uuid: string): Promise<ContainerStatusResponse> => ({
      uuid: '66185bcb-0fa7-4f1c-95fe-f1f801c03a72',
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      server_id: 'sample-server-id',
      url: 'sample-url',
      space_id: '6483cd6e30306618972d856a', // dummy id
      space_version: '6483cd7abff4f6ebadea90ce', // dummy id
      space_mode: ZONE_MODE.BUILD,
      gd_server_version: '5.3.1'
    })
  ),
  getVmStatus: vi.fn(
    async (uuid: string): Promise<ContainerStatusResponse> => ({
      uuid: 'c7dc9b66-3713-4a4e-aeb1-1387d0e6a2a8',
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      server_id: 'sample-server-id',
      url: 'sample-url',
      space_id: '6483cd6e30306618972d856a', // dummy id
      space_version: '6483cd7abff4f6ebadea90ce', // dummy id
      space_mode: ZONE_MODE.BUILD,
      gd_server_version: '5.3.1'
    })
  ),
  getAllZoneContainers: vi.fn(
    async (): Promise<ContainerStatusResponse[]> => [
      {
        uuid: '5eb339c1-2914-4fa8-a6a6-9391922fe3b9',
        ip_address: 'sample-ip-address',
        port: 12345,
        state: CONTAINER_STATE.READY,
        server_id: 'sample-server-id',
        url: 'sample-url',
        space_id: '648e5e978c02bd5434226f80', // dummy id
        space_version: '648e5ea1ac2b9336ea861daf', // dummy id
        space_mode: ZONE_MODE.BUILD,
        gd_server_version: '5.3.1'
      },
      {
        uuid: '84ae8935-92bf-4dd5-8687-6b8106831845',
        ip_address: 'sample-ip-address',
        port: 12345,
        state: CONTAINER_STATE.READY,
        server_id: 'sample-server-id',
        url: 'sample-url',
        space_id: '6483cd6e30306618972d856a', // dummy id
        space_version: '6483cd7abff4f6ebadea90ce', // dummy id
        space_mode: ZONE_MODE.BUILD,
        gd_server_version: '5.3.1'
      }
    ]
  ),
  createContainer: vi.fn(
    async (): Promise<ContainerStatusResponse> => ({
      uuid: '5c2ddd31-0a10-45ce-8714-a35b15a39430',
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      server_id: 'sample-server-id',
      url: 'sample-url',
      space_id: '648e5e978c02bd5434226f80', // dummy id
      space_version: '648e5ea1ac2b9336ea861daf', // dummy id
      space_mode: ZONE_MODE.BUILD,
      gd_server_version: '5.3.1'
    })
  ),
  getContainerStatusByResourceUuid: vi.fn(
    async (uuid: string): Promise<ContainerStatusResponse> => ({
      uuid,
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      server_id: 'sample-server-id',
      url: 'sample-url',
      space_id: '648e5e978c02bd5434226f80', // dummy id
      space_version: '648e5ea1ac2b9336ea861daf', // dummy id
      space_mode: ZONE_MODE.BUILD,
      gd_server_version: '5.3.1'
    })
  ),
  deleteContainer: vi.fn(
    async (uuid: string): Promise<ContainerStatusResponse> => ({
      uuid,
      ip_address: 'sample-ip-address',
      port: 12345,
      state: CONTAINER_STATE.READY,
      server_id: 'sample-server-id',
      url: 'sample-url',
      space_id: '6483cd6e30306618972d856a', // dummy id
      space_version: '6483cd7abff4f6ebadea90ce', // dummy id
      space_mode: ZONE_MODE.BUILD,
      gd_server_version: '5.3.1'
    })
  )
}
