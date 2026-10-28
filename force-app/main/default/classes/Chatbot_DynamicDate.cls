public without sharing class Chatbot_DynamicDate {
    
    public class DateInput {
        @InvocableVariable
        public String dateString;
        
    }
    
   public class DateOutput {
        @InvocableVariable
        public List<String> timeOptions;
    }
    
    @InvocableMethod(Label = 'Get Dynamic Date Slots')
    public static  List<DateOutput> checkCurrentDate(List<DateInput> dateInputs){
         system.debug('dateInputs-->'+dateInputs);
         List<DateOutput> outputResponse = new List<DateOutput>();
        
        try{
            			  
			List<String> splitDt = dateInputs[0].dateString.split('/');
            Datetime currentDateTime = Datetime.now();   
            Integer currentHour = currentDateTime.hour(); 
            Integer currentDay = 0 ;
            for (DateInput dateObj : dateInputs) {
                if (dateObj.dateString != null) { 
                    currentDay = Integer.valueOf(splitDt[0])  ;
                } 
                break;
            }
            
            List<String> timeOptions = new List<String>();
            //currentHour=21;
            if(currentHour >= 8 && currentHour < 18 && currentDay == currentDateTime.day() ){
                System.debug('currentHour-->'+currentHour);
                //response = generateTimeSlotsAfterCurrentTime();
                Integer count = 1;                
                String responseString = '';
                for( Integer temp = Math.Mod(currentHour, 2) == 0 ? currentHour+2 : currentHour; temp < 20 ; temp++){
                    //System.debug('Math.Mod(temp, 2)-->'+Math.Mod(temp, 2));
                    if(Math.Mod(temp, 2) == 0){
                        String am = 'AM';
                        String pm = 'AM';
                        
                        if(temp >= 12){
                            am = 'PM';
                        }
                        
                        if((temp+2) >= 12){
                            pm = 'PM';
                        }
                        String startTime = String.valueOf(temp);
                        if(temp  > 12 ){
                            startTime = '0'+String.valueOf(temp-12);
                        }
                        if(temp <10){
                            startTime = '0'+startTime;
                        }
                        
                        String endTime = String.valueOf(temp+2);
                        if((temp+2)  > 12 ){
                            endTime = String.valueOf((temp-10));                            
                        }
                        if(Integer.valueOf(endTime) <10){
                            endTime = '0'+endTime;
                        }
                        
                        //String slotText = 'Press '+count+' for - '+startTime+':00 '+am+' - '+endTime+':00 '+pm;
                        String slotText = '';
                         
                        slotText ='for '+ startTime+':00 '+am+' - '+endTime+':00 '+pm;
                        if(endTime == '08'){
                           slotText = 'for ' +startTime+':00 '+am+' - '+endTime+' :00 '+pm;

                        }
                        timeOptions.add(slotText);
                            
                        count++;
                         
                    }  
                    
                }
                  
                 
            }else{
                timeOptions = new List<String>{
                    'for 08:00 AM - 10:00 AM',
                    'for 10:00 AM - 12:00 PM',
                    'for 12:00 PM - 02:00 PM',
                    'for 02:00 PM - 04:00 PM',
                    'for 04:00 PM - 06:00 PM',
                    'for 06:00 PM - 08 :00 PM'} ; 
                
            } 
            DateOutput obj = new DateOutput();
            obj.timeOptions = timeOptions;
            outputResponse.add(obj); 
        }
        catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : Chatbot_DynamicDate at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('Chatbot_DynamicDate', 'checkDate', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }		       
        return outputResponse;        
    } 
    
    
}