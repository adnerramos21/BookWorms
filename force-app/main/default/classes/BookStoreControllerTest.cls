@isTest
private class BookStoreControllerTest {
    
    
    // ── Test Data Factory ─────────────────────────────────────────────────────
    
    @TestSetup
    static void setupData() {
        Contact contact = new Contact(FirstName = 'Jane', LastName = 'Doe');
        insert contact;
        
        List<Book__c> books = new List<Book__c>{
            new Book__c(Title__c='1984',             Author__c='George Orwell',      Genre__c='Dystopian Fiction',    Publication_Year__c='1949', ISBN__c='9780451524935', Current_Inventory__c=11, Max_Inventory__c=11, Price__c=7.99,  Active__c=true),
            new Book__c(Title__c='Animal Farm',      Author__c='George Orwell',      Genre__c='Political Satire',     Publication_Year__c='1945', ISBN__c='9786055114336', Current_Inventory__c=7,  Max_Inventory__c=7,  Price__c=6.49,  Active__c=true),
            new Book__c(Title__c='Brave New World',  Author__c='Aldous Huxley',      Genre__c='Dystopian Fiction',    Publication_Year__c='1932', ISBN__c='9780060830953', Current_Inventory__c=8,  Max_Inventory__c=8,  Price__c=9.99,  Active__c=true),
            new Book__c(Title__c='Cat\'s Cradle',    Author__c='Kurt Vonnegut',      Genre__c='Science Fiction',      Publication_Year__c='1963', ISBN__c='9780955242489', Current_Inventory__c=0,  Max_Inventory__c=5,  Price__c=10.15, Active__c=true)
        };
        insert books;
    }
    
    private static Reservation__c buildReservation(Id bookId, Id contactId) {
        return new Reservation__c(
            Book__c             = bookId,
        Contact__c          = contactId,
        Status__c           = 'Reserved',
        Reservation_Date__c = DateTime.now(),
        Expiration_Date__c  = DateTime.now().addDays(2)
            );
    }
    
    // ── searchBookAvailability — ISBN ─────────────────────────────────────────
    
    @isTest
    static void testSearch_ByIsbn_ReturnsExactMatch() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('', '', '9780451524935');
        Test.stopTest();
        
        Assert.areEqual(1, results.size(),    'Should return exactly 1 result');
        Assert.areEqual('1984', results[0].title, 'Should return the correct book');
    }
    
    @isTest
    static void testSearch_ByIsbn_NoMatch_ReturnsEmpty() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('', '', '0000000000000');
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list for unknown ISBN');
    }
    
    @isTest
    static void testSearch_ByIsbn_SanitizesInput() {
        // ISBN with injected non-numeric characters
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('', '', '978045abc1524935!!!');
        Test.stopTest();
        
        // Sanitized to '9780451524935' — should still match
        Assert.areEqual(1, results.size(), 'Sanitized ISBN should still match');
    }
    
    // ── searchBookAvailability — Title ────────────────────────────────────────
    
    @isTest
    static void testSearch_ByTitle_ReturnsPartialMatch() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('Animal', '', '');
        Test.stopTest();
        
        Assert.areEqual(1, results.size(),           'Should return 1 result');
        Assert.areEqual('Animal Farm', results[0].title, 'Should match Animal Farm');
    }
    
    @isTest
    static void testSearch_ByTitle_CaseInsensitive() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('animal', '', '');
        Test.stopTest();
        
        Assert.isFalse(results.isEmpty(), 'LIKE search should be case-insensitive in Salesforce');
    }
    
    @isTest
    static void testSearch_ByTitle_NoMatch_ReturnsEmpty() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('ZZZ_NO_MATCH', '', '');
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty for no title match');
    }
    
    // ── searchBookAvailability — Author ───────────────────────────────────────
    
    @isTest
    static void testSearch_ByAuthor_ReturnsMultipleMatches() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('', 'George Orwell', '');
        Test.stopTest();
        
        Assert.areEqual(2, results.size(), 'Should return both George Orwell books');
    }
    
    @isTest
    static void testSearch_ByAuthor_NoMatch_ReturnsEmpty() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('', 'Unknown Author', '');
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty for unknown author');
    }
    
    // ── searchBookAvailability — Title AND Author ─────────────────────────────
    
    @isTest
    static void testSearch_ByTitleAndAuthor_NarrowsResults() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('1984', 'George Orwell', '');
        Test.stopTest();
        
        Assert.areEqual(1, results.size(),        'Should return exactly 1 result');
        Assert.areEqual('1984', results[0].title, 'Should return 1984');
    }
    
    @isTest
    static void testSearch_ByTitleAndAuthor_NoMatch_ReturnsEmpty() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('1984', 'Aldous Huxley', '');
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty when title and author do not match same book');
    }
    
    // ── searchBookAvailability — ISBN overrides Title/Author ──────────────────
    
    @isTest
    static void testSearch_IsbnOverridesTitleAuthor() {
        // ISBN points to 1984, title/author point to Brave New World — ISBN should win
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('Brave New World', 'Aldous Huxley', '9780451524935');
        Test.stopTest();
        
        Assert.areEqual(1, results.size(),        'Should return 1 result');
        Assert.areEqual('1984', results[0].title, 'ISBN should override title/author');
    }
    
    // ── searchBookAvailability — all blank ────────────────────────────────────
    
    @isTest
    static void testSearch_AllBlank_ReturnsEmpty() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('', '', '');
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'All blank should return empty list');
    }
    
    @isTest
    static void testSearch_NullInputs_ReturnsEmpty() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability(null, null, null);
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Null inputs should return empty list');
    }
    
    // ── searchBookAvailability — DTO shape ────────────────────────────────────
    
    @isTest
    static void testSearch_OutOfStock_ReturnsCorrectFlags() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('Cat\'s Cradle', '', '');
        Test.stopTest();
        
        Assert.areEqual(1,            results.size(),              'Should return 1 result');
        Assert.isTrue(results[0].isOutOfStock,                     'isOutOfStock should be true');
        Assert.areEqual('Out of Stock', results[0].reserveLabel,   'reserveLabel should be Out of Stock');
    }
    
    @isTest
    static void testSearch_InStock_ReturnsCorrectFlags() {
        Test.startTest();
        List<BookDTO> results = BookStoreController.searchBookAvailability('1984', '', '');
        Test.stopTest();
        
        Assert.areEqual(1,          results.size(),            'Should return 1 result');
        Assert.isFalse(results[0].isOutOfStock,                'isOutOfStock should be false');
        Assert.areEqual('Reserve', results[0].reserveLabel,    'reserveLabel should be Reserve');
    }
    
    // ── getReservations ───────────────────────────────────────────────────────
    
    @isTest
    static void testGetReservations_ReturnsReservations() {
        Book__c book = [SELECT Id FROM Book__c WHERE Title__c = '1984' LIMIT 1];
        
        Contact contact = new Contact(FirstName = 'Jane', LastName = 'Doe');
        insert contact;
        
        insert new Reservation__c(
            Book__c             = book.Id,
        Contact__c          = contact.Id,   // ← required field
        Status__c           = 'Reserved',
        Reservation_Date__c = DateTime.now(),
        Expiration_Date__c  = DateTime.now().addDays(2)
            );
        
        Test.startTest();
        List<ReservationDTO> results = BookStoreController.getReservations();
        Test.stopTest();
        
        Assert.isFalse(results.isEmpty(), 'Should return at least 1 reservation');
        Assert.isNotNull(results[0].id,   'DTO id should be populated');
    }
    
    @isTest
    static void testGetReservations_NoReservations_ReturnsEmpty() {
        Test.startTest();
        List<ReservationDTO> results = BookStoreController.getReservations();
        Test.stopTest();
        
        Assert.isNotNull(results,          'Result should not be null');
        Assert.areEqual(0, results.size(), 'Should return empty when no reservations exist');
    }
}