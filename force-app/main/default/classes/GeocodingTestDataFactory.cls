@IsTest
public class GeocodingTestDataFactory {
  public static GeocodingInvocable.Parameters buildParameters() {
    GeocodingInvocable.Parameters parameters = new GeocodingInvocable.Parameters();
    parameters.records = new List<Account>{ createAccount(true) };
    parameters.streetField = 'BillingStreet';
    parameters.cityField = 'BillingCity';
    parameters.stateField = 'BillingState';
    parameters.zipField = 'BillingPostalCode';
    parameters.includeZipPlusFour = true;
    parameters.latitudeField = 'BillingLatitude';
    parameters.longitudeField = 'BillingLongitude';
    // Intentionally using these fields as they are standard Account text fields
    parameters.countyField = 'Description';
    parameters.censusTractField = 'AccountNumber';
    parameters.fipsCodeField = 'NaicsDesc';
    return parameters;
  }

  public static Account createAccount(Boolean doInsert) {
    return createAccount('Test Account', doInsert);
  }

  public static Account createAccount(String name, Boolean doInsert) {
    Account newAccount = new Account(
      Name = name,
      BillingStreet = '37921 N Dilleys Rd',
      BillingCity = 'Wadsworth',
      BillingState = 'IL',
      BillingPostalCode = '60083'
    );
    if (doInsert) {
      insert newAccount;
    }
    return newAccount;
  }

  public static String getResponseBody(String responseType, String recordId) {
    switch on responseType {
      when 'success' {
        return getSucessResponse(recordId);
      }
      when 'no fields' {
        return getNoFieldsResponse(recordId);
      }
      when 'error' {
        return '{"error": "You can\'t make this request as it is above your daily maximum."}';
      }
      when else {
        return null;
      }
    }
  }

  public static String getSucessResponse(String recordId) {
    String jsonPart1 = '{"results":{"' + recordId + '":{"response":{"results":[';
    String jsonPart2 =
      '{' +
      ' "address_components": {' +
      '   "county": "Lake County"' +
      ' },' +
      ' "location": {' +
      '   "lat": 42.413297,' +
      '   "lng": -87.941093' +
      ' },' +
      ' "fields": {' +
      '   "census": {' +
      '     "2024": {' +
      '       "tract_code": "861505",' +
      '       "full_fips": "170978615051002"' +
      '      }' +
      '     },' +
      '   "zip4": {' +
      '     "zip9": [' +
      '       "60083-9630"' +
      '     ]' +
      '   }' +
      '  }' +
      ' }' +
      ' ]}}}}';
    return jsonPart1 + jsonPart2;
  }
  public static String getNoFieldsResponse(String recordId) {
    String jsonPart1 = '{"results":{"' + recordId + '":{"response":{"results":[';
    String jsonPart2 =
      '{' +
      ' "address_components": {' +
      '   "county": "Lake County"' +
      ' },' +
      ' "location": {' +
      '   "lat": 42.413297,' +
      '   "lng": -87.941093' +
      ' }' +
      '}' +
      ']}}}}';
    return jsonPart1 + jsonPart2;
  }
}
