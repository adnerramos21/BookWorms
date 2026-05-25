@isTest
private class ReservationTriggerHandlerTest {
    
    // ── Add @TestSetup ────────────────────────────────────────────────────────────
    @TestSetup
    static void setupData() {
        insert new Contact(FirstName = 'Test', LastName = 'Contact');
    }
    
    // ── Test Data Factory ─────────────────────────────────────────────────────
    
    private static Book__c buildBook(String title, Decimal inventory, Decimal maxInventory) {
        return new Book__c(
            Title__c             = title,
        Author__c            = 'Test Author',
        Genre__c             = 'Literary Fiction',
        Publication_Year__c  = '1949',
        ISBN__c              = String.valueOf(Math.random()).substring(0, 10),
        Current_Inventory__c = inventory,
        Max_Inventory__c     = maxInventory,
        Price__c             = 9.99,
        Active__c            = true
            );
    }
    
    private static Reservation__c buildReservation(Id bookId, String status) {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        return new Reservation__c(
            Book__c             = bookId,
        Contact__c          = contact.Id,
        Status__c           = status,
        Reservation_Date__c = DateTime.now(),
        Expiration_Date__c  = DateTime.now().addDays(2)
            );
    }
    
    // ── Status = Reserved → decrement ─────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_Reserved_DecrementsInventory() {
        Book__c book = buildBook('1984', 11, 11);
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Reserved');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(10, updated.Current_Inventory__c, 'Inventory should decrement by 1');
    }
    
    @isTest
    static void testHandleAfterInsert_Reserved_InventoryAtOne_DecrementsToZero() {
        Book__c book = buildBook('Animal Farm', 1, 5);
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Reserved');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(0, updated.Current_Inventory__c, 'Inventory should decrement to 0');
    }
    
    @isTest
    static void testHandleAfterInsert_Reserved_InventoryAtZero_NoDecrement() {
        Book__c book = buildBook('Cat\'s Cradle', 0, 5);
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Reserved');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(0, updated.Current_Inventory__c, 'Inventory should not go below 0');
    }
    
    // ── Status = Cancelled → increment ────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_Cancelled_IncrementsInventory() {
        Book__c book = buildBook('Dune', 3, 10);
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Cancelled');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(4, updated.Current_Inventory__c, 'Inventory should increment by 1');
    }
    
    // ── Status = Expired → increment ──────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_Expired_IncrementsInventory() {
        Book__c book = buildBook('Brave New World', 5, 10);
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Expired');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(6, updated.Current_Inventory__c, 'Inventory should increment by 1');
    }
    
    // ── Max inventory cap ─────────────────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_Cancelled_AtMaxInventory_NoIncrement() {
        Book__c book = buildBook('Fahrenheit 451', 10, 10); // already at max
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Cancelled');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(10, updated.Current_Inventory__c, 'Inventory should not exceed Max_Inventory__c');
    }
    
    // ── Null Book__c guard ────────────────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_NullBook_SkipsGracefully() {
        // Build an in-memory reservation with null Book__c — bypass DML
        Reservation__c res = new Reservation__c();
        res.Book__c    = null;
        res.Status__c  = 'Reserved';
        
        Test.startTest();
        try {
            ReservationTriggerHandler.handleAfterInsert(new List<Reservation__c>{ res });
            Assert.isTrue(true, 'Should skip gracefully when Book__c is null');
        } catch (Exception e) {
            Assert.fail('Should not throw exception for null Book__c: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // ── Inactive book — not updated ───────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_InactiveBook_InventoryNotChanged() {
        Book__c book = new Book__c(
            Title__c             = 'Inactive Book',
        Author__c            = 'Author',
        Genre__c             = 'Fiction',
        Publication_Year__c  = '2000',
        ISBN__c              = '1234567890',
        Current_Inventory__c = 5,
        Max_Inventory__c     = 10,
        Price__c             = 5.00,
        Active__c            = false  // ← inactive
            );
        insert book;
        
        Test.startTest();
        insert buildReservation(book.Id, 'Reserved');
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(5, updated.Current_Inventory__c, 'Inactive book inventory should not change');
    }
    
    // ── Bulk safety ───────────────────────────────────────────────────────────
    
    @isTest
    static void testHandleAfterInsert_BulkInsert_AllDecrement() {
        List<Book__c> books = new List<Book__c>();
        for (Integer i = 0; i < 10; i++) {
            books.add(buildBook('Book ' + i, 5, 10));
        }
        insert books;
        
        List<Reservation__c> reservations = new List<Reservation__c>();
        for (Book__c b : books) {
            reservations.add(buildReservation(b.Id, 'Reserved'));
        }
        
        Test.startTest();
        insert reservations;
        Test.stopTest();
        
        List<Book__c> updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id IN :books];
        for (Book__c b : updated) {
            Assert.areEqual(4, b.Current_Inventory__c, 'Each book inventory should decrement by 1');
        }
    }
    
    // ── Trigger fires ─────────────────────────────────────────────────────────
    
    @isTest
    static void testTrigger_FiresOnInsert_DecrementsThroughTrigger() {
        Book__c book = buildBook('Trigger Test Book', 8, 8);
        insert book;
        
        // Insert via DML — trigger fires automatically
        Test.startTest();
        Reservation__c res = buildReservation(book.Id, 'Reserved');
        insert res;
        Test.stopTest();
        
        Book__c updated = [SELECT Current_Inventory__c FROM Book__c WHERE Id = :book.Id];
        Assert.areEqual(7, updated.Current_Inventory__c, 'Trigger should have fired and decremented inventory');
    }
}