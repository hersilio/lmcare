/**
 * @description       : 
 * @author            : Francisco Ribeiro
 * @group             : 
 * @last modified on  : 03-10-2024
 * @last modified by  : João Rosa
**/
import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

import getContaPesquisa from "@salesforce/apex/c_PesquisaConta.getAccountsMdm";
import getContaSF from "@salesforce/apex/c_PesquisaConta.getAccountSF";
import criaEditaContaSF from "@salesforce/apex/c_PesquisaConta.upsertAccountSF";
//import editaContaMDM from "@salesforce/apex/c_PesquisaConta.updateAccountMDM";
import GetProfissionalRecordTypeId from "@salesforce/apex/c_PesquisaConta.GetProfissionalRecordTypeId";
import GetPersonRecordTypeId from "@salesforce/apex/c_PesquisaConta.GetPersonRecordTypeId";
import GetAccountsSF from "@salesforce/apex/c_PesquisaConta.getAccountsSF";
//import insertAccMDM from "@salesforce/apex/c_PesquisaConta.insertAccMDM";

export default class PesquisaConta extends NavigationMixin(LightningElement) {
	@track contasMDM = [];
	@track contasSF = [];
	@track AccId = "";
	@track accountSF;
	@track accountMDM;
	textValue = [];
	IdContasAdicionadas = [];
	searchFieldsValue = "NIF";
	record;
	name = "";
	label = "number";
	SearchLastName = "";
	recordTypePersonId = "";
	recordTypeProfessionalId = "";
	style = "";
	minLength = 9;
	maxLength = 9;
	accountsFail = 0;
	onlyInSF = false;
	mdmInSF = false;
	mdmNotInSF = false;
	@track isPersonAccount = false;
	secondName = false;
	boolSpinner = false;
	BoolTableAccounts = false;

	@wire(GetPersonRecordTypeId) personAccountRecordId;
	@wire(GetProfissionalRecordTypeId) personProfessionaltRecordId;
	connectedCallback() {
	}
	createAccountMDM(event){
		let idlist= [];
		idlist.push(event.currentTarget.dataset.id);
		console.log(idlist);

		//insertAccMDM({accountsForUpdate: idlist}).then(result => {
		//	this.showToast('Conta Criada', 'conta foi enviada para a base de dados e aguarda criação', 'success');
		//}).catch(error => {
		//	this.showToast(
		//		"Erro ao enviar conta",
		//		error,
		//		"error"
		//	);
		//});
	}
	
	showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(event);
	}

	handleNome(event) {
		if (event.key === "Enter") {
			this.mdmInSF = false;
			this.mdmNotInSF = false;
			this.onlyInSF = false;
			this.isPersonAccount = false;
			this.AccId = "";
			this.accountSF = null;
			this.accountMDM = null;

			if (!this.validationEmail(event.target.value) && this.searchFieldsValue === "Email") {
				this.showToast(
					"Email inválido",
					"Insira um email válido!",
					"error"
				);
			} else {
				this.textValue.length = 0;
				if(this.secondName) {
					this.textValue.push(this.name, this.SearchLastName);
				} else {
					this.textValue.push(event.target.value);
				}

				this.boolSpinner = true;
				
				this.UpdateListMDM();
			}
		}
	}


	UpdateListMDM(){
		getContaPesquisa({Pesquisa: this.textValue, TipoPesquisa: this.searchFieldsValue}).then((data) => {
			if (data != null) {
				this.contasMDM.length = 0;
				this.IdContasAdicionadas.length = 0;
				data.forEach((element) => {
					if (!this.IdContasAdicionadas.includes(element.clientNumber)) {
						console.log('contas do mdm');
						
						console.log(element);
						
						let sname;
						let nif;
						if (element.inhabitant.lastName === "-" || element.inhabitant.lastName === "" || element.inhabitant.lastName === null) {
							sname = element.professionalOrganization.registeredName
							nif = element.professionalOrganization.administrativeCodes.nif;
						}else{
							sname = element.inhabitant.firstName + ' ' + element.inhabitant.lastName;
							nif = element.inhabitant.administrativeIdentifiers.nif;
						}

						let emailAddress = '';
						element.emailAddresses.forEach(mail => {
							if (mail.isContactPriority === true) {
								emailAddress = mail.email;
							}
						});
						
						let phoneN = '';
						
						element.phones.forEach(phoneNumberItem => {
							console.log('phone number item');	
							console.log(phoneNumberItem);
							if (phoneNumberItem.isContactPriority === true) {
								phoneN = phoneNumberItem.numberSF;
							}
						});

						this.contasMDM.push({
							Id: element.Id,
							isMDM: true,
							isSF: false,
							name: sname,
							firstName: element.inhabitant.firstName,
							lastName: element.inhabitant.lastName,
							nif: nif,
							phone: phoneN,
							email: emailAddress,
							clientNumber: element.clientNumber,
							updatedAt: element.updatedAt,
							fullData: element
						});
						this.IdContasAdicionadas.push(element.clientNumber);
						this.boolSpinner = false;
						this.BoolTableAccounts = true;
					}
				});
				this.UpdateListSf();
				this.orderList();
			} else{
				this.contasMDM.length = 0;
				this.IdContasAdicionadas.length = 0;
				this.BoolTableAccounts = false;
				console.log("Contas mdm" + JSON.stringify(this.contasMDM));
				this.showToast(
					"Sem Registos MDM",
					"Não foram encontrados registos!",
					"error"
				);
				this.UpdateListSf();
				this.orderList();
			}
			this.orderList();
		});
	}


	UpdateListSf(){
		GetAccountsSF({Pesquisa: this.textValue, TipoPesquisa: this.searchFieldsValue}).then((datasf) => {
			if (datasf != null && datasf != undefined) {
				datasf.forEach((element) => {
					let phone = element.Phone != null && element.Phone !== undefined && element.Phone !== '' ? element.Phone : element.PersonMobilePhone != null && element.PersonMobilePhone !== undefined && element.PersonMobilePhone !== '' ? element.PersonMobilePhone : element.PersonHomePhone; 
					if (!this.IdContasAdicionadas.includes(element.Numero_de_Conta__c)) {
						
							let conta = {
								Id: element.Id,
								isSF: true,
								isMDM: false,
								name: element.FirstName + ' ' + element.LastName,
								firstName: element.FirstName,
								lastName: element.LastName,
								nif: element.NIF__c,
								phone: phone,
								email: element.PersonEmail,
								clientNumber: element.Numero_de_Conta__c,
								updatedAt: element.LastModifiedDate,
								fullData: element
							}
							if (element.Name != null && element.Name != undefined) {
								conta.name = element.Name;
							}
							console.log(conta);
							if (conta.email == undefined || conta.email == null) {
								conta.email = element.E_mail_Empresa__c;
							}
							this.contasMDM.push(conta);
							if (element.Numero_de_Conta__c !== undefined) {
								this.IdContasAdicionadas.push(element.Numero_de_Conta__c);
							}
							this.boolSpinner = false;
							this.BoolTableAccounts = true;
					}else{
						this.contasMDM.forEach((conta) => {
							if (conta.clientNumber===element.Numero_de_Conta__c) {
								conta.isSF = true;
							}
						})
					}
				});

			} else {
				this.contasSF.length = 0;
				this.IdContasAdicionadas.length = 0;
				this.BoolTableAccounts = false;
				console.log("Contas SF" + JSON.stringify(this.contasSF));
				this.showToast(
					"Sem Registos Locais",
					"Não foram encontrados registos no salesforce!",
					"error"
				);
			}
			
			this.orderList();
			this.boolSpinner = false;
		}).catch(error => {
			this.showToast(
				"Sem Registos Locais",
				"Não foram encontrados registos no salesforce!",
				"error"
			);
			this.boolSpinner = false;
			this.BoolTableAccounts = true;
		});
	}

	handleName(event) {
		this.name = event.target.value;
		console.log(this.name);
	}

	orderList(){
		this.contasMDM.sort(function (a,b){
			if (a.clientNumber == null || a.clientNumber == undefined || a.clientNumber == '') {
				return 1;
			}
			return a.clientNumber - b.clientNumber});
		console.log(this.contasMDM);
	}

	handleSubmit(event) {
		event.preventDefault(); // stop the form from submitting
		const fields = event.detail.fields;
		console.log(fields);
		this.template.querySelector("lightning-record-form").submit(fields);
		if (this.AccId !== "") {
			this.showToast("Sucesso!", "A account foi atualizada!", "success");
		} else {
			this.showToast("Sucesso!", "A account foi criada!", "success");
		}
	}

	handleOnClickList(event) {
		let value = event.currentTarget.dataset;
		console.log(JSON.stringify(value));
		this.BoolTableAccounts = false;

		let formatter = new Intl.DateTimeFormat('en-GB', {
			year: "numeric" ,
			month: "numeric",
			day: "numeric",
			hour: "2-digit",
			minute: "2-digit",
			second: "2-digit"
		});

		if(value.ismdm === "true"){
			getContaSF({clientNumber: value.cardno}).then((data) => {
				this.contasMDM.every((element) => {
					if(element.clientNumber.toString() === value.cardno) {
						element.updatedAt = formatter.format(Date.parse(element.updatedAt));
						this.accountMDM = element;
						return false;
					}
					return true;
				});
	
				if(data != null) {
					this.AccId = data.Id;
					if(data.RecordTypeId === this.personAccountRecordId.data){
						this.isPersonAccount = true;
					}			
					data.LastModifiedDate = formatter.format(Date.parse(data.LastModifiedDate));
					data.phone = data.Phone != null && data.Phone !== undefined && data.Phone !== '' ? data.Phone : data.PersonMobilePhone != null && data.PersonMobilePhone !== undefined && data.PersonMobilePhone !== '' ? data.PersonMobilePhone : data.PersonHomePhone; 
					this.accountSF = data;
					this.accountSF.Phone = data.Phone == null || data.Phone == undefined ? data.PersonMobilePhone:data.Phone;
					this.mdmInSF = true;
				}else {
					this.mdmNotInSF = true;
				}
			});
		}

		if(value.ismdm === "false" && value.issf === "true"){
			var pesquisa= [];
			if(value.cardno !== null && value.cardno !== undefined){
				pesquisa.push(value.cardno); 
				getContaPesquisa({Pesquisa: pesquisa, TipoPesquisa: "Nº de Cliente"}).then((datamdm) => {
					if (datamdm !== null) {
						console.log(datamdm[0]);
						let sname;
						let nif;
						if (datamdm[0].inhabitant.lastName == '-') {
							sname = datamdm[0].professionalOrganization.registeredName
						}else{
							sname = datamdm[0].inhabitant.firstName + ' ' + datamdm[0].inhabitant.lastName;
						}
						if(datamdm[0].professionalOrganization != null){
							if (datamdm[0].professionalOrganization.administrativeCodes !== null) {
								nif = datamdm[0].professionalOrganization.administrativeCodes.nif;
							}
						}
						else{
							nif = datamdm[0].inhabitant.administrativeIdentifiers.nif;
						}

						let emailAddress = '';
						datamdm[0].emailAddresses.forEach(mail => {
							if (mail.isContactPriority === true) {
								emailAddress = mail.email;
							}
						});
						
						let phoneN = '';
						
						datamdm[0].phones.forEach(phoneNumberItem => {
							console.log('phone number item');	
							console.log(phoneNumberItem);
							if (phoneNumberItem.isContactPriority === true) {
								phoneN = phoneNumberItem.numberSF;
							}
						});


						this.accountMDM = {
							Id: datamdm[0].Id,
							isMDM: true,
							isSF: false,
							name: sname,
							firstName: datamdm[0].inhabitant.firstName,
							lastName: datamdm[0].inhabitant.lastName,
							nif: nif,
							phone: phoneN,
							email: emailAddress,
							clientNumber: datamdm[0].clientNumber,
							updatedAt: formatter.format(Date.parse(datamdm[0].updatedAt)),
							fullData: datamdm[0]
						};
					}					
	
					getContaSF({clientNumber: value.cardno}).then((data) => {			
						if(data != null) {
							console.log(data);
							this.AccId = data.Id;
							if(data.RecordTypeId === this.personAccountRecordId.data){
								this.isPersonAccount = true;
							}			
							data.LastModifiedDate = formatter.format(Date.parse(data.LastModifiedDate));
							this.accountSF = data;
							this.accountSF.Phone = data.Phone == null || data.Phone == undefined ? data.PersonMobilePhone:data.Phone;
							if (datamdm !== null) {
								this.mdmInSF = true;
							}else{
								this.onlyInSF = true;
							}
						}else {
							this.mdmNotInSF = true;
						}
					});
				});
			}else{

				pesquisa.push(value.id);
				GetAccountsSF({Pesquisa: pesquisa, TipoPesquisa: "ID"}).then((data) => {
					this.contasMDM.every((element) => {
						if (element.clientNumber != null) {
							if(element.clientNumber.toString() === value.cardno) {
								element.updatedAt = formatter.format(Date.parse(element.updatedAt));
								this.accountMDM = element;
								return false;
							}
						}
					});
		
					if(data != null) {
						this.AccId = data[0].Id;
						if(data.RecordTypeId === this.personAccountRecordId.data){
							this.isPersonAccount = true;
						}			
						data.LastModifiedDate = formatter.format(Date.parse(data[0].LastModifiedDate));
						this.accountSF = data[0];
						this.accountSF.Phone = data[0].Phone == null || data[0].Phone == undefined ? data[0].PersonMobilePhone:data[0].Phone;
						this.onlyInSF = true;
					}else {
						this.mdmNotInSF = true;
					}
				});
			}
			
		}
	}

	navigateToRecordPage() {
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: this.AccId,
				objectApiName: "Account",
				actionName: "view"
			}
		});
	}

	newAccountSF() {
		if(this.accountSF != null) {
			let formatter = new Intl.DateTimeFormat('en-GB', {
				year: "numeric" ,
				month: "numeric",
				day: "numeric",
				hour: "2-digit",
				minute: "2-digit",
				second: "2-digit"
			});
			
			criaEditaContaSF({data: this.accountMDM.fullData, isSync: false}).then((results) => {
				this.mdmNotInSF = false;
				console.log(results);
				if(results[0] === "true") {
					if(this.accountSF != null) {
						this.showToast("Sucesso!", "A Conta foi editada!", "success");
					} else {
						this.showToast("Sucesso!", "A Conta foi criada!", "success");
					}
					this.AccId = results[1];
					this.navigateToRecordPage();
				} else{
					if(this.accountSF != null) {
						this.showToast("Erro!", "Não foi possivel editar a conta!", "error");
					} else {
						this.showToast("Erro!", "Não foi possivel criar a conta!", "error");
					}
				}
			}).catch((error) => {
				console.log(error);
				if(this.accountSF != null) {
					this.showToast("Erro!", "Não foi possivel editar a conta!", "error");
				} else {
					this.showToast("Erro!", "Não foi possivel criar a conta!", "error");
				}
			});
		} else {
			criaEditaContaSF({data: this.accountMDM.fullData, isSync: false}).then((results) => {
				this.mdmNotInSF = false;
				console.log(results);
				if(results[0] === "true") {
					if(this.accountSF != null) {
						this.showToast("Sucesso!", "A Conta foi editada!", "success");
					} else {
						this.showToast("Sucesso!", "A Conta foi criada!", "success");
					}
					this.AccId = results[1];
					this.navigateToRecordPage();
				} else{
					if(this.accountSF != null) {
						this.showToast("Erro!", "Não foi possivel editar a conta!", "error");
					} else {
						this.showToast("Erro!", "Não foi possivel criar a conta!", "error");
					}
				}
			}).catch((error) => {
				console.log(error);
				if(this.accountSF != null) {
					this.showToast("Erro!", "Não foi possivel editar a conta!", "error");
				} else {
					this.showToast("Erro!", "Não foi possivel criar a conta!", "error");
				}
			});
		}
	}

	handleChangeSeachFields(event) {
		this.searchFieldsValue = event.detail.value;
		console.log(this.searchFieldsValue);

		this.contasMDM.length = 0;
		this.BoolTableAccounts = false;
		if (this.searchFieldsValue === "NIF") {
			this.secondName = false;
			this.minLength = 9;
			this.maxLength = 9;
			this.label = "number";
		} else if (this.searchFieldsValue === "Telemóvel") {
			this.secondName = false;
			this.minLength = 9;
			this.maxLength = 9;
			this.label = "number";
		}
		else if (this.searchFieldsValue === "Nº de Cliente") {
			this.secondName = false;
			this.minLength = 1;
			this.maxLength = 8;
			this.label = "number";
		} else {
			this.secondName = false;
			this.minLength = 1;
			this.maxLength = 999;
			this.label = "text";
		}
	}

	get searchFields() {
		return [
			{ label: "NIF", value: "NIF" },
			{ label: "Contacto Telefónico", value: "Telemóvel" },
			{ label: "Email", value: "Email" },
			{ label: "Nº de Cliente", value: "Nº de Cliente" }
		];
	}

	validationEmail(email) {
		return email.match(
			/^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
		);
	}
	
	handleLastName(event) {
		this.SearchLastName = event.target.value;
	}

	onMouseOver(event) {
		event.currentTarget.style.backgroundColor = "#eaf2ff";
		event.currentTarget.style.cursor = "pointer";
	}
	onMouseOut(event) {
		event.currentTarget.style.backgroundColor = "#ffffff";
	}
}