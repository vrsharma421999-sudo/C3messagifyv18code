({
    
    handleChatNotification : function(component, event) {
        var utilityAPI = component.find("utilitybar");
        if(utilityAPI)
        {
            if(event.getParam('unreadMsgCount') && parseInt(event.getParam('unreadMsgCount')) >0 )
            {
                utilityAPI.setUtilityHighlighted({highlighted:true});
                utilityAPI.setUtilityLabel({label: 'WhatsApp Message ('+parseInt(event.getParam('unreadMsgCount'))+')'});
            }else{
                utilityAPI.setUtilityHighlighted({highlighted:false});
                utilityAPI.setUtilityLabel({label: 'WhatsApp Message'});
            }
              
        }
    },

  
})