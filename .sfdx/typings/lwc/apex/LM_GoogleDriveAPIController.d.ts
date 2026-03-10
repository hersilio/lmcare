declare module "@salesforce/apex/LM_GoogleDriveAPIController.uploadFile" {
  export default function uploadFile(param: {file: any, filename: any, filetype: any, folderId: any}): Promise<any>;
}
declare module "@salesforce/apex/LM_GoogleDriveAPIController.getLinkFromFile" {
  export default function getLinkFromFile(param: {fileId: any}): Promise<any>;
}
declare module "@salesforce/apex/LM_GoogleDriveAPIController.getGDriveParentId" {
  export default function getGDriveParentId(param: {parentFolder: any}): Promise<any>;
}
declare module "@salesforce/apex/LM_GoogleDriveAPIController.getGDriveFolderId" {
  export default function getGDriveFolderId(param: {folderName: any, parentFolder: any}): Promise<any>;
}
