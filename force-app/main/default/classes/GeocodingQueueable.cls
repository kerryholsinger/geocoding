public class GeocodingQueueable implements Queueable, Database.AllowsCallouts {
  private GeocodingInvocable.Parameters parameters;
  private GeocodingAPIService api;

  public GeocodingQueueable(GeocodingInvocable.Parameters invocableParameters) {
    this.parameters = invocableParameters;
    this.api = new GeocodingAPIService(invocableParameters);
  }

  public void execute(QueueableContext context) {
    HttpResponse response = api.sendRequest();
    GeocodingResponseProcessor processor = new GeocodingResponseProcessor(parameters);
    processor.process(response);
  }
}
