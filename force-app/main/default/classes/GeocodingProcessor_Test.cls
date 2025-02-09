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

    Account account = [
      SELECT Id, BillingPostalCode, BillingLatitude, BillingLongitude, Description, AccountNumber, NaicsDesc
      FROM Account
      WHERE Id = :recordId
    ];

    // Verify that the fields were populated with the expected values
    Assert.areEqual('60083-9630', account.BillingPostalCode, 'Expected BillingPostalCode to be 60083-9630');
    Assert.areEqual(42.413297, account.BillingLatitude, 'Expected BillingLatitude to be 42.413297');
    Assert.areEqual(-87.941093, account.BillingLongitude, 'Expected BillingLongitude to be -87.941093');
    Assert.areEqual('Lake', account.Description, 'Expected County (Description) to be "Lake"');
    Assert.areEqual('861505', account.AccountNumber, 'Expected Census Tract (AccountNumber) to be "861505"');
    Assert.areEqual('170978615051002', account.NaicsDesc, 'Expected FIPS Code (NaicsDesc) to be "170978615051002"');
  }

  @IsTest
  static void testMissingResponseData() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    String recordId = parameters.records[0].Id;

    Test.startTest();
    // return a response with without the fields object requested
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'no fields', recordId));
    try {
      HttpResponse response = new Http().send(new HttpRequest());
      GeocodingProcessor processor = new GeocodingProcessor(parameters);
      processor.process(response);
      // Immediately fail the test if an exception was not thrown
      Assert.fail('Expected GeocodingProcessorException to be thrown due to missing fields');
    } catch (GeocodingProcessor.GeocodingProcessorException e) {
      // Verify the expected exception was thrown
      Assert.isTrue(
        e.getMessage().contains('Invalid response structure or missing data'),
        'Expected error message to be: "Invalid response structure or missing data"'
      );
    }
    Test.stopTest();
  }
}
