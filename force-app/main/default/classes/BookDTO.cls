/**
 * @description Transform the book list data to a naming convention that can be interpreted by view
 */
public with sharing class BookDTO {
    
    @AuraEnabled public String  id;
    @AuraEnabled public String  title;
    @AuraEnabled public String  author;
    @AuraEnabled public String  genre;
    @AuraEnabled public String  publicationYear;
    @AuraEnabled public String  isbn;
    @AuraEnabled public Integer quantity;
    @AuraEnabled public Decimal price;
    @AuraEnabled public Boolean isOutOfStock; 
    @AuraEnabled public String  reserveLabel;
    
    public BookDTO(Book__c b) {
        this.id              = b.Id;
        this.title           = b.Title__c;
        this.author          = b.Author__c;
        this.genre           = b.Genre__c;
        this.publicationYear = b.Publication_Year__c;
        this.isbn            = b.ISBN__c;
        this.quantity        = (Integer) b.Current_Inventory__c;
        this.price           = b.Price__c;
        this.isOutOfStock    = b.Current_Inventory__c <= 0;
        this.reserveLabel    = b.Current_Inventory__c <= 0 ? 'Out of Stock' : 'Reserve';
    }
    
    public static List<BookDTO> fromSObjects(List<Book__c> books) {
        List<BookDTO> result = new List<BookDTO>();
        for (Book__c b : books) result.add(new BookDTO(b));
        return result;
    }
}