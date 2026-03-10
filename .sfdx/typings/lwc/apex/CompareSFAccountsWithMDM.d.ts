declare module "@salesforce/apex/CompareSFAccountsWithMDM.CompareAccounts" {
  export default function CompareAccounts(param: {IdConta: any}): Promise<any>;
}
declare module "@salesforce/apex/CompareSFAccountsWithMDM.getParameters" {
  export default function getParameters(param: {IdConta: any}): Promise<any>;
}
declare module "@salesforce/apex/CompareSFAccountsWithMDM.updateAccountSf" {
  export default function updateAccountSf(param: {clientMDM: any, AccountIdToUpdate: any}): Promise<any>;
}
declare module "@salesforce/apex/CompareSFAccountsWithMDM.ListAccountsWithSameId" {
  export default function ListAccountsWithSameId(param: {AccountId: any}): Promise<any>;
}
