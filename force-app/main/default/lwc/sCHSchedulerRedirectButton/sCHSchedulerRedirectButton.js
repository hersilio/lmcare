import { LightningElement, api} from 'lwc';

export default class SCHSchedulerRedirectButton extends LightningElement {
    
    @api recordId;
    test = false;
 
    handleButtonClick() {
        this.test=true;
    }
 
    closeModel(){
        this.test=false;
    }
 
    get inputFlowVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
            
        ];
    }
 
    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.test=false;
        }
    }
}