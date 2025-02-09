/**
 * A Queueable job for geocoding a collection of records via the Geocodio API.
 * Sends a geocoding request using GeocodingAPIService and processes the response with GeocodingProcessor.
 *
 * @author Kerry Holsinger
 * @group Geocoding
 * @created Feb 2025
 * @tests GeocodingQueueable_Test
 */
public class GeocodingQueueable implements Queueable, Database.AllowsCallouts {
  private GeocodingInvocable.Parameters parameters;
  private GeocodingAPIService api;

  /**
   * Constructs a new Queueable job, setting the paramaters for geocoding and intialilizing the API service.
   * @param invocableParameters The parameters used for geocoding requests.
   */
  public GeocodingQueueable(GeocodingInvocable.Parameters invocableParameters) {
    this.parameters = invocableParameters;
    this.api = new GeocodingAPIService(invocableParameters);
  }

  /**
   * Executes the queueable job by sending a geocoding request to the Geocodio API and processing the response.
   * @param context The Queueable context.
   */
  public void execute(QueueableContext context) {
    HttpResponse response = api.sendRequest();
    GeocodingProcessor processor = new GeocodingProcessor(parameters);
    processor.process(response);
  }
}
