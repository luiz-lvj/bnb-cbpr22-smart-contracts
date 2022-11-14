const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { BigNumber } = ethers;

describe("Testing MedicalData", function () {
  let hospital;
  const addressZero = '0x0000000000000000000000000000000000000000';

  before(async function () {
    [ hospital ] = await ethers.getSigners();
  })

  describe("Deployment", function () {
    it("Should deploy with address", async function () {
      const MedicalData = await ethers.getContractFactory('MedicalData');
      const medicalData = await MedicalData.deploy();

      const _hospital = await medicalData.hospital();
      expect(_hospital).to.be.equal(hospital.address);
    });
  });

  describe("Functions", async function () {
    let medico, paciente;

    let medicalData;
    let IDconsulta;
    let area;
    let especificacao;
    let epochTime;
    let laudo

    before(async function () {
      [ , medico, paciente ] = await ethers.getSigners();

      IDconsulta = BigNumber.from(1);
      area = "cardiologia";
      especificacao = "radiografia";
      epochTime = BigNumber.from(2);
      laudo = "Muito bom";
    });


    beforeEach(async function () {
      const MedicalData = await ethers.getContractFactory('MedicalData');
      medicalData = await MedicalData.deploy();
    });

    describe("Post consulta", async function () {
      it("Should post consulta", async function () {
        await medicalData.postConsulta(
          IDconsulta,
          area,
          especificacao,
          medico.address,
          paciente.address,
          epochTime,
          laudo
        );

        const consulta = await medicalData.getConsulta(IDconsulta);

        expect(consulta.exists).to.be.equal(true);
        expect(consulta.IDconsulta).to.be.equal(IDconsulta);
        expect(consulta.area).to.be.equal(area);
        expect(consulta.especificacao).to.be.equal(especificacao);
        expect(consulta.hospital).to.be.equal(hospital.address);
        expect(consulta.medico).to.be.equal(medico.address);
        expect(consulta.paciente).to.be.equal(paciente.address);
        expect(consulta.epochTime).to.be.equal(epochTime);
        expect(consulta.laudo).to.be.equal(laudo);
        expect(consulta.IDexames).to.eql([]);
        
        const consultasPaciente = await medicalData.getIDConsultasPaciente(paciente.address);
        expect(consultasPaciente).to.eql([IDconsulta]);

        const consultasMedicoPaciente = await medicalData.getIDConsultasMedicoPaciente(medico.address, paciente.address);
        expect(consultasMedicoPaciente).to.eql([IDconsulta]);

        const pacientes = await medicalData.getPacientes();
        expect(pacientes).to.be.eql([paciente.address]);
      });

      it('Should not register if not hospital', async function () {
        const call = medicalData.connect(medico).postConsulta(
          IDconsulta,
          area,
          especificacao,
          medico.address,
          paciente.address,
          epochTime,
          laudo
        );

        expect(call).revertedWith('Acionador nao eh hospital');
      });

      it('Should not register if ID == 0', async function () {
        const call = medicalData.postConsulta(
          BigNumber.from(0),
          area,
          especificacao,
          medico.address,
          paciente.address,
          epochTime,
          laudo
        );

        expect(call).to.be.revertedWith('Acionador nao eh hospital');
      });

      it('Should not register if address 0 as medico', async function () {
        const call = medicalData.postConsulta(
          IDconsulta,
          area,
          especificacao,
          addressZero,
          paciente.address,
          epochTime,
          laudo
        );

        expect(call).revertedWith('Acionador nao eh hospital');
      });


      it('Should not register if address 0 as paciente', async function () {
        const call = medicalData.connect(medico).postConsulta(
          IDconsulta,
          area,
          especificacao,
          medico.address,
          addressZero,
          epochTime,
          laudo
        );

        expect(call).revertedWith('Acionador nao eh hospital');
      });

      it("Should not register twice", async function () {
        await medicalData.postConsulta(
          IDconsulta,
          area,
          especificacao,
          medico.address,
          paciente.address,
          epochTime,
          laudo
        );

        const call = medicalData.postConsulta(
          IDconsulta,
          area,
          especificacao,
          medico.address,
          paciente.address,
          epochTime,
          laudo
        );

        expect(call).revertedWith('Acionador nao eh hospital');
      });
    });
    
    describe('Post Exame', async function () {
      let IDexame;
      let nome;
      let laudoExame;
      let epochTimeExame;

      before(async function () {
        IDexame = BigNumber.from(1);
        nome = "Radiografia do coracao";
        laudoExame = "tudo certo";
        epochTimeExame = BigNumber.from(3);
      });

      beforeEach(async function () {
        await medicalData.postConsulta(
          IDconsulta,
          area,
          especificacao,
          medico.address,
          paciente.address,
          epochTime,
          laudo
        );
      });

      it('Should post exame', async function () {
        await medicalData.postExame(
          IDexame,
          nome,
          paciente.address,
          laudoExame,
          epochTimeExame,
          IDconsulta
        );

        const exame  = await medicalData.exames(IDexame);
        expect(exame.exists).to.be.equal(true);
        expect(exame.IDexame).to.be.equal(IDexame);
        expect(exame.nome).to.be.equal(nome);
        expect(exame.paciente).to.be.equal(paciente.address);
        expect(exame.laudo).to.be.equal(laudoExame);
        expect(exame.epochTime).to.be.equal(epochTimeExame);
        expect(exame.IDconsulta).to.be.equal(IDconsulta);

        const exames = await medicalData.getIDExamesPaciente(paciente.address);
        expect(exames).to.be.eql([IDexame]);
      });

      it('Should post exame without consulta', async function () {
        
      });
    });
  });
});