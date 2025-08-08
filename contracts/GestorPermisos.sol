// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GestorPermisos {
    address public propietario;

    mapping(uint => mapping(address => bool)) private permisos;

    event PermisoOtorgado(uint indexed idProducto, address indexed usuario);
    event PermisoRevocado(uint indexed idProducto, address indexed usuario);

    modifier soloPropietario() {
        require(msg.sender == propietario, "No eres el propietario");
        _;
    }

    constructor() {
        propietario = msg.sender;
    }

    function otorgarPermiso(uint idProducto, address usuario) external soloPropietario {
        permisos[idProducto][usuario] = true;
        emit PermisoOtorgado(idProducto, usuario);
    }

    function revocarPermiso(uint idProducto, address usuario) external soloPropietario {
        permisos[idProducto][usuario] = false;
        emit PermisoRevocado(idProducto, usuario);
    }

    function tienePermiso(uint idProducto, address usuario) external view returns (bool) {
        return permisos[idProducto][usuario];
    }
}
