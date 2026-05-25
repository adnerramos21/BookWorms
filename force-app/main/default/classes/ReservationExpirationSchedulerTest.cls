@isTest
private class ReservationExpirationSchedulerTest {
    
    private static final String CRON_EXP = '0 59 23 * * ?';
    private static final String JOB_NAME = 'Test Reservation Expiration Job';
    
    // ── Add @TestSetup ────────────────────────────────────────────────────────────
    @TestSetup
    static void setupData() {
        insert new Contact(FirstName = 'Test', LastName = 'Contact');
    }
    
    // ── Test Data Factory ─────────────────────────────────────────────────────
    
    private static Book__c buildBook() {
        return new Book__c(
            Title__c             = 'Test Book',
        Author__c            = 'Test Author',
        Genre__c             = 'Literary Fiction',
        Publication_Year__c  = '2000',
        ISBN__c              = '9780000000000',
        Current_Inventory__c = 5,
        Max_Inventory__c     = 10,
        Price__c             = 9.99,
        Active__c            = true
            );
    }
    
    private static Reservation__c buildReservation(Id bookId, String status, DateTime expirationDate) {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        return new Reservation__c(
            Book__c             = bookId,
        Contact__c          = contact.Id,  
        Status__c           = status,
        Reservation_Date__c = DateTime.now(),
        Expiration_Date__c  = expirationDate
            );
    }
    
    // ── execute — marks expired records ──────────────────────────────────────
    
    @isTest
    static void testExecute_ExpiredReservations_MarkedAsExpired() {
        Book__c book = buildBook();
        insert book;
        
        // Expiration date in the past — should be caught
        Reservation__c res = buildReservation(book.Id, 'Reserved', DateTime.now().addDays(-1));
        insert res;
        
        Test.startTest();
        ReservationExpirationScheduler scheduler = new ReservationExpirationScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        Reservation__c updated = [SELECT Status__c FROM Reservation__c WHERE Id = :res.Id];
        Assert.areEqual('Expired', updated.Status__c, 'Status should be updated to Expired');
    }
    
    @isTest
    static void testExecute_FutureReservations_NotExpired() {
        Book__c book = buildBook();
        insert book;
        
        // Expiration date in the future — should NOT be touched
        Reservation__c res = buildReservation(book.Id, 'Reserved', DateTime.now().addDays(2));
        insert res;
        
        Test.startTest();
        ReservationExpirationScheduler scheduler = new ReservationExpirationScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        Reservation__c updated = [SELECT Status__c FROM Reservation__c WHERE Id = :res.Id];
        Assert.areEqual('Reserved', updated.Status__c, 'Future reservation should remain Reserved');
    }
    
    @isTest
    static void testExecute_AlreadyExpired_NotProcessedAgain() {
        Book__c book = buildBook();
        insert book;
        
        // Already marked Expired — should not be re-processed
        Reservation__c res = buildReservation(book.Id, 'Expired', DateTime.now().addDays(-1));
        insert res;
        
        Test.startTest();
        ReservationExpirationScheduler scheduler = new ReservationExpirationScheduler();
        scheduler.execute(null); // no exception should be thrown
        Test.stopTest();
        
        Reservation__c updated = [SELECT Status__c FROM Reservation__c WHERE Id = :res.Id];
        Assert.areEqual('Expired', updated.Status__c, 'Already-expired reservation should remain Expired');
    }
    
    @isTest
    static void testExecute_CancelledReservation_NotTouched() {
        Book__c book = buildBook();
        insert book;
        
        Reservation__c res = buildReservation(book.Id, 'Cancelled', DateTime.now().addDays(-1));
        insert res;
        
        Test.startTest();
        ReservationExpirationScheduler scheduler = new ReservationExpirationScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        Reservation__c updated = [SELECT Status__c FROM Reservation__c WHERE Id = :res.Id];
        Assert.areEqual('Cancelled', updated.Status__c, 'Cancelled reservation should not be touched');
    }
    
    @isTest
    static void testExecute_NoReservations_RunsWithoutError() {
        Test.startTest();
        try {
            ReservationExpirationScheduler scheduler = new ReservationExpirationScheduler();
            scheduler.execute(null);
            Assert.isTrue(true, 'Should run without exception when no records exist');
        } catch (Exception e) {
            Assert.fail('Should not throw exception with empty reservations: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // ── Bulk ─────────────────────────────────────────────────────────────────
    
    @isTest
    static void testExecute_BulkExpiredReservations_AllMarkedExpired() {
        Book__c book = buildBook();
        insert book;
        
        List<Reservation__c> reservations = new List<Reservation__c>();
        for (Integer i = 0; i < 20; i++) {
            reservations.add(buildReservation(book.Id, 'Reserved', DateTime.now().addDays(-1)));
        }
        insert reservations;
        
        Test.startTest();
        ReservationExpirationScheduler scheduler = new ReservationExpirationScheduler();
        scheduler.execute(null);
        Test.stopTest();
        
        List<Reservation__c> updated = [SELECT Status__c FROM Reservation__c WHERE Id IN :reservations];
        for (Reservation__c r : updated) {
            Assert.areEqual('Expired', r.Status__c, 'All expired reservations should be marked Expired');
        }
    }
    
    // ── Scheduled via System.schedule ────────────────────────────────────────
    
    @isTest
    static void testSchedule_JobRegistersSuccessfully() {
        Test.startTest();
        String jobId = System.schedule(JOB_NAME, CRON_EXP, new ReservationExpirationScheduler());
        Test.stopTest();
        
        Assert.isNotNull(jobId, 'Job ID should not be null after scheduling');
        
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
        ];
        Assert.areEqual(1, jobs.size(), 'Exactly one scheduled job should exist');
    }
}