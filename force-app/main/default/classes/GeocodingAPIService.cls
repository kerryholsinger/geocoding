/**
 * Handles batch geocoding via the Geocodio API. Constructs and sends HTTP requests,
 * formats address data, and supports optional fields like ZIP+4 and census tract data.
 * Defaults the census year to two years ago if not specified.
 *
 * @author Kerry Holsinger
 * @group Geocoding
 * @created Feb 2025
 * @tests _Test
 */
public class GeocodingAPIService implements Database.AllowsCallouts {
  private static final String GEOCODIO_ENDPOINT = 'https://api.geocod.io/v1.7/geocode?api_key=';

  private GeocodingInvocable.Parameters parameters;
  private String censusYear = GeocodingUtility.getCensusYear();

  /**
   * Initializes the GeocodingAPIService with the given parameters.
   * Sets the census year from the Geocodio Census Year custom label or defaults to two years ago.
   * @param parameters The geocoding request parameters.
   */
  public GeocodingAPIService(GeocodingInvocable.Parameters parameters) {
    this.parameters = parameters;
  }

  /**
   * Sends an HTTP POST request to the Geocodio API for geocoding a collection of addresses.
   * The request body contains multiple addresses in a structured JSON format, with each record's ID as the key.
   * @return The HttpResponse received from the Geocodio API.
   * @throws CalloutException if an error occurs during the HTTP request.
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
      validateResponse(response);
      return response;
    } catch (Exception e) {
      throw new CalloutException('Error sending Geocodio request: ' + e.getMessage());
    }
  }

  /**
   * @description Builds the complete Geocodio API endpoint URL, including the API key
   * and optional fields parameters based on the requested geocoding details.
   * @return The fully constructed endpoint URL as a String.
   */
  private String buildEndpoint() {
    String endpoint = GEOCODIO_ENDPOINT + System.Label.Geocodio_API_Key;

    // Add optional fields to the endpoint if specified
    Set<String> fields = new Set<String>();
    if (parameters.includeZipPlusFour) {
      fields.add('zip4');
    }
    if (parameters.censusTractField != null || parameters.fipsCodeField != null) {
      fields.add('census' + censusYear);
    }
    String fieldsParameter = fields.isEmpty() ? '' : '&fields=' + String.join(fields, ',');
    return endpoint + fieldsParameter;
  }

  /**
   * Builds a JSON request body for batch geocoding. Iterates through the provided records, extracts address fields
   * using dynamic field names, and structures the data as a JSON object where each record's ID is the key.
   * @return A JSON-formatted string representing the batch geocoding request.
   */
  private String buildRequestBody() {
    Map<String, Map<String, String>> geocodeRequest = new Map<String, Map<String, String>>();

    for (SObject record : parameters.records) {
      String recordId = (String) record.get('Id');
      Map<String, String> addressMap = new Map<String, String>();

      addressMap.put('street', (String) record.get(parameters.streetField));
      addressMap.put('city', (String) record.get(parameters.cityField));
      addressMap.put('state', (String) record.get(parameters.stateField));
      addressMap.put('postal_code', (String) record.get(parameters.zipField));

      geocodeRequest.put(recordId, addressMap);
    }
    return JSON.serialize(geocodeRequest);
  }

  /**
   * Validates the response from the Geocodio API. Ensures the response is not null and has a successful status code.
   * @param response The HttpResponse received from the Geocodio API.
   * @throws CalloutException if the response is null or the status code is not 200.
   */
  private void validateResponse(HttpResponse response) {
    if (response == null) {
      throw new CalloutException('Geocodio API request failed: No response received.');
    }
    if (response.getStatusCode() != 200) {
      throw new CalloutException('Geocodio API request failed with status code: ' + response.getStatusCode() + '. Response body: ' + response.getBody());
    }
  }
}
