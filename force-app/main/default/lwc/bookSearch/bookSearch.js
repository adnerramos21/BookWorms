import { LightningElement, track } from 'lwc';

export default class BookSearch extends LightningElement {

    @track formData = { title: '', author: '', isbn: '' };


    handleInput(event) {
        const { name, value } = event.target;
        this.formData = { ...this.formData, [name]: value };
    }

    handleClick(event) {
        const { title, author, isbn } = this.formData;

        this.dispatchEvent(new CustomEvent('search', 
            {
                detail: {
                    action: event.target.label,
                    title: title,
                    author: author,
                    isbn: isbn
                }
            }
        ));
    } 
}