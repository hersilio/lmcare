import { track, api, wire, LightningElement } from 'lwc';
import {refreshApex} from '@salesforce/apex';
import generateToken from '@salesforce/apex/LM_TokenGenerator.auraGenerateToken';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import LightningAlert from 'lightning/alert';
import ORDER_ID from '@salesforce/schema/Order.Id';
import VALIDATION_TOKEN from '@salesforce/schema/Order.Validation_Token__c';
import EXPIRED from '@salesforce/schema/Order.Expired_Token__c';
import STATUSCODE from '@salesforce/schema/Order.StatusCode';


export default class LM_ResendTokenButton extends LightningElement {

  @api recordId;
  @wire(getRecord, { recordId: "$recordId", fields: [ORDER_ID, VALIDATION_TOKEN, EXPIRED, STATUSCODE] })
  order;

  async handleClick(event) {

    await refreshApex(this.order);

    //console.log(getFieldValue(this.order.data, EXPIRED));
    //console.log(getFieldValue(this.order.data, STATUSCODE));

    if (getFieldValue(this.order.data, STATUSCODE) == "Activated") {
        LightningAlert.open({
            message: "Não é possível gerar um novo Token.",
            theme: 'warning',
            label: "Pedido finalizado.", 
        });
        return;
    }
    
    // if (getFieldValue(this.order.data, EXPIRED) === false) {
    //     LightningAlert.open({
    //         message: "O Token anterior ainda não expirou.",
    //         theme: 'warning',
    //         label: "Token não enviado",
    //     });
    //   return;
    // }

    let token = await generateToken();
    //save token to order
    const fields = {};

    fields[ORDER_ID.fieldApiName] = this.recordId;
    fields[VALIDATION_TOKEN.fieldApiName] = token;
    fields[EXPIRED.fieldApiName] = false;

    updateRecord({ fields }).then(() => {
        LightningAlert.open({
            message: "Token Enviado.",
            theme: 'success', 
            label: "Sucesso", 
        });
    });
  }
}