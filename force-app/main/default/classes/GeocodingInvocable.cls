/**
 * @description Invocable action for bulk geocoding addresses on any object.
 * Accepts a collection of sObjects and enqueues a Queueable job for asynchronous processing.
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Jan 2025
 * @tests: TBD
 */
public class GeocodingInvocable {
  /**
   * @description Invocable action to enqueue a geocoding job with the provided geocoding parameters.
   * @param invocableParameters List of geocoding parameters containing the address fields and other geocoding details.
   */
  @InvocableMethod(label='Address Gecoding' description='Geocode a collection of addresses on any object')
  public static void enqueueGeocodingJob(List<Parameters> invocableParameters) {
    for (Parameters parameters : invocableParameters) {
      validateInputParameters(parameters);
      System.enqueueJob(new GeocodingQueueable(parameters));
    }
  }

  /**
   * Validates that the specified fields exist on the provided records.
   * Throws an exception if any of the fields do not exist on the object.
   */
  private static void validateInputParameters(Parameters parameters) {
    // Ensure the provided record collection is not empty
    if (parameters.records.isEmpty()) {
      throw new IllegalArgumentException('The provided record collection is empty.');
    }

    Map<String, Schema.SObjectField> objectFields = parameters.records[0].getSObjectType().getDescribe().fields.getMap();

    List<String> inputFieldsToCheck = new List<String>{
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

    // Ensure all fields provded in the input parameters exist on the object
    for (String field : inputFieldsToCheck) {
      if (String.isNotBlank(field) && !objectFields.containsKey(field)) {
        throw new IllegalArgumentException('Field does not exist on the provided record: ' + field);
      }
    }
  }

  /**
   * Parameters for geocoding an address with the invocable.
   * Defines required address fields and optional geocoding attributes.
   */
  public class Parameters {
    // Required parameters
    @InvocableVariable(label='Record Collection' required=true)
    public List<SObject> records;

    @InvocableVariable(label='Street Field API Name' required=true)
    public String streetField;

    @InvocableVariable(label='City Field API Name' required=true)
    public String cityField;

    @InvocableVariable(label='State Field API Name' required=true)
    public String stateField;

    @InvocableVariable(label='ZIP Field API Name' required=true)
    public String zipField;

    // Optional parameters
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
