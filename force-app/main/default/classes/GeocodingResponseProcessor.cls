public class GeocodingResponseProcessor {
  private static final String COUNTY_PATH = 'results.[0].address_components.county';
  private static final String LATITUDE_PATH = 'results.[0].location.lat';
  private static final String LONGITUDE_PATH = 'results.[0].location.lng';
  private static final String ZIP_PLUS_FOUR_PATH = 'results.[0].fields.zip4.zip9.[0]';

  private GeocodingInvocable.Parameters parameters;
  private String censusYear;
  private Boolean censusDataAvailable = false;

  public GeocodingResponseProcessor(GeocodingInvocable.Parameters parameters) {
    this.parameters = parameters;
  }

  public void process(HttpResponse response) {
    JSONParse parser = new JSONParse(response.getBody());
    updateFieldIfValid(parameters.countyField, parser.get(COUNTY_PATH).getStringValue());
    updateFieldIfValid(parameters.latitudeField, parser.get(LATITUDE_PATH).getDecimalValue());
    updateFieldIfValid(parameters.longitudeField, parser.get(LONGITUDE_PATH).getDecimalValue());
    updateFieldIfValid(parameters.zipField, parser.get(ZIP_PLUS_FOUR_PATH).getStringValue());

    if (this.censusDataAvailable) {
      updateFieldIfValid(parameters.censusTractField, parser.get(getCensusTractPath()).getStringValue());
      updateFieldIfValid(parameters.fipsCodeField, parser.get(getFipsPath()).getStringValue());
    }

    try {
      update parameters.records[0];
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error processing Geocodio response: ' + e.getMessage());
    }
  }

  private void updateFieldIfValid(String fieldName, Object value) {
    if (String.isNotBlank(fieldName) && value != null) {
      parameters.records[0].put(fieldName, value);
    }
  }

  private String getCensusTractPath() {
    return 'results.[0].fields.census.' + censusYear + '.tract_code';
  }

  private String getFipsPath() {
    return 'results.[0].fields.census.' + censusYear + '.full_fips';
  }
}
