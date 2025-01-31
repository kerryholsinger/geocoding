public class GeocodingQueueable implements Queueable, Database.AllowsCallouts {
  /** Constants for JSON paths to extract data from the Geocodio API response */
  /** For Census Tract and FIPS Code JSON paths, see getCensusTractPath() and getFipsPath() */
  private static final String COUNTY_PATH = 'results.[0].address_components.county';
  private static final String LATITUDE_PATH = 'results.[0].location.lat';
  private static final String LONGITUDE_PATH = 'results.[0].location.lng';
  private static final String ZIP_PLUS_FOUR_PATH = 'results.[0].fields.zip4.zip9.[0]';

  private GeocodingParameters parameters;
  private HttpResponse response;
  private String street;
  private String city;
  private String state;
  private String zip;
  private String censusYear;
  private Boolean censusDataAvailable = false;

  // ---------------------------------------
  // ------ Queueable Execution ------------
  // ---------------------------------------

  /**
   * @description Invocable action to enqueue a geocoding job with the provided geocoding parameters.
   * @param inputParameters List of GeocodingParameters containing the address and other geocoding details.
   */
  @InvocableMethod(label='Geocode an Address')
  public static void enqueueJob(List<GeocodingParameters> inputParameters) {
    GeocodingQueueable queueable = new GeocodingQueueable();
    queueable.parameters = inputParameters[0];
    System.enqueueJob(queueable);
  }

  /**
   * @description Executes the geocoding job by validating the address, sending an HTTP request, and processing the response.
   * @param context The queueable context containing the job details.
   */
  public void execute(QueueableContext context) {
    validateFields();
    initializeRequestVariables();
    validateAddress();
    sendRequest();
    processResponse();
  }

  // ---------------------------------------
  // ------ Variable Initialization --------
  // ---------------------------------------

  private void validateFields() {
    List<String> fieldsToCheck = new List<String>{
      parameters.streetField,
      parameters.cityField,
      parameters.stateField,
      parameters.zipField,
      parameters.countyField,
      parameters.latitudeField,
      parameters.longitudeField,
      parameters.censusTractField,
      parameters.fipsCodeField
    };

    Map<String, Schema.SObjectField> objectFields = parameters.record.getSObjectType().getDescribe().fields.getMap();

    for (String field : fieldsToCheck) {
      if (String.isNotBlank(field) && !objectFields.containsKey(field)) {
        throw new IllegalArgumentException('Field does not exist on the provided record: ' + field);
      }
    }
  }

  /**
   * @description Initializes the request variables, including address components and census year.
   */
  private void initializeRequestVariables() {
    this.street = (String) parameters.record.get(parameters.streetField);
    this.city = (String) parameters.record.get(parameters.cityField);
    this.state = (String) parameters.record.get(parameters.stateField);
    this.zip = (String) parameters.record.get(parameters.zipField);

    this.censusYear = String.isBlank(System.Label.Geocodio_Census_Year)
      ? String.valueOf(Date.today().year() - 2) // Default to 2 years ago to ensure Census data is available
      : System.Label.Geocodio_Census_Year;
  }

  /**
   * @description Validates the address fields to ensure they are not null or empty.
   * @throws IllegalArgumentException if any of the address fields are null or empty.
   */
  private void validateAddress() {
    if (String.isBlank(street) || String.isBlank(city) || String.isBlank(state) || String.isBlank(zip)) {
      throw new IllegalArgumentException('Address fields cannot be null or empty.');
    }
  }

  // ---------------------------------------
  // ------ API Request Handling -----------
  // ---------------------------------------

  /**
   * @description Sends an HTTP GET request to the Geocodio API to retrieve geocoding details for the address.
   */
  private void sendRequest() {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(buildEndpoint());
    request.setMethod('GET');
    request.setTimeout(120000); // Set timeout to 120 seconds
    try {
      response = new Http().send(request);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error sending Geocodio request: ' + e.getMessage());
    }
  }

  /**
   * @description Builds the endpoint URL for the Geocodio API request.
   * @return The endpoint URL as a String.
   */
  private String buildEndpoint() {
    String address = formatAddress();
    String fields = buildFieldsParameter();
    String endpoint = 'https://api.geocod.io/v1.7/geocode?q=' + address + '&api_key=' + System.Label.Geocodio_API_Key;
    if (!String.isEmpty(fields)) {
      endpoint += '&fields=' + fields;
    }
    System.debug('*** endpoint: ' + endpoint);
    return endpoint;
  }

  /**
   * @description Formats the address into a URL-encoded string.
   * @return The formatted address as a String.
   */
  private String formatAddress() {
    String address = street + '+' + city + '+' + state + '+' + zip;
    address = address.replace('#', '') // Remove '#' symbols
      .replace('\r', ' ') // Replace carriage returns with spaces
      .replace('\n', ' ') // Replace new lines with spaces
      .replace(' ', '+'); // Replace spaces with '+'
    return address;
  }

  /**
   * @description Builds the fields parameter for the Geocodio API request.
   * @return A comma-separated string of fields to include in the request, or an empty string if no fields are needed.
   */
  private String buildFieldsParameter() {
    List<String> fields = new List<String>();
    if (parameters.includeZipPlusFour) {
      fields.add('zip4');
    }
    if (parameters.censusTractField != null || parameters.fipsCodeField != null) {
      fields.add('census' + censusYear);
      this.censusDataAvailable = true;
    }
    return String.join(fields, ',');
  }

  // ---------------------------------------
  // ------ Response Processing ------------
  // ---------------------------------------

  /**
   * @description Processes the response from the Geocodio API and updates the corresponding fields.
   */
  private void processResponse() {
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
      update parameters.record;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error processing Geocodio response: ' + e.getMessage());
    }
  }

  /**
   * @description Updates the specified field if the field name is not blank and the value is not null.
   * @param fieldName The API name of the field to update in the record.
   * @param value The value to set in the specified field.
   */
  private void updateFieldIfValid(String fieldName, Object value) {
    if (String.isNotBlank(fieldName) && value != null) {
      parameters.record.put(fieldName, value);
    }
  }

  /**
   * @description Returns the JSON path for Census Tract based on the dynamic census year.
   * @return The formatted JSON path for Census Tract.
   */
  private String getCensusTractPath() {
    return 'results.[0].fields.census.' + censusYear + '.tract_code';
  }

  /**
   * @description Returns the JSON path for Full FIPS based on the dynamic census year.
   * @return The formatted JSON path for Full FIPS.
   */
  private String getFipsPath() {
    return 'results.[0].fields.census.' + censusYear + '.full_fips';
  }

  /**
   * @description Subclass to capture parameters for geocoding in the InvocableMethod.
   */
  public class GeocodingParameters {
    @InvocableVariable(label='Record' required=true)
    public SObject record;

    @InvocableVariable(label='Street Field API Name' required=true)
    public String streetField;

    @InvocableVariable(label='City Field API Name' required=true)
    public String cityField;

    @InvocableVariable(label='State Field API Name' required=true)
    public String stateField;

    @InvocableVariable(label='ZIP Field API Name' required=true)
    public String zipField;

    @InvocableVariable(label='Include ZIP+4' required=false)
    public Boolean includeZipPlusFour = false;

    @InvocableVariable(label='County Field API Name' required=false)
    public String countyField;

    @InvocableVariable(label='Latitude Field API Name' required=false)
    public String latitudeField;

    @InvocableVariable(label='Longitude Field API Name' required=false)
    public String longitudeField;

    @InvocableVariable(label='Census Tract Field API Name' required=false)
    public String censusTractField;

    @InvocableVariable(label='FIPS Code Field API Name' required=false)
    public String fipsCodeField;
  }
}
