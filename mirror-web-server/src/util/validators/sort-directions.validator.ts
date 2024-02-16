import {
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
  registerDecorator,
  ValidationOptions
} from 'class-validator'
import { SORT_DIRECTION } from '../pagination/pagination.interface'

@ValidatorConstraint({ async: false })
class SortDirectionValidator implements ValidatorConstraintInterface {
  validate(value: any, args: ValidationArguments) {
    if (value === 'asc' || value === 1 || value === '1') {
      args.object[args.property] = SORT_DIRECTION.ASC
      return true
    }

    if (value === 'desc' || value === -1 || value === '-1') {
      args.object[args.property] = SORT_DIRECTION.DESC
      return true
    }

    return false
  }

  defaultMessage(args: ValidationArguments) {
    return `The ${args.property} must be either 'asc', 'desc', 1, or -1.`
  }
}

export function IsSortDirection(validationOptions?: ValidationOptions) {
  return function (object: Record<string, any>, propertyName: string) {
    registerDecorator({
      name: 'isSortDirection',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      constraints: [],
      validator: SortDirectionValidator
    })
  }
}
