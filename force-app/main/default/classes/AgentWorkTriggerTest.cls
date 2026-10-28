@isTest(SeeAlldata=true) 
public class AgentWorkTriggerTest {
    static testMethod void testMethod1() {
		list<AgentWork> agentworks = new list<AgentWork>([select Id from AgentWork limit 1]);
        update agentworks;
        
    }

}