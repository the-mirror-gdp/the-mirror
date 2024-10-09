"use server"
import { uniqueNamesGenerator, Config, adjectives, colors, animals } from 'unique-names-generator';


const randomName: string = uniqueNamesGenerator({
  dictionaries: [adjectives, animals]
});


export async function generateSpaceName() {
  const customConfig: Config = {
    dictionaries: [adjectives, animals],
    separator: ' ',
    length: 2,
    style: 'capital'
  };
  
return uniqueNamesGenerator(customConfig); 
}


export async function generateSceneName() {
  const customConfig: Config = {
    dictionaries: [adjectives],
    separator: ' ',
    length: 1,
    style: 'capital'
  };
  
  return uniqueNamesGenerator(customConfig); 
  }
  