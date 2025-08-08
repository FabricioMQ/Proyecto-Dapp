// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RegistroProductos {
    address public propietario;
    address public logicaCadenaSuministro;

    struct Producto {
        uint id;
        string descripcion;
        address actualPoseedor;
        bool existe;
    }

    mapping(uint => Producto) private productos;

    event ProductoCreado(uint indexed idProducto, string descripcion, address indexed poseedor);
    event PoseedorProductoActualizado(uint indexed idProducto, address indexed nuevoPoseedor);

    modifier soloPropietario() {
        require(msg.sender == propietario, "No eres el propietario");
        _;
    }

    modifier soloLogicaCadenaSuministro() {
        require(msg.sender == logicaCadenaSuministro, "Solo LogicaCadenaSuministro puede llamar");
        _;
    }

    constructor() {
        propietario = msg.sender;
    }

    function setLogicaCadenaSuministro(address _logica) external soloPropietario {
        logicaCadenaSuministro = _logica;
    }

    function crearProductoDesdeLogica(uint idProducto, string calldata descripcion, address poseedorInicial) external soloLogicaCadenaSuministro {
        require(!productos[idProducto].existe, "Producto ya existe");

        productos[idProducto] = Producto(idProducto, descripcion, poseedorInicial, true);
        emit ProductoCreado(idProducto, descripcion, poseedorInicial);
    }

    function actualizarPoseedor(uint idProducto, address nuevoPoseedor) external soloLogicaCadenaSuministro {
        require(productos[idProducto].existe, "Producto no existe");

        productos[idProducto].actualPoseedor = nuevoPoseedor;
        emit PoseedorProductoActualizado(idProducto, nuevoPoseedor);
    }

    function existeProducto(uint idProducto) external view returns (bool) {
        return productos[idProducto].existe;
    }

    function obtenerPoseedor(uint idProducto) external view returns (address) {
        require(productos[idProducto].existe, "Producto no existe");
        return productos[idProducto].actualPoseedor;
    }

    function obtenerDescripcion(uint idProducto) external view returns (string memory) {
        require(productos[idProducto].existe, "Producto no existe");
        return productos[idProducto].descripcion;
    }
}
