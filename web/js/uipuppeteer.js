/// Helper functions for puppeteering the Flutter app

const UIP = {
    subscriptions:{}
}

function triggerComponentEventJS(eventName, hashCode, componentName, payload){
    if(UIP.subscriptions[hashCode] && UIP.subscriptions[hashCode][eventName]){
        UIP.subscriptions[hashCode][eventName].forEach(e => {
            e.func.call(e, e, payload);
        });
    }
}

//document.querySelector('iframe').contentWindow.navigateToPage('Screens/SelectBreathModeRunning')
// callFuncJS('navigateToPage', 'Screens/SelectBreathModeRunning', 'iframe')
function callFuncJS(funcName, params, selector){
    let ps = []
    if(params){
        if(Array.isArray(params)) {
            ps = params
        }else if(typeof params == 'string'){
            ps = params.split('|')
        }
    }
    if(selector){
        document.querySelector(selector).contentWindow[funcName].apply(this, ps)
    }else{
        window[funcName].apply(this, ps)
    }
}

/**
 * Subscribe to component event
 * @param {*} eventName Event name e.g. tap, tapUp, tapDown ...
 * @param {Integer or Object} hashCode hash code of flutter widget (integer) or object with {name:'Component Name', index:0}
 * @param {*} func Function to trigger on event
 * @param {*} componentName Optional component name when using integer hashCode
 * examples:

 subscribeToComponentEvent('tap', 1234, (event)=>{})

 subscribeToComponentEvent('tap', {
     name: 'ButtonWhoIs/Default State',
     index: 0
 }, (event)=>{
     console.log('Event triggered', event)
 })

 */
function subscribeToComponentEvent(eventName, hashCode, func, componentName){
    if(isNaN(hashCode) && typeof hashCode == 'object'){
        componentName = hashCode.name
        let index = hashCode.index || 0
        hashCode = getWidgetHashCode(componentName, index)
        if(hashCode == -1) throw Error('Widget', componentName, 'not found')
    }
    if(!UIP.subscriptions[hashCode]) UIP.subscriptions[hashCode] = {}
    if(!UIP.subscriptions[hashCode][eventName]) UIP.subscriptions[hashCode][eventName] = []
    let len =  UIP.subscriptions[hashCode][eventName].push({componentName, eventName, hashCode, func})
    return len - 1
}

function unsubscribeToComponentEvent(eventName, hashCode, index){
    if(UIP.subscriptions[hashCode] && UIP.subscriptions[hashCode][eventName] && UIP.subscriptions[hashCode][eventName][index]){
        UIP.subscriptions[hashCode][eventName].splice(index, 1)
    }
}