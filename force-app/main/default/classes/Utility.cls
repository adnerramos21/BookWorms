public class Utility {
    
    /**
     * Escapes LIKE special characters so user input is treated as literals.
     * % = wildcard for any sequence
     * _ = wildcard for a single character
     */
    public static String sanitizeLike(String value) {
        if (String.isBlank(value)) return null;
        return value.trim()
            .replace('%', '\\%')
            .replace('_', '\\_');
    }
    
    /**
     * Strips everything except digits and hyphens from an ISBN.
     * '978-0-13-468599-1' → '978-0-13-468599-1'  (valid)
     * '978abc!@#'         → '978'                 (junk removed)
     */
    public static String sanitizeIsbn(String value) {
        if (String.isBlank(value)) return null;
        return value.trim().replaceAll('[^0-9\\-]', '');
    }
    
    // Format: "Mar 31, 2026 at 11:59 PM"
    public static String formatDateTime(DateTime dt) {
        if (dt == null) return null;
        
        String month = dt.format('MMM');   // Mar
        String day = String.valueOf(dt.day());
        String year = String.valueOf(dt.year());
        String timeFormat = dt.format('h:mm a'); // 11:59 PM
        
        return month + ' ' + day + ', ' + year + ' at ' + timeFormat;
    }
}