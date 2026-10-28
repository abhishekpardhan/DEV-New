public class AutoCheckoutLocalJourneyJob implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        new AutoCloseJourneyCommonController().autoCheckoutJourneys(false);
    }
}