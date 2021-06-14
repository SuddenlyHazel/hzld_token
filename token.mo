import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";
import User "mo:base/Array";

shared({ caller = owner }) actor class Token() = this {
    stable var FEE = 1;

    // A user can be any principal or canister
    type User = Principal;

    // Token amounts are unbounded
    type Balance = Nat;

    type Metadata = Blob;

    // Request and responses for getBalance
    type BalanceRequest = {
        user: User;
    };

    type BalanceResponse = [Balance];

    // Request and responses for transfer
    type TransferRequest = {
        from: User;
        to: User;
        amount: Balance;
        metadata: ?Metadata;
    };

    type TransferResponse = Result.Result<(), {
        #Unauthorized;
        #InvalidSource: User;
        #InsufficientBalance;
    }>;

    type OperatorAction = {
        #setOperator;
        #removeOperator;
    };

    type OperatorRequest = {
        owner: User;
        operators: [(User, OperatorAction)];
    };

    type OperatorResponse = Result.Result<(), {
        #Unauthorized;
        #InvalidOwner: User;
    }>;

    // Request and responses for isAuthorized
    type IsAuthorizedRequest = {
        owner: User;
        operator: User;
        amount: Balance;
    };

    type IsAuthorizedResponse = [Bool];

    // Utility functions for User and TokenId, useful when implementing containers
    module User = {
        public let equal = Principal.equal;
        public let hash = Principal.hash;
    };

    stable var balanceEntries : [(User, Balance)] = [];
    let balances : HashMap.HashMap<User, Balance> = HashMap.fromIter(balanceEntries.vals(), 0, User.equal, User.hash);

    public shared func getNumberOfAccounts() : async Nat {
        balances.size();
    };

    public shared func getBalance(request: BalanceRequest) : async ?Balance {
        switch(balances.get(request.user)) {
                case(?v) {
                    return ?v;
                };
                case(null) {return null};
        };
    };

    public shared query func getBalanceInsecure(request: BalanceRequest) : async ?Balance {
        switch(balances.get(request.user)) {
                case(?v) {
                    return ?v;
                };
                case(null) {return null};
        };
    };

    public shared({caller = caller}) func transfer(request: TransferRequest) : async TransferResponse {
        if (not isAuthorized(caller, request.from)) {
            return #err(#Unauthorized);
        };

        switch (balances.get(request.from)) {
            case (?balance) {
                if (request.amount + FEE > balance) {
                    return #err(#InsufficientBalance);
                };
                subBalance(request.from, request.amount + FEE);
                addBalance(request.to, request.amount);
                addBalance(Principal.fromActor(this), FEE); //Community Chest
            };
            case (null) {
                return #err(#InvalidSource(request.from));
            }
        };
        
        //Integrate your own wbl here
        //ignore TransactionWbl.writeTransaction(request.from, request.to, request.amount);
        return #ok();
    };

    // Can caller act on user balance?
    private func isAuthorized(caller : User, user : User) : Bool {
        return user == caller;
    };

    // Any Principal can get a balance
    private func addBalance(user : Principal, amount : Nat) {
        switch(balances.get(user)) {
            case (?balance) {
                balances.put(user, amount + balance)
            };
            case (null) {
                balances.put(user, amount);
            }
        };
    };

    private func subBalance(user : Principal, amount : Nat) {
        switch(balances.get(user)) {
            case (?balance) {
                assert balance >= amount;
                balances.put(user, balance - amount)
            };
            case (null) {
                assert false; // TRAP
            }
        };
    };

    system func preupgrade() {
        balanceEntries := Iter.toArray(balances.entries());
    };

    system func postupgrade() {
        balanceEntries := [];
    };
}
