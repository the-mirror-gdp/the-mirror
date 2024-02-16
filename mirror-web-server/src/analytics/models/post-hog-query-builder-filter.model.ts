export class PostHogQueryBuilderPropertiesFilter {
  propertiesFilter?: Record<string, string | number | boolean>

  constructor(propertiesFilter?: Record<string, string | number>) {
    this.propertiesFilter = propertiesFilter
  }

  public convertToQueryBuilderPropertiesFilter() {
    let propertiesFilter = []

    if (this.propertiesFilter) {
      propertiesFilter = Object.keys(this.propertiesFilter).map(
        (key) =>
          `properties.${key} = '${this.propertiesFilter[key].toString()}'`
      )
    }

    return propertiesFilter.length ? propertiesFilter.join(' AND ') : ''
  }
}
