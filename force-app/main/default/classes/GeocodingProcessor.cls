/**
 * Processes geocoding data for a set of records. The processor retrieves geocoding results from an HTTP response,
 * maps the results to the corresponding records, and updates record fields with the geocoding data.
 * If census data is available, it also processes and updates the census-related fields.
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 * @tests: _Test
 */
public with sharing class GeocodingProcessor {
  private GeocodingInvocable.Parameters parameters;
  private String censusYear = GeocodingUtility.getCensusYear();

  /**
   * Constructs a GeocodingProcessor with the specified parameters.
   * @param parameters The parameters containing records and field mappings for geocoding processing.
   */
  public GeocodingProcessor(GeocodingInvocable.Parameters parameters) {
    this.parameters = parameters;
  }

  /**
   * Retrieves and processes geocoding results for each record in the response.
   * @param response The HTTP response containing geocoding data.
   * @throws GeocodingProcessorException if the response is improperly structured or missing data.
   */
  public void process(HttpResponse response) {
    Map<String, Object> results = getResults(response);
    List<SObject> recordsToUpdate = new List<SObject>();
    try {
      for (SObject record : parameters.records) {
        String recordId = (String) record.get('Id');
        Map<String, Object> geocodingResult = getGeocodingResult(results, recordId);
        processGeocodingResult(record, geocodingResult);
        recordsToUpdate.add(record);
      }
    } catch (Exception e) {
      throw new GeocodingProcessorException('Invalid response structure or missing data: ' + e.getMessage(), e);
    }
    update recordsToUpdate;
  }

  /**
   * Processes the geocoding result for a given record by extracting relevant location data
   * and updating the corresponding fields in the record.
   * @param record The record to be updated with geocoding data.
   * @param geocodingResult A map containing the geocoding result data for the record.
   */
  private void processGeocodingResult(SObject record, Map<String, Object> geocodingResult) {
    // Get the geocoding data points from the result
    String countyResult = getCounty(geocodingResult);
    Decimal latitudeResult = getLatitude(geocodingResult);
    Decimal longitudeResult = getLongitude(geocodingResult);
    String censusTractResult = getCensusTract(geocodingResult);
    String fipsCodeResult = getFipsCode(geocodingResult);
    String zipPlusFourResult = getZipPlusFour(geocodingResult);

    // Update the record with the geocoding data if the field is specified and the data is available
    updateFieldIfValid(record, parameters.countyField, countyResult);
    updateFieldIfValid(record, parameters.latitudeField, latitudeResult);
    updateFieldIfValid(record, parameters.longitudeField, longitudeResult);
    updateFieldIfValid(record, parameters.censusTractField, censusTractResult);
    updateFieldIfValid(record, parameters.fipsCodeField, fipsCodeResult);
    // Ensure zip is updated only if zip+4 is requested
    if (parameters.includeZipPlusFour) {
      updateFieldIfValid(record, parameters.zipField, zipPlusFourResult);
    }
  }

  /**
   * Updates the specified field with the given value if the field is not blank and the value is not null.
   * @param record The record to be updated.
   * @param fieldName The API name of the field to be updated.
   * @param value The value to set for the specified field.
   */
  private void updateFieldIfValid(SObject record, String fieldName, Object value) {
    if (String.isNotBlank(fieldName) && value != null) {
      record.put(fieldName, value);
    }
  }

  /**
   * Maps the HTTP response from the Geocodio API to a structured format.
   * @param response The HttpResponse received from the Geocodio API.
   * @return A Map containing the parsed results from the response body.
   */
  private Map<String, Object> getResults(HttpResponse response) {
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    return (Map<String, Object>) responseMap.get('results');
  }

  /**
   * Retrieves the first geocoding result for a specific record ID from the parsed response data.
   * @param results The parsed geocoding response data, mapped by record ID.
   * @param recordId The ID of the record to retrieve results for.
   * @return The first geocoding result as a Map.
   */
  private Map<String, Object> getGeocodingResult(Map<String, Object> results, String recordId) {
    Map<String, Object> recordData = (Map<String, Object>) results.get(recordId);
    Map<String, Object> responseDetails = (Map<String, Object>) recordData.get('response');
    List<Object> geocodingResults = (List<Object>) responseDetails.get('results');
    return (Map<String, Object>) geocodingResults[0];
  }

  /**
   * Extracts the county name from the geocoding result.
   * @param geocodingResult The geocoding result data containing address components.
   * @return The county name as a string
   */
  private String getCounty(Map<String, Object> geocodingResult) {
    Map<String, Object> addressComponents = (Map<String, Object>) geocodingResult.get('address_components');
    String county = (String) addressComponents.get('county');
    return county.replace(' County', '');
  }

  /**
   * Retrieves the location data from the geocoding result.
   * @param geocodingResult The geocoding result containing location details.
   * @return A map containing location information
   */
  private Map<String, Object> getLocation(Map<String, Object> geocodingResult) {
    return (Map<String, Object>) geocodingResult.get('location');
  }

  /**
   * Extracts the latitude value from the geocoding result's location data.
   * @param geocodingResult The geocoding result containing location details.
   * @return The latitude value as a decimal.
   */
  private Decimal getLatitude(Map<String, Object> geocodingResult) {
    Map<String, Object> location = getLocation(geocodingResult);
    return (Decimal) location.get('lat');
  }

  /**
   * Extracts the longitude value from the geocoding result's location data.
   * @param geocodingResult The geocoding result containing location details.
   * @return The longitude value as a decimal.
   */
  private Decimal getLongitude(Map<String, Object> geocodingResult) {
    Map<String, Object> location = getLocation(geocodingResult);
    return (Decimal) location.get('lng');
  }

  /**
   * Retrieves the 'fields' data from the geocoding result.
   * @param geocodingResult The geocoding result containing the fields data.
   * @return A Map containing the fields data from the geocoding result.
   */
  private Map<String, Object> getFields(Map<String, Object> geocodingResult) {
    return (Map<String, Object>) geocodingResult.get('fields');
  }

  /**
   * Retrieves the census data from the geocoding result.
   * @param geocodingResult The geocoding result containing the fields data.
   * @return A Map containing the census data for the specified year.
   */
  private Map<String, Object> getCensus(Map<String, Object> geocodingResult) {
    Map<String, Object> fields = getFields(geocodingResult);
    Map<String, Object> censusData = (Map<String, Object>) fields.get('census');
    return (Map<String, Object>) censusData.get(GeocodingUtility.getCensusYear());
  }

  /**
   * Retrieves the census tract code from the geocoding result.
   * @param geocodingResult The geocoding result containing census data.
   * @return The census tract code as a String.
   */
  private String getCensusTract(Map<String, Object> geocodingResult) {
    Map<String, Object> census = getCensus(geocodingResult);
    return (String) census.get('tract_code');
  }

  /**
   * Retrieves the FIPS code from the geocoding result.
   * @param geocodingResult The geocoding result containing census data.
   * @return The FIPS code as a String.
   */
  private String getFipsCode(Map<String, Object> geocodingResult) {
    Map<String, Object> census = getCensus(geocodingResult);
    return (String) census.get('full_fips');
  }

  /**
   * Retrieves the Zip+4 code from the geocoding result.
   * @param geocodingResult The geocoding result containing fields data.
   * @return The Zip+4 code as a String.
   */
  private String getZipPlusFour(Map<String, Object> geocodingResult) {
    Map<String, Object> fields = getFields(geocodingResult);
    Map<String, Object> zip4 = (Map<String, Object>) fields.get('zip4');
    List<Object> zip9 = (List<Object>) zip4.get('zip9');
    return (String) zip9[0];
  }

  /**
   * Custom exception class for errors in geocoding processing.
   */
  public class GeocodingProcessorException extends Exception {
  }
}
