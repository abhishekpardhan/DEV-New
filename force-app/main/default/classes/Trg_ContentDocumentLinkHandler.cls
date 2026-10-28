public class Trg_ContentDocumentLinkHandler {
   
     public static void handleBeforeInsert(List<ContentDocumentLink> newList) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

       Trg_Contentdocumentlinkhelper.validateFileUpload(newList);
    }
}