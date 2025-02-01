public class GeocodingAPIService implements Database.AllowsCallouts {
  private static final String GEOCODIO_ENDPOINT = 'https://api.geocod.io/v1.7/geocode?api_key=';

  private GeocodingInvocable.Parameters parameters;
  private String censusYear;

  /**
   * Initializes the GeocodingAPIService with the given parameters.
   * Sets the census year from the Geocodio Census Year custom label or defaults to two years ago.
   *
   * @param parameters The geocoding request parameters.
   */
  public GeocodingAPIService(GeocodingInvocable.Parameters parameters) {
    this.parameters = parameters;
    this.censusYear = String.isBlank(System.Label.Geocodio_Census_Year)
      ? String.valueOf(Date.today().year() - 2) // Default to 2 years ago to ensure Census data is available
      : System.Label.Geocodio_Census_Year;
  }

  /**
   * Sends an HTTP POST request to the Geocodio API for batch geocoding.
   * The request body contains multiple addresses in a structured JSON format, with each record's ID as the key.
   *
   * @return The HttpResponse received from the Geocodio API.
   */
  public HttpResponse sendRequest() {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(buildEndpoint());
    request.setMethod('POST');
    request.setTimeout(120000);
    request.setHeader('Content-Type', 'application/json');
    request.setBody(buildRequestBody());
    try {
      HttpResponse response = new Http().send(request);
      return response;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error sending Geocodio request: ' + e.getMessage());
      return null;
    }
  }

  /**
   * @description Builds the complete Geocodio API endpoint URL, including the API key
   * and optional fields parameters based on the requested geocoding details.
   * @return The fully constructed endpoint URL as a String.
   */
  private String buildEndpoint() {
    List<String> fields = new List<String>();
    if (parameters.includeZipPlusFour) {
      fields.add('zip4');
    }
    if (parameters.censusTractField != null || parameters.fipsCodeField != null) {
      fields.add('census' + censusYear);
    }
    String fieldsParam = fields.isEmpty() ? '' : '&fields=' + String.join(fields, ',');
    return GEOCODIO_ENDPOINT + System.Label.Geocodio_API_Key + fieldsParam;
  }

  /**
   * Builds a JSON request body for batch geocoding. Iterates through the provided records, extracts address fields
   * using dynamic field names, and structures the data as a JSON object where each record's ID is the key.
   *
   * @return A JSON-formatted string representing the batch geocoding request.
   */
  private String buildRequestBody() {
    Map<String, Map<String, String>> geocodeRequest = new Map<String, Map<String, String>>();

    for (SObject record : parameters.records) {
      String recordId = (String) record.get('Id');
      Map<String, String> address = new Map<String, String>();

      address.put('street', (String) record.get(parameters.streetField));
      address.put('city', (String) record.get(parameters.cityField));
      address.put('state', (String) record.get(parameters.stateField));
      address.put('postal_code', (String) record.get(parameters.zipField));

      geocodeRequest.put(recordId, address);
    }
    return JSON.serialize(geocodeRequest);
  }
}
