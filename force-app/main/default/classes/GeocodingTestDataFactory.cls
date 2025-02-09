@IsTest
public class GeocodingTestDataFactory {
  public static GeocodingInvocable.Parameters buildParameters() {
    GeocodingInvocable.Parameters parameters = new GeocodingInvocable.Parameters();
    parameters.records = new List<Account>{ createAccount(true) };
    parameters.streetField = 'BillingStreet';
    parameters.cityField = 'BillingCity';
    parameters.stateField = 'BillingState';
    parameters.zipField = 'BillingPostalCode';
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
}
