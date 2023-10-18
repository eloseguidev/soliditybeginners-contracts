// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "contracts/ERC20.sol";

contract TokenSale {
    uint256 tokenPrice = 1 ether;

    ERC20 token;

    constructor(address _token) {
        token = ERC20(_token);
    }

    function purchase() public payable {
        require(msg.value >= tokenPrice, "ERROR: Not enough money");
        // Se van a comprar tantos tokens como lo que tenemos en msg.value nos permita
        uint256 tokensToTransfer = msg.value / tokenPrice;

        // msg.sender en este caso no es la de quien despliega el smart contract sino la del contrato TokenSale
        // Es necesario enviarle tokens a la dirección en la que se despliega este contrato para poder hacer la operación.
        token.transfer(msg.sender, tokensToTransfer * 10 ** token.decimals());
    }
}