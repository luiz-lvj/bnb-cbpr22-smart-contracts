// SPDX-License-Identifier: ULINCENSED
pragma solidity ^0.8.0;

enum MedicalArea {
    Heart
}

struct Consulta {
    bool exists;

    string area;
    string specification;

    address hospital;
    address doctor;
    address paciente;
    
    uint epochDate;
    string laudo;

    uint[] exames;
}

struct Exame {
    bool exists;

    string nome;

    address hospital;
    address paciente;

    uint epochDate;
    string laudo;

    uint consulta;
}

contract MedicalData {
    address hospital;

    modifier onlyHospital {
        require(msg.sender == hospital, "Sender is not hospital");
        _;
    }

    constructor () {
        hospital = msg.sender;
    }

    mapping (uint => Consulta) public consultas;
    mapping (address => uint[]) consultasPaciente;
    mapping (address => mapping(address => uint[])) consultasMedicoPaciente;

    mapping (uint => Exame) public exames;
    mapping (address => uint[]) examesAvulsos;

    function postColsulta(
        uint externKey,
        string calldata area,
        string calldata specification,
        address doctor,
        address paciente,
        uint epochDate,
        string calldata laudo
    ) external onlyHospital {
        Consulta storage consulta = consultas[externKey];
        require(!consulta.exists, "Consulta ja existente");

        consulta.exists = true;
        consulta.area = area;
        consulta.specification = specification;
        consulta.doctor = doctor;
        consulta.paciente = paciente;
        consulta.hospital = hospital;

        // maybe add some time verification
        consulta.epochDate = epochDate;
        consulta.laudo = laudo;

        consultasPaciente[paciente].push(externKey);
        consultasMedicoPaciente[doctor][paciente].push(externKey);
    }

    function postExame (
        uint externKey,
        string calldata nome,

        address paciente,

        string calldata laudo,
        uint epochDate,

        uint consulta
    ) external onlyHospital {
        Exame storage exame = exames[externKey];
        require(!exame.exists, "Exame ja existe");

        exame.exists = true;
        exame.nome = nome;

        exame.paciente = paciente;
        exame.hospital = hospital;

        exame.laudo = laudo;
        exame.epochDate = epochDate;

        exame.consulta = consulta;
        
        if(consulta != 0) consultas[consulta].exames.push(externKey);
        else examesAvulsos[paciente].push(externKey);
    }

    function getConsultasPaciente (address paciente)
    external view returns (uint[] memory) {
        return consultasPaciente[paciente];
    }

    function getConsultasMedicoPaciente (address medico, address paciente)
    external view returns (uint[] memory) {
        return consultasMedicoPaciente[medico][paciente];
    }
}