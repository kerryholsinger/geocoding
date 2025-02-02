public class GeocodingProcessor {
  private GeocodingInvocable.Parameters parameters;
  private String censusYear;
  private Boolean censusDataAvailable = false;

  public GeocodingProcessor(GeocodingInvocable.Parameters parameters) {
    this.parameters = parameters;
  }

  public void process(HttpResponse response) {
    try {
      Map<String, Object> results = mapResponseResults(response);

      for (SObject record : parameters.records) {
        String recordId = (String) record.get('Id');
        List<Object> recordResult = getRecordResult(results, recordId);

        // Process the geocoding result if valid, else skip
        if (recordResult != null && !recordResult.isEmpty()) {
          processGeocodingResult(record, (Map<String, Object>) recordResult.get(0));
        }
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error processing geocoding data: ' + e.getMessage());
      throw new IllegalArgumentException('Invalid response structure or missing data: ' + e.getMessage(), e);
    }
  }

  // Combined method to get and validate results only once
  private Map<String, Object> mapResponseResults(HttpResponse response) {
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

    if (responseMap == null || !responseMap.containsKey('results')) {
      throw new IllegalArgumentException('Invalid response structure: ' + response.getBody());
    }

    return (Map<String, Object>) responseMap.get('results');
  }

  private List<Object> getRecordResult(Map<String, Object> results, String recordId) {
    Map<String, Object> recordData = (Map<String, Object>) results.get(recordId);
    Map<String, Object> responseDetails = (Map<String, Object>) recordData.get('response');
    List<Object> resultsList = (List<Object>) responseDetails.get('results');
    return (List<Object>) responseDetails.get('results');
  }

  private void processGeocodingResult(SObject record, Map<String, Object> firstResult) {
    Map<String, Object> addressComponents = (Map<String, Object>) firstResult.get('address_components');
    Map<String, Object> location = (Map<String, Object>) firstResult.get('location');

    updateFieldIfValid(record, parameters.countyField, (String) addressComponents.get('county'));
    updateFieldIfValid(record, parameters.latitudeField, (Decimal) location.get('lat'));
    updateFieldIfValid(record, parameters.longitudeField, (Decimal) location.get('lng'));
    updateFieldIfValid(record, parameters.zipField, (String) addressComponents.get('zip'));

    if (censusDataAvailable) {
      processCensusData(record, firstResult);
    }
  }

  private void processCensusData(SObject record, Map<String, Object> firstResult) {
    Map<String, Object> fields = (Map<String, Object>) firstResult.get('fields');
    if (fields != null && fields.containsKey('census')) {
      Map<String, Object> censusData = (Map<String, Object>) fields.get('census');
      Map<String, Object> censusYearData = (Map<String, Object>) censusData.get(censusYear);

      if (censusYearData != null) {
        updateFieldIfValid(record, parameters.censusTractField, (String) censusYearData.get('tract_code'));
        updateFieldIfValid(record, parameters.fipsCodeField, (String) censusYearData.get('full_fips'));
      }
    }
  }

  private void updateFieldIfValid(SObject record, String fieldName, Object value) {
    if (String.isNotBlank(fieldName) && value != null) {
      record.put(fieldName, value);
    }
  }
}
