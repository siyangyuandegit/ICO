// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable{
    // 代币初始价格
    uint256 public constant tokenPrice = 0.001 ether;
    // 每个nft空投100个代币
    uint256 public constant tokensPerNFT = 10 * 10 ** 18;
    // 代币最大供应量
    uint256 public constant maxTotalSupply = 10000 * 10 ** 18;
    // nft对应合约的实例化对象
    ICryptoDevs CryptoDevsNFT;
    // 记录某个nft是否已经claim代币
    mapping(uint256 => bool) public tokenIdsClaimed;
    // 构造nft合约
    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD"){
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }

    function mint(uint256 amount) public payable{
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is incorrect");
        // mint后代币总量不得大于最大限制
        uint256 amountWithDecimals = amount * 10 ** 18;
        require(
            (totalSupply() + amountWithDecimals < maxTotalSupply), 
            "Exceeds the max total supply available."
        );
        _mint(msg.sender, amountWithDecimals);
    }

    function claim() public{
        address sender = msg.sender;
        uint256 balance = CryptoDevsNFT.balanceOf(sender);
        require(balance > 0, "You dont own any Crypto Dev NFT's");
        uint256 amount = 0;
        // 循环遍历玩家拥有的nft
        for (uint256 i; i < balance; i++){
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);
            if (!tokenIdsClaimed[tokenId]){
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }
        // 要求至少有一个未领取的nft
        require(amount > 0, "You have already claimed all the tokens");
        _mint(msg.sender, amount * tokensPerNFT);
    }

    function withdraw() public onlyOwner{
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent,) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable{}
    fallback() external payable{}
}
