#  B Hash Masternode Docker Install

### Requirements:
* 2000 HASH + tx fee (any more or less, even by a fraction and propagation will be unsuccessful)
* A computer to host your local wallet (your main computer is adequate and allows you to manage Masternodes on your local wallet while you host them securely on a VPS)
* A server that is powered on, connected to the internet 24/7 and has a static IP address.

*Note:  Lines that start with a # are comments and should not be entered into the cli (Command Line Interface).  Anything typed inside [square brackets] (including the brackets) is to be replaced with the appropriate text.

1. On your main computer, open the b-hash wallet and go to Tools>Debug Console, you will see a screen like the one below pop up allowing you to access the command line.
![](B%20Hash%20Masternode%20Docker%20Install/bhashConsole.png)
2. Enter the following command to generate a private key for each Masternode.  Save this key somewhere secure, you will need to enter it into your vps. 
```shell
createmasternodekey
# result will look similar to this
# y0uRm4st3rn0depr1vatek3y
```
3. After you generate a private key, you will enter (without quotations):
```shell
# replace MN1 with any alpha-numerical 'alias' that you would like to name your masternode.
# This is for your future reference and not a public address.

getaccountaddress MN1
# result will look similar to this
# mA7fXSTe23RNoD83Esx6or4uYLxLqunDm5
```
5. You will receive an address that you will send the 2000 hash stake to.
6. Still in the b-hash wallet, send 2000 hash to the address that you created in the previous step with the `getaccountaddress` command, ensure it is exactly 2,000 hash after the tx fee is deducted, any variance and installation will be unsuccessful.
7. Once you see the 2000 hash show up in your transactions enter the following command into the console:
```shell
masternode outputs
# result will look similar to this
# tr4ns4cti0nh4ash 0
```
8. you will get a transaction ID and a transaction index. The first is the transaction ID that will verify you have sent exactly 2000 hash as collateral, the second verifies the transaction index, often this will simply be 0.
9. Create a line like the one below populating the information with what we’ve created above. Replace the text in brackets (including the brackets) with the actual values.
```
[ALIAS] [IP:17652] [MASTERNODEPRIVKEY] [TXID] [TXIN]
```
[ALIAS]: your node alias.  
[IP: 17652] your server public IP address and the Masternode port.  
[MASTERNODEPRIVKEY] the private key that you created in step 2.  
[TXID] the transaction ID that you created in step 7.  
[TXIN] the transaction index from step 7, usually 0.  
For example:  `myn0de 123.456.789:17652 y0uRm4st3rn0depr1vatek3y tr4ns4cti0nh4ash 0`.  You will also need this information to enter into the Masternode VPS.  
11. Log into your VPS, enter the following command and follow the prompts:
```shell
sudo bash -c "$(curl -sSL https://raw.githubusercontent.com/greerso/docker-bhash-masternode/master/install.sh)"
```
12. Back in the wallet on your main computer, go to Tools>Open Masternode Configuration File.  A text file will open in your default text editor.  Enter the text that you created in step 10, delete anything else.  You should have one line per Masternode.  Save the file and exit the text editor:
```shell
MN1 123.456.789:17652 y0uRm4st3rn0depr1vatek3y tr4ns4cti0nh4ash 0
```
13. In the wallet, this time go to Tools>Open Wallet Configuration File.  and add the following text, replacing the information in brackets with the values from the Masternode:
```shell
 rpcuser=[username]
 rpcpassword=[password]
 rpcallowip=127.0.0.1
 listen=0
 server=1
 daemon=0
 logtimestamps=1
 maxconnections=256
```
14. Close the wallet, then reopen it.  If you get an error, you have likely made a typo in either the Masternode Configuration File from step 12 or the Wallet Configuration File from step 13.
15. When you reopen the wallet, you should see your Masternode listed in the Masternodes tab.
16. You will now be able to use the wallet Masternode buttons to start your alias’.  It may take up to 24 hours for your Masternode to fully propagate.
 
![](B%20Hash%20Masternode%20Docker%20Install/BHash_Core_-_Wallet.jpg)
17. Back on your VPS, you can check the status of your Masternode running inside the docker container at any time by typing one of the following (self explanatory commands:
```shell
bhash-cli masternode status
bhash-cli getinfo
bhash-cli help```

BASH: bUfQ5De52EYbi3Rn6XL9LnN466hs7nCzkJ  
ETH: 0x0f64257fAA9E5E36428E5BbB44C9A2aE3A055577  
ZEN: zndLiWRo7cYeAKuPArtpQ6HNPi6ZdaTmLFL  
BTC: 1BzrkEMSF4aXBtZ19DhVf8KMPVkXjXaAPG  
