import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface
} from 'class-validator'

@ValidatorConstraint({ async: false })
export class UniqueTagsConstraint implements ValidatorConstraintInterface {
  validate(value: any) {
    if (!Array.isArray(value)) {
      return false
    }

    const seen = new Set<string>()

    for (const item of value) {
      const name = typeof item === 'string' ? item : item.name

      if (seen.has(name)) {
        return false
      } else {
        seen.add(name)
      }
    }

    return true
  }
}

export function IsUniqueTags(validationOptions?: ValidationOptions) {
  return function (object: Record<string, any>, propertyName: string) {
    registerDecorator({
      name: 'isUniqueTags',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      constraints: [],
      validator: UniqueTagsConstraint
    })
  }
}
