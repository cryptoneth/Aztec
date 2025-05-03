![1080x360](https://github.com/user-attachments/assets/15741795-7527-4c5b-9378-f4b585485ecf)


# Crypton's Aztec Sequencer Node Setup Guide

<p align="center">
  <pre>
_________                        __                 
\_   ___ \_______ ___.__._______/  |_  ____   ____  
/    \  \/\_  __ <   |  |\____ \   __\/  _ \ /    \ 
\     \____|  | \/\___  ||  |_> >  | (  <_> )   |  \
 \______  /|__|   / ____||   __/|__|  \____/|___|  /
        \/        \/     |__|                    \/
  </pre>
</p>

this script automates setting up an Aztec Sequencer Node on the testnet, guiding you to run a node and earn the **Apprentice** role on the Aztec Discord. Contribute to Aztec’s privacy-focused network with ease! 🚀

**Note**: No confirmed rewards or airdrops exist. This is for learning and early contribution.

## 💻 System Requirements
| Component      | Specification               |
|----------------|-----------------------------|
| CPU            | 8-core Processor            |
| RAM            | 16 GiB                      |
| Storage        | 100 GiB SSD                 |
| Internet Speed | 25 Mbps Upload / Download   |

> [!Note]
> A 4-core CPU, 8 GiB RAM, and 25 GiB storage suffice for earning the **Apprentice** role, but meet recommended specs for long-term stability.

## ⚙️ Prerequisites
- **Ubuntu System**: Script requires Ubuntu.
- **Sepolia Ethereum RPC**: Get from [Alchemy](https://dashboard.alchemy.com/apps).
- **Sepolia Beacon RPC**: Obtain from [Chainstack](https://chainstack.com/global-nodes).
- **EVM Wallet**: Fund with **2.5 Sepolia ETH** for validator registration.
- **sudo Privileges**: Needed for package installation and firewall setup.

> [!IMPORTANT]
> Free RPC services may hit request limits. Switch providers or upgrade if limited.

## 📥 Installation
1. **Clone and Run the Script**:
   ```bash
   cd
   rm -r Aztec
   git clone https://github.com/cryptoneth/Aztec.git
   cd Aztec
   chmod +x aztec.sh
   ./aztec.sh


**Follow Prompts:

Step 1 - 3: ... !

Step 4: Enter Sepolia Ethereum RPC, Beacon RPC, Ethereum private key, public address (with 2.5 Sepolia ETH), and server IP.

Step 7: Confirm earning the Apprentice role on Discord.

you can see your node running

```bash
screen -x aztec
```

Press Crtl + A + D to quit

Get Role
Go to the discord channel :[operators| start-here](https://discord.com/invite/aztec) and follow the prompts, You can continue the guide with my commands if you need help.

![image](https://github.com/user-attachments/assets/90e9d34e-724b-481a-b41f-69b1eb4c9f65)

**Step 1: Get the latest proven block number:**
```bash
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
http://localhost:8080 | jq -r ".result.proven.number"
```
* Save this block number for the next steps
* Example output: 20905

**Step 2: Generate your sync proof**
```bash
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK_NUMBER","BLOCK_NUMBER"],"id":67}' \
http://localhost:8080 | jq -r ".result"
```
* Replace 2x `BLOCK_NUMBER` with your number

**Step 3: Register with Discord**
* Type the following command in this Discord server: `/operator start`
* After typing the command, Discord will display option fields that look like this:
* `address`:            Your validator address (Ethereum Address)
* `block-number`:      Block number for verification (Block number from Step 1)
* `proof`:             Your sync proof (base64 string from Step 2)

Then you'll get your `Apprentice` Role

## Register Validator
```bash
aztec add-l1-validator \
  --l1-rpc-urls RPC_URL \
  --private-key your-private-key \
  --attester your-validator-address \
  --proposer-eoa your-validator-address \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```
Replace `RPC_URL`, `your-validator-address` & 2x `your-validator-address`, then proceed


##Update your node :

```
aztec-up alpha-testnet
```
---

# Error: `ERROR: world-state:block_stream Error processing block stream: Error: Obtained L1 to L2 messages failed to be hashed to the block inHash`

* Stop node with Ctrl+C.
* Delete node data:
```bash
rm -r /root/.aztec/alpha-testnet
```
* Re-run the node using run command.
