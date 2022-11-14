// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.0;

struct Consulta {
    bool exists;

    string area;
    string especificacao;

    address hospital;
    address medico;
    address paciente;
    
    uint epochTime;
    string laudo;

    uint[] exames;
}

struct Exame {
    bool exists;

    string nome;

    address hospital;
    address paciente;

    uint epochTime;
    string laudo;

    uint consulta;
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

    function postConsulta(
        uint IDconsulta,
        string calldata area,
        string calldata especificacao,
        address medico,
        address paciente,
        uint epochTime,
        string calldata laudo
    ) external somenteHospital {
        require(IDconsulta != 0, "ID consulta nao pode ser 0");
        require(medico != address(0), "Indereco invalido: medico");
        require(paciente != address(0), "Indereco invalido: paciente");

        Consulta storage consulta = consultas[IDconsulta];
        require(!consulta.exists, "Consulta ja existente");

        consulta.exists = true;
        consulta.area = area;
        consulta.especificacao = especificacao;
        consulta.medico = medico;
        consulta.paciente = paciente;
        consulta.hospital = msg.sender;

        // maybe add some time verification
        consulta.epochTime = epochTime;
        consulta.laudo = laudo;

        consultasPaciente[paciente].push(IDconsulta);
        consultasMedicoPaciente[medico][paciente].push(IDconsulta);

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
        require(paciente != address(0), "Endereco invalido: paciente");
        require(consulta == 0 || consultas[consulta].paciente == paciente, "Consulta e examos nao sao do mesmo paciente");

        Exame storage exame = exames[IDexame];
        require(!exame.exists, "Exame ja existe");

        exame.exists = true;
        exame.nome = nome;

        exame.paciente = paciente;
        exame.hospital = hospital;

        exame.laudo = laudo;
        exame.epochTime = epochTime;

        exame.consulta = consulta;
        
        if(consulta != 0) consultas[consulta].exames.push(IDexame);
        examesPaciente[paciente].push(IDexame);

        _insertPaciente(paciente);
    }

    function getConsulta(uint IDconsulta)
    external view returns (Consulta memory) {
        return consultas[IDconsulta];
    }

    function getConsultasPaciente (address paciente)
    external view returns (uint[] memory) {
        return consultasPaciente[paciente];
    }

    function getConsultasMedicoPaciente (address medico, address paciente)
    external view returns (uint[] memory) {
        return consultasMedicoPaciente[medico][paciente];
    }

    function getPacientes()
    external view returns (address[] memory) {
        return pacientes;
    }

    function getExamesPaciente(address paciente) 
    external view returns (uint[] memory) {
        return examesPaciente[paciente];
    }

    function getHistory(address paciente)
    external view returns (Consulta[] memory, Exame[] memory) {
        uint[] storage IDsConsultas = consultasPaciente[paciente];
        Consulta[] memory _consultas = new Consulta[](IDsConsultas.length);

        for(uint i=0; i<IDsConsultas.length; i++)
            _consultas[i] = consultas[IDsConsultas[i]];

        uint[] storage IDsExames = examesPaciente[paciente];
        Exame[] memory _exames = new Exame[](IDsExames.length);
        for(uint i=0; i<IDsExames.length; i++)
            _exames[i] = exames[IDsExames[i]];

        return (_consultas, _exames);
    }
}