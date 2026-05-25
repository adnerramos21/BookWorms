import { LightningElement, api } from 'lwc';

export default class ReservationList extends LightningElement {

    @api reservations = [];

    get reservationList() {
        console.log(this.reservations);
        return this.reservations.map(reservation => (
            {
                ...reservation,
                cssClassPill: `pill slds-m-bottom_xx-small ${reservation.status}`,
                canShowDatetimeBlock: reservation.status === 'Reserved'
            }
        ));
    }

    get totalReservation() {
        return this.reservations.length;
    }

    get totalReserved() {
        return this.reservations.filter(val => val.status === 'Reserved').length;
    }

    get totalCancelled() {
        return this.reservations.filter(val => val.status === 'Cancelled').length;
    }

    get totalPickedUp() {
        return this.reservations.filter(val => val.status === 'Picked Up').length;
    }

    get totalExpired() {
        return this.reservations.filter(val => val.status === 'Expired').length;
    }

}