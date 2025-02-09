/**
 * Unit tests for the GeocodingAPIService class
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 */
@IsTest
public class GeocodingAPIService_Test {
  /**
   * Tests the successful execution of the Geocoding API callout.
   * Verifies that the response returns a 200 status code.
   */
  @IsTest
  static void testSuccess() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    String recordId = parameters.records[0].Id;
    GeocodingAPIService api = new GeocodingAPIService(parameters);

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'success', recordId));
    HttpResponse response = api.sendRequest();
    Test.stopTest();

    // Verifies that a 200 status code was returned
    Assert.areEqual(200, response.getStatusCode(), 'Expected response status code to be 200');
  }

  /**
   * Verifies that a 403 error response throws a CalloutException with the expected message.
   */
  @IsTest
  static void testError() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    String recordId = parameters.records[0].Id;
    GeocodingAPIService api = new GeocodingAPIService(parameters);

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(403, 'error', recordId));
    try {
      HttpResponse response = api.sendRequest();
      // Immediately fail the test if an exception was not thrown
      Assert.fail('Expected CalloutException was not thrown');
    } catch (CalloutException e) {
      // Verify that the expected exception was thrown
      Assert.isTrue(
        e.getMessage().contains('Geocodio API request failed with status code: 403'),
        'Expected CalloutException was not thrown - validate response'
      );
    }
    Test.stopTest();
  }

  /**
   * Ensures a null response triggers a CalloutException with the expected error message.
   */
  @IsTest
  static void testNullResponse() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    GeocodingAPIService api = new GeocodingAPIService(parameters);

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(null, null, null));
    try {
      HttpResponse response = api.sendRequest();
      // Immediately fail the test if an exception was not thrown
      Assert.fail('Expected CalloutException was not thrown.');
    } catch (CalloutException e) {
      // Verify that the expected exception was thrown
      Assert.isTrue(e.getMessage().contains('Error sending Geocodio request:'), 'Expected CalloutException was not thrown - error sending request');
    }
    Test.stopTest();
  }
}
