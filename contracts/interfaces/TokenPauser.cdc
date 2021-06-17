pub contract interface TokenPauser { 
    
    // state if it is paused
    pub var paused: Bool;
    
    // event when state changed to true
    pub event Paused();

    // event when state changed to false
    pub event Unpaused();

    pub resource interface Execute {
        // set paused = true; 
        pub fun pause();
        
        // set paused = false; 
        pub fun unpause();
    }

}
