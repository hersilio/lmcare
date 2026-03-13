public with sharing class SCH_ServiceAppointmentCreateOnlineCtrl {
    
    public ServiceAppointment sa { get; private set; }
    
    private Boolean dataLoaded = false;
    
    // Setter que dispara o carregamento quando recebe valor
    private String saIdBacking;
    public String saIdVariable {
        get { return saIdBacking; }
        set {
            saIdBacking = value;
            if (!String.isBlank(saIdBacking)) {
                ensureDataLoaded();
            }
        }
    }
    
    public String AccountName { get; private set; }
    public String ProjectName { get; private set; }
    public String ProjectDisplayName { get; private set; }
    public String StartSchedule { get; private set; }
    public String ServiceTerritory { get; private set; }
    public String ServiceResourceName { get; private set; }
    public String GoogleICSUrl { get; private set; }
    public String GoogleMeetUrl { get; private set; }
    public String RequirementsHtml { get; private set; }
    public String BringWithYou { get; private set; }
    public Decimal AppointmentSize { get; private set; }
    public Boolean isOnline { get; private set; }
    public Boolean isNotCancel { get; private set; }

    public String CalendarLabel {get; private set; }
    public String ProjectDetailsLabel {get; private set; }
    public String SupportLabel {get; private set; }

    // WorkType obtido do ServiceAppointment; precisa ser instância, não estático
    private WorkType wt;

    private void ensureDataLoaded() {
        if (dataLoaded) return;
        if (String.isBlank(saIdBacking)) {
            // Fallback mínimo quando não há Id
            AccountName = 'Cliente';
            dataLoaded = true;
            return;
        }
        
        try {
            // Query ServiceAppointment
            sa = [
                SELECT Id, AccountId, ContactId, ParentRecordId, WorkTypeId, EngagementChannelType.Name, 
                       SCH_StartSchedule__c, SCH_Google_ICS__c, SCH_Google_Meet_URL__c, ServiceTerritory.Name,
                       SCH_Service_Resource__r.Name, Status, AppointmentNumber
                FROM ServiceAppointment
                WHERE Id = :saIdBacking
                LIMIT 1
            ];

            // Determinar parent record (Account ou Lead)
            Id parentRecordId = sa.AccountId != null ? sa.AccountId : sa.ParentRecordId;
            
            if (parentRecordId != null) {
                if (parentRecordId.getSObjectType() == Account.sObjectType) {
                    Account acct = [SELECT Name FROM Account WHERE Id = :parentRecordId LIMIT 1];
                    AccountName = acct.Name;
                } else if (parentRecordId.getSObjectType() == Lead.sObjectType) {
                    Lead lead = [SELECT FirstName, LastName FROM Lead WHERE Id = :parentRecordId LIMIT 1];
                    AccountName = ((lead.FirstName != null ? lead.FirstName + ' ' : '') + (lead.LastName != null ? lead.LastName : '')).trim();
                    if (String.isBlank(AccountName)) AccountName = 'Cliente';
                } else if(parentRecordId.getSObjectType() == Contact.sObjectType) {
                    Contact contact = [SELECT FirstName, LastName FROM Contact WHERE Id = :parentRecordId LIMIT 1];
                    AccountName = ((contact.FirstName != null ? contact.FirstName + ' ' : '') + (contact.LastName != null ? contact.LastName : '')).trim();
                }
            } else {
                AccountName = 'Cliente';
            }
            
            // Campos do ServiceAppointment
            StartSchedule = formatDateTimeForUser(sa.SCH_StartSchedule__c);
            ServiceTerritory = sa.ServiceTerritory.Name;
            ServiceResourceName = sa.SCH_Service_Resource__r.Name;
            GoogleICSUrl = sa.SCH_Google_ICS__c;
            GoogleMeetUrl = sa.SCH_Google_Meet_URL__c;
            
             // Buscar WorkType e Metadata
            if (sa.WorkTypeId != null) {

                wt = [SELECT Name FROM WorkType WHERE Id = :sa.WorkTypeId LIMIT 1];
                
                Appointment_Email_Config__mdt config = [SELECT Project_Display_Name__c, Requirements__c, Appointment_Size__c, Category__c
                                                        FROM Appointment_Email_Config__mdt
                                                        WHERE WorkTypeName__c = :wt.Name AND Email_Status__c = :sa.Status LIMIT 1];
                
                ProjectName = config.Category__c;
                ProjectDisplayName = config.Project_Display_Name__c;
                RequirementsHtml = config.Requirements__c;
                AppointmentSize = config.Appointment_Size__c;

                // Definir a label "BringWithYou" dependendo do WorkType/Projeto
                if(config.Requirements__c != null){
                    BringWithYou = labelBringWithYou(wt, ProjectDisplayName);
                }
            }

            isOnline = sa.EngagementChannelType != null && sa.EngagementChannelType.Name != 'Presencial';

            ProjectDetailsData pdd = new ProjectDetailsData(ProjectName, String.valueOf(StartSchedule), ServiceResourceName, ServiceTerritory, String.valueOf(sa.AppointmentNumber));

            ProjectDetailsLabel = labelProjectDetails(isOnline, sa.Status, pdd);
            CalendarLabel = wt.Name == 'WC' ? labelCalendar('Appointment') : labelCalendar('Schedule');
            SupportLabel = labelSupport(sa.Status);

            System.debug('Status: ' + sa.Status);
            isNotCancel = sa.Status != 'Canceled' ? true : false;

            dataLoaded = true;
        } catch (Exception e) {
            // Fallback seguro sem logs de debug em produção
            AccountName = 'Cliente';
            dataLoaded = true;
        }
    }

    // Helper para formatar DateTime no padrão dd/MM/aaaa HH:mm no fuso/locale do usuário
    private static String formatDateTimeForUser(Datetime dt) {
        if (dt == null) return '';
        // Converter para o timezone do usuário e formatar
        return dt.format('dd/MM/yyyy HH:mm', UserInfo.getLocale());
    }

    private static String projectNameSplit(String name){
        if(name == null) return '';
        List<String> parts = name.split('-');
        if(parts.size() > 1){
            if(parts[1].trim() == 'WC'){
                return parts[0].trim() + ' de Casa de Banho';
            } else {
                return parts[0].trim() + ' de ' + parts[1].trim();
            }
        }else {
            return 'Projeto';
        }
    }

    // Retorna a label de "o que trazer", evitando uso de estado estático
    private static String labelBringWithYou(WorkType workType, String projectDisplayName){
        if (workType != null && (workType.Name == 'Projeto 2 ou mais divisões (Cozinha, WC e/ou Roupeiro)' || workType.Name == 'Projeto - Janelas')) {
            return 'Para assegurar um planeamento ajustado ao espaço dos seus sonhos, tenha consigo:';
        }
        return 'Para assegurar que temos toda a informação para projetar ' + (projectDisplayName != null ? projectDisplayName : 'o seu projeto') + ', traga consigo:';
    }

    //Returns the label for calendar section
    private static String labelCalendar(String calendarType){
        //Marcação
        if(calendarType == 'Schedule'){
            return 'Para adicionar a marcação ';
        //Agendamento
        } else if(calendarType == 'Appointment'){
            return 'Caso pretenda adicionar este agendamento ';
        }
        return '';
    }

     //Returns the label for project details section
    private static String labelProjectDetails(Boolean isOnline, String Status, ProjectDetailsData pdd){

        if(Status == 'Scheduled'){ //Create
            String projectName = pdd.ProjectName != null ? 'para o projecto de ' + pdd.ProjectName : ' ';
            String st = projectName + ' para o dia ' +  pdd.StartSchedule + ', com ' + pdd.ServiceResourceName;
            if(!isOnline){
                return 'Confirmamos o seu agendamento ' + st + ' na loja Leroy Merlin ' + pdd.ServiceTerritory + '.';
            } else {
                return 'Confirmamos o seu agendamento online ' + st + '.';
            }
        } else if(Status == 'Scheduled - Updated' || Status == 'Canceled'){ //Update

                String st = 'Informamos que o seu agendamento do projeto de ' + (Status != 'Canceled' ? pdd.ProjectName + ' - ' : '') + pdd.ServiceAppointmentNumber + ', ';

                String stUpdate = 'foi alterado para o dia ' + pdd.StartSchedule + ', com ' + pdd.ServiceResourceName + (!isOnline ? ' na loja Leroy Merlin ' + pdd.ServiceTerritory + '.' : '.' ) ;
                String stCancel = 'marcado para o dia ' + pdd.StartSchedule + ' foi cancelado.';
                
                return st + (Status == 'Scheduled - Updated' ? stUpdate : stCancel);
        }

        return '';
    }

     //Returns the label for calendar section
    private static String labelSupport(String Status){
        //Marcação
        if(Status == 'Scheduled'){
            return 'Se precisar de alterar ou cancelar o seu agendamento, ligue para a nossa linha de apoio ao cliente: 211 944 944 (Chamada para a rede fixa nacional)';
        //Agendamento
        } else if(Status == 'Scheduled - Updated' || Status == 'Canceled'){
            return 'Se necessitar de algum esclarecimento adicional poderá contactar-nos através do Apoio ao Cliente: 211944944 (Chamada para a rede fixa nacional) ';
        }
        return '';
    }
    
    // Getter para uso em Visualforce: expõe se foi criado online
    public Boolean getIsCreatedOnline() { 
        return isOnline && sa != null && (sa.Status == 'Scheduled' || sa.Status == 'Scheduled - Updated'); 
    }

    public class ProjectDetailsData{
        public String ProjectName;
        public String StartSchedule;
        public String ServiceResourceName;
        public String ServiceTerritory;
        public String ServiceAppointmentNumber;
        
        /**
         * Constructs a ProjectDetailsData holder.
         * @param projectName Name of the project/category
         * @param startSchedule Formatted start schedule string
         * @param serviceResourceName Name of the assigned resource
         * @param serviceTerritory Name of the service territory/store
         * @param serviceAppointmentNumber Appointment number reference
         */
        public ProjectDetailsData(String projectName, String startSchedule, String serviceResourceName, String serviceTerritory, String serviceAppointmentNumber){
            this.ProjectName = projectName;
            this.StartSchedule = startSchedule;
            this.ServiceResourceName = serviceResourceName;
            this.ServiceTerritory = serviceTerritory;
            this.ServiceAppointmentNumber = serviceAppointmentNumber;
        }
    }

    // Getters
    public String getAccountName() { ensureDataLoaded(); return AccountName; }
    public String getProjectName() { ensureDataLoaded(); return ProjectName; }
    public String getProjectDisplayName() { ensureDataLoaded(); return ProjectDisplayName; }
    public String getStartSchedule() { ensureDataLoaded(); return StartSchedule; }
    public String getServiceResourceName() { ensureDataLoaded(); return ServiceResourceName; }
    public String getGoogleICSUrl() { ensureDataLoaded(); return GoogleICSUrl; }
    public String getGoogleMeetUrl() { ensureDataLoaded(); return GoogleMeetUrl; }
    public String getRequirementsHtml() { ensureDataLoaded(); return RequirementsHtml; }
}