<h1 align="center">
  <img alt="bayc logo" src="https://lh3.googleusercontent.com/Ju9CkWtV-1Okvf45wo8UctR-M9He2PjILP0oOvxE89AyiPPGtrR3gysu1Zgy0hjd2xKIgjJJtWIc0ybj4Vd7wv8t3pxDGHoJBzDB=s0" width="168px"/><br/>
  BAYC-ERC721 Solidity contract
</h1>
<p align="center">Recreated Bored Ape Yacht Club contract by using <b>OpenZeppelin libraries</b>. Tested and deployed to Rinkeby test network. <br>Added to OpenSea testnets to test functionality in the real world application.</p>

<p align="center">
  <a href="https://testnets.opensea.io/collection/superfakeboredapeyachtclub" target="_blank"><img src="https://user-images.githubusercontent.com/67603492/164070006-a219739e-5675-4c46-8af6-bdf3874ef50a.png" width="64px" alt="opensea logo" /></a>
  <a href="https://rinkeby.etherscan.io/address/0x93d1bf50a11dbb3b54ef786de38eacd4b85c8c8a" target="_blank"><img src="https://user-images.githubusercontent.com/67603492/164070077-8a3b0e17-3873-49bb-8ff4-0f11f14765b3.png" width="64px" alt="etherscan logo"/></a>
  <a href="https://superfakeboredapeyachtclub.com" target="_blank"><img src="https://user-images.githubusercontent.com/67603492/164071417-4be6f067-c885-499b-b297-8fa63f3bca13.png" width="64px" alt="bayc logo"/>
  </a>
 </p>

## Details
- Contract created using Solidity Style guide, contract documentation using Ethereum NatSpec.
- Removed `starting index` variable and functions assotiated with it, since there's no real use for it on testnets.
- Deployed, tested and veryfied by using <b>hardhat</b> and hardhat pluguns.
- Added <b>OpenZeppelin</b> pausable funcitonality.
- Function to change the mint price while the contract is paused.
- Function to withdraw ether.
- Function to set new URI.
