public with sharing class BookStoreController {
    
    /**
     * @description Searches books by Title, Author OR ISBN fields.
     *              Uses dynamic SOQL with bind variables for injection safety.
     * @param title The field to search against: 'Title'
     * @param author The field to search against: 'Author'
     * @param isbn The field to search against:  'ISBN'
     * @return List of matching Book records
     */
    @AuraEnabled
    public static List<BookDTO> searchBookAvailability(String title, String author, String isbn) {
        
        String titleBind;
        String authorBind;
        String isbnBind;
        
        List<Book__c> listOfBooks = new List<Book__c>();
        List<String> conditions = new List<String>();
        
        String selectStatement =
            'SELECT Title__c, Author__c, Genre__c, Publication_Year__c, ISBN__c, Current_Inventory__c, Price__c ' +
            'FROM Book__c';
        
        String cleanIsbn = Utility.sanitizeIsbn(isbn);
        
        if (String.isNotBlank(cleanIsbn)) {
            isbnBind = cleanIsbn.trim();
            conditions.add('ISBN__c = :isbnBind');
        } else {
            List<String> likeConditions = new List<String>();
            
            String cleanTitle  = Utility.sanitizeLike(title);
            String cleanAuthor = Utility.sanitizeLike(author);
            
            if(String.isNotBlank(cleanTitle)) {
                titleBind = '%' + cleanTitle + '%';
                likeConditions.add('Title__c LIKE :titleBind');
            }
            
            if (String.isNotBlank(cleanAuthor)) {
                authorBind = '%' + cleanAuthor + '%';
                likeConditions.add('Author__c LIKE :authorBind');
            }
            
            if(!likeConditions.isEmpty()) {
                conditions.add('(' + String.join(likeConditions, ' AND ') + ')');
            }
        }
        
        if (conditions.isEmpty()) return new List<BookDTO>();
        
        String queryStr = selectStatement + ' WHERE ' + String.join(conditions, ' OR ') + ' LIMIT 10';
        
        try {
            List<Book__c> records = Database.query(queryStr);
            return BookDTO.fromSObjects(records);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Retrieve all the reservations available.
     * @return List of matching Reservations records
     */
    @AuraEnabled
    public static List<ReservationDTO> getReservations() {
        List<Reservation__c> records = [SELECT Id, Name, Status__c,
                                                Reservation_Date__c, Expiration_Date__c,
                                                CreatedDate,
                                                Contact__r.Name,
                                                Pickup_Contact__r.Name,
                                                Book__r.Title__c,
                                                Book__r.Author__c
                                        FROM Reservation__c 
                                        ORDER BY CreatedDate DESC
                                        LIMIT 50];
        
        return ReservationDTO.fromSObjects(records);
    }
}