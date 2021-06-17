pub contract interface TokenBlockLister{ 
    
    // event when Account Blocked 
    pub event Blocked(account: Address);

    // event when Account Unblocked 
    pub event Unblocked(account: Address);

    pub resource interface UpdateBlockList {
        // set paused = true; 
        pub fun Blocked(account: Address);
        
        // set paused = false; 
        pub fun Unblocked(account: Address);
    }
}
