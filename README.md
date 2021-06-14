# hzld_token

## Motoko Example

https://ic.rocks/principal/qz7gu-giaaa-aaaaf-qaaka-cai

```
module {
  public type Balance = Nat;
  public type BalanceRequest = { user : User };
  public type User = Principal;
  public type Metadata = [Nat8];
  
  public type TransferResponse = {
    #ok;
    #err : { #InsufficientBalance; #InvalidSource : User; #Unauthorized };
  };
  
  public type TransferRequest = {
    to : User;
    metadata : ?Metadata;
    from : User;
    amount : Balance;
  };
    
  public type Token = actor {
    getBalance : shared BalanceRequest -> async ?Balance;
    getBalanceInsecure : shared query BalanceRequest -> async ?Balance;
    getInfo : shared query () -> async {
        balance : Nat;
        maxLiveSize : Nat;
        heap : Nat;
        size : Nat;
    };
    
    transfer : shared TransferRequest -> async TransferResponse;
    updateOperator : shared [OperatorRequest] -> async OperatorResponse;
  };
  
  let tokenService : Token = actor("qz7gu-giaaa-aaaaf-qaaka-cai");
}
```
