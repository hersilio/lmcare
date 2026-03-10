declare module "@salesforce/apex/c_PesquisaConta.getAccountsSF" {
  export default function getAccountsSF(param: {Pesquisa: any, TipoPesquisa: any}): Promise<any>;
}
declare module "@salesforce/apex/c_PesquisaConta.getAccountsMdm" {
  export default function getAccountsMdm(param: {Pesquisa: any, TipoPesquisa: any}): Promise<any>;
}
declare module "@salesforce/apex/c_PesquisaConta.getAccountSF" {
  export default function getAccountSF(param: {clientNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/c_PesquisaConta.upsertAccountSF" {
  export default function upsertAccountSF(param: {data: any, isSync: any}): Promise<any>;
}
declare module "@salesforce/apex/c_PesquisaConta.getToken" {
  export default function getToken(): Promise<any>;
}
declare module "@salesforce/apex/c_PesquisaConta.GetPersonRecordTypeId" {
  export default function GetPersonRecordTypeId(): Promise<any>;
}
declare module "@salesforce/apex/c_PesquisaConta.GetProfissionalRecordTypeId" {
  export default function GetProfissionalRecordTypeId(): Promise<any>;
}
