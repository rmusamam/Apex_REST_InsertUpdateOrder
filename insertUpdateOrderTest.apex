@isTest
private class SVC_CreateOrderWithItemsTest {

    @isTest
    static void testCreateOrderWithItems() {
        // Create a test Account and Contact
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(AccountId = testAccount.Id, FirstName = 'John', LastName = 'Doe', Email = 'test@example.com');
        insert testContact;
		
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id= pricebookId, IsActive = true );
    	update pb;

        // Create a Product2 record
        Product2 testProduct = new Product2(Name = 'Test Product', External_ID__c = 'EXT001');
        insert testProduct;
        

        // Create a PriceBookEntry for the product
        PriceBookEntry pbe = new PriceBookEntry(Product2Id = testProduct.Id, Pricebook2Id =pb.Id , isActive=true, UnitPrice = 100.00);      
        insert pbe;
       
        XStore_Association__c xStore = new XStore_Association__c(Contact__c=testContact.id, XStore_Cust_Id__c= '123456');
        insert xStore;
        
        // Call the createOrderWithItems method
        Test.startTest();	
        // Serialize the request into JSON	
		String jsonRequest = '{"order":{"effectivedate":"2023-08-16","orderCurrency":"us","External_Id":"EXT001","order_total":1000,"product_sub_total":1000,"product_total":1000,"status":"pending","tax_total":100,"customer_Id":"123456","tax_value":100,"Payment_Amount":100,"BillingStreet":"123 Main","BillingCity":"Houston","BillingCountry":"US","Billing_First_Name":"Joe","Billing_Full_Name":"Joe Customer","Billing_Last_Name":"Customer1","Billing_Phone":"555-123-4567","BillingPostalCode":"77001","BillingState":"TX","OrderType":"POS","OrderItems":[{"Line_Number":1,"External_Id":"extid123_P123_1","ProductCode":"EXT001","Quantity":10,"UnitPrice":22,"Price":1005,"productid":"123","Tax":1001,"Tax_Basis":1001,"Tax_class_Id":"1234","Tax_Rate":1234.12345,"c_fromStoreId":"000111","Types":"Product","ContractNumber":"4567","Status":"Returned"},{"Line_Number":8,"External_Id":"extid123 P123_2","ProductCode":"EXT001","Quantity":12,"UnitPrice":1002,"Price":1002,"productid":"123","Tax":100,"Tax_Basis":100,"Tax_class_Id":"123","Tax_Rate":1234.12345,"c_fromStoreId":"000112","Types":"Care Plan","ContractNumber":"4567","Status":"Returned"}]}}';
        
        // Set up the RestRequest and RestResponse objects
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestBody = Blob.valueOf(jsonRequest);
        RestContext.request = request;
        RestContext.response = response;


        SVC_CreateOrderWithItems.createOrderWithItems();
        SVC_CreateOrderWithItems.createOrderWithItems();
        
        SVC_CreateOrderWithItems.RestResponseClass responseObj1 = (SVC_CreateOrderWithItems.RestResponseClass)JSON.deserialize(
        RestContext.response.responseBody.toString(), SVC_CreateOrderWithItems.RestResponseClass.class);
         System.assertEquals('Success', responseObj1.status);    

        // Serialize the request into JSON	
		String jsonRequest1 = '{"order":{"effectivedate":"2023-08-16","orderCurrency":"us","External_Id":"EXT001","order_total":1000,"product_sub_total":1000,"product_total":1000,"status":"pending","tax_total":100,"customer_Id":"1234567","tax_value":100,"Payment_Amount":100,"BillingStreet":"123 Main","BillingCity":"Houston","BillingCountry":"US","Billing_First_Name":"Joe","Billing_Full_Name":"Joe Customer","Billing_Last_Name":"Customer1","Billing_Phone":"555-123-4567","BillingPostalCode":"77001","BillingState":"TX","OrderType":"POS","OrderItems":[{"Line_Number":1,"External_Id":"extid123_P123_1","ProductCode":"EXT001","Quantity":10,"UnitPrice":22,"Price":1005,"productid":"123","Tax":1001,"Tax_Basis":1001,"Tax_class_Id":"1234","Tax_Rate":1234.12345,"c_fromStoreId":"000111","Types":"Product","ContractNumber":"4567","Status":"Returned"},{"Line_Number":8,"External_Id":"extid123 P123_2","ProductCode":"EXT001","Quantity":12,"UnitPrice":1002,"Price":1002,"productid":"123","Tax":100,"Tax_Basis":100,"Tax_class_Id":"123","Tax_Rate":1234.12345,"c_fromStoreId":"000112","Types":"Care Plan","ContractNumber":"4567","Status":"Returned"}]}}';
        
        // Set up the RestRequest and RestResponse objects
        RestRequest request1 = new RestRequest();
        RestResponse response1 = new RestResponse();
        request.requestBody = Blob.valueOf(jsonRequest1);
        RestContext.request = request1;
        RestContext.response = response1;        
        SVC_CreateOrderWithItems.createOrderWithItems();

        Test.stopTest();
        
     
        // Verify the response
        SVC_CreateOrderWithItems.RestResponseClass responseObj = (SVC_CreateOrderWithItems.RestResponseClass)JSON.deserialize(
        RestContext.response.responseBody.toString(), SVC_CreateOrderWithItems.RestResponseClass.class);

        // Add assertions for the response
        System.assertEquals('Failed', responseObj.status);       

    }
}