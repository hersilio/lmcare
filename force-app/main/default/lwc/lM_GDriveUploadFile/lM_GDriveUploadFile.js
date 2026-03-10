import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import uploadFile from "@salesforce/apex/LM_GoogleDriveAPIController.uploadFile";
import getLinkFromFile from "@salesforce/apex/LM_GoogleDriveAPIController.getLinkFromFile";
import createUrl from "@salesforce/apex/LM_GDriveUrlController.createUrl";
import getFolderIdFromCurrentUser from "@salesforce/apex/LM_GDriveUrlController.getFolderIdFromCurrentUser";
import RECORD_TYPE_NAME from "@salesforce/schema/Order.Record_Type_API_Name__c";

export default class LM_GDriveUploadFile extends LightningElement {
  @api recordId;
  currentOrder;
  processId;

  @wire(getRecord, { recordId: "$recordId", fields: [RECORD_TYPE_NAME] })
  wiredRecord({ error, data }) {
    if (error) {
      let message = "Unknown error";
      if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        message = error.body.message;
      }
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Sending File",
          message,
          variant: "error"
        })
      );
    } else if (data) {
      this.currentOrder = data;
      console.log(data);
    }
  }

  fileData;

  async openfileUpload(event) {
    const file = event.target.files[0];
    let reader = new FileReader();
    const orderRecType = getFieldValue(this.currentOrder, RECORD_TYPE_NAME);
    console.log(orderRecType);
    const folderId = await getFolderIdFromCurrentUser({
            orderRecordType: orderRecType
        });

    reader.onload = () => {
      let base64 = reader.result.split(",")[1];
      this.fileData = {
        file: base64,
        filename: file.name,
        filetype: "pdf",
        folderId: folderId
      };
      console.log(this.fileData);
    };
    reader.readAsDataURL(file);
  }

  async handleClick() {
    let fileId = await uploadFile(this.fileData);
    console.log("FileId: " + fileId);
    let title = `${this.fileData.filename} uploaded successfully!!!`;
    this.toast(title);

    let fileUrl = await getLinkFromFile({ fileId: fileId });
    console.log("FileUrl: " + fileUrl);
    createUrl({
      filename: this.fileData.filename,
      url: fileUrl,
      orderId: this.recordId
    });
    this.fileData = undefined;
  }

  toast(title) {
    const toastEvent = new ShowToastEvent({
      title,
      variant: "success"
    });
    this.dispatchEvent(toastEvent);
  }
}