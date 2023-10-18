// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    // ----------------- VARIABLES -----------------
    /// @notice Almacenará los tokens que tiene cada una de la direcciones que interactúen con el contrato
    mapping (address => uint256) private _balance;

    /** @notice address => dirección del owner, dueño de los tokens
     address del segunto mapping => dirección del spender al que se permite la gestión de la cantidad uint256
     Recogerá los permisos de la gestión y la cantidad que un owner delega a uno o varios spender
     Con esta estructura podemos almacenar para un owner, vaios spender **/
    mapping (address => mapping (address => uint256)) private _allowance;

    /// @notice Almacenará la cantidad total de tokens que está en circulación en cada momento
    uint256 private _totalSupply;

    /// @notice Nombre del token
    string private _name;

    /// @notice Símbolo del token
    string private _symbol;

    // ----------------- CONSTRUCTOR -----------------
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ----------------- GETTERS Y SETTERS -----------------
    /// @notice Sirve para obtener el nombre del token
    /// @return String que contiene el nombre del token
    function name() public view virtual returns(string memory){
        return _name;
    }

    /// @notice Sirve para obtener el símbolo del token
    /// @return String que contiene el símbolo del token
    function symbol() public view virtual returns(string memory){
        return _symbol;
    }

    // ----------------- FUNCIONES PÚBLICAS -----------------
    /// @notice Obtener el número de decimales del token
    /// @return Entero con el número de decimales del token
    function decimals() public pure virtual returns (uint8){
        return 0;
    }

    // ----------------- IMPLEMENTACIÓN DE FUNCIONES DE LA INTERFAZ -----------------
    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256){
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual override returns (uint256){
        return _balance[account];
    }
    
    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public virtual override returns (bool){
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    
    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual override returns (uint256){
        return _allowance[owner][spender];
    }
    
    /// @inheritdoc IERC20
    function approve(address spender, uint amount) public virtual override returns (bool){
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom (address from, address to, uint256 amount) public virtual override returns (bool){
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Aumenta la cantidad de tokens delegados al spender
    /// @param spender Dirección a la que se delegan los tokens
    /// @param amount Cantidad de tokens que se añadirán a lo que ya tiene delegado
    /// @return Devuelve un booleano que indica si la función se ha ejecutado correctamente o no
    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        address owner = msg.sender;
        unchecked {
            _approve(owner, spender, allowance(owner, spender) + amount);
        }
        return true;
    }

    /// @notice Disminuye la cantidad de tokens delegados al spender
    /// @param spender Dirección a la que se delegan los tokens
    /// @param amount Cantidad de tokens que se restarán a lo que ya tiene delegado
    /// @return Devuelve un booleano que indica si la función se ha ejecutado correctamente o no
    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        address owner = msg.sender;
        require(allowance(owner, spender) >= amount, "ERROR: There is not enough tokens amount delegated");
        unchecked {
            _approve(owner, spender, allowance(owner, spender) - amount);
        }
        return true;
    }

    // ----------------- FUNCIONES INTERNAS -----------------
    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool){
        // Comprobar que ni la dirección de origen ni destino son la dirección cero
        require(from != address(0), "ERROR: You can't transfer from the zero address");
        require(to != address(0), "ERROR: You can't transfer to the zero address");

        // Comprobar que el balance es suficiente
        require(_balance[from] >= amount, "ERROR: Insufficient balance");
        _beforeTokenTransfer(from, to, amount);
        _balance[from] -= amount;
        _balance[to] += amount;
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /// @notice Función interna con la lógica de la aprobación de la gestión de amount tokens del owner al spender
    /// @param owner Dirección dueña de los tokens encargada de aprobar la transacción de cesión
    /// @param spender Dirección a la que se cede la gestión de los tokens
    /// @param amount Cantidad de tokens que owner cede a spender para su gestión
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        // Comprobar que ni la dirección del owner ni spender son la dirección cero
        require(owner != address(0), "ERROR: You approve the zero address as owner");
        require(spender != address(0), "ERROR: You can't use the zero address as spender");

        _allowance[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /// @notice Función interna mediante la cual el spender gasta amount tokens que tiene cedidos del owner
    /// @param owner Dirección dueña de los tokens
    /// @param spender Dirección a la que se cede la gestión de los tokens
    /// @param amount Cantidad de tokens que owner cede a spender para su gestión
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);

        if(currentAllowance != type(uint256).max){
            require(currentAllowance >= amount, "ERROR: ERC20 Insufficient balance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /// @notice Genera amount nuevos tokens 
    function _mint (address account, uint256 amount) internal virtual {
        require(account != address(0), "ERROR: You can't use the zero address");
        
        _beforeTokenTransfer(address(0), account, amount); 
        _totalSupply += amount;
        // TODO revisar por qué puse esta línea
        //_transfer(address(0), account, amount);
        unchecked {
            _balance[account] += amount;
        }

        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /// @notice Quema amount tokens
    function _burn (address account, uint256 amount) internal virtual {
        require(account != address(0), "ERROR: You can't use the zero address");
        
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balance[account];
        require(accountBalance >= amount, "ERROR: Burn amount exceeds balance");

        //_transfer(account, address(0), amount);
        
        unchecked {
            _balance[account] -= amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    /* @notice Funcionalidad vacía creados unicamente para que puedan modificar su comportamiento los contratos que hereden de este
       y que se ejecute siempre después de una transacción */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual{

    }

    /* @notice Funcionalidad vacía, creados unicamente para que puedan modificar su comportamiento los contratos que hereden de este
       y que se ejecute siempre después de una transacción */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual{

    }
}