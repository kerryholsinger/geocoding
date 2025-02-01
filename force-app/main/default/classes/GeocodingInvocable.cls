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
  @InvocableMethod(label='Address Gecoding' description='Geocode a collection of addresseses on any object')
  public static void enqueueGeocodingJob(List<Parameters> invocableParameters) {
    for (Parameters parameters : invocableParameters) {
      System.enqueueJob(new GeocodingQueueable(parameters));
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
