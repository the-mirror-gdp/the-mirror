import {
  Body,
  Controller,
  Get,
  InternalServerErrorException,
  NotFoundException,
  Param,
  Res,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { Response } from 'express'
import { StorageFile } from '../storage/storage.file'
import { StorageService } from '../storage/storage.service'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { Roles } from '../roles/roles.decorator'
import { ROLE } from '../roles/models/role.enum'
import { ApiParam } from '@nestjs/swagger'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'
@Controller('storage')
@UsePipes(new ValidationPipe({ whitelist: true }))
export class StorageController {
  constructor(
    private storageService: StorageService,
    private readonly mirrorServerConfigService: MirrorServerConfigService
  ) {}

  private static storageApiUrl = 'https://storage.googleapis.com'
  private static clientPlatformFiles: object = {
    mac: 'macos.zip',
    win: 'windows.zip',
    linux: 'linuxbsd.tar.gz'
  }

  /**
   * Calculates the base url where the current client versions are stored.
   * @returns the base client storage url calculated from the client build bucket and current released version.
   */
  private async getBaseClientStorageUrl(): Promise<string> {
    return `${StorageController.storageApiUrl}/${
      process.env.CLIENT_BUILDS_BUCKET
    }/AutoUpdater/versions/${
      (await this.mirrorServerConfigService.getConfig()).gdServerVersion
    }`
  }

  /**
   * Returns the filename with the platform short name. Throws not found exception for an unknown platform.
   * @param platform platform shorthand name. EG: "win", "mac", "linux".
   * @returns filename of the shorthand platform parameter.
   */
  private static getPlatformClientFilename(platform: string): string {
    if (!StorageController.clientPlatformFiles.hasOwnProperty(platform)) {
      throw new NotFoundException(`No such platform: ${platform}`)
    }
    return StorageController.clientPlatformFiles[platform]
  }

  /**
   * Calculates the complete file url of the shorthand platform parameter.
   * @param platform platform shorthand name. EG: "win", "mac", "linux".
   * @returns the complete file url of the shorthand platform parameter.
   */
  private async getPlatformClientFilenameUrl(
    platform: string
  ): Promise<string> {
    const storageUrl = await this.getBaseClientStorageUrl()
    return `${storageUrl}/${StorageController.getPlatformClientFilename(
      platform
    )}`
  }

  /**
   * Public endpoint for getting the current version of the client application.
   * @returns An object containing a `version` property string of the current version of the released client.
   */
  @Get('/client/version')
  async getClientVersion(): Promise<object> {
    return {
      version: (await this.mirrorServerConfigService.getConfig())
        .gdServerVersion
    }
  }

  /**
   * Public endpoint for getting the client application download URL for the target platform parameter.
   * @param platform platform shorthand name. EG: "win", "mac", "linux".
   * @returns the file url for the shorthand platform parameter of the current released client.
   */
  @Get('/client/:platform')
  @ApiParam({ name: 'platform', type: 'string', required: true })
  async getClientUrl(@Param('platform') platform: string): Promise<string> {
    return await this.getPlatformClientFilenameUrl(platform)
  }

  /**
   * Public endpoint for getting all supported platforms client application download URLs.
   * @returns object containing urls for all the supported platform client application download urls.
   */
  @Get('/clients')
  async getClientUrls(): Promise<object> {
    return {
      mac: await this.getPlatformClientFilenameUrl('mac'),
      win: await this.getPlatformClientFilenameUrl('win'),
      linux: await this.getPlatformClientFilenameUrl('linux'),
      version: (await this.mirrorServerConfigService.getConfig())
        .gdServerVersion
    }
  }

  @Get('/:fileName')
  @ApiParam({ name: 'fileName', type: 'string', required: true })
  @FirebaseTokenAuthGuard()
  async downloadFile(
    @Param('fileName') fileName: string,
    @Res() res: Response
  ) {
    let storageFile: StorageFile
    try {
      storageFile = await this.storageService.get(
        process.env.GCS_BUCKET,
        fileName
      )
    } catch (e) {
      if (e.message.toString().includes('No such object')) {
        throw new NotFoundException('File not found')
      } else {
        throw new InternalServerErrorException(
          'Error fetching file: ',
          e.message
        )
      }
    }
    res.setHeader('Content-Type', storageFile.contentType)
    res.setHeader('Cache-Control', 'max-age=60d')
    res.end(storageFile.buffer)
  }
}
