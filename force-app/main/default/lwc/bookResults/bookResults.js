import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import BookReservation from 'c/bookReservation';

const COLUMNS = [
    { label: 'Title', fieldName: 'title' },
    { label: 'Author', fieldName: 'author' },
    { label: 'Genre', fieldName: 'genre' },
    { label: 'Publication Year', fieldName: 'publicationYear' },
    { label: 'ISBN', fieldName: 'isbn' },
    { label: 'Quantity', fieldName: 'quantity', type: 'number' },
    { label: 'Price', fieldName: 'price', type: 'currency' },
    {
        label: 'Action',
        type: 'button',
        fixedWidth: 130,
        typeAttributes: {
            label:  { fieldName: 'reserveLabel' },
            name: 'reserve',
            variant: 'outline',
            disabled: { fieldName: 'isOutOfStock' } 
        }
    }
];

export default class BookResults extends LightningElement {

    @api data = [];
    columns = COLUMNS;

    connectedCallback() {
        console.log(this.data);
    }

    async handleRowAction(event) {
        const { name } = event.detail.action;   // matches typeAttributes.name
        const row = event.detail.row;      // the full row object

        if (name === 'reserve') {
            try {
                const reservationId = await BookReservation.open({
                    size: 'medium',
                    label: 'Book Reservation',
                    bookRow: row   // maps to @api bookRow in BookReservation
                });

                if (reservationId) {
                    console.log("Reservation created", reservationId);

                    this.dispatchEvent(new CustomEvent('createdreservation'));
                }

            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Warning',
                    message: `Couldn't open the book reservation, please try again`,
                    variant: 'warning'
                }));
            }

        }
    }
}