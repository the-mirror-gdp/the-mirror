import { AxiosResponse } from 'axios'
import { lastValueFrom, map } from 'rxjs'
import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  UnauthorizedException
} from '@nestjs/common'
import { HttpService } from '@nestjs/axios'
import { godotServerOverrideControllerPath } from '../godot-server-override-config/godot-server-override-config.path'
import { SpaceId, SpaceVersionId } from '../util/mongo-object-id-helpers'

import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsEnum,
  ValidateIf,
  validateOrReject
} from 'class-validator'
import { ZONE_MODE } from './zone.schema'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'

export enum CONTAINER_STATE {
  // 1. Queued: The request has been received, but it hasn't been picked up yet to start a container.
  QUEUED = 'QUEUED',
  // 2. Booting: When the scaler is checking for a server or has had to boot a scaler vm host
  BOOTING = 'BOOTING',
  // 3. READY: Good to go. When the scaler has booted the space and is ready for the client to join
  READY = 'READY',
  // 4. Error: When an infrastructure issue prevents the space from starting
  ERROR = 'ERROR'
}

export class ContainerStatusResponse {
  url: string
  server_id: string | null
  uuid: string
  space_id: string
  space_version: string
  space_mode: ZONE_MODE
  ip_address: string | null
  port: number
  state: CONTAINER_STATE
  gd_server_version?: string | null
}

export class CreateContainerDto {
  @IsNotEmpty()
  @IsString()
  spaceId: SpaceId

  @IsNotEmpty()
  @IsEnum(ZONE_MODE)
  zoneMode = ZONE_MODE.BUILD

  @IsNotEmpty()
  @IsString()
  gdServerVersion: string

  // a spaceVersion is only required for PLAY mode
  @ValidateIf((o) => o.zoneMode === ZONE_MODE.PLAY)
  @IsNotEmpty()
  @IsString()
  spaceVersionId?: SpaceVersionId

  /**
   * @description I'm not exactly sure what we should use name for since we have space.name. Should we use it at all?
   * @date 2023-06-17 19:19
   */
  @IsOptional()
  @IsString()
  name?: string
}

/**
 * @description Note: After much confusion and deliberation and multiple previous engineers working on this with all different approaches...
 * ZONE = A CONTAINER FOR A SPACE (Podman)
 * @date 2023-06-16 03:45
 */
@Injectable()
export class SpaceManagerExternalService {
  constructor(
    private httpService: HttpService,
    private logger: Logger,
    private readonly mirrorServerConfigService: MirrorServerConfigService
  ) {}

  /**
   * @description Gets ALL containers running on the space-manager
   * @date 2023-06-16 03:44
   */
  async getAllZoneContainers(): Promise<ContainerStatusResponse[]> {
    const url = `${this._getBaseUrl()}/containers`
    return await lastValueFrom(
      this.httpService
        .get(url, {
          headers: {
            Authorization: `${process.env.SPACE_MANAGER_SECRET}`
          }
        })
        .pipe(map((resp) => resp.data))
    ).catch((error) => {
      if (
        error?.response?.status === 401 ||
        error?.response?.message?.Authorization
      ) {
        return Promise.reject(
          'Failed Auth Dependency: 401 From External Resource'
        )
      }
      if (error?.response?.status === 404) {
        return Promise.reject('Failed Dependency: 404 From External Resource')
      }
      // Don't throw ServiceUnavailableException here - ServiceUnavailableException implies THIS app is down (not the external service), so reject the promise
      return Promise.reject('Failed Dependency: External Resource')
      // Add this line in once we move to local multiplayer hosting
      // console.warn(
      //   'Quiet error: server scaler service is not responding. Not an issue at the moment until we add it back as a premium feature.'
      // )
    })
  }

  /**
   * @description Creates a zone container for a space
   * @date 2023-06-11 15:48
   */
  async createContainer(
    dto: CreateContainerDto
  ): Promise<ContainerStatusResponse> {
    // we need to manually call validateOrReject since we're not using a controller
    try {
      await validateOrReject(dto)
    } catch (errors) {
      throw new BadRequestException(
        'Caught promise rejection for Role creation (validation failed). Errors: ',
        errors
      )
    }
    const mode = dto?.zoneMode || ZONE_MODE.BUILD // default to BUILD mode
    const config = await this.mirrorServerConfigService.getConfig()
    const gdServerVersion = config.gdServerVersion
    const bucketUrl = await this._getBucketUrl()
    const body = {
      pack_url: `${bucketUrl}/mirror-server.pck`,
      binary_url: `${bucketUrl}/mirror-server.x86_64`,
      override_cfg_url: godotServerOverrideControllerPath + `/${dto.spaceId}`,
      space_id: dto.spaceId,
      name: dto?.name ?? 'zone',
      space_version: dto?.spaceVersionId,
      space_mode: mode,
      server_arguments: `--headless --server --space ${dto.spaceId} --mode ${mode} --WSS_SECRET ${process.env.WSS_SECRET}`,
      gd_server_version: gdServerVersion
    }
    const url = `${this._getBaseUrl()}/containers`
    return await lastValueFrom(
      this.httpService
        .post(url, body, {
          headers: {
            Authorization: `${process.env.SPACE_MANAGER_SECRET}`
          }
        })
        .pipe(map((resp) => resp.data))
    ).catch((error) => {
      if (
        error?.response?.status === 401 ||
        error?.response?.message?.Authorization
      ) {
        return Promise.reject(
          'Failed Auth Dependency: 401 From External Resource'
        )
      }
      if (error?.response?.status === 404) {
        return Promise.reject('Failed Dependency: 404 From External Resource')
      }

      this.logger.error(error)
      // Don't throw ServiceUnavailableException here - ServiceUnavailableException implies THIS app is down (not the external service), so reject the promise
      return Promise.reject('Failed Dependency: External Resource')

      // Add this line in once we move to local multiplayer hosting
      // console.warn(
      //   'Quiet error: server scaler service is not responding. Not an issue at the moment until we add it back as a premium feature.'
      // )
    })
  }

  /**
   * @description Retrieves the status of a zone container.
   * This gives info like whether Podman has started the container, whether the container is running, etc.
   * @date 2023-06-12 15:36
   */
  async getContainerStatusByResourceUuid(
    uuid: string
  ): Promise<AxiosResponse<ContainerStatusResponse>> {
    const url = `${this._getBaseUrl()}/containers/${uuid}`
    return await lastValueFrom(
      this.httpService
        .get(url, {
          headers: {
            Authorization: `${process.env.SPACE_MANAGER_SECRET}`
          }
        })
        .pipe(map((resp) => resp.data))
    ).catch((error) => {
      if (
        error?.response?.status === 401 ||
        error?.response?.message?.Authorization
      ) {
        return Promise.reject(
          'Failed Auth Dependency: 401 From External Resource'
        )
      }
      if (error?.response?.status === 404) {
        return Promise.reject('Failed Dependency: 404 From External Resource')
      }
      this.logger.error('Failed to get external container status. uuid: ', uuid)
      this.logger.error(error)
      // Don't throw ServiceUnavailableException here - ServiceUnavailableException implies THIS app is down (not the external service), so reject the promise

      return Promise.reject('Failed Dependency: External Resource')

      // Add this line in once we move to local multiplayer hosting
      // console.warn(
      //   'Quiet error: server scaler service is not responding. Not an issue at the moment until we add it back as a premium feature.'
      // )
    })
  }

  async deleteContainer(
    uuid: string
  ): Promise<AxiosResponse<ContainerStatusResponse>> {
    const url = `${this._getBaseUrl()}/containers/${uuid}`
    return await lastValueFrom(
      this.httpService
        .delete(url, {
          headers: {
            Authorization: `${process.env.SPACE_MANAGER_SECRET}`
          }
        })
        .pipe(map((resp) => resp.data))
    ).catch((error) => {
      if (
        error?.response?.status === 401 ||
        error?.response?.message?.Authorization
      ) {
        return Promise.reject(
          'Failed Auth Dependency: 401 From External Resource'
        )
      }
      if (error?.response?.status === 404) {
        this.logger.error('Failed to delete external container uuid: ', uuid)

        return Promise.reject('Failed Dependency: 404 From External Resource')
      }

      this.logger.error('Failed to delete external container uuid: ', uuid)
      this.logger.error(error)

      // Don't throw ServiceUnavailableException here - ServiceUnavailableException implies THIS app is down (not the external service), so reject the promise

      return Promise.reject('Failed Dependency: 404 From External Resource')

      // Add this line in once we move to local multiplayer hosting
      // console.warn(
      //   'Quiet error: server scaler service is not responding. Not an issue at the moment until we add it back as a premium feature.'
      // )
    })
  }

  private async _getBucketUrl(): Promise<string> {
    return `gs://${process.env.GD_SERVER_BUCKET}/${
      (await this.mirrorServerConfigService.getConfig()).gdServerVersion
    }`
  }

  /**
   * @description Base URL to communicate with space-manager service
   * @date 2023-06-12 15:47
   */
  private _getBaseUrl(): string {
    return `${process.env.SERVER_SCALER_URL}/api`
  }

  private getZoneContainerUrl(uuid: string): string {
    return `${this._getBaseUrl()}/${uuid}`
  }
}
