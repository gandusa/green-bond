 Green-Bond Smart Contract

 Overview
The **Green-Bond Smart Contract** is a Clarity-based blockchain solution designed to issue and manage environmentally focused bonds.  
It enables transparent fundraising for sustainable projects while ensuring investor protection through trustless execution and immutable records.

 Features
- **Bond Issuance**: Contract owner can create green bonds with fixed interest rates and maturity dates.
- **Investor Participation**: Investors can purchase bonds using STX.
- **Automatic Interest & Payout**: Investors receive their principal plus interest at maturity.
- **Transparency**: Bond details are publicly viewable on-chain.
- **Eco-Funding Guarantee**: Ensures funds are allocated only to verified sustainable projects.

 How It Works
1. **Bond Creation**: Owner sets the bond parameters (maturity date, interest rate, total supply).
2. **Investment**: Investors send STX to purchase bond units.
3. **Hold Period**: Funds remain locked until maturity.
4. **Maturity Payout**: Investors can claim their principal + interest once the bond matures.

 Smart Contract Functions
| Function Name       | Description |
|---------------------|-------------|
| `create-bond`       | Allows contract owner to issue a new green bond. |
| `buy-bond`          | Enables investors to purchase bond units. |
| `get-bond-details`  | Returns bond information for public viewing. |
| `claim-payout`      | Allows investors to claim principal + interest after maturity. |
| `get-investor-info` | Retrieves an investor's holdings and expected payout. |

 Requirements
- [Clarinet](https://github.com/hirosystems/clarinet) installed for local development.
- Stacks blockchain wallet with STX for deployment.

 Installation & Testing
```bash
# Clone the repository
git clone https://github.com/<your-username>/green-bond.git
cd green-bond

# Install dependencies
clarinet integrate

# Run tests
clarinet test
