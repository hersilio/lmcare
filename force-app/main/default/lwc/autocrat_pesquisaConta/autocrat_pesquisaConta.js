import { LightningElement, api, track } from 'lwc';

export default class Autocrat_pesquisaConta extends LightningElement {
    @api searchResults = [];
    @api selectedResult;

    columns = [
        { label: 'Nome', fieldName: 'name' },
        { label: 'NIF', fieldName: 'nif' },
        { label: 'Telefone', fieldName: 'phone' },
        { label: 'Email', fieldName: 'email' },
        { label: 'Nº do Cliente', fieldName: 'clientNumber' },
        { label: 'No LM Care', fieldName: 'isInSF', type: 'boolean' },
        { label: 'No ELO', fieldName: 'isInMDM', type: 'boolean' }
    ];

    handleRowSelection(event) {
        this.selectedResult = event.detail.selectedRows[0];
    }
}