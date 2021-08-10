// This script reads the allowance field set in a vault for another resource 


// Currently AnyStruct is input arg is not allowed, hence wrapping it in optional
pub fun main(v: AnyStruct?): [UInt8] {
    let value = v!;
    switch value.getType(){
        case Type<String>():
            let temp = value as? String;
            return temp!.utf8;
        case Type<UInt64>():
            let temp = value as? UInt64;
            return temp!.toBigEndianBytes();
        case Type<UFix64>():
            let temp = value as? UFix64;
            return temp!.toBigEndianBytes();
        case Type<Address>():
            let temp = value as? Address;
            return temp!.toBytes();
        default:
            log("Type is not supported")
            return []
    }
}
