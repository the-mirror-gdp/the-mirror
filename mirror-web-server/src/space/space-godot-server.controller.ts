import {
  Controller,
  Get,
  InternalServerErrorException,
  Logger,
  NotFoundException,
  Param,
  Put,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { FileInterceptor } from '@nestjs/platform-express'
import { GodotServerGuard } from '../godot-server/godot-server.guard'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { SpaceService } from './space.service'
/**
 * Note that this uses the same /space controller, but is processed AFTER the space controller.
 * /space should be removed once everything is changed to /space-godot-server 2023-04-04 12:05:17
 */
@Controller(['space-godot-server'])
@UsePipes(new ValidationPipe({ whitelist: true }))
@UseGuards(GodotServerGuard)
export class SpaceGodotServerController {
  constructor(
    private readonly logger: Logger,
    private readonly spaceService: SpaceService,
    private readonly fileUploadService: FileUploadService
  ) {}

  /*****************************
   TEMP: AUTHED ENDPOINT UP HERE FOR 2023-03-17 13:53:32 RELEASE ISSUE
   * We should likely refactor our pattern for classes because order of routes DOES matter in NestJS, so being @Public() up top can cause issues
   ****************************/
  @Get('latest/:id')
  public async getLatestPublishedSpaceBySpaceId(@Param('id') spaceId: string) {
    this.logger.log('test!')
    const spaceVersion =
      await this.spaceService.getLatestSpaceVersionBySpaceIdAdmin(spaceId)
    if (!spaceVersion) {
      this.logger.log(
        `latest/:id ${spaceId} not found`,
        SpaceGodotServerController.name
      )
      throw new NotFoundException('No Published Space Available')
    }
    return spaceVersion
  }

  @Get('active/:id')
  public async getActiveSpaceVersionForSpaceBySpaceId(
    @Param('id') spaceId: string
  ) {
    const spaceVersion =
      await this.spaceService.getActiveSpaceVersionForSpaceBySpaceIdAdmin(
        spaceId
      )

    if (!spaceVersion) {
      this.logger.log(
        `active/:id ${spaceId} not found`,
        SpaceGodotServerController.name
      )

      throw new NotFoundException('No Published Space Available')
    }

    return spaceVersion
  }
  /*****************************
    END TEMP: AUTHED ENDPOINT UP HERE FOR 2023-03-17 13:53:32 RELEASE ISSUE
    ****************************/

  @Put('voxels/:id')
  @UseInterceptors(FileInterceptor('file'))
  public async updateTerrain(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File
  ) {
    try {
      const remoteRelativePath = `space/${id}/terrain/voxels.dat`

      if (process.env.ASSET_STORAGE_DRIVER === 'GCP') {
        await this.fileUploadService.streamFile(
          process.env.GCS_BUCKET_PUBLIC,
          remoteRelativePath,
          file,
          'publicRead'
        )
        return {
          success: true,
          publicUrl: `${process.env.GCP_BASE_PUBLIC_URL}/${remoteRelativePath}`
        }
      }

      if (
        !process.env.ASSET_STORAGE_DRIVER ||
        process.env.ASSET_STORAGE_DRIVER === 'LOCAL'
      ) {
        await this.fileUploadService.uploadFileLocal(file, remoteRelativePath)
        return {
          success: true,
          publicUrl: `${process.env.ASSET_STORAGE_URL}/${remoteRelativePath}`
        }
      }
    } catch (e) {
      this.logger.error(e?.message, e, SpaceGodotServerController.name)
      throw new InternalServerErrorException('Error uploading terrain data')
    }
  }
}
