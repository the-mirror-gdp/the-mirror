import { Stream } from 'stream'

/* eslint-disable */
export class ModelStub {
  constructor(dto) {}
  public save() {}
  public find() {}
  public limit(number) {}
  public where(data) {}
  public exec() {}
  public findById(id) {}
  public findOne(query) {}
  public findByIdAndUpdate(id, updateFavoriteDto) {}
  public findOneAndDelete(id) {}
  public watch() {
    return new Stream()
  }
}
