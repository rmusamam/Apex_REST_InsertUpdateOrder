@RestResource(urlMapping='/createOrderWithItems')
global with sharing class SVC_CreateOrderWithItems {
    global class RestResponseClass {
        global String status;
        global String orderNumber;
    }

    global class RestFailureResponse {
        global String status;
        global String errorMessage;
    }

    @HttpPost
    global static void createOrderWithItems() {
        try {
            RestRequest request = RestContext.request;
            String jsonResponse = request.requestBody.toString();
            
            Map<String, PriceBookEntry> priceBookEntryContractNumberMap = new Map<String, PriceBookEntry>();
            
            OrderWithItemsWrapper requestData = (OrderWithItemsWrapper) JSON.deserialize(
                jsonResponse,
                OrderWithItemsWrapper.class
            );

            List<OrderItem> newOrderItems = new List<OrderItem>();
            List<Care_Plan_Type__c> newCarePlans = new List<Care_Plan_Type__c>();
            List<String> prdSkuList = new List<String>();
            
            // External Id, Product Map
            Map<String, Product2> extIdProductmap = new Map<String, Product2>();
            Map<String, String> ExtIdContractNumMap = new Map<String, String>();
            Map<String, String> ExtIdTypeMap = new Map<String, String>();

            //fetching xStoreAssociation with related AccountId
            List<XStore_Association__c> xStoreAssociations = SVC_XStoreAssociationSelector.getXStoreAssociations(
                requestData
            );

            //fetching standard pricebook
            Pricebook2 standardPriceBook = SVC_PriceBookSelector.getStandardPriceBook().get(0);

            //preparing sku list
            for (OrderItemInput itemInput : requestData.order.OrderItems) {
                prdSkuList.add(itemInput.ProductCode);
            }
            
            //fetching products
            List<Product2> prodList = SVC_ProductSelector.getProductsByExternalId(prdSkuList);

            Map<Id, Product2> productMap = new Map<Id, Product2>(prodList);

            //preparing sku-product map
            for (Product2 prod : prodList) {
                if (prod.External_ID__c != null) {
                    extIdProductmap.put(prod.External_ID__c, prod);
                }
            }

            // Create the Order record
            Order newOrder = createOrder(requestData, xStoreAssociations, standardPriceBook);

            Map<String, OrderItem> orderItemContractMap = new Map<String, OrderItem>();
            Map<String, Care_Plan_Type__c> carePlanContractMap = new Map<String, Care_Plan_Type__c>();

            List<String> extProdIds = new List<STring>();
            
            //Creating OrderItems
            for (OrderItemInput itemInput : requestData.order.OrderItems) {
                ExtIdTypeMap.put(itemInput.productCode, itemInput.Types);
                if (itemInput.Types == 'Product') {
                    OrderItem newOrderItem = new OrderItem();

                    //creating External Id
                    String extId =
                        newOrder.External_ID__c +
                        '_' +
                        extIdProductmap.get(itemInput.ProductCode).External_ID__c +
                        '_' +
                        itemInput.Line_Number;

                    newOrderItem.OrderId = newOrder.id;
                    newOrderItem.External_ID__c = extId;
                    newOrderItem.UnitPrice = itemInput.UnitPrice;
                    newOrderItem.Quantity = itemInput.Quantity;
                    newOrderItem.Line_Number__c = itemInput.Line_Number;
                    newOrderItem.Price__c = itemInput.Price;
                    newOrderItem.Tax__c = itemInput.Tax;
                    newOrderItem.Tax_Basis__c = itemInput.Tax_Basis;
                    newOrderItem.Tax_Class_Id__c = itemInput.Tax_Class_Id;
                    newOrderItem.Tax_Rate__c = itemInput.Tax_Rate;
                    newOrderItem.Status__c = itemInput.Status;
                    newOrderItem.Type__c = itemInput.Types;
                    newOrderItem.c_fromStoreId__c = itemInput.c_fromStoreId;
                    newOrderItem.Status__c = itemInput.Status;
                    newOrderItem.Product2Id = extIdProductmap.get(itemInput.ProductCode).id;
                    
                    priceBookEntryContractNumberMap.put(
                        itemInput.ContractNumber,
                        getPriceBookEntry(itemInput, extIdProductmap, standardPriceBook.Id)
                    );

                    orderItemContractMap.put(itemInput.ContractNumber, newOrderItem);

                } else if (itemInput.Types == 'Care Plan') {
                    Care_Plan_Type__c newCarePlan = new Care_Plan_Type__c();
                    
                    newCarePlan.orderId__c = newOrder.id;
                    newCarePlan.ProductId__c = extIdProductmap.get(itemInput.ProductCode).id;
                    newCarePlan.ContractNumber__c = itemInput.ContractNumber;

                    carePlanContractMap.put(itemInput.ContractNumber, newCarePlan);
                }
            }

            //creating and updating the PriceBookEntries.
            upsert priceBookEntryContractNumberMap.values();
            for (String contractNumber : orderItemContractMap.keyset()) {
                orderItemContractMap.get(contractNumber).PriceBookEntryId = priceBookEntryContractNumberMap.get(
                        contractNumber
                    )
                    .Id;
            }

            upsert orderItemContractMap.values() External_ID__c;

            for (String contractNumber : carePlanContractMap.keyset()) {
                carePlanContractMap.get(contractNumber).OrderItem__c = orderItemContractMap.get(contractNumber).Id;
            }

            List<Care_Plan_Type__c> carePlanList = [
                SELECT id, ContractNumber__c
                FROM Care_Plan_Type__c
                WHERE ContractNumber__c IN :carePlanContractMap.keyset()
            ];

            for (Care_Plan_Type__c carePlanType : carePlanList) {
                if (carePlanContractMap.get(carePlanType.ContractNumber__c) != null) {
                    carePlanContractMap.get(carePlanType.ContractNumber__c).OrderItem__c = orderItemContractMap.get(
                            carePlanType.ContractNumber__c
                        )
                        .Id;
                    carePlanContractMap.get(carePlanType.ContractNumber__c).Id = carePlanType.Id;
                }
            }

            upsert carePlanContractMap.values();

            //Preparing Response
            String success = 'Success';
            String message = newOrder.External_ID__c;

            RestResponse res = RestContext.response;
            res = createResponse(success, message);
            
        } catch (Exception e) {
            String success = 'Failed';
            String message = e.getMessage();
            RestResponse res = RestContext.response;
            res = createFailResponse(success, message);
        }
    }

    public static RestResponse createResponse(String success, String message) {
        RestResponseClass response = new RestResponseClass();
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        response.status = success;
        response.orderNumber = message;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
        return res;
    }

    public static RestResponse createFailResponse(String success, String message) {
        RestFailureResponse response = new RestFailureResponse();
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        response.status = success;
        response.errorMessage = message;
        res.responseBody = Blob.valueOf(JSON.serialize(response));
        return res;
    }

    public static PriceBookEntry getPriceBookEntry(
        SVC_CreateOrderWithItems.OrderItemInput itemInput,
        Map<String, Product2> extIdProductmap,
        Id spbId
    ) {
        Product2 product = extIdProductmap.get(itemInput.ProductCode);
        if (product != null && product.PricebookEntries.size() > 0) {
            return product.PricebookEntries.get(0);
        } else {
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Product2Id = product.id;
            pbe.UnitPrice = itemInput.UnitPrice;
            pbe.Pricebook2Id = spbId;
            return pbe;
        }
    }

    public static Order createOrder(
        OrderWithItemsWrapper requestData,
        List<XStore_Association__c> xStoreAssociations,
        Pricebook2 standardPriceBook
    ) {
        Order newOrder = new Order(
            EffectiveDate = Date.valueOf(requestData.order.effectivedate),
            AccountId = xStoreAssociations.get(0).Contact__r.AccountId,
            currency__c = requestData.order.orderCurrency,
            External_ID__c = requestData.order.External_Id,
            order_total__c = requestData.order.order_total,
            product_sub_total__c = requestData.order.product_sub_total,
            product_total__c = requestData.order.product_total,
            status__c = requestData.order.status,
            tax_total__c = requestData.order.tax_total,
            customer_Id__c = requestData.order.customer_Id,
            tax_value__c = requestData.order.tax_value,
            Payment_Amount__c = requestData.order.Payment_Amount,
            BillingStreet = requestData.order.BillingStreet,
            BillingCity = requestData.order.BillingCity,
            BillingCountry = requestData.order.BillingCountry,
            Billing_First_Name__c = requestData.order.Billing_First_Name,
            Billing_Full_Name__c = requestData.order.Billing_Full_Name,
            Billing_Last_Name__c = requestData.order.Billing_Last_Name,
            Billing_Phone__c = requestData.order.Billing_Phone,
            BillingPostalCode = requestData.order.BillingPostalCode,
            BillingState = requestData.order.BillingState,
            Type = requestData.order.OrderType,
            Pricebook2Id = standardPriceBook.id
        );

        upsert newOrder External_ID__c;
        return newOrder;
    }

    // Define wrapper classes for deserialization
    @SuppressWarnings('PMD.FieldNamingConventions')
    public class OrderItemInput {
        public String ProductCode;
        public Decimal Quantity;
        public Decimal UnitPrice;
        public Decimal Price;
        public Decimal Tax;
        public Decimal Tax_Basis;
        public String Tax_class_Id;
        public Decimal Tax_Rate;
        public String c_fromStoreId;
        public String Types;
        public String ContractNumber;
        public String External_Id;
        public Integer Line_Number;
        public String Status;
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    public class OrderWrapper {
        public String Account;
        public Date effectivedate;
        public String orderCurrency;
        public String External_Id;
        public Decimal order_total;
        public Decimal product_sub_total;
        public Decimal product_total;
        public String status;
        public Decimal tax_total;
        public String customer_Id;
        public Decimal tax_value;
        public Decimal Payment_Amount;
        public String BillingStreet;
        public String BillingCity;
        public String BillingCountry;
        public String Billing_First_Name;
        public String Billing_Full_Name;
        public String Billing_Last_Name;
        public String Billing_Phone;
        public String BillingPostalCode;
        public String BillingState;
        public String OrderType;
        public List<OrderItemInput> OrderItems;
    }

    public class OrderWithItemsWrapper {
        public OrderWrapper order;
    }
}