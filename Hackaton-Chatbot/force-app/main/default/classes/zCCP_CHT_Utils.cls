public with sharing class zCCP_CHT_Utils {

    public class zCCP_CHT_UtilsException extends Exception{}
    
    public static zCCP_CHT_Wrapper initChat(){

        zCCP_CHT_Wrapper context = new zCCP_CHT_Wrapper();

        for(zCCP_CHT_Chat_Config__c cConf : [SELECT Id, 
                                                    Name, 
                                                    zCCP_CHT_Action_Answer__c, 
                                                    zCCP_CHT_Action_Type__c, 
                                                    zCCP_CHT_Parent_Chat_Config__c,
                                                    zCCP_CHT_Header_Message__c,
                                                    zCCP_CHT_SOQL__c, 
                                                    zCCP_CHT_Sort_Order__c,
                                                    zCCP_CHT_Training_Phrase__c, 
                                                    zCCP_CHT_Training_Phrase_Keywords__c,
                                                    zCCP_CHT_Type__c       
                                            FROM zCCP_CHT_Chat_Config__c 
                                            WHERE zCCP_CHT_Active__c = true]){
            switch on cConf.zCCP_CHT_Type__c {
                when 'zCCP_CHT_Menu' {
                    processInitMenu(context, cConf);
                }
                when 'zCCP_CHT_Sub_Menu' { 
                    processInitSubMenu(context, cConf);
                }
                when 'zCCP_CHT_Action'{
                    processInitAction(context, cConf);
                }
                when 'zCCP_CHT_Tag' { 
                    processInitTag(context, cConf);
                }
                when 'zCCP_CHT_Training_Phrase' {
                    processInitTrainingPhrase(context, cConf);
                }
                when else{
                    throw new zCCP_CHT_UtilsException('Unknown Type...');
                }
            }
        }

        processMenu(context, null);

        return context;
    }

    public static zCCP_CHT_Wrapper processChatMessage(zCCP_CHT_Wrapper context, String message){

        if(context == null){
            throw new zCCP_CHT_UtilsException('Context is null...');
        }

        message = message.trim();

        if(message.isNumeric()){
            processMenu(context, message);
        }
        else{
            /**
             * Respond based on Answer
             */
            if(context.expectsAnswer){
                constructSOQLAnswer(context, message, context.actionMap.get(context.currentAction));
            }
            /**
             * Tag | Single Word
             */
            else if(!message.containsWhitespace()){
                processTag(context, message.toLowerCase());
            }
            /**
             * Training Phrase | Sentence
             */
            else{
                processPhrase(context, message.toLowerCase());
            }
        }

        return context;
    }


    /************************************************************************************************************************
     * UTILITY MENU METHODS
     ***********************************************************************************************************************/
    public static void processMenu(zCCP_CHT_Wrapper context, String message){

        /**
         * Main Menu Construction
         */
        if(String.isBlank(message)){
            constructMainMenu(context);
        }
        /**
         * Sub Menu Construction
         */
        else {
            Integer selection = Integer.valueOf(message);
            if(selection <= 0 || selection > context.currentMenuSelection.size()){
                context.response = 'Index out of bounds';
            }
            else{
                selection -= 1; //We offset Frontend selection with 1

                String response = '';
                if(context.currentMenu == zCCP_CHT_Constants.MAIN_MENU){
                    zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu menu = context.menuMap.get(context.currentMenuSelection[selection]);
                    if(menu.message != null){
                        response += menu.message + '\n\n';
                    }
                }
                else if(context.currentMenu != null){
                    zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu subMenu = context.subMenuMap.get(context.currentMenuSelection[selection]);
                    if(subMenu.message != null){
                        response += subMenu.message + '\n\n';
                    }
                }

                context.currentMenu = context.currentMenuSelection[selection];

                Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> subMenuMap = context.menuWithSubMenuMap.get(context.currentMenu);

                /**
                 * Submenu has submenu's
                 */
                if(subMenuMap != null){
                    constructSubMenu(context, response, subMenuMap);
                }
                /**
                 * Submenu has action
                 */
                else{
                    Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action>  subMenuActionMap = context.subMenuWithActionMap.get(context.currentMenu); 

                    /**
                     * Found an Action
                     */
                    if(subMenuActionMap != null){
                        processAction(context, message, subMenuActionMap);
                    }
                }
            }
        }
    }

    private static void constructMainMenu(zCCP_CHT_Wrapper context){

        context.currentMenu = zCCP_CHT_Constants.MAIN_MENU;

        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu> menus = context.menuMap.values();
        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu> sortedMenus = sortMenus(menus);

        context.response = 'Welcome to Ask Indra,\nPlease select one of the options below or start chatting\n\n';
        context.currentMenuSelection = new List<String>();

        Integer counter = 1;
        for(zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu menu : sortedMenus){
            context.response += String.valueOf(counter) + '. ' + menu.name + '\n';
            context.currentMenuSelection.add(menu.recordId);
            counter += 1;
        }
    }

    private static void constructSubMenu(zCCP_CHT_Wrapper context, String response, Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> subMenuMap){
        
        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> subMenus = subMenuMap.values();
        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> sortedSubMenus = sortSubMenus(subMenus);

        context.response = response;
        context.currentMenuSelection = new List<String>();

        Integer counter = 1;
        for(zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu subMenu : sortedSubMenus){
            context.response += String.valueOf(counter) + '. ' + subMenu.name + '\n';
            context.currentMenuSelection.add(subMenu.recordId);
            counter += 1;
        }
    }   

    /************************************************************************************************************************
     * UTILITY ACTION METHODS
     ***********************************************************************************************************************/
    private static void processAction(zCCP_CHT_Wrapper context, String message, Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action> subMenuActionMap){

        /**
         * Current implementation we only process the first action
         */

        if(!subMenuActionMap.keySet().isEmpty()){

            zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action;
            
            Set<String> keys = subMenuActionMap.keySet(); 
            for(String key : subMenuActionMap.keySet()){
                action = subMenuActionMap.get(key);
            }

            switch on action.type {
                when 'zCCP_CHT_URL'{
                    constructURLAnswer(context, action);
                }
                when 'zCCP_CHT_Answer' {
                    constructTextAnswer(context, action);
                }
                when 'zCCP_CHT_Query'{
                    constructSOQLAnswer(context, message, action);
                }
            }
        }
    }

    private static void constructURLAnswer(zCCP_CHT_Wrapper context, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action){
        context.isUrlAnswer = true;
        context.URLLabel = action.name;
        context.response = action.answer;
    }

    private static void constructTextAnswer(zCCP_CHT_Wrapper context, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action){
        context.response = action.answer;
    }

    private static void constructSOQLAnswer(zCCP_CHT_Wrapper context, String message, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action){

        /**
         * Action first requests user feedback
         */
        if(context.currentAction == null && action.message != null){
            context.response = action.message;
            context.expectsAnswer = true;
        }
        /**
         * Answer after user feedback
         */
        else if(context.currentAction != null && action.message != null){
            executeSOQL(context, action, message);
            context.expectsAnswer = false;
        }
        /**
         * Immediate Answer
         */
        else{
            executeSOQL(context, action, null);
            context.expectsAnswer = false;
        }

        context.currentAction = action.recordId;
    }

    /************************************************************************************************************************
     * UTILITY SOQL METHODS
     ***********************************************************************************************************************/
    private static void executeSOQL(zCCP_CHT_Wrapper context, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action, String message){

        /**
         * Immediate Answer
         */
        if(message == null){

            List<SObject> sObjs = Database.query(action.soql);

            if(!sObjs.isEmpty()){
                processAnswer(context, sObjs[0], action.answer);
            }
            else{
                context.response = 'Couldn\' find any results.';
            }
        }
        /**
         * Answer after user feedback
         */
        else{
            
            String query = action.soql; 

            List<String> formatter = new List<String>{message};

            query = String.format(query, formatter);

            List<SObject> sObjs = Database.query(query);
            if(!sObjs.isEmpty()){
                processAnswer(context, sObjs[0], action.answer);
            }
            else{
                context.response = 'Couldn\' find any results.';
            }
        }
    }

    private static void processAnswer(zCCP_CHT_Wrapper context, SObject sObj, String answer){

        String answerCopy = answer;
        String placeholder;
        String queryValue;
        while(answerCopy.contains('{')){
            answerCopy = answerCopy.subStringAfter('{');
            placeholder = answerCopy.subStringBefore('}');
            queryValue = String.valueOf(sObj.get(placeholder));
            answer = answer.replace('{' + placeholder + '}', queryValue);
        }

        context.response = answer;
    }

    /************************************************************************************************************************
     * UTILITY TAG METHODS
     ***********************************************************************************************************************/
    private static void processTag(zCCP_CHT_Wrapper context, String message){

        if(context.tagMap.containsKey(message)){
            zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Tag tag = context.tagMap.get(message);

            String response = '';

            zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu menu = context.menuMap.get(tag.subMenuId);
            if(menu != null){
                if(menu.message != null){
                    response += menu.message + '\n\n';
                }
            }
            else{
                zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu subMenu = context.subMenuMap.get(tag.subMenuId);
                if(subMenu.message != null){
                    response += subMenu.message + '\n\n';
                }
            }

            context.currentMenu = tag.subMenuId;

            Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> subMenuMap = context.menuWithSubMenuMap.get(context.currentMenu);

            /**
             * Submenu has submenu's
             */
            if(subMenuMap != null){
                constructSubMenu(context, response, subMenuMap);
            }
            /**
             * Submenu has action
             */
            else{
                Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action>  subMenuActionMap = context.subMenuWithActionMap.get(context.currentMenu); 

                /**
                 * Found an Action
                 */
                if(subMenuActionMap != null){
                    processAction(context, message, subMenuActionMap);
                }
            }
        }
        else{
            context.response = 'Unable to resolve Tag';
        }
    }

    /************************************************************************************************************************
     * UTILITY PHRASE METHODS
     ***********************************************************************************************************************/
    private static void processPhrase(zCCP_CHT_Wrapper context, String message){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Training_Phrase matchPhrase = getMatchingPhrase(context, message);

        if(matchPhrase != null){
            zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action = context.actionMap.get(matchPhrase.actionId);

            switch on action.type {
                when 'zCCP_CHT_URL'{
                    constructURLAnswer(context, action);
                }
                when 'zCCP_CHT_Answer' {
                    constructTextAnswer(context, action);
                }
                when 'zCCP_CHT_Query'{
                    constructSOQLAnswer(context, message, action);
                }
            }
        }
        else{
            context.response = 'Unable to resolve Phrase';
        }
    }

    private static zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Training_Phrase getMatchingPhrase(zCCP_CHT_Wrapper context, String message){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Training_Phrase matchPhrase;

        List<String> messageWords = message.split(' ');

        Integer matchCounter;
        List<String> allKeyWords; 
        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Training_Phrase currentPhrase;

        Integer maxCounter = 0;

        for(String phrase : context.trainingPhraseMap.keySet()){
            matchCounter = 0;
            
            currentPhrase = context.trainingPhraseMap.get(phrase);
            if(currentPhrase.keywords.contains(zCCP_CHT_Constants.KEYWORD_SPLITTER)){
                allKeyWords = currentPhrase.keywords.toLowerCase().split(zCCP_CHT_Constants.KEYWORD_SPLITTER);
            }
            else{
                allKeyWords = new List<String>{currentPhrase.keywords.toLowerCase()};
            }

            for(String word : messageWords){
                for(String keyWord : allKeyWords){
                    if(keyWord.contains(word)){
                        matchCounter += 10;
                    }
                }
                if(currentPhrase.phrase.contains(word)){
                    matchCounter += 1;
                }
            }

            if(matchCounter > maxCounter){
                maxCounter = matchCounter;
                matchPhrase = currentPhrase;
            }
        }

        return matchPhrase;
    }


    /************************************************************************************************************************
     * UTILITY SORT METHODS
     ***********************************************************************************************************************/
    private static List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu> sortMenus(List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu> menus){

        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu> initMenus = new List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu>();
        initMenus.addAll(menus);

        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu> sortedMenus = new List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu>();

        Decimal minimum = 1000000;
        Integer index;
        while(sortedMenus.size() != menus.size()){
            for(Integer i=0; i < initMenus.size(); i++){
                if(initMenus[i].sortOrder == null || initMenus[i].sortOrder < minimum){
                    minimum = initMenus[i].sortOrder;
                    index = i;
                }
            }
            if(index != null){
                sortedMenus.add(initMenus[index]);
                initMenus.remove(index);
                index = null;
                minimum = 1000000;
            }
        }

        return sortedMenus;
    }

    private static List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> sortSubMenus(List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> subMenus){

        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> initSubMenus = new List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu>();
        initSubMenus.addAll(subMenus);

        List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> sortedSubMenus = new List<zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu>();

        Decimal minimum = 10000;
        Integer index;
        while(!initSubMenus.isEmpty()){
            for(Integer i=0; i < initSubMenus.size(); i++){
                if(initSubMenus[i].sortOrder == null || initSubMenus[i].sortOrder < minimum){
                    minimum = initSubMenus[i].sortOrder;
                    index = i;
                }
            }
            if(index != null){
                sortedSubMenus.add(initSubMenus[index]);
                initSubMenus.remove(index);
                index = null;
                minimum = 10000;
            }
        }

        return sortedSubMenus;
    }

    /************************************************************************************************************************
     * UTILITY INIT METHODS
     ***********************************************************************************************************************/
    private static void processInitMenu(zCCP_CHT_Wrapper context, zCCP_CHT_Chat_Config__c cConf){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu menu = new zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Menu((String) cConf.Id, cConf.Name, cConf.zCCP_CHT_Sort_Order__c, cConf.zCCP_CHT_Header_Message__c);

        if(!context.menuMap.containsKey(menu.recordId)){
            context.menuMap.put(menu.recordId, menu);
        }
    }

    private static void processInitSubMenu(zCCP_CHT_Wrapper context, zCCP_CHT_Chat_Config__c cConf){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu subMenu = new zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu((String) cConf.Id, (String) cConf.zCCP_CHT_Parent_Chat_Config__c, cConf.Name, cConf.zCCP_CHT_Sort_Order__c, cConf.zCCP_CHT_Header_Message__c);

        if(!context.subMenuMap.containsKey(subMenu.recordId)){
            context.subMenuMap.put(subMenu.recordId, subMenu);
        }

        if(!context.menuWithSubMenuMap.containsKey(subMenu.menuId)){
            context.menuWithSubMenuMap.put(subMenu.menuId, new Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu>());
        }

        Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Sub_Menu> intermediateMap = context.menuWithSubMenuMap.get(subMenu.menuId);
        intermediateMap.put(subMenu.recordId, subMenu);
        context.menuWithSubMenuMap.put(subMenu.menuId, intermediateMap);
    }

    private static void processInitAction(zCCP_CHT_Wrapper context, zCCP_CHT_Chat_Config__c cConf){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action action = new zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action((String) cConf.Id, (String) cConf.zCCP_CHT_Parent_Chat_Config__c, cConf.name, cConf.zCCP_CHT_Action_Type__c, cConf.zCCP_CHT_Action_Answer__c, cConf.zCCP_CHT_SOQL__c, cConf.zCCP_CHT_Header_Message__c);

        if(action.subMenuId != null){
            if(!context.subMenuWithActionMap.containsKey(action.subMenuId)){
                context.subMenuWithActionMap.put(action.subMenuId, new Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action>());
            }

            Map<String, zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Action> intermediateMap = context.subMenuWithActionMap.get(action.subMenuId);
            intermediateMap.put(action.recordId, action);
            context.subMenuWithActionMap.put(action.subMenuId, intermediateMap);
        }

        if(!context.actionMap.containsKey(action.recordId)){
            context.actionMap.put(action.recordId, action);
        }
    }

    private static void processInitTag(zCCP_CHT_Wrapper context, zCCP_CHT_Chat_Config__c cConf){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Tag tag = new zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Tag((String) cConf.Id, (String) cConf.zCCP_CHT_Parent_Chat_Config__c, cConf.name);

        if(!context.tagMap.containsKey(tag.name.toLowerCase())){
            context.tagMap.put(tag.name.toLowerCase(), tag);
        }
    }

    private static void processInitTrainingPhrase(zCCP_CHT_Wrapper context, zCCP_CHT_Chat_Config__c cConf){

        zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Training_Phrase tPhrase = new zCCP_CHT_Wrapper.zCCP_CHT_Wrapper_Training_Phrase((String) cConf.Id, (String) cConf.zCCP_CHT_Parent_Chat_Config__c, cConf.zCCP_CHT_Training_Phrase__c.toLowerCase(), cConf.zCCP_CHT_Training_Phrase_Keywords__c);

        if(!context.trainingPhraseMap.containsKey(tPhrase.phrase.toLowerCase())){
            context.trainingPhraseMap.put(tPhrase.phrase.toLowerCase(), tPhrase);
        }
    }
}
