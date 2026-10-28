public class AutoCheckoutOutstationJourneyJob implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        new AutoCloseJourneyCommonController().autoCheckoutJourneys(true);
    }
}