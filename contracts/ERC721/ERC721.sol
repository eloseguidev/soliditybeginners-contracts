// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC721Metadata.sol";
import "./ERC165.sol";
import "./Context.sol";

import "@openzeppelin/contracts/utils/Strings.sol";


abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Strings for uint256;
    // --------------------------- VARIABLES    
    // Nombre y símbolo de la colección de NFTs
    string private _name;
    string private _symbol;

    /* @notice Mapping para almacenar las direcciones de los propietarios de los tokens. 
    En este caso, como cada token es único, llevará asociado un identificador que es ese uint256 */
    mapping(uint256 tokenId => address) private _owners;
    
    /* @notice Este mapping almacena el número de tokens ERC721 de una colección que tiene una dirección */
    mapping(address owner => uint256) private _balances;

    /* @notice Este mapping almacena las direcciones de los spenders de los ERC721. En el ERC721 también vamos a poder delegar la gestión de los NFT a un tercero    */
    mapping(uint256 tokenId => address) private _tokenApprovals;

    /* @notice Mapping anidado que almacena los operadores autorizados parfa gestionar TODA la colección de tokens de un owner, no solo un NFT*/
    mapping (address owner => mapping (address  operator => bool)) private _operatorApprovals;

    // --------------------------- CONSTRUCTOR, GETTERS Y SETTERS
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override  returns (string memory) {
        return _symbol;
    }

    // --------------------------- FUNCIONES
    
    // Contracts that want to implement ERC165 should inherit from this contract and override supportsInterface to check for the additional interface id that will be supported
    /// @notice Esta función es para ver si este contrato puede soportar las interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                super.supportsInterface(interfaceId);
    }    

    /// @notice Devuelve el número de tokens que tiene asignada la dirección que se introduce por parámetro
    function balanceOf(address owner) public view virtual override returns (uint256) {
        // TODO ¿No se comprueba que la dirección pertenezca al balance? ¿y si es una dirección errónea?
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @notice Devuelve la dirección propietaria del token cuyo identificador es el que se le introduce por parámetro
    function ownerOf(uint256 tokenId) public view virtual override returns (address){
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @notice Da permisos a 'to' para transferir el token 'tokenId' a otra cuenta
     * La aprobación se borra cuando se transfiere el token
     *
     * Solo se puede aprobar una única cuenta al mismo tiempo, así que aprovando la dirección cero se borras las previas
     *
     * Requisitos:
     *
     * - El que llama debe ser el propietario del token o un operador autorizado
     * - 'tokenId' debe existir
     *
     * Emite un {Approval} event.
     */ 
     // La puede ejecutar o bien el propietario o la persona que tiene permiso para manejar todos los tokens de la colección
    function approve(address to, uint256 tokenId) public virtual override  {
        address owner = ownerOf(tokenId);
        address operator = msg.sender;
        require(to != owner, "ERC721: approval to current owner");

        require(operator == owner || isApprovedForAll(owner, operator), "ERC721: approve caller is not token owner or approved for all");

        _approve(to, tokenId);

    }

    /**
     * @notice Indica si el operador tiene permisos o no para gestionar la colección del owner.
     * Llama al mapping anidado _operatorApprovals
     */

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool isApproved) {
        return _operatorApprovals[owner][operator];
    }

    function getApproved(uint256 tokenId) public view returns (address operator){
        // Comprobamos el requisito de que el tokenId debe existir, es decir, ha de estar minteado.
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Aprueba o elimina `operator` como operador para quien llama a la función.
     * Los operators puede llamar a  {transferFrom} o {safeTransferFrom} con cualquier token cuyo propietario sea quien llama a la función.
     *
     * Requisitos:
     *
     * - El `operator` no puede ser quien llama a la función.
     *
     * Emite un evento {ApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC721: The operator cannot be the caller");
        _setApprovalForAll(msg.sender, operator, approved);
    }

     /**
     * @dev Transfiere el token `tokenId` de `from` a `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override  {
        // Comprobar que ejecuta la función el propietario del token o una persona que tiene permisos para manejarlo
        //require(msg.sender == from || isApprovedForAll(msg.sender, operator););
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner o approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
        require(from != address(0), "ERC721: from cannot be zero address");
        require(to != address(0), "ERC721: to cannot be zero address");
        _requireMinted(tokenId);
        require(_ownerOf(tokenId) == from, "ERC721: token must exist and be owned by from");

        if(msg.sender != from) {
            require(isApprovedForAll(from, msg.sender) || _isApprovedOrOwner(msg.sender, tokenId), "ERC721: not allowed to move this token");
        }
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    //      safeTransferFrom(from, to, tokenId, bytes(""));
    // }

    // ------------------------------------------------------------------------------------------------------------------------------------
    // -------------------------------------------- FUNCIONES INTERNAS --------------------------------------------------------------------
    // ------------------------------------------------------------------------------------------------------------------------------------

    /// @notice Devuelve la dirección del propietario del tokenId. Si devuelve la address(0) significa que el token no existe
    function _ownerOf(uint256 tokenId) internal view returns (address) {
        // TODO comprobar que si se pasa una dirección que no existe en vez de dar excepción, devuelve la address(0)
        return _owners[tokenId];
    }

    /// @notice Añade tokens y direcciones al mapping de approvals
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /// @notice Comprueba si el tokenId existe, es decir, si ha sido minteado
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /// @notice Indica si existe o no tokenId
    function _exists(uint256 tokenId) internal view virtual returns (bool exists) {
        // Si al consultar esta función obtenemos la address(0) significa que el token no existe
        return _ownerOf(tokenId) != address(0);
    }

    /// @notice Añade direcciones al mapping anidado de operators
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /// @notice COmprobar si el spender es el owner, o tiene permisos para gestionar este token completo o todos los tokens de la colección
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal virtual returns (bool){
        address owner = ownerOf(tokenId);
        return (owner == spender || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        // Comprobamos que el dueño del token es la dirección desde la que se va a hacer la transferencia
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);
        // se vuelve a realizar la comprobación por seguridad, para evitar problemas derivados de la sobreescritura de la función _beforeTokenTransfer
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // los derechos de gestión los había cedido el owner al spender. Después de transferir el token se eliminan esos derechos porque tiene nuevo propietario
        delete _tokenApprovals[tokenId];

        unchecked {
            // Ajustamos el balance de los tokens
            _balances[from] -= 1;
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /// @notice Llama a la función interna _transfer() y después comprueba que se ha recibido el token mediante la función _checkOnERC721Received()
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @notice Comprueba la recepción de un token ERC-721 en un contrato inteligente.
     * Esta función se activa automáticamente cuando se recibe un token ERC721 en el contrato
     * y se utiliza para verificar que el token recibido cumple con los requisitos específicos del contrato.
     *
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        // Comprobar si la dirección to es o no un contrato
        if(to.code.length > 0) {
            // Crea instancial del Receiver y comprueba que se han entregado correctamente
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if(reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    // @notice Genera un nuevo token NFT
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);

        // Cuando se hace un mint de un token, se "hace como que" lo genera la dirección cero, y esta es la forma de comprobar que este minteo es seguro
        require(_checkOnERC721Received(address(0), to, tokenId, data), "ERC721: transfer to non ERC721Receiver");
    }

    function _mint (address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);
        // se vuelve a realizar la comprobación por seguridad, para asegurarnos de que no se ha creado otro token dentro de la función de beforeTokenTransfer
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Sumamos uno al número de tokens total de la colección que tiene la dirección
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function _burn (uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
         _beforeTokenTransfer(owner, address(0), tokenId, 1);
         owner = ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            // Restamos uno al número de tokens total de la colección que tiene la dirección
            _balances[owner] -= 1;
        }

        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /* @notice Funcionalidad vacía creados unicamente para que puedan modificar su comportamiento los contratos que hereden de este
       y que se ejecute siempre después de una transacción */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual{

    }

    /* @notice Funcionalidad vacía, creados unicamente para que puedan modificar su comportamiento los contratos que hereden de este
       y que se ejecute siempre después de una transacción */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual{

    }

}
