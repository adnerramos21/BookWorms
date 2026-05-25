import LightningModal from 'lightning/modal';
import { api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import EXPIRATION_FIELD from "@salesforce/schema/Reservation__c.Expiration_Date__c";
import RESERVATION_FIELD from "@salesforce/schema/Reservation__c.Reservation_Date__c";
import STATUS_FIELD from "@salesforce/schema/Reservation__c.Status__c";
import NAME_FIELD from "@salesforce/schema/Reservation__c.Name";
import BOOK_FIELD from "@salesforce/schema/Reservation__c.Book__c";
import CONTACT_FIELD from "@salesforce/schema/Reservation__c.Contact__c";
import PICKUP_CONTACT_FIELD from "@salesforce/schema/Reservation__c.Pickup_Contact__c";

export default class BookReservation extends LightningModal {
    @api bookRow;  // passed in from BookResults via .open()

    get modalTitle() {
        return `Reserve: ${this.bookRow?.title ?? ''}`;
    }

    get bookRowReservationName() {
        return `Reservation for book ISBN: ${this.bookRow.isbn}`;
    }

    fields = [NAME_FIELD, STATUS_FIELD, BOOK_FIELD, EXPIRATION_FIELD, 
        RESERVATION_FIELD, CONTACT_FIELD, PICKUP_CONTACT_FIELD];

    handleSuccess(event) {
        const recordId = event.detail.id;

        this.dispatchEvent(new ShowToastEvent({
            title:   'Success',
            message: 'Reservation created successfully.',
            variant: 'success'
        }));

        this.close(recordId);   // closes modal, resolves the promise in BookResults
    }

    handleError(event) {
        console.error(event.detail);
    }

    handleCancel() {
        this.close(null); 
    }

    handleSubmit() {
        this.template.querySelector('lightning-record-edit-form').submit();
    }
}