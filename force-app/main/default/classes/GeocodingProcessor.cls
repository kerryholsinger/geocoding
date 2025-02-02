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
  private String censusYear;
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
    Map<String, Object> responseResults = mapResponseResults(response);
    try {
      for (SObject record : parameters.records) {
        String recordId = (String) record.get('Id');
        Map<String, Object> recordResult = getRecordResult(responseResults, recordId);
        processGeocodingResult(record, recordResult);
      }
    } catch (Exception e) {
      throw new GeocodingProcessorException('Invalid response structure or missing data: ' + e.getMessage(), e);
    }
  }

  /**
   * Maps the HTTP response from the Geocodio API to a structured format.
   * @param response The HttpResponse received from the Geocodio API.
   * @return A Map containing the parsed results from the response body.
   * @throws GeocodingProcessorException if the response structure is invalid or missing expected data.
   */
  private Map<String, Object> mapResponseResults(HttpResponse response) {
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    if (responseMap == null || !responseMap.containsKey('results')) {
      throw new GeocodingProcessorException('Response is missing "results" key or has an invalid structure: ' + response.getBody());
    }
    return (Map<String, Object>) responseMap.get('results');
  }

  /**
   * Retrieves the first geocoding result for a specific record ID from the parsed response data.
   * Expects the response to be structured with a "response" object containing a "results" list.
   * @param results The parsed geocoding response data, mapped by record ID.
   * @param recordId The ID of the record to retrieve results for.
   * @return The first geocoding result as a Map.
   * @throws GeocodingProcessorException if the response is missing expected data.
   */
  private Map<String, Object> getRecordResult(Map<String, Object> results, String recordId) {
    if (results == null || !results.containsKey(recordId)) {
      throw new GeocodingProcessorException('Geocoding response is missing results for record ID: ' + recordId);
    }

    Map<String, Object> recordData = (Map<String, Object>) results.get(recordId);
    if (recordData == null || !recordData.containsKey('response')) {
      throw new GeocodingProcessorException('Geocoding response is missing the "response" object for record ID: ' + recordId);
    }

    Map<String, Object> responseDetails = (Map<String, Object>) recordData.get('response');
    if (responseDetails == null || !responseDetails.containsKey('results')) {
      throw new GeocodingProcessorException('Geocoding response is missing the "results" list for record ID: ' + recordId);
    }

    List<Object> recordResults = (List<Object>) responseDetails.get('results');
    if (recordResults == null || recordResults.isEmpty()) {
      throw new GeocodingProcessorException('Geocoding response contains an empty "results" list for record ID: ' + recordId);
    }

    // Return the first geocoding result for the record
    return (Map<String, Object>) recordResults[0];
  }

  private void processGeocodingResult(SObject record, Map<String, Object> geocodingResult) {
    if (geocodingResult.containsKey('location')) {
      Map<String, Object> location = (Map<String, Object>) geocodingResult.get('location');
      Object latitudeResult = location.containsKey('lat') ? location.get('lat') : null;
      Object longitudeResult = location.containsKey('lng') ? location.get('lng') : null;

      updateFieldIfValid(record, parameters.latitudeField, latitudeResult);
      updateFieldIfValid(record, parameters.longitudeField, longitudeResult);
    }

    Boolean censusDataAvailable;
    Boolean zipPlusFourAvailable;

    if (geocodingResult.containsKey('fields')) {
      Map<String, Object> fields = (Map<String, Object>) geocodingResult.get('fields');
      censusDataAvailable = fields.containsKey('census');
      zipPlusFourAvailable = fields.containsKey('zip4');
    }
  }

  private void updateFieldIfValid(SObject record, String fieldName, Object value) {
    if (String.isNotBlank(fieldName) && value != null) {
      record.put(fieldName, value);
    }
  }

  public class GeocodingProcessorException extends Exception {
  }
}
