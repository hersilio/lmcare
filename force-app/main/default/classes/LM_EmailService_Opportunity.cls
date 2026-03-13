global class LM_EmailService_Opportunity implements Messaging.InboundEmailHandler {
    
    // Wrapper para devolver o registro relacionado e o EmailMessage original
    private class EmailLookupResult {
        Id relatedToId;
        Id originalEmailMessageId; // Email que foi enviado do Salesforce e ao qual estamos respondendo
    }
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,Messaging.InboundEnvelope envelope) {
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            // 1. Extrair ThreadIdentifier do email (Message-ID ou In-Reply-To)
            String threadId = extractThreadIdentifier(email, envelope);
            
            // 2. Encontrar registro relacionado e EmailMessage original pelo Thread ID
            EmailLookupResult lookup = findRelatedByThreadId(threadId);
            
            // 3. Se encontrou por ThreadId, associa ao registro encontrado; caso contrário, cria Lead de imediato
            if (lookup != null && lookup.relatedToId != null) {
                createEmailMessage(email, envelope, lookup.relatedToId, lookup.originalEmailMessageId);
                // Enviar notificação ao remetente do email original, indicando que há uma resposta associada ao registo
                notifyOriginalSenderOfReply(lookup.originalEmailMessageId, lookup.relatedToId);
                result.success = true;
                result.message = 'Email processado e associado ao registro: ' + lookup.relatedToId;
            } else {
                // Sem lookup (inclui casos sem ThreadId ou ThreadId não encontrado): criar imediatamente uma nova Lead e associar o email
                Lead newLead = createLeadFromEmail(email);
                createEmailMessage(email, envelope, newLead.Id, null);
                result.success = true;
                result.message = 'Email processado. Nova Lead criada e atribuída à queue LM_Email_Leads. Lead Id: ' + newLead.Id;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Erro ao processar email: ' + e.getMessage();
            System.debug('Email Service Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return result;
    }
    
    private String extractThreadIdentifier(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        if (email.headers != null) {
            for (Messaging.InboundEmail.Header header : email.headers) {
                if (header.name.equalsIgnoreCase('References') && header.value != null) {
                    // Pode haver vários IDs separados por espaço ou quebras de linha
                    List<String> references = header.value.split('\\s+');
                    
                    for (String ref : references) {
                        // Opcional: limpar caracteres especiais se existirem
                        ref = ref.trim();
                        if (!String.isBlank(ref)) {
                            return ref; // Retorna o primeiro ID válido
                        }
                    }
                }
            }
            // Fallback para In-Reply-To se References não encontrado
            for (Messaging.InboundEmail.Header header : email.headers) {
                if (header.name.equalsIgnoreCase('In-Reply-To') && header.value != null) {
                    return header.value.trim();
                }
            }
            // Fallback para Message-ID
            for (Messaging.InboundEmail.Header header : email.headers) {
                if (header.name.equalsIgnoreCase('Message-ID') && header.value != null) {
                    return header.value.trim();
                }
            }
        }
        return null;
    }
    
    private EmailLookupResult findRelatedByThreadId(String threadId) {
        if (String.isBlank(threadId)) return null;
        
        // 1) Tentar encontrar EmailMessage com RelatedToId já definido (caso padrão)
        List<EmailMessage> relatedEmails = [
            SELECT Id, RelatedToId
            FROM EmailMessage 
            WHERE ThreadIdentifier = :threadId 
            AND RelatedToId != null
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!relatedEmails.isEmpty()) {
            EmailLookupResult res = new EmailLookupResult();
            res.relatedToId = relatedEmails[0].RelatedToId;
            res.originalEmailMessageId = relatedEmails[0].Id;
            return res;
        }

        // 2) Se não existir RelatedToId no EmailMessage original, verificar se o original tem recetor (recipient) do tipo Lead
        // Procurar o EmailMessage pelo ThreadIdentifier (sem exigir RelatedToId) e depois verificar recipients
        List<EmailMessage> originalEmails = [
            SELECT Id
            FROM EmailMessage
            WHERE ThreadIdentifier = :threadId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (originalEmails.isEmpty()) return null;

        Id originalId = originalEmails[0].Id;

        // Verificar relações do EmailMessage (Sender/Recipients) e procurar um recipient Lead
        List<EmailMessageRelation> relations = [
            SELECT Id, RelationId, RelationType
            FROM EmailMessageRelation
            WHERE EmailMessageId = :originalId
        ];

        for (EmailMessageRelation r : relations) {
            // Considerar destinatários (ToAddress, CcAddress, BccAddress).
            // Não é possível filtrar pelo sObjectType diretamente; validaremos mais abaixo após tentar carregar o registro.
            if (r.RelationType == 'ToAddress' || r.RelationType == 'CcAddress' || r.RelationType == 'BccAddress') {
                if (r.RelationId != null) {
                    // Tentar encontrar Lead por Id
                    Lead leadCandidate = [SELECT Id FROM Lead WHERE Id = :r.RelationId LIMIT 1];
                    if (leadCandidate != null) {
                        EmailLookupResult res = new EmailLookupResult();
                        res.relatedToId = leadCandidate.Id; // Associar à Lead encontrada nos recipients
                        res.originalEmailMessageId = originalId;
                        return res;
                    }
                }
            }
        }

        // 3) Caso não tenha recipients de Lead, como fallback verificar se o Sender é Lead
        for (EmailMessageRelation r : relations) {
            if (r.RelationType == 'FromAddress' && r.RelationId != null) {
                // Verificar se o sender é Lead
                Lead senderLead = [SELECT Id FROM Lead WHERE Id = :r.RelationId LIMIT 1];
                if (senderLead != null) {
                    EmailLookupResult res = new EmailLookupResult();
                    res.relatedToId = senderLead.Id;
                    res.originalEmailMessageId = originalId;
                    return res;
                }
            }
        }

        return null;
    }
    
    private Id findRelatedRecordByEmail(String senderEmail) {
        // Buscar Contact pelo email do remetente
        List<Contact> contacts = [
            SELECT AccountId 
            FROM Contact 
            WHERE Email = :senderEmail 
            LIMIT 1
        ];
        
        if (!contacts.isEmpty()) {
            // Buscar Opportunity relacionada ao Account mais recente
            List<Opportunity> opps = [
                SELECT Id 
                FROM Opportunity 
                WHERE AccountId = :contacts[0].AccountId
                AND IsClosed = false
                ORDER BY CreatedDate DESC
                LIMIT 1
                ];
            return opps.isEmpty() ? contacts[0].AccountId : opps[0].Id;
        }
        return null;
    }
    
    private void createEmailMessage(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope, Id relatedId, Id replyToEmailMessageId) {
        // Prevenção contra nulos
        String subject = (email.subject != null) ? email.subject : '(No Subject)';
        String fromAddress = (email.fromAddress != null) ? email.fromAddress : 'unknown@unknown.com';
        String toAddress = (envelope.toAddress != null) ? envelope.toAddress : 'unknown@unknown.com';
        String htmlBody = (email.htmlBody != null) ? email.htmlBody : (email.plainTextBody != null ? email.plainTextBody : '(No Body)');
        String textBody = (email.plainTextBody != null) ? email.plainTextBody : '(No Text Body)';

        // Registar anexos e flags
        List<Messaging.InboundEmail.BinaryAttachment> attachments = email.binaryAttachments;
        Boolean hasAttachments = (attachments != null && !attachments.isEmpty());

        // Determinar se o relatedId é uma Lead. Se for, NÃO podemos usar RelatedToId = Lead.
        // Em vez disso, deixamos RelatedToId a null e criamos EmailMessageRelation para associar ao Lead como destinatário/remetente.
        Id leadIdIfAny = null;
        if (relatedId != null) {
            // Tentar identificar se é Lead (consulta segura)
            try {
                Lead l = [SELECT Id FROM Lead WHERE Id = :relatedId LIMIT 1];
                if (l != null) {
                    leadIdIfAny = l.Id;
                }
            } catch (Exception ex) {
                // Ignorar: not a Lead
            }
        }

        EmailMessage emailMsg = new EmailMessage(
            RelatedToId = (leadIdIfAny == null ? relatedId : null),
            ReplyToEmailMessageId = replyToEmailMessageId,
            FromAddress = fromAddress,
            ToAddress = 'lmcare@leroymerlin.pt',
            Subject = subject,
            HtmlBody = htmlBody,
            TextBody = textBody,
            Incoming = true,
            Status = '1' // Novo
        );

        insert emailMsg;

        // Se o relatedId for Lead, relacionar o EmailMessage ao Lead através de EmailMessageRelation
        if (leadIdIfAny != null) {
            // Em mensagens recebidas, o remetente é o cliente; manteremos a semântica através de RelationType.
            // Como estamos a responder/associar a uma thread, criaremos uma relação genérica com a Lead.
            EmailMessageRelation rel = new EmailMessageRelation(
                EmailMessageId = emailMsg.Id,
                RelationId = leadIdIfAny,
                RelationType = 'FromAddress' // Para incoming, o registro geralmente aparece como destinatário (ajuste conforme necessidade)
            );
            insert rel;
        }

        // Se existir Contact correspondente ao remetente, criar a relação via EmailMessageRelation
        else if (!String.isBlank(fromAddress)) {
            List<Contact> cts = [
                SELECT Id 
                FROM Contact 
                WHERE Email = :fromAddress 
                LIMIT 1
            ];
            if (!cts.isEmpty()) {
                EmailMessageRelation emr = new EmailMessageRelation(
                    EmailMessageId = emailMsg.Id,
                    RelationId = cts[0].Id,
                    RelationType = 'FromAddress' // Para mensagens recebidas (Incoming=true), o Contact é o remetente
                );
                insert emr;
            }
        }

        if (hasAttachments) {
            processAttachments(emailMsg.Id, attachments);
        }
    }
    
    private void processAttachments(Id emailMsgId, List<Messaging.InboundEmail.BinaryAttachment> attachments) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        for (Messaging.InboundEmail.BinaryAttachment attachment : attachments) {
            ContentVersion cv = new ContentVersion(
                Title = attachment.fileName,
            PathOnClient = attachment.fileName,
            VersionData = attachment.body,
            IsMajorVersion = true,
            ContentLocation = 'S', // Content is in Salesforce
            FirstPublishLocationId = emailMsgId // Relaciona ao EmailMessage
                );
            contentVersions.add(cv);
        }
        
        if (!contentVersions.isEmpty()) {
            insert contentVersions;
        }
    }
    
    // Obter Id da Queue por DeveloperName
    private Id getEmailLeadsQueueId() {
        List<Group> qs = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'LM_Email_Leads'
            LIMIT 1
        ];
        return qs.isEmpty() ? null : qs[0].Id;
    }
    
    // Criar Lead a partir do email recebido e atribuir à queue LM_Email_Leads
    private Lead createLeadFromEmail(Messaging.InboundEmail email) {
        String fromAddress = (email.fromAddress != null) ? email.fromAddress.trim() : null;
        String subject = (email.subject != null) ? email.subject : '(No Subject)';
        String textBody = (email.plainTextBody != null) ? email.plainTextBody :
            ((email.htmlBody != null) ? email.htmlBody : '(No Body)');
        
        // Extrair nome do remetente a partir do header "From" quando disponível
        String displayName = extractDisplayNameFromFromHeader(email);
        String firstName;
        String lastName;
        
        if (!String.isBlank(displayName)) {
            // Separar em FirstName e LastName com heurística simples: último token = lastName
            List<String> tokens = displayName.split('\\s+');
            if (tokens.size() == 1) {
                lastName = tokens[0];
            } else {
                lastName = tokens.remove(tokens.size() - 1);
                firstName = String.join(tokens, ' ');
            }
        }
        
        // Se não obteve nome do header, derivar LastName a partir do email
        if (String.isBlank(lastName)) {
            lastName = 'Inbound';
            if (!String.isBlank(fromAddress) && fromAddress.contains('@')) {
                lastName = fromAddress.substringBefore('@');
            }
        }
        
        Lead ld = new Lead();
        ld.LastName = String.isBlank(lastName) ? 'Inbound' : lastName;
        if (!String.isBlank(firstName)) ld.FirstName = firstName;
        if (!String.isBlank(fromAddress)) ld.Email = fromAddress;
        ld.LeadSource = 'Email';
        ld.Title = subject;
        // ld.Description = textBody;
        ld.Canal_de_Interacao__c = 'Email';
        ld.cliente_existente__c = isAlreadyClient(fromAddress);
        Id qId = getEmailLeadsQueueId();
        if (qId != null) {
            ld.OwnerId = qId;
        }
        
        Database.SaveResult sr = Database.insert(ld, AccessLevel.USER_MODE);
        if (!sr.isSuccess()) {
            // Reunir mensagens de erro de forma segura
            String errMsg = 'Falha ao criar Lead.';
            if (sr.getErrors() != null && sr.getErrors().size() > 0 && sr.getErrors()[0] != null) {
                errMsg += ' ' + sr.getErrors()[0].getMessage();
            }
            // Lançar exceção para o handler superior capturar
            throw new AuraHandledException(errMsg);
        }
        
        // Atribuir à Queue se existir
        // Id qId = getEmailLeadsQueueId();
        // if (qId != null) {
        //     ld.OwnerId = qId;
        //     Database.update(ld, AccessLevel.USER_MODE);
        // }
        
        return ld;
    }
    
    // Extrai o display name do header "From" (ex.: "João Silva" <joao@exemplo.com>)
    private String extractDisplayNameFromFromHeader(Messaging.InboundEmail email) {
        if (email == null || email.headers == null) return null;
        for (Messaging.InboundEmail.Header header : email.headers) {
            if (header != null && header.name != null && header.name.equalsIgnoreCase('From') && header.value != null) {
                String raw = header.value.trim();
                // Remover a parte <...> se existir
                Integer lt = raw.indexOf('<');
                if (lt > 0) {
                    String candidate = raw.substring(0, lt).trim();
                    // Remover aspas se existirem
                    if (candidate.startsWith('"') && candidate.endsWith('"') && candidate.length() >= 2) {
                        candidate = candidate.substring(1, candidate.length()-1);
                    }
                    if (!String.isBlank(candidate)) return candidate;
                }
                // Se não houver <..>, tentar separar por endereço
                // Alguns provedores podem enviar apenas o email; nesse caso retorna null
                if (raw.contains('@')) {
                    return null;
                }
                // Caso seja apenas um nome sem email
                if (!String.isBlank(raw)) return raw;
            }
        }
        return null;
    }

    // Notifica via email o Owner do EmailMessage original (origEmailId) que existe uma resposta ligada ao registo (relatedId)
    private void notifyOriginalSenderOfReply(Id origEmailId, Id relatedId) {
        if (origEmailId == null) return;

        // Carregar o EmailMessage original com Owner e metadados
        EmailMessage orig = [
            SELECT Id, Subject, MessageDate, RelatedToId, CreatedById
            FROM EmailMessage
            WHERE Id = :origEmailId
            LIMIT 1
        ];

        // Resolver email do Owner (User)
        String recipient;
        if (orig.CreatedById != null) {
            try {
                User u = [SELECT Id, Email FROM User WHERE Id = :orig.CreatedById LIMIT 1];
                if (u != null) recipient = u.Email;
            } catch (Exception ignoreUser) {}
        }
        if (String.isBlank(recipient)) return; // Sem destinatário válido, não enviar

        // Construir subject e corpo da notificação com contexto do registo
        String relatedInfo = '';
        if (relatedId != null) {
            try {
                if (Schema.sObjectType.Opportunity.isAccessible()) {
                    Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :relatedId LIMIT 1];
                    if (opp != null) relatedInfo = 'Oportunidade: ' + opp.Name;
                }
            } catch (Exception ignoreOpp) {}
            if (String.isBlank(relatedInfo)) {
                try {
                    if (Schema.sObjectType.Case.isAccessible()) {
                        Case cs = [SELECT Id, CaseNumber FROM Case WHERE Id = :relatedId LIMIT 1];
                        if (cs != null) relatedInfo = 'Caso: ' + cs.CaseNumber;
                    }
                } catch (Exception ignoreCase) {}
            }
            if (String.isBlank(relatedInfo)) {
                try {
                    Lead ld = [SELECT Id, Name FROM Lead WHERE Id = :relatedId LIMIT 1];
                    if (ld != null) relatedInfo = 'Lead: ' + ld.Name;
                } catch (Exception ignoreLead) {}
            }
            if (String.isBlank(relatedInfo)) {
                try {
                    Account acc = [SELECT Id, Name FROM Account WHERE Id = :relatedId LIMIT 1];
                    if (acc != null) relatedInfo = 'Conta: ' + acc.Name;
                } catch (Exception ignoreAcc) {}
            }
            if (String.isBlank(relatedInfo)) relatedInfo = 'Registo relacionado (' + String.valueOf(relatedId) + ')';
        }

        // Construir URL direto para o registo (Lightning)
        String recordUrl = buildRecordUrl(relatedId);

        // Tentar melhorar o rótulo se ficou genérico
        String entityLabel = guessRecordLabelByPrefix(relatedId);
        if (!String.isBlank(relatedInfo) && relatedInfo.startsWith('Registo relacionado') && !String.isBlank(entityLabel)) {
            relatedInfo = entityLabel + ' (' + String.valueOf(relatedId) + ')';
        }

        String notifSubject = 'Tem uma nova resposta relacionada - ' + relatedInfo;
        String baseSubject = String.isBlank(orig.Subject) ? '(Sem assunto)' : orig.Subject;
        String notifBody = 'Olá,'
            + '\n\nFoi recebida uma resposta relacionada ao email "' + baseSubject + '".'
            + '\n' + (String.isBlank(relatedInfo) ? 'Registo relacionado.' : ('Registo: ' + relatedInfo));
        if (!String.isBlank(recordUrl)) {
            notifBody += '\nURL do registo: ' + recordUrl;
        }
        notifBody += '\nData do email original: ' + (orig.MessageDate != null ? String.valueOf(orig.MessageDate) : 'N/D')
            + '\n\nEsta é uma notificação automática.';

        // Enviar email ao Owner do EmailMessage original
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { recipient });
        mail.setSubject(notifSubject);
        mail.setPlainTextBody(notifBody);
        // Definir remetente através de uma Organization-Wide Email Address (OWEA) verificada
        // TODO: Substituir pelo Id real da OWEA na org (Setup -> Organization-Wide Addresses)
        // Recomenda-se parametrizar via Custom Metadata/Setting em vez de hardcode.
        // Exemplo temporário (deixe vazio até definir o Id real):
        Id oweaId = '0D2Ae0000000MADKA2'; 
        if (oweaId != null) mail.setOrgWideEmailAddressId(oweaId);
        try {
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }, false);
            // Logar resultado do envio
            if (r != null && r.size() > 0) {
                for (Messaging.SendEmailResult ser : r) {
                    System.debug(LoggingLevel.INFO, 'NotifyOriginalSenderOfReply - Envio email: success=' + ser.isSuccess() + 
                        ', errors=' + (ser.getErrors() != null && ser.getErrors().size() > 0 ? ser.getErrors()[0].getMessage() : 'none'));
                }
            } else {
                System.debug(LoggingLevel.WARN, 'NotifyOriginalSenderOfReply - Resultado de envio vazio ou nulo');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'NotifyOriginalSenderOfReply - Falha ao enviar email: ' + e.getMessage());
            // Não interromper o fluxo por falha na notificação
        }

        // Enviar também Custom Notification (In-App) ao mesmo utilizador, usando CustomNotificationType
        try {
            if (orig.CreatedById != null) {
                // Obter o Notification Type pelo DeveloperName (API Name)
                CustomNotificationType notificationType = [
                    SELECT Id, DeveloperName 
                    FROM CustomNotificationType 
                    WHERE DeveloperName = 'Nova_Lead_por_Email'
                    LIMIT 1
                ];

                // Criar notificação
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(notifSubject);
                notification.setBody(notifBody);

                // Definir o tipo e o alvo (deep link)
                if (notificationType != null) {
                    notification.setNotificationTypeId(notificationType.Id);
                }
                if (relatedId != null) {
                    notification.setTargetId(relatedId);
                }

                // Destinatários (CustomNotification.send requer Set<String> de User Ids)
                Set<String> recipientIds = new Set<String>();
                recipientIds.add(String.valueOf(orig.CreatedById));

                // Enviar
                try {
                    notification.send(recipientIds);
                } catch (Exception sendEx) {
                    System.debug(LoggingLevel.ERROR, 'NotifyOriginalSenderOfReply - Falha ao enviar Custom Notification: ' + sendEx.getMessage());
                }
            }
        } catch (Exception cnExOuter) {
            System.debug(LoggingLevel.ERROR, 'NotifyOriginalSenderOfReply - Erro ao preparar Custom Notification: ' + cnExOuter.getMessage());
        }
    }

    private boolean isAlreadyClient(String email) {
        List<Account> accs = [SELECT Id FROM Account WHERE PersonEmail = :email LIMIT 1];
        
        return !accs.isEmpty();
    }

    // Constrói URL absoluto para a página Lightning do registo
    private String buildRecordUrl(Id recordId) {
        if (recordId == null) return null;
        // URL do domínio da org (compatível com Prod/Sandbox/Scratch)
        String base = URL.getOrgDomainUrl().toExternalForm();
        // Network.getDomainUrl() não existe; não usar. Caso base venha vazio (improvável), retornamos null.
        // Alternativas seriam usar Site.getDomain() em contexto de Site ou Custom Setting/Metadata para override.
        if (String.isBlank(base)) {
            return null;
        }
        if (String.isBlank(base)) return null;

        // Formato robusto que resolve o objeto a partir do Id
        String path = '/lightning/r/' + String.valueOf(recordId) + '/view';
        return base + path;
    }

    // Rótulo amigável baseado no prefixo do Id
    private String guessRecordLabelByPrefix(Id recordId) {
        if (recordId == null) return 'Registo';
        String p = ((String)recordId).substring(0, 3);
        if (p == '006') return 'Oportunidade';
        if (p == '500') return 'Caso';
        if (p == '00Q') return 'Lead';
        if (p == '001') return 'Conta';
        if (p == '003') return 'Contacto';
        return 'Registo';
    }
}