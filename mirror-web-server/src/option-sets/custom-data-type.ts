// Not implemented yet, but will be used for data[key] validation of keys in CustomData
export enum CUSTOM_DATA_TYPE {
  STRING = 'STRING',
  NUMBER = 'NUMBER',
  DATE = 'DATE',
  BOOLEAN = 'BOOLEAN'

  // These use foreign key (Mongo ObjectId) references
  // Not implemented yet, but will be in the future. 2023-03-03 15:34:01
  // SPACE_OBJECT = 'SPACE_OBJECT'
  // USER = 'USER'
}
