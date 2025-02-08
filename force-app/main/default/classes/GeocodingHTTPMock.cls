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
    response.setBody(getResponseBody());
    return response;
  }

  private String getResponseBody() {
    String json;
    switch on responseType {
      when 'success' {
        json = getSucessResponse();
      }
    }
    return json;
  }

  private String getSucessResponse() {
    String json =
      '{' +
      '    "results": {' +
      '        "' +
      recordId +
      '": {' +
      '            "response": {' +
      '                "results": [' +
      '                    {' +
      '                        "address_components": {' +
      '                            "county": "Lake County"' +
      '                        },' +
      '                        "location": {' +
      '                            "lat": 42.413297,' +
      '                            "lng": -87.941093' +
      '                        },' +
      '                        "fields": {' +
      '                            "census": {' +
      '                                "2024": {' +
      '                                    "tract_code": "861505",' +
      '                                    "full_fips": "170978615051002"' +
      '                                }' +
      '                            },' +
      '                            "zip4": {' +
      '                                "zip9": [' +
      '                                    "60083-9630"' +
      '                                ]' +
      '                            }' +
      '                        }' +
      '                    }' +
      '                ]' +
      '            }' +
      '        }' +
      '    }' +
      '}';
    return json;
  }
}
