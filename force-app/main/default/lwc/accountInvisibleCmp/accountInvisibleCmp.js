import { LightningElement, api } from "lwc";
import CompareAccounts from "@salesforce/apex/CompareSFAccountsWithMDM.CompareAccounts";

export default class AccountInvisibleCmp extends LightningElement {
	@api recordId;

	connectedCallback() {
		console.log("Entrei no cmp");
		console.log("Entrei no cmp valor do record Id: " + this.recordId);

		CompareAccounts({
			IdConta: this.recordId
		}).then(() => {
			eval("$A.get('e.force:refreshView').fire();");
		});
	}
}