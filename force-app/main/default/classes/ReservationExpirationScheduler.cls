public with sharing class ReservationExpirationScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        List<Reservation__c> expiredReservations = [
            SELECT Id, Status__c, Expiration_Date__c
            FROM Reservation__c
            WHERE Status__c = 'Reserved'
            AND Expiration_Date__c <= :DateTime.now()
        ];
        
        if(expiredReservations.isEmpty()) return;
        
        for(Reservation__c r : expiredReservations) {
            r.Status__c = 'Expired';
        }
        
        try {
            update expiredReservations;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
            
        }
    }
}