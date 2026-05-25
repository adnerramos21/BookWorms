trigger ReservationTrigger on Reservation__c (after insert) {
	ReservationTriggerHandler.handleAfterInsert(Trigger.new);
}