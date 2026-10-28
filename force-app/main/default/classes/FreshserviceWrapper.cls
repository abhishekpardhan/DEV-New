public with sharing class FreshserviceWrapper {

    public class CreateTicketRequest {
        public String email;
        public String subject;
        public String description;
        public Integer source = 10;
        public Integer status = 2;
        public String type = 'Incident';
        public Integer workspace_id = 5;
        public Integer priority = 2;
        public Map<String, Object> custom_fields = new Map<String, Object>();
    }

    public class CreateTicketResponse {
        public Ticket ticket;
        public List<Object> articles = new List<Object>();
    }

    public class Ticket {
        public Long id;
        public Long display_id;
        public String subject;
        public String description;
        public Integer status;
        public Integer priority;
        public Integer source;
        public String type;
        public Integer workspace_id;
        public Map<String, Object> custom_fields;
    }

    public class ServiceCatalogRequest {
        public Integer itemId;
        public String email;
        public String requested_for;
        public Map<String, Object> custom_fields = new Map<String, Object>();
    }

    public class ServiceCatalogResponse {
        public ServiceRequest service_request;
    }

    public class ServiceRequest {
        public Long id;
        public Long display_id;
        public String subject;
        public Integer status;
        public Integer priority;
        public Integer workspace_id;
        public Map<String, Object> custom_fields;
    }

    public class ConversationListResponse {
        public List<Conversation> conversations;
    }

    public class ReplyRequest {
        public String body;

        public ReplyRequest(String body) {
            this.body = body;
        }
    }

    public class ReplyResponse {
        public Conversation conversation;
    }

    public class Conversation {
        public Long id;
        public Long ticket_id;
        public Long user_id;
        public String body;
        public String body_text;
        public Boolean incoming;
        public Boolean private_note;
        public Integer source;
        public String from_email;
        public String support_email;
        public List<String> to_emails;
        public List<String> cc_emails;
        public List<String> bcc_emails;
        public String created_at;
        public String updated_at;
        public List<Attachment> attachments;
    }

    public class Attachment {
        public Long id;
        public String name;
        public String file_name;
        public String attachment_url;
        public String content_type;
        public Long size;
    }

    public class CaseUpdateRequest {
        public String ticketNumber;
        public Date createdDate;
        public Map<String, Object> fields = new Map<String, Object>();
    }

    public class CaseUpdateResponse {
        public Boolean success;
        public String message;
        public Id caseId;
        public List<String> updatedFields = new List<String>();
    }
}