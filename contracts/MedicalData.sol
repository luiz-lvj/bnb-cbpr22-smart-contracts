// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.0;

struct Consulta {
    bool exists;
    uint IDconsulta;

    string area;
    string especificacao;

    address hospital;
    address medico;
    address paciente;
    
    uint epochTime;
    string laudo;

    uint[] IDexames;
}

struct Exame {
    bool exists;
    uint IDexame;

    string nome;

    address hospital;
    address paciente;

    uint epochTime;
    string laudo;

    uint IDconsulta;
}

contract MedicalData {
    address public hospital;

    mapping (uint => Consulta) consultas;
    mapping (address => uint[]) consultasPaciente;
    mapping (address => mapping(address => uint[])) consultasMedicoPaciente;

    mapping (address => bool) pacientesMap;
    address[] pacientes;

    mapping (uint => Exame) public exames;
    mapping (address => uint[]) examesPaciente;

    modifier somenteHospital {
        require(msg.sender == hospital, "Acionador nao eh hospital");
        _;
    }

    constructor () {
        hospital = msg.sender;
    }

    function _insertPaciente(address paciente)
    internal {
        if(pacientesMap[paciente]) return;

        pacientesMap[paciente] = true;
        pacientes.push(paciente);
    }

    function _postConsulta(
        uint IDconsulta,
        string calldata area,
        string calldata especificacao,
        address _hospital,
        address medico,
        address paciente,
        uint epochTime,
        string calldata laudo
    ) internal {
        require(IDconsulta != 0, "ID consulta nao pode ser 0");
        require(medico != address(0), "Indereco invalido: medico");
        require(paciente != address(0), "Indereco invalido: paciente");

        Consulta storage consulta = consultas[IDconsulta];
        require(!consulta.exists, "Consulta ja existente");

        consulta.exists = true;
        consulta.IDconsulta = IDconsulta;

        consulta.area = area;
        consulta.especificacao = especificacao;

        consulta.hospital = _hospital;
        consulta.medico = medico;
        consulta.paciente = paciente;

        consulta.epochTime = epochTime;
        consulta.laudo = laudo;

        consultasPaciente[paciente].push(IDconsulta);
        consultasMedicoPaciente[medico][paciente].push(IDconsulta);

        _insertPaciente(paciente);
    }

    function postConsulta(
        uint IDconsulta,
        string calldata area,
        string calldata especificacao,
        address medico,
        address paciente,
        uint epochTime,
        string calldata laudo
    ) external somenteHospital {
        _postConsulta(
            IDconsulta,
            area,
            especificacao,
            msg.sender,
            medico,
            paciente,
            epochTime,
            laudo
        );
    }

    function _postExame (
        uint IDexame,
        string calldata nome,

        address paciente,

        string calldata laudo,
        uint epochTime,

        uint IDconsulta
    ) internal {
        require(paciente != address(0), "Endereco invalido: paciente");
        require(IDconsulta == 0 || consultas[IDconsulta].paciente == paciente, "Consulta e examos nao sao do mesmo paciente");

        Exame storage exame = exames[IDexame];
        require(!exame.exists, "Exame ja existe");

        exame.exists = true;
        exame.IDexame = IDexame;
        exame.nome = nome;

        exame.paciente = paciente;
        exame.hospital = hospital;

        exame.laudo = laudo;
        exame.epochTime = epochTime;

        exame.IDconsulta = IDconsulta;
        
        if(IDconsulta != 0) consultas[IDconsulta].IDexames.push(IDexame);
        examesPaciente[paciente].push(IDexame);

        _insertPaciente(paciente);
    }

    function postExame (
        uint IDexame,
        string calldata nome,

        address paciente,

        string calldata laudo,
        uint epochTime,

        uint consulta
    ) external somenteHospital {
        _postExame(
            IDexame,
            nome,
            paciente,
            laudo,
            epochTime,
            consulta
        );
    }

    function convertID(address _hospital, uint ID)
    internal pure returns (uint) {
        return uint(keccak256(abi.encode(_hospital,ID)));
    }

    function importHistory(Consulta[] calldata _consultas, Exame[] calldata _exames)
    external somenteHospital {
        for(uint i=0; i<_consultas.length; i++){
            Consulta calldata _consulta = _consultas[i];
            address _hospital = _consulta.hospital;
            uint _IDconsulta_bef = _consulta.IDconsulta;
            uint _IDconsulta_new = convertID(_hospital, _IDconsulta_bef);

            _postConsulta(
                _IDconsulta_new,
                _consulta.area,
                _consulta.especificacao,
                _consulta.hospital,
                _consulta.medico,
                _consulta.paciente,
                _consulta.epochTime,
                _consulta.laudo
            );
        }

        for(uint i=0; i<_exames.length; i++) {
            Exame calldata _exame = _exames[i];
            address _hospital = _exame.hospital;
            uint _ID_exame_bef = _exame.IDexame;
            uint _ID_exame_new = convertID(_hospital,_ID_exame_bef);

            uint _ID_consulta = _exame.IDconsulta == 0 ? 0 : convertID(_hospital, _exame.IDconsulta);

            _postExame(
                _ID_exame_new,
                _exame.nome,
                _exame.paciente,
                _exame.laudo,
                _exame.epochTime,
                _ID_consulta
            );
        }
    }

    function getConsulta(uint IDconsulta)
    external view returns (Consulta memory) {
        return consultas[IDconsulta];
    }

    function getIDConsultasPaciente(address paciente)
    external view returns (uint[] memory) {
        return consultasPaciente[paciente];
    }

    function _queryIDconsultas(uint[] memory ids)
    internal view returns (Consulta[] memory) {
        Consulta[] memory _consultas = new Consulta[](ids.length);
        for(uint i=0; i<ids.length; i++)
            _consultas[i] = consultas[ids[i]];

        return _consultas;
    }

    function getConsultasPaciente(address paciente)
    public view returns (Consulta[] memory) {
        return _queryIDconsultas(consultasPaciente[paciente]);
    }

    function getIDConsultasMedicoPaciente(address medico, address paciente)
    external view returns (uint[] memory) {
        return consultasMedicoPaciente[medico][paciente];
    }

    function getConsultasMedicoPaciente(address medico, address paciente)
    external view returns (Consulta[] memory) {
        return _queryIDconsultas(consultasMedicoPaciente[medico][paciente]);
    }

    function getPacientes()
    external view returns (address[] memory) {
        return pacientes;
    }

    function _queryIDexame(uint[] memory ids)
    internal view returns (Exame[] memory) {
        Exame[] memory _exames = new Exame[](ids.length);
        for(uint i=0; i<ids.length; i++)
            _exames[i] = exames[ids[i]];

        return _exames;
    }

    function getIDExamesPaciente(address paciente) 
    external view returns (uint[] memory) {
        return examesPaciente[paciente];
    }

    function getExamesPaciente(address paciente)
    public view returns (Exame[] memory) {
        return _queryIDexame(examesPaciente[paciente]);
    }

    function getHistory(address paciente)
    external view returns (Consulta[] memory, Exame[] memory) {
        return (getConsultasPaciente(paciente), getExamesPaciente(paciente));
    }
}