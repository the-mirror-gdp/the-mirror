import {
  Config,
  adjectives,
  animals,
  colors,
  uniqueNamesGenerator
} from 'unique-names-generator'

export const generateUniqueName = () => {
  const config: Config = {
    dictionaries: [adjectives, colors, animals],
    separator: ' ',
    style: 'capital'
  }

  return uniqueNamesGenerator(config)
}
