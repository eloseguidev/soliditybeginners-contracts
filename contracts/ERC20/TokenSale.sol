// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "contracts/ERC20.sol";

contract TokenSale {
    uint256 tokenPrice = 1 ether;

    ERC20 token;

    constructor(address _token) {
        token = ERC20(_token);
    }

    /// @notice Comprar amount tokens con el saldo de msg.value y recibir el dinero sobrante
    /// @param amount Número de tokens a comprar
    function purchase(uint256 amount) public payable {
        require(msg.value >= tokenPrice * amount, "ERROR: Not enough money");

        // En esta variable se almacenan "las vueltas" el dinero sobrante de msg.value después de hacer la compra
        uint256 remainder = msg.value - (tokenPrice * amount);
        // msg.sender en este caso no es la de quien despliega el smart contract sino la del contrato TokenSale
        // Es necesario enviarle tokens a la dirección en la que se despliega este contrato para poder hacer la operación.
        token.transfer(msg.sender, amount * 10 ** token.decimals());

        // msg.sender es una dirección pero no de tipo payable, así que hay que convertirla antes de poder transferir
        payable(msg.sender).transfer(remainder);
    }
}