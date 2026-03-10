/**
 * @description       : 
 * @author            : Francisco Ribeiro
 * @group             : 
 * @last modified on  : 14-11-2024
 * @last modified by  : João Rosa
**/
import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";

import getContaPesquisa from "@salesforce/apex/c_PesquisaConta.getAccountsMdm";
import getContaSF from "@salesforce/apex/SyncAccount.getAccount";
import editaContaSF from "@salesforce/apex/c_PesquisaConta.upsertAccountSF";
//import createMdmAccount from "@salesforce/apex/SyncAccount.createMdmAccount";
import editaContaSync from "@salesforce/apex/SyncAccount.updateAccount";

export default class SyncAccountCmp extends LightningElement {
    @track contasMDM = [];
    @track spinner = false;
    @track synced = true;
    @track message = '';
    @track refresh = true;
    @api recordId;
    accountSF;

    sync() {
        this.spinner = true;

        getContaSF({recordID: this.recordId}).then((data) => {
			if(data != null) {
				this.accountSF = data;
                var search = [];
                search.push(this.accountSF.Numero_de_Conta__c);

                if (this.accountSF.Numero_de_Conta__c === null || this.accountSF.Numero_de_Conta__c === '' || this.accountSF.Numero_de_Conta__c === undefined) {
                    
                    console.log("Erro!", "Não foi possivel cirar a conta!", "error");

                    this.message = 'Não é possível sincronizar uma conta do LM Care que não tenha o Número de Conta do ELO/MDM. Por favor criar nova conta no ELO, pesquisar a nova conta no menu Pesquisa de Conta e carregar no botão "Clonar conta no LM Care"';
                    this.spinner = false;
                    this.synced = false;
                    this.refresh = false;
                    
                    /*createMdmAccount({recordID: this.recordId}).then((data) => {
                        this.spinner = false;
                        this.synced = false;
                        this.message = 'A Conta foi sincronizada!';
                    }).catch((error) => {

                        console.log("Erro!", "Não foi possivel cirar a conta!", "error");

                        this.message = 'Não foi possivel criar a conta';
                        this.spinner = false;
                        this.synced = false;
                        this.refresh = false;
                    })*/
                }else{
                    getContaPesquisa({Pesquisa: search, TipoPesquisa: 'Nº de Cliente'}).then((data) => {
                        if (data != null) {
                            this.contasMDM.length = 0;
                            console.log(data[0]);
                            this.contasMDM.push({
                                updatedAt: data[0].updatedAt,
                                fullData: data[0]
                            });
    
                            console.log('sf acc last date : ' + this.accountSF.LastModifiedDate);
                            console.log('MDM acc last date : ' + this.contasMDM[0].updatedAt);
                            //if(this.accountSF.LastModifiedDate < this.contasMDM[0].updatedAt) {
                                editaContaSF({data: this.contasMDM[0].fullData, isSync: true}).then((results) => {
                                    console.log(results);
                                    if(results[0] === "true") {
                                        console.log("Sucesso!", "A Conta foi editada!", "success");
                                        this.message = 'A Conta foi sincronizada!';
                                    } else{
                                        console.log("Erro!", "Não foi possivel editar a conta!", "error");
                                        this.message = 'Não foi possivel sincronizar a conta.';
                                        this.refresh = false;
                                    }
                                    this.spinner = false;
                                    this.synced = false;
                                }).catch((error) => {
                                    console.log(error);
                                    console.log("Erro!", "Não foi possivel editar a conta!", "error");
                                    this.message = 'Não foi possivel sincronizar a conta.';
                                    this.spinner = false;
                                    this.synced = false;
                                    this.refresh = false;
                                });
                            //} else {
                            //    editaContaSync({recordID: this.recordId}).then((results) => {
                            //        if(results === true) {
                            //            console.log("Sucesso!", "A Conta foi editada!", "success");
                            //            this.message = 'A Conta foi sincronizada!';
                            //            
                            //        } else{
                            //            console.log("Erro!", "Não foi possivel editar a conta!", "error");
                            //            this.message = 'Não foi possivel sincronizar a conta.';
                            //            this.refresh = false;
                            //        }
                            //        this.spinner = false;
                            //        this.synced = false;
                            //    }).catch((error) => {
                            //        console.log(error);
                            //        console.log("Erro!", "Não foi possivel editar a conta!", "error");
                            //        this.message = 'Não foi possivel sincronizar a conta.';
                            //        this.spinner = false;
                            //        this.synced = false;
                            //        this.refresh = false;
                            //    });
                            //}
                        } else {
                            console.log("Contas mdm" + JSON.stringify(this.contasMDM));
                            this.contasMDM.length = 0;
                            console.log("Erro!", "Não foi possivel obter a conta MDM", "error");
                            this.message = 'Não foi possivel sincronizar a conta. Numero De conta não encontrado';
                            this.spinner = false;
                            this.synced = false;
                            this.refresh = false;
    
                        }
                    }).catch((errorMDM) => {
                        console.log(errorMDM);
                        console.log("Erro!", "Não foi possivel obter a conta MDM", "error");
                        this.message = 'Não foi possivel sincronizar a conta.';
                        this.spinner = false;
                        this.synced = false;
                        this.refresh = false;
                    });
                }
                
			}
		}).catch((errorSF) => {
            console.log(errorSF);
            console.log("Erro!", "Não foi possivel obter a conta Salesforce", "error");
            this.message = 'Não foi possivel sincronizar a conta.';
            this.spinner = false;
            this.synced = false;
            this.refresh = false;
        });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());        
    }
}