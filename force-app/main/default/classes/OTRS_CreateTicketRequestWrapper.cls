/**
 * @File Name          : OTRS_CreateTicketRequestWrapper.cls
 * @Description        : This class is the wrapper class for the create ticket API for the OTRS with default values
 * @Author             : Deepak
 * @Group              : Techmatrix
 * @Last Modified By   : Deepak
 * @Last Modified On   : 12-07-2021
 * @Modification Log   :
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
* 1.0        14-07-2021                Deepak                   Initial Version
**/

public class OTRS_CreateTicketRequestWrapper {
    public cls_Ticket Ticket;
    public cls_Article Article;
    public cls_DynamicField[] DynamicField;
    public class cls_Ticket {
        public String Title = 'Test With form data with attachment';    //Test With form data with attachment
        public String TypeID = '5';    //3
        public String Queue = '48';    //1
        public String State = '1';    //1
        public String Priority = '3';    //3
        public String Source = '100';    //100
        public String CustomerUser = 'User1';    //User1
    }
    public class cls_Article {
        public String Subject = 'Rest Create Test';    //Rest Create Test
        public String Body = 'This is only a test due to customer issue';    //This is only a test due to customer issue
        public String ContentType = 'ext/plain; charset=utf8';    //text/plain; charset=utf8
    }
    public class cls_DynamicField {
        public String Name = 'MainCategory';    //MainCategory
        public String Value = 'InfraSupport';    //InfraSupport
    }
}