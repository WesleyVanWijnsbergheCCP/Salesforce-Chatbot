public with sharing class zCCP_CHT_Controller {

    @AuraEnabled
    public static zCCP_CHT_Wrapper initChat(){

        try{
            zCCP_CHT_Wrapper context = zCCP_CHT_Utils.initChat();
            context.userName = UserInfo.getName();

            return context;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static zCCP_CHT_Wrapper processChatMessage(String contextString, String message){
        
        zCCP_CHT_Wrapper context = zCCP_CHT_Wrapper.parseSingle(contextString);

        try{
            return zCCP_CHT_Utils.processChatMessage(context, message);
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
}
 