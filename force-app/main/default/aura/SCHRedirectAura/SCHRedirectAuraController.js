({
    init: function(component, event, helper) {
       // for Display Model,set the "isOpen" attribute to "true"
       component.set("v.isOpen", true);
       var flow = component.find('flow');
       var inputVariables = [
        {
         name : "recordID",
         type : "flowDataType",
         value : component.get("v.recordId")
     
       }
     ];
       flow.startFlow('SCH_ServiceAppointmentCancel');
 
    },
 
    closeModel: function(component, event, helper) {
       // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
       component.set("v.isOpen", false);
    },
 
   
 })