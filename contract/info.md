I’m currently studying how MakerDAO’s stablecoin system works, and I’ve learned that it’s made up of \*\*modular smart contracts that all interact with each other to make the DAI stablecoin possible.
and as we are borrowing stableCoin using someone's else money we have to pay extra in easy worjd we have to pay interest and this interest in stableCoin is called as stabilityFee;
and the stability fee will change every second as increases exponentially that ans we know that htis calculation can also return in decimals e.g. 023.223 and as we know their is no concept of it in evm ecosystem and this the reason why we increse the value with RAD that 1e45 that cant cause error. and also one more important thing that stability fee can volatile every second mean its not fixed. 

One of the key parts is the **Vat** contract, it’s like the **heart of the whole system**, where all collateral and debt balances are tracked.
Each user creates a **CDP (Collateralized Debt Position)**, also called a **vault**, where they lock collateral to generate DAI.

🧠 **1. Vat (Core Accounting)** in our code base its called as CDPEngine
This is the core ledger of MakerDAO. It keeps track of everyone’s collateral, debt, and the overall balances of the system. Every other module connects to this one.

💎 **2. GemJoin (Collateral Gateway)**
This contract lets users deposit ERC20 tokens like WETH or WBTC into the system. Once deposited, the collateral gets recorded inside the Vat.

💰 **3. DaiJoin (Stablecoin Gateway)** in our code base its called as INRCJoin
It connects the internal accounting system (Vat) with the actual ERC20 DAI token. When users mint or withdraw aka borrow DAI, this contract handles that bridge.

🏦 **4. CDP Manager (Vault Manager)**
This is the user-facing contract that manages vaults, it lets you open, modify, or close a vault, deposit collateral, and generate or repay DAI. we can think it like index book to keep track what is hapeming.

📈 **5. Spotter (Price Reader)**
This contract reads collateral prices from the PIP (price feed) and updates the system with current market values, so Maker knows whether a vault is safe or undercollateralized.

📊 **6. PIP (Oracle Feed)**
This provides real-time price data of assets like ETH/USD or BTC/USD to the Spotter.

⚡ **7. Dog (Liquidation Trigger)**
This is the watchdog. It monitors all vaults and triggers liquidation when a vault’s collateral ratio drops below the required level. Once triggered, it calls the Clipper contract.

🧨 **8. Clipper (Collateral Auction)**
Clipper is the main liquidation module introduced in Liquidations 2.0. It runs Dutch auctions to sell collateral when a vault is unsafe — starting from a high price that drops over time until buyers purchase it.

💣 **9. Flopper (Debt Auction)**
When the system has a deficit (not enough DAI to cover bad debt), this contract mints new MKR tokens and sells them for DAI to restore balance.

💎 **10. Flapper (Surplus Auction)**
This one handles the opposite — when there’s extra DAI in the system, it sells DAI for MKR to burn MKR tokens and maintain stability.

🛠️ **11. Jug (Stability Fee Manager)**
This contract continuously adds interest (called the “stability fee”) to vaults over time. It’s how MakerDAO earns fees from borrowers.

⏳ **12. Pot (DAI Savings Rate)**
This is the savings module. Users can deposit DAI into the Pot to earn interest, based on the system’s DAI Savings Rate (DSR).

📘 **13. Vow (Accounting of Surplus & Debt)**
The Vow acts like the system’s balance sheet — it keeps track of overall surplus and deficit. It decides whether to trigger **Flapper** (for surplus) or **Flopper** (for debt).

and in this info the MKR is the governance token of makerDAO which is being used by another stable coin too and it's deeply tied to the health of stable Coin,

surpless mean overfill like having more then needded
and debt mean being in loss
Unbacked DAI basically means DAI that was minted without actual collateral


collatralized auctoin when any user wallet is for liquidation so it bid the use collateral in exchange of inrc token add then pay the debt

debt auction when thereis any unbacked system debt so the sys sell the MKR toke to repay the unbacked debt
surplus auction when thier is any more than enough coin so system sells coin and purcahse governance token MKR


dog contract is main liquidation engine 
ds engine is for handling surplus and debt while there is surplus it calls Flopper and while thier is debt it calls liquidation engine

and liquidation engine handles clipper auction 

the clipper contract is designed to handle on type of collateral Auction


cdpEngine
