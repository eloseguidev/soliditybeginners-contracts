// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

/// @notice Interfaz del token ERC20
interface IERC20 {
    /// @notice Obtener el número de decimales del token
    /// @return Entero con el número de decimales del token
    function totalSupply() external view returns (uint256);

    /// @notice Devuelve el balance de la cuenta que recibe como parámetro
    /// @param account cuenta de la que se consultará el balance
    /// @return balance de la cuenta
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfiere tokens desde quien ejecuta el contrato a la dirección indicada
    /// @param to dirección a la que se transfieren los tokens
    /// @param amount cantidad de tokens a transferir
    /// @return true si la transacción se ejecuta correctamente y false en caso contrario
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Devuelve el número de tokens pertenecientes a owner pero que puede gestionar spender. La gestión se realizará a través del método approve.
    /// @param owner Dirección que posee los tokens
    /// @param spender Dirección que puede gestionar tokens de owner
    /// @return Número de tokens de owner que puede gestionar spender
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice La persona que ejecuta el contrato autoriza a spender a gestionar la cantidad de tokens amount
    /// @param spender Dirección a la que se autoriza la gestión de los tokens
    /// @param amount Cantidad de tokens que se autoriza a gestionar
    /// @return true si la transacción se ejecuta correctamente y false en caso contrario
    function approve(address spender, uint amount) external returns (bool);

    /// @notice El spender puede gastar o enviar los tokens que tiene delegados por el owner a la dirección to
    /// @param from es la dirección del dueño original de los tokens, el owner
    /// @param to la dirección a la que irán destinados esos tokens
    /// @param amount número de tokens
    /// @return true si la transacción se ejecuta correctamente y false en caso contrario
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // ----------------- EVENTOS -----------------
    /// @dev los parámetros indexed permiten buscar estos eventos a través de las address
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);
}
