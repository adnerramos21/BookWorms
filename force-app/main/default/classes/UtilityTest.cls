@isTest
private class UtilityTest {

    // ── sanitizeLike ──────────────────────────────────────────────────────────

    @isTest
    static void testSanitizeLike_NullInput_ReturnsNull() {
        Test.startTest();
        String result = Utility.sanitizeLike(null);
        Test.stopTest();

        Assert.isNull(result, 'Null input should return null');
    }

    @isTest
    static void testSanitizeLike_BlankInput_ReturnsNull() {
        Test.startTest();
        String result = Utility.sanitizeLike('   ');
        Test.stopTest();

        Assert.isNull(result, 'Blank input should return null');
    }

    @isTest
    static void testSanitizeLike_CleanInput_ReturnsTrimmed() {
        Test.startTest();
        String result = Utility.sanitizeLike('  George Orwell  ');
        Test.stopTest();

        Assert.areEqual('George Orwell', result, 'Should trim whitespace');
    }

    @isTest
    static void testSanitizeLike_EscapesPercent() {
        Test.startTest();
        String result = Utility.sanitizeLike('100%');
        Test.stopTest();

        Assert.areEqual('100\\%', result, 'Should escape % character');
    }

    @isTest
    static void testSanitizeLike_EscapesUnderscore() {
        Test.startTest();
        String result = Utility.sanitizeLike('Cat_Cradle');
        Test.stopTest();

        Assert.areEqual('Cat\\_Cradle', result, 'Should escape _ character');
    }

    @isTest
    static void testSanitizeLike_EscapesBothSpecialChars() {
        Test.startTest();
        String result = Utility.sanitizeLike('100%_done');
        Test.stopTest();

        Assert.areEqual('100\\%\\_done', result, 'Should escape both % and _');
    }

    // ── sanitizeIsbn ──────────────────────────────────────────────────────────

    @isTest
    static void testSanitizeIsbn_NullInput_ReturnsNull() {
        Test.startTest();
        String result = Utility.sanitizeIsbn(null);
        Test.stopTest();

        Assert.isNull(result, 'Null input should return null');
    }

    @isTest
    static void testSanitizeIsbn_BlankInput_ReturnsNull() {
        Test.startTest();
        String result = Utility.sanitizeIsbn('   ');
        Test.stopTest();

        Assert.isNull(result, 'Blank input should return null');
    }

    @isTest
    static void testSanitizeIsbn_ValidIsbnWithHyphens_ReturnsUnchanged() {
        Test.startTest();
        String result = Utility.sanitizeIsbn('978-0-13-468599-1');
        Test.stopTest();

        Assert.areEqual('978-0-13-468599-1', result, 'Valid ISBN with hyphens should be unchanged');
    }

    @isTest
    static void testSanitizeIsbn_ValidIsbnNoHyphens_ReturnsUnchanged() {
        Test.startTest();
        String result = Utility.sanitizeIsbn('9780451524935');
        Test.stopTest();

        Assert.areEqual('9780451524935', result, 'Valid ISBN without hyphens should be unchanged');
    }

    @isTest
    static void testSanitizeIsbn_StripsAlphaAndSpecialChars() {
        Test.startTest();
        String result = Utility.sanitizeIsbn('978abc!@#');
        Test.stopTest();

        Assert.areEqual('978', result, 'Should strip non-numeric non-hyphen characters');
    }

    @isTest
    static void testSanitizeIsbn_TrimsWhitespace() {
        Test.startTest();
        String result = Utility.sanitizeIsbn('  9780451524935  ');
        Test.stopTest();

        Assert.areEqual('9780451524935', result, 'Should trim surrounding whitespace');
    }

    // ── formatDateTime ────────────────────────────────────────────────────────

    @isTest
    static void testFormatDateTime_NullInput_ReturnsNull() {
        Test.startTest();
        String result = Utility.formatDateTime(null);
        Test.stopTest();

        Assert.isNull(result, 'Null DateTime should return null');
    }

    @isTest
    static void testFormatDateTime_ValidDateTime_ReturnsFormattedString() {
        DateTime dt = DateTime.newInstance(2026, 3, 31, 23, 59, 0);

        Test.startTest();
        String result = Utility.formatDateTime(dt);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('2026'),  'Result should contain the year');
        Assert.isTrue(result.contains('31'),    'Result should contain the day');
        Assert.isTrue(result.contains('at'),    'Result should contain the at separator');
    }

    @isTest
    static void testFormatDateTime_ContainsCorrectStructure() {
        DateTime dt = DateTime.newInstance(2026, 1, 5, 11, 30, 0);

        Test.startTest();
        String result = Utility.formatDateTime(dt);
        Test.stopTest();

        // Format: "Jan 5, 2026 at 11:30 AM"
        Assert.isTrue(result.contains('Jan'),  'Should contain abbreviated month');
        Assert.isTrue(result.contains('5'),    'Should contain day');
        Assert.isTrue(result.contains('2026'), 'Should contain year');
        Assert.isTrue(result.contains('at'),   'Should contain at separator');
    }
}