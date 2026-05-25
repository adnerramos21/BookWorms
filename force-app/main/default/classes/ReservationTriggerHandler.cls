public with sharing class ReservationTriggerHandler {
    
    public static void handleAfterInsert(List<Reservation__c> newReservations) {
        Set<Id> bookIds = new Set<Id>();
        Set<Id> notReservedBookIds = new Set<Id>();
        List<Book__c> updatedInventory = new List<Book__c>();
        
        for (Reservation__c r : newReservations) {
            
            if(r.Book__c == null) continue;

            if(r.Status__c == 'Reserved') {
                bookIds.add(r.Book__c);

            } else if(r.Status__c == 'Cancelled' || r.Status__c == 'Expired') {
                notReservedBookIds.add(r.Book__c);
            }
        }
        
        if(!bookIds.isEmpty()) {
            for (Book__c b : [SELECT Id, Current_Inventory__c FROM Book__c WHERE Id IN :bookIds AND Active__c = true]) {
                if(b.Current_Inventory__c > 0) {
                    b.Current_Inventory__c -= 1;
                    updatedInventory.add(b);
                }
            }
        }

        if(!notReservedBookIds.isEmpty()) {
            for (Book__c b : [SELECT Id, Current_Inventory__c, Max_Inventory__c FROM Book__c WHERE Id IN :notReservedBookIds AND Active__c = true]) {
                if(b.Current_Inventory__c < b.Max_Inventory__c) {
                    b.Current_Inventory__c += 1;
                    updatedInventory.add(b);
                }
            }
        }

        if(!updatedInventory.isEmpty()) {
            update updatedInventory;
        }
        
    }
}