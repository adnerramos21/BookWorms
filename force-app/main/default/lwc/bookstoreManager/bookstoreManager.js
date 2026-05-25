import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import searchBookAvailability from '@salesforce/apex/BookStoreController.searchBookAvailability';
import getReservations from '@salesforce/apex/BookStoreController.getReservations';

export default class BookstoreManager extends LightningElement {

    isTableVisible = false;
    isEmpty = false;
    hasNoData = false;
    isLoading = false;
    _lastSearchParams = null;

    @track listOfBooks = [];
    @track listOfReservations = [];

    connectedCallback() {
        this.getAllReservations();
    }

    async searchHandler(event) {
        this.isTableVisible = false;
        this.isEmpty = false;
        this.hasNoData = false;
        this.isLoading = true;

        const { action, title, author, isbn } = event.detail;

        const compoundString = title + author + isbn;

        if (compoundString.length === 0) {
            this.isEmpty = true;
            this.isLoading = false;
            return;
        }

        const params = {
            title: title?.trim() ?? '',
            author: author?.trim() ?? '',
            isbn: isbn?.trim() ?? ''
        };

        this._lastSearchParams = params;

        await this.fetchBooks(params, action);
    }

    async fetchBooks(params, action = 'Search') {
        this.isLoading = true;

        try {
            this.listOfBooks = await searchBookAvailability(params);
            this.hasNoData = this.listOfBooks.length === 0;
            this.isTableVisible = action === 'Search' && this.listOfBooks.length > 0;

        } catch (error) {
            this.dispatch(new ShowToastEvent({
                title: 'Warning',
                message: `Couldn't find any books, please try again`,
                variant: 'warning'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    async getAllReservations() {
        try {
            this.listOfReservations = await getReservations();
            console.log(this.listOfReservations);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: `There was an error retrieving your reservations. Please refresh your page`,
                variant: 'warning'
            }));
        }
    }

    async handleCreatedReservation() {
        try {
            await Promise.all([
                this.getAllReservations(),
                this._lastSearchParams ? this.fetchBooks(this._lastSearchParams) : Promise.resolve()
            ]);
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Warning',
                message: `Couldn't update your data, please reload the screen to see your changes`,
                variant: 'warning'
            }));
        }
    }

}