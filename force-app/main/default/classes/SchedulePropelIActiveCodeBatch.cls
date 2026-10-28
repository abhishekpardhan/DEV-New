global class SchedulePropelIActiveCodeBatch implements Schedulable{
    
    global void execute(SchedulableContext sc){
        BatchToDeletePropelIActiveCode batch = new BatchToDeletePropelIActiveCode(new List<String>()); // Your batch class
        database.executeBatch(batch, 50);
    }
    
}