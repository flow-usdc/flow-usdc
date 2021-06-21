pub contract interface TokenBlockLister{ 
    
    // event when resource is Blocked 
    pub event Blocklisted(resourceId: UInt64);

    // event when resource is Unblocked 
    pub event Unblocklisted (resourceId: UInt64);

    pub resource interface UpdateBlockList {
        // add to blocklist 
        pub fun blocklist(resourceId: UInt64);
        
        // remove from blocklist
        pub fun unblocklist(resourceId: UInt64);
    }
}
