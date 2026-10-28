//Class to prevent the trigger to run recursively by using static flags
public class checkRecursive {
    
    public static boolean firstRun = true;
    public static boolean isFirstRun(){
        if(firstRun){
            firstRun = false;// true
            return true;
        }else{
            return firstRun;
        }
    }
}