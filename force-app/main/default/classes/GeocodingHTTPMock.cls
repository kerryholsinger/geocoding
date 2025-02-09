@isTest
public class GeocodingHTTPMock implements HttpCalloutMock {
  private Integer statusCode;
  private String responseType;
  private String recordId;

  public GeocodingHTTPMock(Integer statusCode, String responseType, String recordId) {
    this.statusCode = statusCode;
    this.responseType = responseType;
    this.recordId = recordId;
  }

  public HTTPResponse respond(HTTPRequest request) {
    HttpResponse response = new HttpResponse();
    response.setStatusCode(statusCode);
    response.setBody(GeocodingTestDataFactory.getResponseBody(responseType, recordId));
    return response;
  }
}
