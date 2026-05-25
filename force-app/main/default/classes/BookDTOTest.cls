@isTest
private class BookDTOTest {

    // ── Test Data Factory ─────────────────────────────────────────────────────

    private static Book__c buildBook(String title, String author, String genre,
                                     String year, String isbn,
                                     Decimal inventory, Decimal price) {
        return new Book__c(
            Title__c             = title,
            Author__c            = author,
            Genre__c             = genre,
            Publication_Year__c  = year,
            ISBN__c              = isbn,
            Current_Inventory__c = inventory,
            Price__c             = price,
            Active__c            = true
        );
    }

    // ── Constructor Tests ─────────────────────────────────────────────────────

    @isTest
    static void testConstructor_FieldsMappedCorrectly() {
        Book__c book = buildBook('1984', 'George Orwell', 'Dystopian Fiction',
                                 '1949', '9780451524935', 11, 7.99);
        insert book;
        book = [SELECT Id, Title__c, Author__c, Genre__c, Publication_Year__c,
                       ISBN__c, Current_Inventory__c, Price__c FROM Book__c WHERE Id = :book.Id];

        Test.startTest();
        BookDTO dto = new BookDTO(book);
        Test.stopTest();

        Assert.areEqual(book.Id,           dto.id,              'Id should match');
        Assert.areEqual('1984',            dto.title,           'Title should match');
        Assert.areEqual('George Orwell',   dto.author,          'Author should match');
        Assert.areEqual('Dystopian Fiction', dto.genre,         'Genre should match');
        Assert.areEqual('1949',            dto.publicationYear, 'Publication year should match');
        Assert.areEqual('9780451524935',   dto.isbn,            'ISBN should match');
        Assert.areEqual(11,                dto.quantity,        'Quantity should match');
        Assert.areEqual(7.99,              dto.price,           'Price should match');
    }

    // ── isOutOfStock Tests ────────────────────────────────────────────────────

    @isTest
    static void testIsOutOfStock_WhenInventoryIsZero() {
        Book__c book = buildBook('Cat\'s Cradle', 'Kurt Vonnegut', 'Science Fiction',
                                 '1963', '9780955242489', 0, 10.15);
        insert book;
        book = [SELECT Id, Title__c, Author__c, Genre__c, Publication_Year__c,
                       ISBN__c, Current_Inventory__c, Price__c FROM Book__c WHERE Id = :book.Id];

        Test.startTest();
        BookDTO dto = new BookDTO(book);
        Test.stopTest();

        Assert.isTrue(dto.isOutOfStock,          'isOutOfStock should be true when inventory is 0');
        Assert.areEqual('Out of Stock', dto.reserveLabel, 'reserveLabel should be Out of Stock');
    }

    @isTest
    static void testIsOutOfStock_WhenInventoryIsPositive() {
        Book__c book = buildBook('Animal Farm', 'George Orwell', 'Political Satire',
                                 '1945', '9786055114336', 7, 6.49);
        insert book;
        book = [SELECT Id, Title__c, Author__c, Genre__c, Publication_Year__c,
                       ISBN__c, Current_Inventory__c, Price__c FROM Book__c WHERE Id = :book.Id];

        Test.startTest();
        BookDTO dto = new BookDTO(book);
        Test.stopTest();

        Assert.isFalse(dto.isOutOfStock,     'isOutOfStock should be false when inventory > 0');
        Assert.areEqual('Reserve', dto.reserveLabel, 'reserveLabel should be Reserve');
    }

    @isTest
    static void testIsOutOfStock_WhenInventoryIsOne() {
        Book__c book = buildBook('The Grapes of Wrath', 'John Steinbeck', 'Literary Fiction',
                                 '1939', '9780143039433', 1, 11.99);
        insert book;
        book = [SELECT Id, Title__c, Author__c, Genre__c, Publication_Year__c,
                       ISBN__c, Current_Inventory__c, Price__c FROM Book__c WHERE Id = :book.Id];

        Test.startTest();
        BookDTO dto = new BookDTO(book);
        Test.stopTest();

        Assert.isFalse(dto.isOutOfStock,     'isOutOfStock should be false when inventory is 1');
        Assert.areEqual('Reserve', dto.reserveLabel, 'reserveLabel should be Reserve');
    }

    // ── fromSObjects Tests ────────────────────────────────────────────────────

    @isTest
    static void testFromSObjects_ReturnsMappedList() {
        List<Book__c> books = new List<Book__c>{
            buildBook('1984',        'George Orwell',  'Dystopian Fiction', '1949', '9780451524935', 11, 7.99),
            buildBook('Animal Farm', 'George Orwell',  'Political Satire',  '1945', '9786055114336',  7, 6.49),
            buildBook('Cat\'s Cradle', 'Kurt Vonnegut','Science Fiction',   '1963', '9780955242489',  0, 10.15)
        };
        insert books;

        books = [SELECT Id, Title__c, Author__c, Genre__c, Publication_Year__c,
                        ISBN__c, Current_Inventory__c, Price__c FROM Book__c WHERE Id IN :books];

        Test.startTest();
        List<BookDTO> dtos = BookDTO.fromSObjects(books);
        Test.stopTest();

        Assert.areEqual(3, dtos.size(), 'Should return 3 DTOs');

        // Spot check each record
        Assert.areEqual('1984',         dtos[0].title, 'First record title should match');
        Assert.isFalse(dtos[0].isOutOfStock,           'First record should not be out of stock');

        Assert.areEqual('Animal Farm',  dtos[1].title, 'Second record title should match');
        Assert.isFalse(dtos[1].isOutOfStock,           'Second record should not be out of stock');

        Assert.areEqual('Cat\'s Cradle', dtos[2].title, 'Third record title should match');
        Assert.isTrue(dtos[2].isOutOfStock,              'Third record should be out of stock');
    }

    @isTest
    static void testFromSObjects_EmptyList_ReturnsEmptyList() {
        Test.startTest();
        List<BookDTO> dtos = BookDTO.fromSObjects(new List<Book__c>());
        Test.stopTest();

        Assert.isNotNull(dtos,          'Result should not be null');
        Assert.areEqual(0, dtos.size(), 'Result should be empty');
    }

    @isTest
    static void testFromSObjects_SingleRecord() {
        Book__c book = buildBook('Dune', 'Frank Herbert', 'Science Fiction',
                                 '1965', '9780441013593', 15, 14.99);
        insert book;
        book = [SELECT Id, Title__c, Author__c, Genre__c, Publication_Year__c,
                       ISBN__c, Current_Inventory__c, Price__c FROM Book__c WHERE Id = :book.Id];

        Test.startTest();
        List<BookDTO> dtos = BookDTO.fromSObjects(new List<Book__c>{ book });
        Test.stopTest();

        Assert.areEqual(1,      dtos.size(),       'Should return exactly 1 DTO');
        Assert.areEqual('Dune', dtos[0].title,     'Title should match');
        Assert.areEqual(15,     dtos[0].quantity,  'Quantity should match');
        Assert.isFalse(dtos[0].isOutOfStock,        'Should not be out of stock');
    }
}