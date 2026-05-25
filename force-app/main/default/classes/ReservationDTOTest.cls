@isTest
private class ReservationDTOTest {
    
    // @TestSetup
    // static void setupData() {
        //     insert new Contact(FirstName = 'Test', LastName = 'Contact');
    // }
    
    // ── Test Data Factory ─────────────────────────────────────────────────────
    
    private static Book__c buildBook(String title, String author, Decimal inventory) {
        return new Book__c(
            Title__c             = title,
        Author__c            = author,
        Genre__c             = 'Literary Fiction',
        Publication_Year__c  = '1949',
        ISBN__c              = title.left(10).replaceAll('[^a-zA-Z0-9]', '') + String.valueOf(Crypto.getRandomInteger()).substring(0, 5), // ← unique per book
        Current_Inventory__c = inventory,
        Max_Inventory__c     = inventory,
        Price__c             = 9.99,
        Active__c            = true
            );
    }
    
    private static Contact buildContact(String firstName, String lastName) {
        return new Contact(FirstName = firstName, LastName = lastName);
    }
    
    private static Reservation__c buildReservation(Id bookId, Id contactId, Id pickupContactId) {
        return new Reservation__c(
            Book__c             = bookId,
        Contact__c          = contactId,
        Pickup_Contact__c   = pickupContactId,
        Status__c           = 'Reserved',
        Reservation_Date__c = DateTime.now(),
        Expiration_Date__c  = DateTime.now().addDays(2)
            );
    }
    
    // ── Constructor — field mapping ───────────────────────────────────────────
    
    @isTest
    static void testConstructor_FieldsMappedCorrectly() {
        Book__c book = buildBook('1984', 'George Orwell', 5);
        insert book;
        
        Contact contact = new Contact(FirstName = 'John', LastName = 'Doe');
        insert contact;
        
        Reservation__c res = buildReservation(book.Id, contact.Id, null);
        insert res;
        
        res = [SELECT Id, Name, Status__c, Reservation_Date__c, Expiration_Date__c,
                  CreatedDate, Contact__r.Name, Pickup_Contact__r.Name,
                  Book__r.Title__c, Book__r.Author__c
           FROM Reservation__c WHERE Id = :res.Id];
        
        Test.startTest();
        ReservationDTO dto = new ReservationDTO(res);
        Test.stopTest();
        
        
        Assert.areEqual(res.Id,        dto.id,     'Id should match');
        Assert.areEqual(res.Name,      dto.name,   'Name should match');
        Assert.areEqual('Reserved',    dto.status, 'Status should match');
        Assert.areEqual('John Doe',    dto.contact,'Contact name should match');
        Assert.isNull(dto.pickupContact,           'Pickup contact should be null');
        Assert.isTrue(dto.book.contains('1984'),   'Book should contain title');
        Assert.isTrue(dto.book.contains('George Orwell'), 'Book should contain author');
        Assert.isNotNull(dto.reservationDateTime,  'Reservation datetime should be formatted');
        Assert.isNotNull(dto.expirationDateTime,   'Expiration datetime should be formatted');
        Assert.isNotNull(dto.createdDateTime,      'Created datetime should be formatted');
    }
    
    // ── Contact fallback ──────────────────────────────────────────────────────
    
    @isTest
    static void testConstructor_PickupContact_PopulatesPickupContactField() {
        Book__c book = buildBook('Animal Farm', 'George Orwell', 3);
        insert book;
        
        Contact contact       = new Contact(FirstName = 'Jane', LastName = 'Smith');
        Contact pickupContact = new Contact(FirstName = 'Bob',  LastName = 'Jones');
        insert new List<Contact>{ contact, pickupContact };
        
        Reservation__c res = buildReservation(book.Id, contact.Id, pickupContact.Id);
        insert res;
        
        res = [SELECT Id, Name, Status__c, Reservation_Date__c, Expiration_Date__c,
                  CreatedDate, Contact__r.Name, Pickup_Contact__r.Name,
                  Book__r.Title__c, Book__r.Author__c
           FROM Reservation__c WHERE Id = :res.Id];
        
        Test.startTest();
        ReservationDTO dto = new ReservationDTO(res);
        Test.stopTest();
        
        Assert.areEqual('Jane Smith', dto.contact,       'Contact name should match');
        Assert.areEqual('Bob Jones',  dto.pickupContact, 'Pickup contact name should match');
    }
    
    @isTest
    static void testConstructor_NoContact_ContactIsNull() {
        Book__c book = new Book__c(
            Title__c             = 'Dune',
        Author__c            = 'Frank Herbert',
        Genre__c             = 'Science Fiction',
        Publication_Year__c  = '1965',
        ISBN__c              = '9780441013593',
        Current_Inventory__c = 10,
        Max_Inventory__c     = 10,
        Price__c             = 14.99,
        Active__c            = true
            );
        insert book;
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        
        Reservation__c res = buildReservation(book.Id, contact.Id, null);
        insert res;
        
        // ← Contact__r.Name and Pickup_Contact__r.Name must be in SELECT
        res = [SELECT Id, Name, Status__c, Reservation_Date__c, Expiration_Date__c,
                  CreatedDate, Contact__r.Name, Pickup_Contact__r.Name,
                  Book__r.Title__c, Book__r.Author__c
           FROM Reservation__c WHERE Id = :res.Id];
        
        Test.startTest();
        ReservationDTO dto = new ReservationDTO(res);
        Test.stopTest();
        
        // Contact is set — but Pickup_Contact__c was null so that relationship is null
        Assert.isNotNull(dto.contact,    'Contact should be populated');
        Assert.isNull(dto.pickupContact, 'Pickup contact should be null when not set');
    }
    
    // ── Book field composition ────────────────────────────────────────────────
    
    @isTest
    static void testConstructor_BookField_ComposedCorrectly() {
        Book__c book = new Book__c(
            Title__c             = 'The Great Gatsby',
        Author__c            = 'F. Scott Fitzgerald',
        Genre__c             = 'Literary Fiction',
        Publication_Year__c  = '1925',
        ISBN__c              = '9798351145013',
        Current_Inventory__c = 2,
        Max_Inventory__c     = 2,
        Price__c             = 7.99,
        Active__c            = true
            );
        insert book;
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        
        Reservation__c res = buildReservation(book.Id, contact.Id, null); // ← real contact
        insert res;
        
        res = [SELECT Id, Name, Status__c, Reservation_Date__c, Expiration_Date__c,
                  CreatedDate, Contact__r.Name, Pickup_Contact__r.Name,
                  Book__r.Title__c, Book__r.Author__c
           FROM Reservation__c WHERE Id = :res.Id];
        
        Test.startTest();
        ReservationDTO dto = new ReservationDTO(res);
        Test.stopTest();
        
        Assert.areEqual('The Great Gatsby by F. Scott Fitzgerald', dto.book,
        'Book field should be Title + by + Author');
    }
    
    // ── fromSObjects ──────────────────────────────────────────────────────────
    
    @isTest
    static void testFromSObjects_ReturnsMappedList() {
        Book__c book1 = buildBook('1984',        'George Orwell', 5);
        Book__c book2 = buildBook('Animal Farm', 'George Orwell', 3);
        insert new List<Book__c>{ book1, book2 };
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        
        insert new List<Reservation__c>{
            buildReservation(book1.Id, contact.Id, null),
            buildReservation(book2.Id, contact.Id, null)
        };
        
        List<Reservation__c> records = [
        SELECT Id, Name, Status__c, Reservation_Date__c, Expiration_Date__c,
               CreatedDate, Contact__r.Name, Pickup_Contact__r.Name,
               Book__r.Title__c, Book__r.Author__c
        FROM Reservation__c
    ];
        
        Test.startTest();
        List<ReservationDTO> dtos = ReservationDTO.fromSObjects(records);
        Test.stopTest();
        
        Assert.areEqual(2, dtos.size(), 'Should return 2 DTOs');
    }
    
    @isTest
    static void testFromSObjects_EmptyList_ReturnsEmptyList() {
        Test.startTest();
        List<ReservationDTO> dtos = ReservationDTO.fromSObjects(new List<Reservation__c>());
        Test.stopTest();
        
        Assert.isNotNull(dtos,          'Result should not be null');
        Assert.areEqual(0, dtos.size(), 'Result should be empty');
    }
    
    @isTest
    static void testFromSObjects_SingleRecord() {
        Book__c book = buildBook('Dune', 'Frank Herbert', 15);
        insert book;
        
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        
        Reservation__c res = buildReservation(book.Id, contact.Id, null);
        insert res;
        
        List<Reservation__c> records = [
        SELECT Id, Name, Status__c, Reservation_Date__c, Expiration_Date__c,
               CreatedDate, Contact__r.Name, Pickup_Contact__r.Name,
               Book__r.Title__c, Book__r.Author__c
        FROM Reservation__c WHERE Id = :res.Id
    ];
        
        Test.startTest();
        List<ReservationDTO> dtos = ReservationDTO.fromSObjects(records);
        Test.stopTest();
        
        Assert.areEqual(1, dtos.size(), 'Should return exactly 1 DTO');
    }
}