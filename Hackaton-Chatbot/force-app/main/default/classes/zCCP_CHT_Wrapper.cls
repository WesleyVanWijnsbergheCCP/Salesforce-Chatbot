public class zCCP_CHT_Wrapper {
    
    @AuraEnabled
    public String userName; 

    @AuraEnabled
    public String response; 

    @AuraEnabled
    public String currentMenu; //If Main Menu: Value is 'MAIN', otherwise Id

    @AuraEnabled
    public String currentAction;

    @AuraEnabled
    public Boolean expectsAnswer;

    /**
     * [(sub)MenuId, (sub)MenuId, ...]
     */
    @AuraEnabled
    public List<String> currentMenuSelection;

    /**
     * {MenuId : zCCP_CHT_Wrapper_Menu, ...}
     */
    @AuraEnabled
    public Map<String, zCCP_CHT_Wrapper_Menu> menuMap;

     /**
     * {SubMenuId : zCCP_CHT_Wrapper_Sub_Menu, ...}
     */
    @AuraEnabled
    public Map<String, zCCP_CHT_Wrapper_Sub_Menu> subMenuMap;

    /**
     * {(sub)MenuId : { SubMenuId : zCCP_CHT_Wrapper_Sub_Menu, ...}, ...}
     */
    @AuraEnabled
    public Map<String, Map<String, zCCP_CHT_Wrapper_Sub_Menu>> menuWithSubMenuMap;

    /**
     * {Name : zCCP_CHT_Wrapper_Tag, ...}
     */
    @AuraEnabled
    public Map<String, zCCP_CHT_Wrapper_Tag> tagMap;

    /**
     * {subMenuId : { actionId : zCCP_CHT_Wrapper_Action, ...}, ...}
     */
    @AuraEnabled
    public Map<String, Map<String, zCCP_CHT_Wrapper_Action>> subMenuWithActionMap;

    /**
     * {actionId : zCCP_CHT_Wrapper_Action, ...}
     */
    @AuraEnabled
    public Map<String, zCCP_CHT_Wrapper_Action> actionMap;

    /**
     * {trainingPhrase : zCCP_CHT_Wrapper_Training_Phrase, ...}
     */
    @AuraEnabled
    public Map<String, zCCP_CHT_Wrapper_Training_Phrase> trainingPhraseMap;

    public zCCP_CHT_Wrapper(){
        this.expectsAnswer = false;
        this.currentMenuSelection = new List<String>();
        this.menuMap = new Map<String, zCCP_CHT_Wrapper_Menu>();
        this.subMenuMap = new Map<String, zCCP_CHT_Wrapper_Sub_Menu>();
        this.menuWithSubMenuMap = new Map<String, Map<String, zCCP_CHT_Wrapper_Sub_Menu>>();
        this.tagMap = new Map<String, zCCP_CHT_Wrapper_Tag>();
        this.subMenuWithActionMap = new Map<String, Map<String, zCCP_CHT_Wrapper_Action>>();
        this.actionMap = new Map<String, zCCP_CHT_Wrapper_Action>();
        this.trainingPhraseMap = new Map<String, zCCP_CHT_Wrapper_Training_Phrase>();
    }

    public class zCCP_CHT_Wrapper_Menu{

        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String name; 

        @AuraEnabled
        public Decimal sortOrder;

        @AuraEnabled
        public String message;

        public zCCP_CHT_Wrapper_Menu(String recordId, String name, Decimal sortOrder, String message){
            this.recordId = recordId;
            this.name = name;
            this.sortOrder = sortOrder;
            this.message = message;
        }
    }

    public class zCCP_CHT_Wrapper_Sub_Menu{

        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String menuId;

        @AuraEnabled
        public String name; 

        @AuraEnabled
        public Decimal sortOrder;

        @AuraEnabled
        public String message;

        public zCCP_CHT_Wrapper_Sub_Menu(String recordId, String menuId, String name, Decimal sortOrder, String message){
            this.recordId = recordId;
            this.menuId = menuId;
            this.name = name;
            this.sortOrder = sortOrder;
            this.message = message;
        }
    }

    public class zCCP_CHT_Wrapper_Tag{

        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String subMenuId;

        @AuraEnabled
        public String name; 

        public zCCP_CHT_Wrapper_Tag(String recordId, String subMenuId, String name){
            this.recordId = recordId;
            this.subMenuId = subMenuId;
            this.name = name;
        }
    }

    public class zCCP_CHT_Wrapper_Action{

        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String subMenuId;

        @AuraEnabled
        public String name;

        @AuraEnabled
        public String type; 

        @AuraEnabled
        public String answer;

        @AuraEnabled
        public String soql;

        @AuraEnabled
        public String message;

        public zCCP_CHT_Wrapper_Action(String recordId, String subMenuId, String name, String type, String answer, String soql, String message){
            this.recordId = recordId;
            this.subMenuId = subMenuId;
            this.name = name;
            this.type = type;
            this.answer = answer;
            this.soql = soql;
            this.message = message;
        }
    }

    public class zCCP_CHT_Wrapper_Training_Phrase{

        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String actionId;

        @AuraEnabled
        public String phrase;

        @AuraEnabled
        public String keywords;

        public zCCP_CHT_Wrapper_Training_Phrase(String recordId, String actionId, String phrase, String keywords){
            this.recordId = recordId;
            this.actionId = actionId; 
            this.phrase = phrase;
            this.keywords = keywords;
        }
    }

    public class zCCP_CHT_Wrapper_Training_Mapping{

        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String trainingPhraseId; 

        @AuraEnabled
        public String key;

        @AuraEnabled
        public String value;

        public zCCP_CHT_Wrapper_Training_Mapping(String recordId, String trainingPhraseId, String key, String value){
            this.recordId = recordId;
            this.trainingPhraseId = trainingPhraseId; 
            this.key = key;
            this.value = value;
        }
    }

    public static zCCP_CHT_Wrapper parseSingle(String jsonString){
        if(jsonString != null && jsonString.length() > 3) { 
            return (zCCP_CHT_Wrapper) System.JSON.deserialize(jsonString, zCCP_CHT_Wrapper.class);
        }
        else {
            return null;
        }
    }
}
