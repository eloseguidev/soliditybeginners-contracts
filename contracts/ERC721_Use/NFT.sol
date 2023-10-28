// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    // Llevar la cuenta del número de NFTs que hay en la colección
    uint256 private _counter;
    uint256 private _price = 2 ether;
    uint256 private _priceLevelUp = 1 ether;
    address private _owner;

    struct Nft {
        string name;
        uint256 id;
        uint8 level;
        uint8 rarity;
    }

    Nft[] private _nfts;

    event newNFT(address owner, uint256 id, string name);

    constructor(string memory collectionName_, string memory symbol_) Ownable(msg.sender) ERC721(collectionName_, symbol_) {
        _counter = 0;
    }

    // --------------------------------------------------------------------------
    // ------------------------------ Funciones públicas ------------------------
    // --------------------------------------------------------------------------

    // @notice Crear un NFT aleatorio a partir únicamente del nombre
    function createRandomNft(string memory name) public payable {
        require(msg.value >= _price, "Insufficient money");
        _createNFT(name);

        /* Calculamos lo que sobra de msg.value tras la transacción para devolverla a msg.sender
         * si no se escriben las dos líneas siguientes, aunque el precio de la transacción sea menor, 
         * se consumirá todo el msg.value disponible y pasará al balance del contrato
         */
        uint256 remainder = msg.value - _price;
        payable(msg.sender).transfer(remainder);
    }

    /// @notice Aumentar el nivel del token
    function levelUp(uint256 tokenId) public payable {
        require(msg.value >= _priceLevelUp, "Insufficient money");
        
        // Solo puede aumentar el nivel del token el dueño del mismo
        require(ownerOf(tokenId) == msg.sender, "You don't have permissions");
        _nfts[tokenId].level++;
        
        // Devolver el dinero sobrante
        uint256 remainder = msg.value - _priceLevelUp;
        payable(msg.sender).transfer(remainder);
    }

    // @notice Retirar todo el balance del contrato a la cuenta del propietario
    function withdraw() external payable onlyOwner {
        balanceOf(msg.sender);
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Actualizar el precio del token
    function updatePrice (uint256 price) external onlyOwner {
        _price = price;
    }

    // @notice Actualizar el precio por el que se puede subir de nivel el token
    function updatePriceLevelUp (uint256 priceLevelUp) external onlyOwner {
        _priceLevelUp = priceLevelUp;
    }

    // @notice Obtener todos los NFTs
    function getAllNfts() public view returns (Nft[] memory) {
        return _nfts;
    }

    // @notice Obtener los NFTs que posee una dirección
    function getNftsByOwner(address owner) public view returns (Nft[] memory){
        Nft[] memory newArray;
        uint count;

        for (uint256 i = 0; i <= _nfts.length; i++) 
        {
            if (ownerOf(i) == owner) {
                newArray[count] = _nfts[i];
                count++;
            }
        }
        return newArray;
    }

    // --------------------------------------------------------------------------
    // ------------------------------ Funciones internas ------------------------
    // --------------------------------------------------------------------------

    /*
     * @notice Genera un número aleatorio de 256 bits y la utilizaremos para calcular la rareza de nuestro NFT
     */
    function _randomNumber (uint256 number) internal view returns (uint256) {
        // block.timestamp devuelve la fecha y hora exactas a la que se genera la transacción
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        uint256 randomNumber = uint256(hash);
        return randomNumber % number;
    }

    /// @notice Creación del NFT
    function _createNFT(string memory name) internal {
        //TODO Duda: cómo castea un número de 256 bits a uno de 8 si es el máximo por ejemplo
        uint8 rarity = uint8(_randomNumber(1000));

        Nft memory newToken = Nft(name, _counter, 1, rarity);
        _safeMint(msg.sender, _counter);

        _nfts.push(newToken);

        emit newNFT(msg.sender, _counter, name);

        _counter++;
    }
}