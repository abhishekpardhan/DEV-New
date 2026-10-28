//Controller class for Quotation component to create the Quotation under the current quote
public class QuotationController {
    
    //Method to query Zone Matrix, Price Master and Group state master records
    @AuraEnabled
    public static List<wrapper> getZone(String ExState){
        //ExState = 'Delhi';
        map<String,List<String>> mapZoneGroup = new map<String,List<String>>();
        map<String,String> mapGroupState = new map<String,String>();
        map<String,Price_Master__c> mapZonePriceMaster = new map<String,Price_Master__c>();
        map<String,Price_Master__c> mapZonePriceMaster2 = new map<String,Price_Master__c>();
        map<String,List<wrapper>> mapListWrapper = new map<String,List<wrapper>>();
        String ExGroup = [select group__c from Group_State_Master__c where state__c includes(:ExState)].group__c;
        System.debug('ExGroup++'+ExGroup);
        List<zone_matrix__c> lstZoneMatrix = [select to_group__c,zone__c from zone_matrix__c where ex_group__c =: ExGroup order by zone__c ASC];
        for(zone_matrix__c zm: lstZoneMatrix){
            
            if(!mapZoneGroup.containskey(zm.Zone__c)){
                mapZoneGroup.put(zm.Zone__c,new List<String>{zm.To_Group__c});
            }
            else{
                List<String> lstString = mapZoneGroup.get(zm.Zone__c);
                lstString.add(zm.To_Group__c);
                mapZoneGroup.put(zm.Zone__c,lstString);
            }
        }
        system.debug('mapZoneGroup++'+mapZoneGroup);
        
        for(Group_State_Master__c gsm : [select id,group__c,state__c from Group_State_Master__c]){
            mapGroupState.put(gsm.Group__c,gsm.State__c);
        }
        
        for(Price_Master__c pm : [select id,Zone__c,Surface_Price__c,Air_Price__c from Price_Master__c where type__c = 'Credit' order by Zone__c ASC]){
            mapZonePriceMaster.put(pm.Zone__c,pm);
        }
        /*for(Price_Master__c pm2 : [select id,Zone__c,amount__c from Price_Master__c where Rate_Type__c =: rtype1 order by Zone__c ASC]){
mapZonePriceMaster2.put(pm2.Zone__c,pm2);
}*/
        system.debug('mapGroupState++'+mapGroupState);
        List<wrapper> lstWrapper = new List<wrapper>();
        for(String s: mapZoneGroup.keyset()){
            
            wrapper wr = new wrapper();
            wr.Zone = s;
            List<String> lstStr = mapZoneGroup.get(s);
            for(String str : lstStr){                
                String states =(( mapGroupState.get(str) != null && mapGroupState.get(str).contains(';')) ?  mapGroupState.get(str).replaceAll(';',',') : mapGroupState.get(str));
                if(String.isBlank(wr.state)){
                    wr.State = states + ',';
                }
                else{
                    wr.State += states + ',';
                }                
                
            }
            wr.State = wr.State.removeEnd(',');            
            system.debug('wrapper++'+wr);
            //Decimal price = mapZonePriceMaster.get(s).amount__c;
            wr.SurfacePrice = mapZonePriceMaster.get(s).Surface_Price__c;
            wr.AirPrice = mapZonePriceMaster.get(s).Air_Price__c;
            lstWrapper.add(wr);   
            
        }
        mapListWrapper.put('CreditSurfaceMax',lstWrapper);
        system.debug('lstWrapper++'+lstWrapper);
        return lstWrapper;
    }
    
    
    //Method to query the Commandment__c records and filling the wrapper
    @AuraEnabled
    public static List<wrapper> getCommandment(){
        List<wrapper> lstWrapper = new List<wrapper>();
        map<string, wrapper> sortCammandMap = new map<string, wrapper>();
        
        List<Commandment_Master__c> lstCM = [select id,name,Air_Amount__c,Surface_Amount__c,Surface_Invoice_Value__c,Air_Invoice_Value__c,
                                             Surface_Percentage__c,  Air_Percentage__c,  Surface_Min__c,  Air_Min__c, 
                                             Surface_Zero_Round_Off__c,  Air_Zero_Round_Off__c,  Air_Rs__c,  Surface_Rs__c 
                                             from Commandment_Master__c];
        System.debug('<< lstCM >> '+lstCM.size());
        for(Commandment_Master__c cm : lstCM){
            
            if(cm.Name != 'State Surcharge' && cm.Name != 'CCSC Destinations')
            {
                wrapper wr = new wrapper();            
                wr.AirPrice =  cm.Name == 'FLFC'? 0 : cm.Air_Amount__c;
                wr.SurfacePrice = cm.Name == 'FLFC'? 0 : cm.Surface_Amount__c;
                wr.Name = cm.Name;
                wr.check = true;
                wr.surfacePercentage = cm.Name == 'FLFC'? 0 : cm.Surface_Percentage__c;
                wr.airPercentage = cm.Name == 'FLFC'? 0 : cm.Air_Percentage__c;
                wr.surfaceMin = cm.Surface_Min__c;
                wr.airMin = cm.Air_Min__c;
                wr.surfaceInvoice = cm.Surface_Invoice_Value__c;
                wr.airInvoice = cm.Air_Invoice_Value__c;
                wr.surfaceZeroRoundOff = cm.Surface_Zero_Round_Off__c;
                wr.airZeroRoundOff = cm.Air_Zero_Round_Off__c;
                wr.surfaceRs = cm.Name == 'FLFC'? 0 : cm.Surface_Rs__c ;
                wr.airRs = cm.Name == 'FLFC'? 0 : cm.Air_Rs__c;
                sortCammandMap.put(wr.Name.toUpperCase(), wr);
                lstWrapper.add(wr);
            }
        }
        System.debug('<< lstWrapper >> '+lstWrapper.size());
        if(!lstWrapper.isEmpty()){
            //if(sortCammandMap.size() > 0)
            {
                return sortWrapper(sortCammandMap);
                //mapWrapper.put('Commandments',sortWrapper(sortCammandMap));
            }
            //return lstWrapper;
        }
        else{
            return null;
        }
    }
    
    //Method to create the new quote line items and deleting the existing ones
    @AuraEnabled
    public static void saveQLI(String lstVal, 
                               String lstZoneState,
                               String lstCommandment,
                               Id qId,
                               String lstSafextension,
                               String exstate,
                               String stateSurcharge,
                               String lstDelete 
                              )
    {
        
        system.debug('lstVal++'+lstVal);        
        system.debug('lstZoneState++'+lstZoneState);
        system.debug('lstCommandment++'+lstCommandment);
        List<Quote_Line_Item__c> lstQLI = new List<Quote_Line_Item__c>();
        
        //List<jsonwrap> jw = (List<jsonwrap>) System.JSON.deserialize(lstVal,List<jsonwrap>.class); 
        List<wrapper> jw = (List<wrapper>) System.JSON.deserialize(lstVal,List<wrapper>.class);
        List<wrapper> jwZone = (List<wrapper>) System.JSON.deserialize(lstZoneState,List<wrapper>.class);
        List<wrapper> wrapperCommand = (List<wrapper>) System.JSON.deserialize(lstCommandment,List<wrapper>.class);
        List<wrapper> safextension = (List<wrapper>) System.JSON.deserialize(lstSafextension,List<wrapper>.class);
        List<wrapper> stateSur = (List<wrapper>) System.JSON.deserialize(stateSurcharge,List<wrapper>.class);
        system.debug('jwZone++'+jwZone);
        for(wrapper j : jw){
            Quote_Line_Item__c qli = new Quote_Line_Item__c();  
            qli.Air_Price__c = j.AirPrice;
            qli.Quote__c = qId; //'a0A5D000001JTD9'
            qli.State__c = j.state;
            qli.City__c = j.city;
            qli.Surface_Price__c = j.SurfacePrice;
            qli.Type__c = 'Special Destinations';
            qli.Name = 'Special Destinations';
            qli.Id = j.qtId;
            qli.Yield_Surface__c = j.YieldSurface;
            qli.Yield_Air__c = j.YieldAir;
            lstQLI.add(qli);
        }
        
        for(wrapper wr : jwZone){
            Quote_Line_Item__c qli = new Quote_Line_Item__c();
            qli.Air_Price__c = wr.AirPrice;
            qli.Quote__c = qId; //'a0A5D000001JTD9'            
            qli.State__c =(( !String.isBlank(wr.state) && wr.state.contains(',')) ? wr.state.replaceAll(',', ';') : wr.state);
            qli.Zone__c = wr.Zone;
            qli.Surface_Price__c = wr.SurfacePrice;
            qli.Type__c = 'Zone Prices';
            qli.Name = 'Zone Prices';
            //qli.Id = wr.qtId;
            qli.Yield_Surface__c = wr.YieldSurface;
            qli.Yield_Air__c = wr.YieldAir;
            system.debug('!@---'+wr.AirPrice+'---'+qli.Air_Price__c+'----'+wr.SurfacePrice+'--'+qli.Surface_Price__c);
            lstQLI.add(qli);
        }
        
        for(wrapper cm : wrapperCommand){
            Quote_Line_Item__c qli = new Quote_Line_Item__c();
            qli.Air_Price__c = cm.AirPrice;
            qli.Quote__c = qId;
            qli.Surface_Price__c = cm.SurfacePrice;
            qli.Type__c = 'Commandments';
            qli.check__c = cm.check;
            qli.Name = cm.Name;
            qli.Id = cm.qtId;
            qli.Surface_Percentage__c = cm.surfacePercentage;  
            qli.Air_Percentage__c = cm.airPercentage;
            qli.Surface_Min__c = cm.surfaceMin;
            qli.Air_Min__c = cm.airMin;
            qli.Surface_Zero_Round_Off__c = cm.surfaceZeroRoundOff;
            qli.Air_Zero_Round_Off__c = cm.airZeroRoundOff;
            qli.Surface_Rs__c = cm.surfaceRs;
            qli.Air_Rs__c = cm.airRs; 
            qli.Fuel_Surcharge_Type__c = cm.fuelSurchargeType ;
            qli.Surface_Invoice_Val__c = cm.surfaceInvoice;
            qli.Air_Invoice_Value__c = cm.airInvoice;
            lstQLI.add(qli);
        }
        
        for(wrapper sf : safextension){
            Quote_Line_Item__c qli = new Quote_Line_Item__c();            
            qli.Quote__c = qId;
            qli.Type__c = 'Safextension';
            qli.Name = sf.Name;
            qli.Id = sf.qtId;
            qli.Rate__c = sf.Rate;
            qli.Minimum_Freight__c = sf.MinimumFrt;            
            lstQLI.add(qli);
        }
        
        for(wrapper ss : stateSur){
            Quote_Line_Item__c qli = new Quote_Line_Item__c();            
            qli.Quote__c = qId;
            qli.Type__c = 'State Surcharge';
            qli.Name = 'State Surcharge';
            qli.State__c = ss.State.contains(',')? ss.State.replace(',', ';') : ss.State;
            //qli.State__c = ss.State;
            qli.Id = ss.qtId;
            qli.Air_Price__c = ss.AirPrice;
            qli.Surface_Price__c = ss.SurfacePrice;
            System.debug('<< ss.stateSurDescription > '+ss.stateSurDescription);
            qli.State_surcharge_Description__c = ss.stateSurDescription;
            lstQLI.add(qli);
        }
        
        Quote__c qt = [select id,name,Ex_State__c from quote__c where id =: qId limit 1];
        qt.Ex_State__c = exstate;
        
        update qt;
        
        delete [select id from Quote_Line_Item__c where Type__c = 'Zone Prices' and Name = 'Zone Prices' and Quote__c =: qId];
        if(!lstQLI.isEmpty()){
            upsert lstQLI;
        }
        Map<Id, Quote_Line_Item__c> qliToDelete = new map<Id, Quote_Line_Item__c>();
        List<Quote_Line_Item__c> lstsafextensionItem = [select id,Quote__c from Quote_Line_Item__c where Type__c = 'Safextension' and Quote__c =: qId order by createdDate ASC];
        if(lstsafextensionItem != null && lstsafextensionItem.size() > 2){
            qliToDelete.put(lstsafextensionItem[0].id,lstsafextensionItem[0]);
            qliToDelete.put(lstsafextensionItem[1].id,lstsafextensionItem[1]);
        }
        system.debug('lstDelete---'+lstDelete);
        if(string.isNotBlank(lstDelete))
        {
            List<wrapper> wrapperLstDelete = (List<wrapper>) System.JSON.deserialize(lstDelete,List<wrapper>.class);
            for(wrapper wp : wrapperLstDelete)
            {
                if(wp.qtId != null)
                {
                    qliToDelete.put(wp.qtId, new Quote_Line_Item__c(Id=wp.qtId));
                }
            }
            
            if(qliToDelete.values().size() > 0 )
            {
                delete qliToDelete.values();
            }
        }
        
    }
    
    //Method to check if the current quote has quote line items already
    @AuraEnabled
    public static String checkQuote(Id qid){
        if(qid != null){
            
            List<wrapper> lstWrapper = new List<wrapper>();
            List<jsonwrap> lstjsonwrap = new List<jsonwrap>();            
            List<Quote_Line_Item__c> lstQLI = [select id,name,type__c,Air_Price__c,State__c,Zone__c,Surface_Price__c from Quote_Line_Item__c where Quote__c =: qid];
            if(lstQLI.size() > 0){                
                
                return 'Existing Quote';
            }
            else{
                return 'New Quote';
            }
            
        }
        else{
            return null;
        }
    }
    
    //Method to update the values in quote wrapper to create the Quote line items
    @AuraEnabled
    public static map<String,List<wrapper>> checkQuote2(Id qid){
        system.debug('chk1'+qid);
        if(qid != null){
            system.debug('chk2'+qid);
            List<wrapper> lstWrapper = new List<wrapper>();
            List<wrapper> lstWrapper2 = new List<wrapper>();
            List<wrapper> lstWrapper3 = new List<wrapper>();
            List<wrapper> lstWrapper4 = new List<wrapper>();
            List<wrapper> lstWrapper5 = new List<wrapper>();
            List<jsonwrap> lstjsonwrap = new List<jsonwrap>();
            map<string, wrapper> sortCammandMap = new map<string, wrapper>();
            map<String,List<wrapper>> mapWrapper = new map<String,List<wrapper>>();
            List<Quote_Line_Item__c> lstQLI = [select id,name,type__c,Air_Price__c,State__c,Zone__c,Surface_Price__c,City__c,check__c,quote__r.Ex_State__c,Minimum_Freight__c,Rate__c, 
                                               Yield_Air__c, Yield_Surface__c, Surface_Percentage__c,  Air_Percentage__c,  Surface_Min__c,  Air_Min__c,  Surface_Zero_Round_Off__c,  Air_Zero_Round_Off__c,  Air_Rs__c,  Surface_Rs__c,  
                                               Air_Invoice_Value__c,Surface_Invoice_Val__c,Fuel_Surcharge_Type__c,State_surcharge_Description__c from Quote_Line_Item__c where Quote__c =: qid and version__c = null order by Zone__c ASC];
            system.debug('lstQLI++'+lstQLI);
            if(lstQLI.size() > 0){
                for(Quote_Line_Item__c qli : lstQLI){
                    if(qli.Type__c == 'Zone Prices'){
                        wrapper wr = new wrapper();
                        wr.AirPrice = qli.Air_Price__c;                     
                        wr.state = ((!String.isBlank(qli.State__c) && qli.State__c.contains(';')) ? qli.State__c.replaceAll(';', ',') : qli.State__c);
                        wr.Zone = qli.Zone__c;
                        wr.SurfacePrice = qli.Surface_Price__c;
                        wr.qtId = qli.Id;
                        wr.Exstate = qli.quote__r.Ex_State__c;
                        wr.YieldSurface = qli.Yield_Surface__c;
                        wr.YieldAir = qli.Yield_Air__c;
                        lstWrapper.add(wr);
                        mapWrapper.put('Zone Prices',lstWrapper);
                    }
                    else if(qli.Type__c == 'Special Destinations'){
                        wrapper wr = new wrapper();
                        wr.AirPrice = qli.Air_Price__c;                     
                        wr.state = ((!String.isBlank(qli.State__c) && qli.State__c.contains(';')) ? qli.State__c.replaceAll(';', ',') : qli.State__c);
                        wr.city = qli.City__c;
                        wr.SurfacePrice = qli.Surface_Price__c;
                        wr.qtId = qli.Id;
                        wr.YieldSurface = qli.Yield_Surface__c;
                        wr.YieldAir = qli.Yield_Air__c;
                        lstWrapper2.add(wr);
                        mapWrapper.put('Special Destinations',lstWrapper2);
                        /*jsonwrap j = new jsonwrap();
j.air = qli.Air_Price__c;                        
j.state = qli.State__c;
j.city = qli.City__c;
j.surface = qli.Surface_Price__c;
lstjsonwrap.add(j);*/
                    }
                    else if(qli.Type__c == 'Commandments'){
                        wrapper wr = new wrapper();
                        wr.AirPrice = qli.Air_Price__c;
                        wr.SurfacePrice = qli.Surface_Price__c;
                        wr.Name = qli.Name;                     
                        wr.qtId = qli.Id;
                        wr.check = qli.check__c;
                        wr.surfacePercentage = qli.Surface_Percentage__c;
                        wr.airPercentage = qli.Air_Percentage__c;
                        wr.surfaceMin = qli.Surface_Min__c;
                        wr.airMin = qli.Air_Min__c;
                        wr.surfaceZeroRoundOff = qli.Surface_Zero_Round_Off__c;
                        wr.airZeroRoundOff = qli.Air_Zero_Round_Off__c;
                        wr.surfaceRs = qli.Surface_Rs__c ;
                        wr.airRs = qli.Air_Rs__c; 
                        wr.fuelSurchargeType = qli.Fuel_Surcharge_Type__c;
                        wr.airInvoice = qli.Air_Invoice_Value__c; 
                        wr.surfaceInvoice = qli.Surface_Invoice_Val__c;
                        sortCammandMap.put(wr.Name.toUpperCase(), wr);
                        lstWrapper3.add(wr);
                        mapWrapper.put('Commandments',lstWrapper3);
                    }
                    else if(qli.Type__c == 'Safextension'){
                        wrapper wr = new wrapper();
                        wr.Rate = qli.Rate__c;
                        wr.MinimumFrt = qli.Minimum_Freight__c;
                        wr.Name = qli.Name;                     
                        wr.qtId = qli.Id;                        
                        lstWrapper4.add(wr);
                        mapWrapper.put('Safextension',lstWrapper4);
                    }
                    else if(qli.Type__c == 'State Surcharge'){
                        wrapper wr = new wrapper();
                        wr.AirPrice = qli.Air_Price__c;
                        wr.SurfacePrice = qli.Surface_Price__c;
                        wr.state = ((!String.ISBLANK(qli.State__c) && qli.State__c.contains(';') ) ? qli.State__c.replaceAll(';', ',') :qli.State__c) ;
                        wr.Name = qli.Name;                     
                        wr.qtId = qli.Id;
                        wr.stateSurDescription = qli.State_surcharge_Description__c;
                        lstWrapper5.add(wr);
                        mapWrapper.put('State Surcharge',lstWrapper5);
                    }
                }
                system.debug('mapWrapper++'+mapWrapper);
                if(sortCammandMap.size() > 0)
                {
                    mapWrapper.put('Commandments',sortWrapper(sortCammandMap));
                    //system.debug('-----'+sortWrapper(sortCammandMap));
                }
                
                return mapWrapper;
            }
            else{
                return null;
            }
            
        }
        else{
            return null;
        }
    }
    
    //Method to describe the Quotation_State_surcharge__c and State__c picklist field values
    @AuraEnabled
    public static List<List<String>> getStates(){
        List<List<String>> lst2States = new List<List<String>>();
        List<String> lstStates = new List<String>();
        Schema.DescribeFieldResult fieldResult = Lead__c.State__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            lstStates.add(f.getValue());
        }
        lst2States.add(lstStates);
        lstStates = new List<String>();
        Schema.DescribeFieldResult fieldResult1 = Quote__c.Quotation_State_surcharge__c.getDescribe();
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
        for( Schema.PicklistEntry f : ple1)
        {
            lstStates.add(f.getValue());
        }
        lst2States.add(lstStates);
        system.debug('lstStates++'+lstStates);
        return lst2States;        
    }
    
    //Method to describe the City__c picklist values
    @AuraEnabled
    public static List<String> getCity(){
        List<String> lstCity = new List<String>();
        Schema.DescribeFieldResult fieldResult = Lead__c.City__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            lstCity.add(f.getValue());
        }
        system.debug('lstCity++'+lstCity);
        return lstCity;        
    }
    
    /*
    @AuraEnabled  
    public static Map<String,List<String>> getDependentPicklist(string objApiName , string contrfieldApiName , string depfieldApiName){
        system.debug(objApiName + '##' + contrfieldApiName + '###' + depfieldApiName);
        
        String objectName = objApiName.toLowerCase();
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        
        if (!Schema.getGlobalDescribe().containsKey(objectName)){
            System.debug('OBJNAME NOT FOUND --.> ' + objectName);
            return null;
        }
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType==null){
            return objResults;
        }
        Bitset bitSetObj = new Bitset();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        //Check if picklist values exist
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            System.debug('FIELD NOT FOUND --.> ' + controllingField + ' OR ' + dependentField);
            return objResults;     
        }
        
        List<Schema.PicklistEntry> contrEntries = objFieldMap.get(controllingField).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> depEntries = objFieldMap.get(dependentField).getDescribe().getPicklistValues();
		System.debug('depEntries size '+depEntries.size());
        objFieldMap = null;
        List<Integer> controllingIndexes = new List<Integer>();
        for(Integer contrIndex=0; contrIndex<contrEntries.size(); contrIndex++){            
            Schema.PicklistEntry ctrlentry = contrEntries[contrIndex];
            String label = ctrlentry.getLabel();
            System.debug('<< inside con >> '+label);
            objResults.put(label,new List<String>());
            controllingIndexes.add(contrIndex);
        }
		System.debug('controllingIndexes >> '+controllingIndexes.size());
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<PicklistEntryWrapper> objJsonEntries = new List<PicklistEntryWrapper>();
        for(Integer dependentIndex=0; dependentIndex<depEntries.size(); dependentIndex++){            
            Schema.PicklistEntry depentry = depEntries[dependentIndex];
            objEntries.add(depentry);
        } 
		System.debug('<< objEntries >> '+objEntries.size());
        objJsonEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objEntries), List<PicklistEntryWrapper>.class);
		System.debug('objJsonEntries >> '+objJsonEntries.size());
        List<Integer> indexes;
        for (PicklistEntryWrapper objJson : objJsonEntries){
            if (objJson.validFor==null || objJson.validFor==''){
                continue;
            }
            System.debug('objJson.validFor '+objJson.validFor+' << objJson.label  >> '+objJson.label );
            indexes = bitSetObj.testBits(objJson.validFor,controllingIndexes);
			System.debug('<< indexes >> '+indexes);
            for (Integer idx : indexes){                
                String contrLabel = contrEntries[idx].getLabel();
                System.debug('<< idx >> '+idx+ ' contrEntries[idx].getLabel() '+  contrEntries[idx].getLabel());
                objResults.get(contrLabel).add(objJson.label);
            }
        }
        objEntries = null;
        objJsonEntries = null;
        system.debug('objResults--->' + objResults.get('Uttarakhand'));
        return objResults;
    }*/
    //This method is to get city according to state.
    @AuraEnabled  
    public static Map<String,List<String>> getDependentPicklist(){

        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
		for(State_And_City_Combination__c objStateAndCity : [Select id,City__c,State__c from State_And_City_Combination__c]){
			if(String.isNOTBLANK(objStateAndCity.City__c)){
                List<String> lstCity = null;
                if(objStateAndCity.City__c.contains(';')){
               		lstCity = objStateAndCity.City__c.split(';'); 
                }else{
                    lstCity =  new List<String>();
                    lstCity.add(objStateAndCity.City__c);
                }
				if(!objResults.containsKey(objStateAndCity.State__c)){
					objResults.put(objStateAndCity.State__c ,lstCity);
				}
			}
		}

        system.debug('objResults--->' + objResults.get('Uttarakhand'));
        return objResults;
    }
    
    //Querying Opportunity
    @AuraEnabled
    public static quote__c getOpportunityDetail(Id qid){
        
        return [select id,name, Opportunity__r.Avg_wt_of_consignment_Kg__c, Opportunity__r.Value_of_Goods_Kg__c from quote__c where id =: qid]; // 'a0A5D000001LllGUAS'
    }
    
    //Sorting wrapper list
    public static list<wrapper> sortWrapper(map<string, wrapper> wrMap)
    {
        map<integer, string> sortingOrderMap = new map<integer, string>();
        sortingOrderMap.put(0, 'MIN CHARGEABLE WEIGHT');
        sortingOrderMap.put(1, 'MIN. CHARGEABLE WT /PKG FOR MULTIPLE PKGS');
        sortingOrderMap.put(2, 'ZERO ROUND OFF');
        sortingOrderMap.put(3, 'VOLUME WEIGHT PER CFT');
        sortingOrderMap.put(4, 'GREEN SURCHARGE');
        sortingOrderMap.put(5, 'VALUE SURCHARGE');
        sortingOrderMap.put(6, 'WAYBILL CHARGE');
        sortingOrderMap.put(7, 'HANDLING CHARGES');
        sortingOrderMap.put(8, 'DOD/DACC/HUB DELIVERY CHARGES');
        sortingOrderMap.put(9, 'MCC CHARGES');
        sortingOrderMap.put(10, 'FUEL SURCHARGE (%AGE)');
        sortingOrderMap.put(11, 'FLFC');
        sortingOrderMap.put(12, 'MINIMUM FREIGHT');
        sortingOrderMap.put(13, 'POD CHARGE');
        
        list<wrapper> wrListSorted = new list<wrapper>();
        for(integer i = 0; i<sortingOrderMap.size(); i++)
        {
            if(wrMap.containsKey(sortingOrderMap.get(i)))
            {
                wrListSorted.add( wrMap.get(sortingOrderMap.get(i)) );
            }
        }
        return wrListSorted;
    }
    
    //Method to send readOnly as false if quote is rejected
    @auraEnabled
    public static boolean checkReadonly(Id qId){ 
        Id recordsTypeQuote = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId(); 
        boolean readOnly = true; 
        system.debug('lstQuo---'+qId);                
        List<Quote__c> lstQuo = [Select id,Approval_Status__c,Status__c from Quote__c 
                                 where Id =:qId AND recordTypeId =:recordsTypeQuote AND //AND Status__c='Active' removed by Shubham
                                 (Approval_Status__c = '' OR Approval_Status__c = 'Rejected By RM' OR 
                                  Approval_Status__c = 'Rejected By Corporate Head Credit/Retail' OR Approval_Status__c = 'Rejected By CCD') 
                                 limit 1];
        
        system.debug('lstQuo---'+lstQuo);
        if(lstQuo != null && lstQuo.size() > 0){ 
            readOnly = false; 
        } 
        return readOnly; 
    }
    
    
    
    //Wrapper class
    public class wrapper{
        @AuraEnabled
        public String Zone;
        @AuraEnabled
        Public String State;
        @AuraEnabled
        Public Decimal SurfacePrice;
        @AuraEnabled
        Public Decimal AirPrice;
        @AuraEnabled
        Public String City;
        @AuraEnabled
        Public Id qtId;
        @AuraEnabled
        Public String Name;
        @AuraEnabled
        Public Decimal Rate;
        @AuraEnabled
        Public Decimal MinimumFrt;
        @AuraEnabled
        Public boolean check;
        @AuraEnabled
        Public String Exstate;
        @AuraEnabled
        Public Decimal YieldSurface;
        @AuraEnabled
        Public Decimal YieldAir;
        
        
        @AuraEnabled
        Public Decimal surfacePercentage;
        @AuraEnabled
        Public Decimal airPercentage;
        @AuraEnabled
        Public Decimal surfaceMin;
        @AuraEnabled
        Public Decimal airMin;
        @AuraEnabled
        Public Decimal surfaceInvoice;
        @AuraEnabled
        Public Decimal airInvoice;
        @AuraEnabled
        Public String stateSurDescription;
        
        @AuraEnabled
        Public String surfaceZeroRoundOff;
        @AuraEnabled
        Public String airZeroRoundOff;
        @AuraEnabled
        Public Decimal surfaceRs;
        @AuraEnabled
        Public Decimal airRs;
        @AuraEnabled
        Public string fuelSurchargeType;
    }
    
    //Wrapper class
    public class jsonwrap{
        public String state;
        public String city;
        public Decimal SurfacePrice;
        public Decimal AirPrice;
        public String surDescription;
        public String zone;
    }
     @AuraEnabled
    public static Id SaveFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
      /*  Attachment attach = new Attachment();
        attach.parentId = parentId;
        attach.Body = EncodingUtil.base64Decode(base64Data);
        attach.Name = fileName;
        attach.ContentType = contentType;
        Insert attach;
        return attach.Id;
        */
        ContentVersion conVer = new ContentVersion();
conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
conVer.PathOnClient = fileName; // The files name, extension is very important here which will help the file in preview.
conVer.Title = fileName; // Display name of the files
conVer.VersionData = EncodingUtil.base64Decode(base64Data); // converting your binary string to Blog
insert conVer;
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        ContentDocumentLink cDe = new ContentDocumentLink();
           cDe.ContentDocumentId = conDoc;
               cDe.LinkedEntityId = parentId; // you can use objectId,GroupId etc
cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
cDe.Visibility = 'AllUsers';
        insert cDe;
        return cDe.Id;
    }

}