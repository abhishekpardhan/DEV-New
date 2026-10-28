public class Scheduler_ConnectionWithPropelI implements Schedulable {
	
    public void execute(SchedulableContext SC) {
        ConnectionWithPropelI.connectWithPropelI();
    }
}