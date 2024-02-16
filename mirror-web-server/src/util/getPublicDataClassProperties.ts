/**
 * @description Returns not-undefined properties on a class. Note that if a property doesn't have a value, it won't appear here.
 * Works:        someProp: string = ''
 * Doesn't Work: someProp: string
 */
function getClassProperties(publicDataClass: any): string[] {
  // Instantiate the class so we can see defined properties on the object
  const instance = new publicDataClass()
  return Object.getOwnPropertyNames(instance)
}
export function getPublicPropertiesForMongooseQuery<T>(
  publicDataClass: T
): string {
  return getClassProperties(publicDataClass).join(' ')
}
