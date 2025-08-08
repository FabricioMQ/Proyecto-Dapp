// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistroProductos {
    function existeProducto(uint idProducto) external view returns (bool);
    function obtenerPoseedor(uint idProducto) external view returns (address);
    function crearProductoDesdeLogica(uint idProducto, string calldata descripcion, address poseedorInicial) external;
    function actualizarPoseedor(uint idProducto, address nuevoPoseedor) external;
}

interface IRegistroUsuarios {
    enum TipoUsuario { Ninguno, Productor, Transportista, Distribuidor }
    function obtenerTipoUsuario(address usuario) external view returns (TipoUsuario);
}

interface IGestorPermisos {
    function otorgarPermiso(uint idProducto, address usuario) external;
    function tienePermiso(uint idProducto, address usuario) external view returns (bool);
}

interface IRegistroAuditoria {
    function registrarCambioEstado(uint idProducto, string calldata estadoAnterior, string calldata nuevoEstado) external;
    function registrarMovimiento(uint idProducto, address desde, address hacia) external;
}

contract LogicaCadenaSuministro {
    IRegistroProductos public registroProductos;
    IRegistroUsuarios public registroUsuarios;
    IGestorPermisos public gestorPermisos;
    IRegistroAuditoria public registroAuditoria;

    mapping(uint => string) public estadosProducto;

    event EstadoProductoActualizado(uint indexed idProducto, string nuevoEstado);
    event ProductoTransferido(uint indexed idProducto, address indexed desde, address indexed hacia);
    event ProductoCreado(uint indexed idProducto, string descripcion, address indexed productor);

    modifier soloConPermiso(uint idProducto) {
        require(gestorPermisos.tienePermiso(idProducto, msg.sender), "No tienes permiso para modificar este producto");
        _;
    }

    constructor(
        address _registroProductos,
        address _registroUsuarios,
        address _gestorPermisos,
        address _registroAuditoria
    ) {
        registroProductos = IRegistroProductos(_registroProductos);
        registroUsuarios = IRegistroUsuarios(_registroUsuarios);
        gestorPermisos = IGestorPermisos(_gestorPermisos);
        registroAuditoria = IRegistroAuditoria(_registroAuditoria);
    }

    function crearProducto(uint idProducto, string calldata descripcion) external {
        IRegistroUsuarios.TipoUsuario tipo = registroUsuarios.obtenerTipoUsuario(msg.sender);
        require(tipo == IRegistroUsuarios.TipoUsuario.Productor, "Solo productores pueden crear productos");
        require(!registroProductos.existeProducto(idProducto), "Producto ya existe");

        registroProductos.crearProductoDesdeLogica(idProducto, descripcion, msg.sender);

        gestorPermisos.otorgarPermiso(idProducto, msg.sender);

        emit ProductoCreado(idProducto, descripcion, msg.sender);
    }

    function actualizarEstadoProducto(uint idProducto, string calldata nuevoEstado) external soloConPermiso(idProducto) {
        require(registroProductos.existeProducto(idProducto), "Producto no existe");

        IRegistroUsuarios.TipoUsuario tipo = registroUsuarios.obtenerTipoUsuario(msg.sender);
        require(tipo != IRegistroUsuarios.TipoUsuario.Ninguno, "Usuario no registrado");

        string memory estadoAnterior = estadosProducto[idProducto];
        estadosProducto[idProducto] = nuevoEstado;

        registroAuditoria.registrarCambioEstado(idProducto, estadoAnterior, nuevoEstado);
        emit EstadoProductoActualizado(idProducto, nuevoEstado);
    }

    function transferirProducto(uint idProducto, address hacia) external soloConPermiso(idProducto) {
        require(registroProductos.existeProducto(idProducto), "Producto no existe");

        address poseedorActual = registroProductos.obtenerPoseedor(idProducto);
        require(msg.sender == poseedorActual, "No eres quien posee el producto");

        IRegistroUsuarios.TipoUsuario tipoActual = registroUsuarios.obtenerTipoUsuario(msg.sender);
        IRegistroUsuarios.TipoUsuario tipoDestino = registroUsuarios.obtenerTipoUsuario(hacia);

        require(tipoDestino != IRegistroUsuarios.TipoUsuario.Ninguno, "Destinatario no registrado");

        require(
            (tipoActual == IRegistroUsuarios.TipoUsuario.Productor && tipoDestino == IRegistroUsuarios.TipoUsuario.Transportista) ||
            (tipoActual == IRegistroUsuarios.TipoUsuario.Transportista && tipoDestino == IRegistroUsuarios.TipoUsuario.Distribuidor),
            "Transferencia no permitida entre estos roles"
        );

        registroProductos.actualizarPoseedor(idProducto, hacia);

        registroAuditoria.registrarMovimiento(idProducto, msg.sender, hacia);
        emit ProductoTransferido(idProducto, msg.sender, hacia);
    }
}
