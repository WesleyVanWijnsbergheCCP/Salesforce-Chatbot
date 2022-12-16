import { LightningElement, track} from 'lwc';

/**
 * Import Apex Methods
 */
import initChat from '@salesforce/apex/zCCP_CHT_Controller.initChat';
import processChat from '@salesforce/apex/zCCP_CHT_Controller.processChatMessage';

export default class ZCCP_CHT_Chat extends LightningElement {

    /**
     * Frontend Variables
     */
    userName;
    today;
    userMessage = null;
    @track conversation = [];

    /**
     * Backend Variable - Statefull 
     */
    context;

    /**
     * Error Variable
     */
    error; 

    get disableButton(){
        return this.userMessage ? false : true;
    }

    connectedCallback(){
        this.initChatter();
    }

    initChatter(){
        initChat()
            .then(context => {
                this.context = context;
                this.userName = context.userName;
                this.setResponse(context.response, context);
            })
            .catch(error => {
                this.error = error;
                console.error(error);
            });
    }

    setMessage(event){
        this.userMessage = event.detail.value;
    }

    processEnter(event){
        if(event.keyCode === 13 && !this.disableButton){
            this.submitMessage(event);
        }
    }

    submitMessage(event){
        this.setRequest(this.userMessage);
        processChat({contextString : JSON.stringify(this.context), message : this.userMessage})
            .then(context => {
                this.context = context;
                this.setResponse(context.response, context);
            })
            .catch(error => {
                this.error = error;
                console.error(error);
            })
            .finally(() => {
                this.userMessage = null;
            })
    }

    /**
     *  User Input
     */
    setRequest(request){
        this.today = new Date();
        let req = {
            message : request, 
            isInbound : false,
            timestamp : this.userName + " • " + String(this.today.getHours()).padStart(2, '0') + ":" + String(this.today.getMinutes()).padStart(2, '0')
        }
        this.conversation.push(req);
    }

    /**
     * Bot Response
     */
    setResponse(response, context){
        this.today = new Date();
        let resp = {
            message : response,
            isInbound : true, 
            timestamp : "AskIndra • " + String(this.today.getHours()).padStart(2, '0') + ":" + String(this.today.getMinutes()).padStart(2, '0'), 
            url : context.isUrlAnswer, 
            label : context.URLLabel
        }
        this.conversation.push(resp);
    }
}