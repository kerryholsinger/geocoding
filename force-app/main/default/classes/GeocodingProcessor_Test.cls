/**
 * Unit tests for the GeocodingProcessor class
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 */
@IsTest
public class GeocodingProcessor_Test {
  @IsTest
  static void testSuccess() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    String recordId = parameters.records[0].Id;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'success', recordId));
    HttpResponse response = new Http().send(new HttpRequest());
    GeocodingProcessor processor = new GeocodingProcessor(parameters);
    processor.process(response);
    Test.stopTest();

    Account account = [SELECT Id, BillingLatitude, BillingLongitude FROM Account WHERE Id = :recordId];

    Assert.areEqual(42.413297, account.BillingLatitude, 'Expected BillingLatitude to be 42.413297');
    Assert.areEqual(-87.941093, account.BillingLongitude, 'Expected BillingLongitude to be -87.941093');
  }
}
