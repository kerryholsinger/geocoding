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
public class GeocodingProcessor {
  private GeocodingInvocable.Parameters parameters;
  private String censusYear = GeocodingUtility.getCensusYear();
  private Boolean censusDataAvailable = false;

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
    try {
      for (SObject record : parameters.records) {
        String recordId = (String) record.get('Id');
        Map<String, Object> geocodingResult = getGeocodingResult(results, recordId);
        processGeocodingResult(record, geocodingResult);
      }
    } catch (Exception e) {
      throw new GeocodingProcessorException('Invalid response structure or missing data: ' + e.getMessage(), e);
    }
  }

  private void processGeocodingResult(SObject record, Map<String, Object> geocodingResult) {
    String countyResult = getCounty(geocodingResult);
    Decimal latitudeResult = getLatitude(geocodingResult);
    Decimal longitudeResult = getLongitude(geocodingResult);
    String censusTractResult = getCensusTract(geocodingResult);
    String fipsCodeResult = getFipsCode(geocodingResult);
    String zipPlusFourResult = getZipPlusFour(geocodingResult);

    updateFieldIfValid(record, parameters.countyField, countyResult);
    updateFieldIfValid(record, parameters.latitudeField, latitudeResult);
    updateFieldIfValid(record, parameters.longitudeField, longitudeResult);
    updateFieldIfValid(record, parameters.censusTractField, censusTractResult);
    updateFieldIfValid(record, parameters.fipsCodeField, fipsCodeResult);
    if (parameters.includeZipPlusFour) {
      updateFieldIfValid(record, parameters.zipField, zipPlusFourResult);
    }
  }

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
   * Expects the response to be structured with a "response" object containing a "results" list.
   * @param results The parsed geocoding response data, mapped by record ID.
   * @param recordId The ID of the record to retrieve results for.
   * @return The first geocoding result as a Map.
   */
  private Map<String, Object> getGeocodingResult(Map<String, Object> results, String recordId) {
    Map<String, Object> recordData = (Map<String, Object>) results.get(recordId);
    Map<String, Object> responseDetails = (Map<String, Object>) recordData.get('response');
    List<Object> recordResults = (List<Object>) responseDetails.get('results');
    return (Map<String, Object>) recordResults[0];
  }

  private String getCounty(Map<String, Object> geocodingResult) {
    Map<String, Object> addressComponents = (Map<String, Object>) geocodingResult.get('address_components');
    return (String) addressComponents.get('county');
  }

  private Map<String, Object> getLocation(Map<String, Object> geocodingResult) {
    return (Map<String, Object>) geocodingResult.get('location');
  }

  private Decimal getLatitude(Map<String, Object> geocodingResult) {
    Map<String, Object> location = getLocation(geocodingResult);
    return (Decimal) location.get('lat');
  }

  private Decimal getLongitude(Map<String, Object> geocodingResult) {
    Map<String, Object> location = getLocation(geocodingResult);
    return (Decimal) location.get('lng');
  }

  private Map<String, Object> getFields(Map<String, Object> geocodingResult) {
    return (Map<String, Object>) geocodingResult.get('fields');
  }

  private Map<String, Object> getCensus(Map<String, Object> geocodingResult) {
    Map<String, Object> fields = getFields(geocodingResult);
    Map<String, Object> censusData = (Map<String, Object>) fields.get('census');
    return (Map<String, Object>) censusData.get(GeocodingUtility.getCensusYear());
  }

  public String getCensusTract(Map<String, Object> geocodingResult) {
    Map<String, Object> census = getCensus(geocodingResult);
    return (String) census.get('tract_code');
  }

  public String getFipsCode(Map<String, Object> geocodingResult) {
    Map<String, Object> census = getCensus(geocodingResult);
    return (String) census.get('fips_code');
  }

  public String getZipPlusFour(Map<String, Object> geocodingResult) {
    Map<String, Object> fields = getFields(geocodingResult);
    Map<String, Object> zip4 = (Map<String, Object>) fields.get('zip4');
    return (String) zip4.get('zip9');
  }

  public class GeocodingProcessorException extends Exception {
  }
}
