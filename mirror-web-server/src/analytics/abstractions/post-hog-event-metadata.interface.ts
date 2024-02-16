export interface IPostHogEventMetadata {
  $ip: string
  $set: {
    $geoip_city_name: string
    $geoip_subdivision_2_name: string
    $geoip_subdivision_2_code: string
    $geoip_subdivision_1_name: string
    $geoip_subdivision_1_code: string
    $geoip_country_name: string
    $geoip_country_code: string
    $geoip_continent_name: string
    $geoip_continent_code: string
    $geoip_postal_code: string
    $geoip_latitude: number
    $geoip_longitude: number
    $geoip_time_zone: string
  }
  $set_once: {
    $initial_geoip_city_name: string
    $initial_geoip_subdivision_2_name: string
    $initial_geoip_subdivision_2_code: string
    $initial_geoip_subdivision_1_name: string
    $initial_geoip_subdivision_1_code: string
    $initial_geoip_country_name: string
    $initial_geoip_country_code: string
    $initial_geoip_continent_name: string
    $initial_geoip_continent_code: string
    $initial_geoip_postal_code: string
    $initial_geoip_latitude: number
    $initial_geoip_longitude: number
    $initial_geoip_time_zone: string
  }
  $geoip_city_name: string
  $geoip_country_name: string
  $geoip_country_code: string
  $geoip_continent_name: string
  $geoip_continent_code: string
  $geoip_postal_code: string
  $geoip_latitude: number
  $geoip_longitude: number
  $geoip_time_zone: string
  $geoip_subdivision_1_code: string
  $geoip_subdivision_1_name: string
  $geoip_subdivision_2_code: string
  $geoip_subdivision_2_name: string
  $plugins_succeeded: [string, string]
  $plugins_failed: []
  $plugins_deferred: []
}
