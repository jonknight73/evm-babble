pragma solidity ^0.4.18;

contract LotteryContract {

  uint constant standardStake = 100;
  bytes32 name;
  HouseAccount houseAccount; 

  Entry[] entries;
  bytes32 drawSeed;
  PrizeAccount[] prizeAccounts;

  struct HouseAccount {
    address beneficiary;
    uint clearedBalance;
    uint payments;
  }


  struct PrizeAccount {
    uint balance;
    string name;
    uint percentageOfStake;    
    bytes32 winPattern;
    uint wins;
    uint payouts;    
  }

  event NewStake(
    address houseAccount,
    address playerAccount,
    uint amount
  );

  event NewPayout(
    address playerAccount,
    address houseAccount,
    uint amount
  );

  event Settlement(
    bool ok
  );


  struct Entry {
    address addr;
    uint  stake;
    bool closedDraw;
  }



  function LotteryContract() public {


// Set up the prize prizeAccounts
        prizeAccounts.push(PrizeAccount(0,"Small Prizes", 40, 0x007, 0, 0));
        prizeAccounts.push(PrizeAccount(0,"Big Prizes", 25, 0x0000077, 0, 0));
        prizeAccounts.push(PrizeAccount(0,"Jackpot Prizes", 35, 0x000000000777, 0, 0));


// Set up house account
        houseAccount = HouseAccount(msg.sender, 0, 0);

// For production system, we would validate that the percentageOfStake sum is 
// between 0 and 100 inclusive

  }



  function enterDraw() public payable {
    uint moneyLeft = msg.value; 

  // Split the stake between prizeAccounts

    for(uint i=0;i<prizeAccounts.length;i++) {
        uint amt = (prizeAccounts[i].percentageOfStake * msg.value)/100;
        moneyLeft -= amt;
        prizeAccounts[i].balance += amt; 
    }


  // The house takes whats left. NB there are no checks to prevent this
  // being negative
    houseAccount.clearedBalance += moneyLeft;
    houseAccount.payments++;

    NewStake(houseAccount.beneficiary, msg.sender, msg.value);  

    entries.push(Entry(msg.sender, msg.value, false) );
  }




function setDrawSalt() public  {
  address[] memory addrs = new address[](entries.length);
  // bytes memory str = new bytes();
 
  for(uint i=0;i<entries.length;i++) {
      addrs[i]=entries[i].addr;
      entries[i].closedDraw = true;   
   }

  drawSeed = keccak256(addrs,block.blockhash(block.number - 1));
}


function processDrawResults() public  {
  bytes32[] memory seeds = new bytes32[](entries.length);

  for(uint i=0;i<entries.length;i++) {
    if (entries[i].closedDraw ) {
      seeds[i] =  keccak256(entries[i].addr, drawSeed) ;
    }
  }


  for(uint j=0;j<prizeAccounts.length;j++) {
    uint[] memory winners = new uint[](entries.length);
    uint memoryIdx = 0;

    for(i=0;i<entries.length;i++) {
      if (entries[i].closedDraw ) {
        if (seeds[i] & prizeAccounts[j].winPattern == prizeAccounts[j].winPattern)
        {
            winners[memoryIdx++] = i;
        }
      }
    }

    if (memoryIdx > 0) // We have winners
    {
        uint winnings = prizeAccounts[j].balance / memoryIdx;
        for (i=0; i < memoryIdx; i++)
        {
            prizeAccounts[j].wins++;
            prizeAccounts[j].payouts+=winnings;
            prizeAccounts[j].balance-=winnings;
            entries[winners[i]].addr.transfer(winnings);
            NewPayout(entries[winners[i]].addr, houseAccount.beneficiary, winnings);  
        }        
    }
  }

  bool notLastItem = false;
  for(i=entries.length-1;i>=0;i--) {
     if(entries[i].closedDraw)
     {
        if (notLastItem)  // Replace element with last element in array which is an "open" Entry
        {   
          entries[i] = entries[entries.length-1];
        }
        // just remove last item which is now invalid
        delete entries[entries.length-1];
        entries.length--;
     } 
     else
     {
        notLastItem = true;
     }
  }
}


}
