@isTest
private class GeocodingQueueable_Test {
  private static Account createAccount() {
    Account account = new Account(
      Name = 'Test Account',
      BillingStreet = '37921 N Dilleys Rd',
      BillingCity = 'Wadsworth',
      BillingState = 'Illinois',
      BillingPostalCode = '60083'
    );
    insert account;
    return account;
  }

  private static GeocodingQueueable.GeocodingParameters setupParameters(SObject record) {
    GeocodingQueueable.GeocodingParameters parameters = new GeocodingQueueable.GeocodingParameters();
    parameters.record = record;
    parameters.streetField = 'BillingStreet';
    parameters.cityField = 'BillingCity';
    parameters.stateField = 'BillingState';
    parameters.zipField = 'BillingPostalCode';
    parameters.includeZipPlusFour = true;
    parameters.latitudeField = 'BillingLatitude';
    parameters.longitudeField = 'BillingLongitude';
    // Intentionally using Description field since standard fields are not available.
    parameters.countyField = 'Description';
    parameters.censusTractField = 'Description';
    parameters.fipsCodeField = 'Description';

    return parameters;
  }

  @isTest
  private static void testSuccess() {
    Account account = createAccount();
    GeocodingQueueable.GeocodingParameters parameters = setupParameters(account);

    Test.setMock(HttpCalloutMock.class, new TestHTTPCalloutMock(200, getMockResponse()));
    Test.startTest();
    GeocodingQueueable.enqueueJob(new List<GeocodingQueueable.GeocodingParameters>{ parameters });
    Test.stopTest();

    Account updatedAccount = [
      SELECT Id, BillingPostalCode
      FROM Account
      WHERE Id = :account.Id
    ];

    Assert.areEqual(
      '60083-9630',
      updatedAccount.BillingPostalCode,
      'Expected the updated BillingPostalCode to match the mock response value of 60083-9630.'
    );
  }

  private static String getMockResponse() {
    String mockResponse =
      '{' +
      '  "input": {' +
      '    "address_components": {' +
      '      "number": "37921",' +
      '      "predirectional": "N",' +
      '      "street": "Dilleys",' +
      '      "suffix": "Rd",' +
      '      "formatted_street": "N Dilleys Rd",' +
      '      "city": "Wadsworth",' +
      '      "state": "IL",' +
      '      "zip": "60083",' +
      '      "country": "US"' +
      '    },' +
      '    "formatted_address": "37921 N Dilleys Rd, Wadsworth, IL 60083"' +
      '  },' +
      '  "results": [' +
      '    {' +
      '      "address_components": {' +
      '        "number": "37921",' +
      '        "predirectional": "N",' +
      '        "street": "Dilleys",' +
      '        "suffix": "Rd",' +
      '        "formatted_street": "N Dilleys Rd",' +
      '        "city": "Wadsworth",' +
      '        "county": "Lake County",' +
      '        "state": "IL",' +
      '        "zip": "60083",' +
      '        "country": "US"' +
      '      },' +
      '      "formatted_address": "37921 N Dilleys Rd, Wadsworth, IL 60083",' +
      '      "location": {' +
      '        "lat": 42.413297,' +
      '        "lng": -87.941093' +
      '      },' +
      '      "accuracy": 1,' +
      '      "accuracy_type": "rooftop",' +
      '      "source": "Lake",' +
      '      "fields": {' +
      '        "census": {' +
      '          "2024": {' +
      '            "census_year": 2024,' +
      '            "state_fips": "17",' +
      '            "county_fips": "17097",' +
      '            "tract_code": "861505",' +
      '            "block_code": "1002",' +
      '            "block_group": "1",' +
      '            "full_fips": "170978615051002",' +
      '            "place": {' +
      '              "name": "Wadsworth",' +
      '              "fips": "1778370"' +
      '            },' +
      '            "metro_micro_statistical_area": {' +
      '              "name": "Chicago-Naperville-Elgin, IL-IN",' +
      '              "area_code": "16980",' +
      '              "type": "metropolitan"' +
      '            },' +
      '            "combined_statistical_area": {' +
      '              "name": "Chicago-Naperville, IL-IN-WI",' +
      '              "area_code": "176"' +
      '            },' +
      '            "metropolitan_division": {' +
      '              "name": "Lake County, IL",' +
      '              "area_code": "29404"' +
      '            },' +
      '            "county_subdivision": {' +
      '              "name": "Warren",' +
      '              "fips": "78877",' +
      '              "fips_class": {' +
      '                "class_code": "T1",' +
      '                "description": "An active county subdivision that is not coextensive with an incorporated place"' +
      '              }' +
      '            },' +
      '            "source": "US Census Bureau"' +
      '          }' +
      '        },' +
      '        "zip4": {' +
      '          "record_type": {' +
      '            "code": "S",' +
      '            "description": "Street"' +
      '          },' +
      '          "residential": true,' +
      '          "carrier_route": {' +
      '            "id": "R001",' +
      '            "description": "Rural Route"' +
      '          },' +
      '          "building_or_firm_name": null,' +
      '          "plus4": ["9630"],' +
      '          "zip9": ["60083-9630"],' +
      '          "government_building": null,' +
      '          "facility_code": {' +
      '            "code": "P",' +
      '            "description": "Post Office"' +
      '          },' +
      '          "city_delivery": false,' +
      '          "valid_delivery_area": true,' +
      '          "exact_match": true' +
      '        }' +
      '      }' +
      '    }' +
      '  ]' +
      '}';
    return mockResponse;
  }
}