import { applyDecorators, Type } from '@nestjs/common'
import { ApiProperty } from '@nestjs/swagger'

export const ApiArrayQuery = (
  valuesType: Type<unknown> | string | Record<string, any> = [String]
) => {
  const swaggerProps = { type: valuesType }
  swaggerProps['style'] = 'form'
  swaggerProps['explode'] = true

  return applyDecorators(ApiProperty(swaggerProps))
}
