"use server"
import { uniqueNamesGenerator, Config, adjectives, colors, animals } from 'unique-names-generator';

const customConfig: Config = {
  dictionaries: [adjectives, animals],
  separator: ' ',
  length: 2,
  style: 'capital'
};

const randomName: string = uniqueNamesGenerator({
  dictionaries: [adjectives, animals]
});


export async function generateSpaceName() {
return uniqueNamesGenerator(customConfig); 
}
