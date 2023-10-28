// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketPlace is Ownable(msg.sender) {
    IERC20 private _tokenERC20;
    IERC721 private _nftsCollection;

    enum SaleStatus {
        open, 
        cancelled, 
        executed 
    }

    struct Sale {
        address owner;
        SaleStatus status;
        // cantidad en tokens ERC20 que se va a transferir a la cuenta del antiguo propietario
        uint256 price;
    }

    // Almacena la venta de los tokens (identificador del token => valores de la venta)
    mapping (uint256 tokenId => Sale) private _sales;

    // Almacena para cada token el número del bloque en el que se ha ejecutado la transacción
    mapping (uint256 tokenId => uint256 blockNumber) private _security;

    /* Definimos un modifier para asegurarnos de que no estamos haciendo operaciones con el mismo token dentro del mismo bloque
     * Por ejemplo: No puede comprarse y venderse un token dentro del mismo bloque 
     * Esto es para evitar un tipo de hackeo que se llama front running
     */
     modifier frontRunning(uint256 nftId) {
        // Comprobamos que el blockNumber correspondiente al nftId es 0, eso quiere decir que no se ha hecho ninguna operación con ese token de momento
        // o que el bloque sea estrictamente menor al que se está minando actualmente (block.number)
        require(_security[nftId] == 0 || _security[nftId] < block.number, "MarketPlace: Security error");

        // Si pasa las comprobaciones de seguridad, se graba el bloque actual en el mapping de seguridad s
        _security[nftId] = block.number;
        _;
     }

    /*
     * @notice Al desplegar este contrato será necesario tener desplegado previamente un token ERC20 y una colección de NFTs   
     * Los tokens de la colección nftsCollection que se van a vender en este MarketPlace van a ser pagados con tokenERC20 
     * que ha de estar previamente desplegado
     */
    constructor(address tokenERC20, address nftsCollection)  {
        _tokenERC20 = IERC20(tokenERC20);
        _nftsCollection = IERC721(nftsCollection);
    }

    // @notice la ejecutan los propietarios de los NFT para ponerlos a la venta
    function openSale(uint256 nftId, uint256 price) public frontRunning(nftId) {
        // Tenemos que comprobar que el msg.sender sea el propietario del token que se está poniendo a la venta
        require(msg.sender == _nftsCollection.ownerOf(nftId), "MartketPlace: You don't have permissions");
        
        // Transferimos el token con identificador nftId de la cuenta de quien ejecuta el contrato al market place
        // con address(this) accedemos a la dirección de este contrato
        _nftsCollection.transferFrom(msg.sender, address(this), nftId);

        _sales[nftId] = Sale(msg.sender, SaleStatus.open, price);
    }

    // @notice Cancelar una venta. Para permitir que alguien que ha puesto un token suyo a la venta, pueda retirarlo de la venta
    function cancelSale(uint256 nftId) public frontRunning(nftId) {
        // primero se comprueba que somos propietarios del token
        require(msg.sender == _sales[nftId].owner, "You don't have permissions");

        // Comprobar que el token no ha sido ya vendido
        require(_sales[nftId].status == SaleStatus.open);

        // cambiar el estado de la venta en el mapping
        _sales[nftId].status = SaleStatus.cancelled;

        // transferir el token a nuestra cuenta (desde la dirección del contrato a nuestro msg.sender
        _nftsCollection.transferFrom(address(this), msg.sender, nftId);
    }

    // @notice Comprar tokens que estén a la venta
    function buyTokens(uint256 nftId) public frontRunning(nftId) {
        // comprobamos que el token está en estado 'open'
        require(_sales[nftId].status == SaleStatus.open, "Sale is not open");

        // Hacemos las transferencias esta vez de tokens ERC20 y este contrato se va a llevar una pequeña tasa por ejecutar el contrato
        // Si el NFT tiene un precio de 10 tokens, aplicamos una tasa del 5% que será lo que se quede el SmartContract
        // En _sales[nftId].owner está el actual dueño del token, que será quien lo venda a msg.sender
        address actualOwner = _sales[nftId].owner;
        require(_tokenERC20.transferFrom(msg.sender, actualOwner, _sales[nftId].price));
        require(_tokenERC20.transferFrom(msg.sender, address(this), _sales[nftId].price * 5/100));

        // Transferir el token al nuevo propietario
        _nftsCollection.transferFrom(actualOwner, msg.sender, nftId);

        // Actualizamos el mapping de sales
        _sales[nftId].owner = msg.sender;
        _sales[nftId].status = SaleStatus.executed;
    }

    // @notice Retirar el balance por parte del owner
    function getFees() public onlyOwner {
        // msg.sender será el owner porque está especificado con el modifier onliOwner
        require(_tokenERC20.transfer(msg.sender, _tokenERC20.balanceOf(address(this))), "Error transfering token");
    }
}