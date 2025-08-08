// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RegistroAuditoria {
    event EstadoCambiado(uint indexed idProducto, string estadoAnterior, string nuevoEstado, address indexed quienCambia, uint timestamp);
    event ProductoMovido(uint indexed idProducto, address desde, address hacia, uint timestamp);

    function registrarCambioEstado(uint idProducto, string calldata estadoAnterior, string calldata nuevoEstado) external {
        emit EstadoCambiado(idProducto, estadoAnterior, nuevoEstado, msg.sender, block.timestamp);
    }

    function registrarMovimiento(uint idProducto, address desde, address hacia) external {
        emit ProductoMovido(idProducto, desde, hacia, block.timestamp);
    }
}
