public with sharing class ReservationDTO {
    
    @AuraEnabled public String id;
    @AuraEnabled public String name;
    @AuraEnabled public String contact;
    @AuraEnabled public String pickupContact;
    @AuraEnabled public String book;
    @AuraEnabled public String status;
    @AuraEnabled public String reservationDateTime;
    @AuraEnabled public String expirationDateTime;
    @AuraEnabled public String createdDateTime;
    
    public ReservationDTO(Reservation__c r) {
        this.id     = r.Id;
        this.name   = r.Name;
        this.status = r.Status__c;
        
        this.contact = r.Contact__r?.Name != null
            ? r.Contact__r.Name
            : null;
        
        this.pickupContact = r.Pickup_Contact__r?.Name != null
            ? r.Pickup_Contact__r?.Name
            : null;
        
        // "One Flew Over the Cuckoo's Nest by Ken Kesey"
        this.book = r.Book__r?.Title__c != null
            ? r.Book__r.Title__c + ' by ' + r.Book__r.Author__c
            : null;
        
        // "Mar 31, 2026 at 11:00 PM"
        this.reservationDateTime = Utility.formatDateTime(r.Reservation_Date__c);
        this.expirationDateTime  = Utility.formatDateTime(r.Expiration_Date__c);
        this.createdDateTime     = Utility.formatDateTime(r.CreatedDate);
    }
    
    public static List<ReservationDTO> fromSObjects(List<Reservation__c> records) {
        List<ReservationDTO> result = new List<ReservationDTO>();
        for (Reservation__c r : records) result.add(new ReservationDTO(r));
        return result;
    }
}