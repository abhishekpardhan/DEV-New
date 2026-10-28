/**
 * File upload helper for Agentforce chat LWCs (Enhanced Chat v2).
 *
 *  - uploadProofFile()  : NEW - one file per call (keeps each request inside Apex heap / request limits)
 *  - uploadChatImages() : existing multi-file method, kept for the current upload card
 *
 * Files are inserted in system mode because in Enhanced Chat the LWC runs as the site guest user.
 * Each file is linked to the Messaging Session (if provided); linking to the Case is done by
 * SafexpressPostDeliveryStatusAction.submitEscalation().
 */
public without sharing class AgentforceImageUploadController {

    private static final Set<String> ALLOWED_EXTENSIONS = new Set<String>{ 'jpg', 'jpeg', 'png', 'pdf' };

    public class FileWrapper {
        @AuraEnabled public String base64Data {get; set;}
        @AuraEnabled public String fileName {get; set;}
    }

    public class UploadException extends Exception {}

    /**
     * Uploads a single proof file and returns its ContentDocumentId.
     */
    @AuraEnabled
    public static String uploadProofFile(String fileName, String base64Data, String messagingSessionId) {
        try {
            FileWrapper file = new FileWrapper();
            file.fileName = fileName;
            file.base64Data = base64Data;

            List<String> ids = insertFiles(new List<FileWrapper>{ file }, messagingSessionId);
            return ids[0];

        } catch (Exception e) {
            throw auraError('Proof upload failed: ' + e.getMessage());
        }
    }

    /**
     * Existing method - uploads several files in one call (kept for backward compatibility).
     */
    @AuraEnabled
    public static List<String> uploadChatImages(List<FileWrapper> fileList, String messagingSessionId) {
        try {
            return insertFiles(fileList, messagingSessionId);
        } catch (Exception e) {
            throw auraError('Multiple file upload failed: ' + e.getMessage());
        }
    }

    // ---------------------------------------------------------------------

    private static List<String> insertFiles(List<FileWrapper> fileList, String messagingSessionId) {
        if (fileList == null || fileList.isEmpty()) {
            throw new UploadException('No files provided for upload.');
        }

        // 1. Prepare ContentVersion records
        List<ContentVersion> cvList = new List<ContentVersion>();
        for (FileWrapper file : fileList) {
            if (file == null || String.isBlank(file.base64Data) || String.isBlank(file.fileName)) {
                continue;
            }

            String extension = file.fileName.substringAfterLast('.').toLowerCase();
            if (!ALLOWED_EXTENSIONS.contains(extension)) {
                throw new UploadException('Unsupported file type: ' + file.fileName + '. Only JPG, PNG and PDF are allowed.');
            }

            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(file.base64Data);
            cv.Title = file.fileName.substringBeforeLast('.');
            cv.PathOnClient = file.fileName;
            cv.IsMajorVersion = true;
            cvList.add(cv);
        }

        if (cvList.isEmpty()) {
            throw new UploadException('Valid file data is missing.');
        }

        Database.insert(cvList, AccessLevel.SYSTEM_MODE);

        // 2. Fetch generated ContentDocumentIds (keep upload order)
        Set<Id> cvIds = new Map<Id, ContentVersion>(cvList).keySet();
        Map<Id, ContentVersion> insertedVersions = new Map<Id, ContentVersion>(
            (List<ContentVersion>) Database.queryWithBinds(
                'SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIds',
                new Map<String, Object>{ 'cvIds' => cvIds },
                AccessLevel.SYSTEM_MODE
            )
        );

        List<String> contentDocumentIds = new List<String>();
        for (ContentVersion cv : cvList) {
            contentDocumentIds.add(insertedVersions.get(cv.Id).ContentDocumentId);
        }

        // 3. Link files to the Messaging Session so agents can see them on the conversation
        Id sessionId = toMessagingSessionId(messagingSessionId);
        if (sessionId != null) {
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            for (String docId : contentDocumentIds) {
                cdlList.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = sessionId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
            Database.insert(cdlList, AccessLevel.SYSTEM_MODE);
        }

        return contentDocumentIds;
    }

    private static Id toMessagingSessionId(String value) {
        if (String.isBlank(value)) return null;
        try {
            Id candidate = Id.valueOf(value.trim());
            return candidate.getSObjectType() == MessagingSession.SObjectType ? candidate : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static AuraHandledException auraError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}