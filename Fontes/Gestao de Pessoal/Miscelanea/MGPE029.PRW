/*
=========================================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
=========================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço     - Igor Melgaço     - 05/10/2025  - 05/11/25   - 52759   - Ajustes para exibir msg no console log.
Igor Melgaço     - Igor Melgaço     - 06/10/2025  - 10/11/25   - 52859   - Inclusão do campo Z35_BAIRRO.
Igor Melgaço     - Igor Melgaço     - 06/10/2025  - 10/11/25   - 53072   - Correção da Importação da UF e Cod Municipio da Certidao de Nascimento.
=========================================================================================================================================================
*/

#Include "RESTFUL.Ch"
#Include "FWMVCDef.Ch"
#INCLUDE "PROTHEUS.CH"


#DEFINE cEnt Chr(10)+ Chr(13)

Static _nRecnoZ35 := 0
Static _nRecnoZ36 := 0
Static _nRecnoZ37 := 0


/*
===============================================================================================================================
Programa----------: MGPE029
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Rotinas de Integração REST Gupy. Chamado: 49804 
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/ 

//*************
// POST
//*************
WsRestful MGPE029 Description "WebService REST Italac x Gupy"

    WsMethod POST IncFuncionario Description "Inclusão de Funcionários" PATH "/MGPE029/Funcionario/Post"  WsSyntax "/MGPE029/Funcionario/Post" // /POST/{method}"
    
End WsRestful

WsMethod POST IncFuncionario WsService MGPE029
   Local _cBody     := ::GetContent() As Character
   Local _cResposta := "" As Character

   If DecodeUtf8(_cBody) <> Nil
      _cBody := DecodeUtf8(_cBody)
   EndIf

   U_MGPE029I(_cBody,@_cResposta)

   ::SetResponse( _cResposta )

Return(.T.)

/*
===============================================================================================================================
Programa----------: MGPE029I
Autor-------------: Igor Melgaço
Data da Criacao---: 04/02/2025
Descrição---------: Realiza de Integração
Parametros--------: _cBody
Retorno-----------:   
===============================================================================================================================
*/ 
User Function MGPE029I(_cBody As Character,_cResposta As Character) As Logical
   Local oData As Object
   Local oCandidate As Object
   Local oAdmission As Object
   Local oDocuments As Object
   Local oDependents As Object
   Local oDocDepend As Object
   Local oValues As Object
   Local oPreEmployee As Object
   Local oBranch  As Object
   Local oSalary  As Object
   Local oCustomFields As Object
   Local oPosition As Object
   Local oCostCenter As Object
   Local oDepartment As Object
   Local oJob As Object
   Local oCustomVaga As Object
   Local oRole	 As Object
   Local oInfPessoais As Object
   Local oRG As Object
   Local oPis As Object
   Local oCompEscol As Object
   Local oCompResid As Object
   Local oCertReserv As Object
   Local oTituloElei As Object
   Local oDadosbco As Object
   Local oCnh As Object
   Local oCtps As Object
   Local oCertNasc As Object
   Local _lContinua   := .F. As Logical
   Local _cIDInte     := "" As Character
   Local _cFilial     := "" As Character
   Local _nI          := 0 As Numeric
   Local _aRegsZ37    := {} As Array
   Local _aCposZ35    := {} As Array
   Local _aCposZ36    := {} As Array
   Local _aCposZ37    := {} As Array
   Local _cCic        := "" As Character
   Local _cRua        := "" As Character
   Local _cNr         := "" As Character
   Local _cCompl      := "" As Character
   Local _cBairro     := "" As Character
   Local _cCodMun     := "" As Character
   Local _cCidade     := "" As Character
   Local _cUF         := "" As Character
   Local _cCep        := "" As Character
   Local _cPais       := "" As Character
   Local _cSexo       := "" As Character
   Local _cRGDtNasc   := CToD("") As Date
   Local _cDtAdmis    := "" As Character
   Local _cCel        := "" As Character
   Local _cEmail      := "" As Character
   Local _cRGNomeCp   := "" As Character
   Local _cRGNumero   := "" As Character
   Local _cRGPaisNa   := "" As Character
   Local _cMotVaga    := "" As Character
   Local _nSalario    := 0 As Numeric
   Local _cTipoDef    := "" As Character
   Local _cObsDef     := "" As Character
   Local _cNome       := "" As Character
   Local _cDep_CIC    := "" As Character
   Local _cDep_Nome   := "" As Character
   Local _cDep_Sexo   := "" As Character
   Local _cDep_DtNasc := "" As Character
   Local _cErro       := "" As Character
   Local _aRespZ36    := {} As Array
   Local _cEstCivil   := "" As Character
   Local _cRGEstNas   := "" As Character
   Local _cGrauInst   := "" As Character
   Local _dDataAdmiss := Date() As Date
   Local _cTipoAdmiss := "" As Character
   Local _cVincEmpR   := "" As Character
   Local _cClausAss   := "" As Character
   Local _cRegra      := "" As Character
   Local _cCC         := "" As Character
   Local _cPis        := "" As Character
   Local _aNames      := {} As Array
   Local _lInclui     := .F. As Logical
   Local _nFilialId   := "" As Character
   Local _cNomFilial  := "" As Character
   Local _cDepartam   := "" As Character
   Local _cCargo      := "" As Character
   Local _cFuncao     := "" As Character
   Local _cEtapa      := "" As Character
   Local _cProcesso   := "" As Character		 
   Local _cTipoPgto	 := "" As Character	    
   Local _cCatFun		 := "" As Character      
   Local _cAutoFret   := "" As Character		 
   Local _cTipoCont   := "" As Character		 
   Local _cHoraParc   := "" As Character		 
   Local _cCompeSab   := "" As Character		 
   Local _cLogrTp     := "" As Character
   Local _cRGNacion   := "" As Character 
   Local _nHrDia      := 0 As Numeric
   Local _nHrSem      := 0 As Numeric
   Local _nHrMen      := 0 As Numeric
   Local _cCatSEFIP   := "" As Character
   Local _cEtapaInt   := Alltrim(SuperGetMV("IT_ETPGUPY",.F.,"6ee6a5c4-fa05-4bed-9ac7-8730edfa9473")) // Etapa de Integração Protheus criada na Gupy
   Local _aSM0        := FWLoadSM0() As Array
   Local _nPosGrupo   := 0 As Numeric
   Local _nPosFilial  := 0 As Numeric
   Local _cCodeBranch := "" As Character
   Local _cRaca       := "" As Character
   Local _cEtnia      := "" As Character
   Local _cGrauInstru := "" As Character
   Local _cNomBco     := "" As Character
   Local _cCodBco     := "" As Character
   Local _cBanco      := "" As Character
   Local _cConta      := "" As Character
   Local _cCertRes    := "" As Character
   Local _cDeficiente := "" As Character
   Local _cHabNr      := "" As Character
   Local _cHabCateg   := "" As Character
   Local _cHabOrgEmi  := "" As Character
   Local _cHabDtEmis  := CToD("") As Date
   Local _cHabDtPriH  := CToD("") As Date
   Local _cHabUFEmis  := "" As Character
   Local _cHabDtVal   := CToD("") As Date
   Local _cRGOrgEmi   := "" As Character
   Local _cRGDtExp    := CToD("") As Date
   Local _cRGNomMae   := "" As Character
   Local _cRGNomPai   := "" As Character
   Local _cCategCNH   := "" As Character
   Local _cRGUfEmis   := "" As Character
   Local _cEstado     := "" As Character
   Local _cDep_UF     := "" As Character
   Local _cDep_Estado := "" As Character
   Local _cDep_Cidade := "" As Character
   Local _cDep_CodMun := "" As Character
   Local _cCertUF     := "" As Character
   Local _cCertCidad  := "" As Character
   Local _cCertCodMun := "" As Character
   Local _dCertEmiss  := CToD("") As Date
   Local _cCertMatri  := "" As Character
   Local _cCertLivro  := "" As Character
   Local _cCertFolha  := "" As Character
   Local _cCertCart   := "" As Character
   Local _cRGUFNasc   := "" As Character
   Local _cRGCidNas   := "" As Character
   Local _cRGCodMunNa := "" As Character
   Local _cTituloNr   := "" As Character
   Local _cZona       := "" As Character
   Local _cSecao      := "" As Character
   Local _cQry        := "" As Character
   Local _cAliasNasc  := "" As Character
   Local _cAliasCert  := "" As Character
   Local _cAliasUF    := "" As Character
   Local _cAliasCC2   := "" As Character
   
   Default _cResposta := ""
   Default _cJson  	 := ""

   Private oJsonAux    := Nil  As Object
   Private lMsErroAuto := .F. As Logical

   _nRecnoZ35 := 0
   _nRecnoZ36 := 0
   _nRecnoZ37 := 0

   oJsonAux := JsonObject():new()
   cRegistro := oJsonAux:fromJson(_cBody)

   If ValType(cRegistro) == "U"
      lContinua := .T.
   Else
      lContinua := .F.
   EndIf

   If lContinua
   
      oData := oJsonAux:GetJsonObject("data")
      
      oAdmission   := oData:GetJsonObject("admission")
      oPosition    := oAdmission:GetJsonObject("position")

      _cEtapa   := MGPE029VAL("status",@oAdmission) //Etapa de Admissão na Gupy
      _dDataAdmiss :=  MGPE029VAL("hiringDate",@oAdmission,"D") //Data de Admissão na Gupy

      If ValType(oPosition) <> "U"
         oBranch      := oPosition:GetJsonObject("branch")
      EndIf

      _cCodeBranch := MGPE029VAL("code",@oBranch) //Codigo da Estrutura Organizacional na Gupy

      _nFilialId   := MGPE029VAL("id",@oBranch)
      _cGrupo      := Subs(_cCodeBranch,1,2)

      If Len(_cCodeBranch) > 4
         _cFilial     := Subs(_cCodeBranch,4,2)
      Else
         _cFilial     := Subs(_cCodeBranch,3,2)
      EndIf

      _cNomFilial  := MGPE029VAL("label",@oBranch) 

      _nPosGrupo := aScan( _aSM0, { |x| x[1] == _cGrupo })
      _nPosFilial := aScan( _aSM0, { |x| x[2] == _cFilial })

      If _nPosGrupo > 0 .And. _nPosFilial > 0

         RpcClearEnv()
         RpcSetEnv(_cGrupo,_cFilial)
         
         If _cEtapa == Upper(_cEtapaInt)
            
            oCandidate   := oData:GetJsonObject("candidate")
            oJob         := oData:GetJsonObject("job")
            oCustomVaga  := oJob:GetJsonObject("customFields")
            oDepartment  := oJob:GetJsonObject("department")
            oDocuments   := oAdmission:GetJsonObject("documents")
            oPreEmployee := oDocuments:GetJsonObject("preEmployee")
            
            If ValType(oPosition) <> "U"
               oCustomFields := oPosition:GetJsonObject("customFields")
               oCostCenter   := oPosition:GetJsonObject("costCenter")
               oRole         := oPosition:GetJsonObject("role")
               oSalary       := oPosition:GetJsonObject("salary")
            EndIf

            For _nI := 1 To Len(oPreEmployee)
               Do Case
                  Case oPreEmployee[_nI]["name"] == "Informações pessoais"
                     oInfPessoais := oPreEmployee[1]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Carteira de Identidade (RG)"
                     oRG := oPreEmployee[_nI]:GetJsonObject("values")
                                 
                  Case oPreEmployee[_nI]["name"] == "Comprovante de PIS/Pasep "
                     oPis := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Comprovante de Escolaridade"
                     oCompEscol := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Comprovante de residência"
                     oCompResid := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Dados bancários"
                     oDadosbco := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Certificado de Reservista"
                     oCertReserv := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Título de Eleitor"
                     oTituloElei := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Carteira de Habilitação (CNH)"
                     oCnh := oPreEmployee[_nI]:GetJsonObject("values")
                  
                  Case oPreEmployee[_nI]["name"] == "Carteira de Trabalho (CTPS)"
                     oCtps := oPreEmployee[_nI]:GetJsonObject("values")

                  Case oPreEmployee[_nI]["name"] == "Certidão de Nascimento "
                     oCertNasc := oPreEmployee[_nI]:GetJsonObject("values")
               EndCase
            Next

            If ValType(oCustomFields) <> "U"   		 
               For _nI := 1 to Len(oCustomFields)
                  Do Case

                     Case oCustomFields[_nI]["title"] == "Cod Processo"
                        _cProcesso := oCustomFields[_nI]["value"]

                     Case oCustomFields[_nI]["title"] == "Tipo de Pagamento"
                        _cTipoPgto := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Tipo de Contrato de Trabalho"
                        _cTipoCont := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Compensa Sabado?"
                        _cCompeSab := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Autonomo Fretista?"
                        _cAutoFret := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Contrato a Tempo Parcial"
                        _cHoraParc := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Categoria do Funcionário"
                        _cCatFun := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Categoria SEFIP"
                        _cCatSEFIP := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Tipo de Admissão"
                        _cTipoAdmiss := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Regra de Apontamento"
                        _cRegra := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Vinculo Empregatício RAIS"
                        _cVincEmpR := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Clausula Assecuratória"
                        _cClausAss := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Nome Reduzido"
                        _cNome := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Motivo da Vaga"
                        _cMotVaga := oCustomFields[_nI]["value"]
                     
                     Case oCustomFields[_nI]["title"] == "Motivo da Vaga"
                        _cMotVaga := oCustomFields[_nI]["value"]

                     Case oCustomFields[_nI]["title"] == "Tipo da Deficiência"
                        _cTipoDef := oCustomFields[_nI]["value"] 

                     Case oCustomFields[_nI]["title"] == "Obs Deficiência"
                        _cObsDef := oCustomFields[_nI]["value"]
                     
                  EndCase
               Next
            EndIf

            _cEstadoCivil := MGPE029VAL("estado-civil",@oInfPessoais)
            Do Case
               Case _cEstadoCivil == "Casado(a)"
                  _cEstCivil := "C"
               Case _cEstadoCivil == "Solteiro(a)"
                  _cEstCivil := "S"
               Case _cEstadoCivil == "Desquitado(a)/Separado(a)"
                  _cEstCivil := "Q"
               Case _cEstadoCivil == "Viuvo(a)"
                  _cEstCivil := "V"
               Case _cEstadoCivil == "Divorciado(a)"
                  _cEstCivil := "D"
               Case _cEstadoCivil == "Marital"
                  _cEstCivil := "M"
               OtherWise
                  _cEstCivil := ""
            EndCase

            _cEtnia := MGPE029VAL("etnia",@oRG)
            Do Case
               Case _cEtnia == "Indigena"
                  _cRaca := "1"
               Case _cEtnia == "Branca"
                  _cRaca := "2"
               Case _cEtnia == "Preta"
                  _cRaca := "4"
               Case _cEtnia == "Amarela"
                  _cRaca := "6"
               Case _cEtnia == "Parda"
                  _cRaca := "8"
               OtherWise //Nao Informado 
                  _cRaca := "9"
            EndCase

            _cGrauInstru := MGPE029VAL("grau_instrucao",@oCompEscol) //"Educação superior completa"
            Do Case
               Case _cGrauInstru == "Analfabeto"
                  _cGrauInst := "10"
               Case _cGrauInstru == "Educação infantil" .OR. _cGrauInstru ==  "Primário imcompleto" //COM 4ª SERIE COMPLETA DO 1º GRAU (PRIMARIO COMPLETO)   
                  _cGrauInst := "20"
               Case _cGrauInstru == "Primário completo" //COM 4ª SERIE COMPLETA DO 1º GRAU (PRIMARIO COMPLETO)   
                  _cGrauInst := "25"       
               Case _cGrauInstru == "Ensino fundamental incompleto" .OR. _cGrauInstru == "Primeiro grau incompleto"
                  _cGrauInst := "30"
               Case _cGrauInstru == "Ensino fundamental completo" .OR. _cGrauInstru == "Primeiro grau completo"
                  _cGrauInst := "35"
               Case _cGrauInstru == "Ensino médio incompleto" .OR. _cGrauInstru == "Segundo grau incompleto"
                  _cGrauInst := "40"
               Case _cGrauInstru == "Ensino médio completo" .OR. _cGrauInstru == "Segundo grau completo"
                  _cGrauInst := "45"      
               Case _cGrauInstru == "Educação superior incompleta" .OR. _cGrauInstru == "Superior incompleto"
                  _cGrauInst := "50"    
               Case _cGrauInstru == "Educação superior completa" .OR. _cGrauInstru == "Superior completo"
                  _cGrauInst := "55"
               Case _cGrauInstru == "Mestrado completo"
                  _cGrauInst := "65"
               Case _cGrauInstru == "Doutorado completo"
                  _cGrauInst := "75"
               Case _cGrauInstru == "Pós-graduação completa"
                  _cGrauInst := "85"
               Case _cGrauInstru == "Pós-doutorado completo"
                  _cGrauInst := "95"               
               /* 
               Case _cGrauInstru == "Mestrado incompleto"
                  _cGrauInst := "60"
               Case _cGrauInstru == "Doutorado incompleto"
                  _cGrauInst := "70"
               Case _cGrauInstru == "Pós-graduação incompleta"
                  _cGrauInst := "80"
               Case _cGrauInstru == "Pós-doutorado incompleto"
                  _cGrauInst := "90"
               */
               Case _cGrauInstru == "Não informado"
                  _cGrauInst := ""
               OtherWise
                  _cGrauInst := ""
            EndCase

            _cNomBco := MGPE029VAL("banco",@oDadosbco)//"Educação superior completa"
            Do Case
               Case _cNomBco == "Banco do Brasil"
                  _cCodBco := "001" //Banco do Brasil
               Case _cNomBco == "Itaú"
                  _cCodBco := "341" //Itaú Unibanco
               Case _cNomBco == "Bradesco"
                  _cCodBco := "237" //Bradesco  
               Case _cNomBco == "Caixa Econômica Federal"
                  _cCodBco := "104" //Caixa Econômica Federal
               Case _cNomBco == "Santander"
                  _cCodBco := "033" //Santander
               Case _cNomBco == "Inter"
                  _cCodBco := "077" //Banco Inter
               Case _cNomBco == "Original"   
                  _cCodBco := "212" //Banco Original
               Case _cNomBco == "Safra"
                  _cCodBco := "422" //Banco Safra        
               Case _cNomBco == "PAN"
                  _cCodBco := "623" //Banco PAN
               Case _cNomBco == "Votorantim"
                  _cCodBco := "655" //Banco Votorantim
               Case _cNomBco == "C6 Bank"
                  _cCodBco := "336" //C6 Bank
               Case _cNomBco == "Nubank"
                  _cCodBco := "260" //Nubank 
               Case _cNomBco == "Next"
                  _cCodBco := "003" //Next
               Case _cNomBco == "BMG"
                  _cCodBco := "318" //Banco BMG
               Case _cNomBco == "Crefisa"
                  _cCodBco := "225" //Banco Crefisa
               Case _cNomBco == "Digio"
                  _cCodBco := "637" //Banco Digio
               Case _cNomBco == "Mercantil do Brasil"
                  _cCodBco := "389" //Banco Mercantil do Brasil   
               Case _cNomBco == "Modal"
                  _cCodBco := "746" //Banco Modal
               OtherWise
                  _cCodBco := "   "
            EndCase

            _cCategCNH   := MGPE029VAL("categoria",@oCnh)
            Do Case
               Case _cCategCNH == "A"
                  _cHabCateg := "1"
               Case _cCategCNH == "B"
                  _cHabCateg := "2"
               Case _cCategCNH == "C"
                  _cHabCateg := "3"
               Case _cCategCNH == "D"
                  _cHabCateg := "4"
               Case _cCategCNH == "E"  
                  _cHabCateg := "5"
               Case _cCategCNH == "AB"
                  _cHabCateg := "6"
               Case _cCategCNH == "AC"
                  _cHabCateg := "7"
               Case _cCategCNH == "AD"
                  _cHabCateg := "8"
               Case _cCategCNH == "AE"
                  _cHabCateg := "9"
               OtherWise
                  _cHabCateg := ""
            EndCase

            _cIDInte     := MGPE029GNU()
            //=====================================================
            _cCic        := U_ITKEY(MGPE029VAL("identificationDocument",@oCandidate),"Z35_CPF")
            _nSalario    := MGPE029VAL("value",@oSalary) //Salario

            //Dados do RG
            _cRGNomeCp := U_CRMA980VCP(MGPE029VAL("nome",@oRG),"",.T.,.T.)
            _cRGNumero := MGPE029C(MGPE029VAL("numero-do-rg",@oRG)) 
            _cRGCidNas := U_CRMA980VCP(MGPE029VAL("cidade-onde-nasceu",@oRG),"",.T.,.T.)
            _cRGEstNas := U_CRMA980VCP(MGPE029VAL("estado-onde-nasceu",@oRG),"",.T.,.T.) 
            _cRGPaisNa := U_CRMA980VCP(MGPE029VAL("nacionalidade",@oRG),"",.T.,.T.)
            _cRGDtNasc := MGPE029VAL("data-de-nascimento",@oRG,"D") //MGPE029VAL("birthDate",@oCandidate,"D")
            _cRGOrgEmi := U_CRMA980VCP(MGPE029VAL("orgao-emissor",@oRG),"",.T.,.T.) // RA_ORGEMRG
            _cRGDtExp  := MGPE029VAL("data-de-expedicao",@oRG,"D") // RA_DTRGEXP
            _cRGNomMae := U_CRMA980VCP(MGPE029VAL("nome-da-mae",@oRG),"",.T.,.T.) // RA_MAE
            _cRGNomPai := U_CRMA980VCP(MGPE029VAL("nome-do-pai",@oRG),"",.T.,.T.) // RA_PAI
            _cRGUfEmis := U_CRMA980VCP(MGPE029VAL("uf-emissor",@oRG),"",.T.,.T.) // RA_UFRG

            //Dados da CNH
            _cHabNr     := MGPE029C(MGPE029VAL("numero-de-registro",@oCnh)) //RA_HABILIT
            _cHabOrgEmi := U_CRMA980VCP(MGPE029VAL("orgao-emissor",@oCnh),"",.T.,.T.) // RA_CNHORG
            _cHabUFEmis := U_CRMA980VCP(MGPE029VAL("uf-emissor",@oCnh),"",.T.,.T.) // RA_UFCNH
            _cHabDtEmis := MGPE029VAL("data-de-emissao",@oCnh,"D") // RA_DTEMCNH
            _cHabDtVal  := MGPE029VAL("validade",@oCnh,"D") // RA_DTVCCNH
            _cHabDtPriH := MGPE029VAL("data-da-primeira-habilitacao",@oCnh,"D") // RA_CTDEPSA 

            //Dados da Titulo de Eleitor
            _cTituloNr  := MGPE029C(MGPE029VAL("numero",@oTituloElei)) //RA_CTDEPSA
            _cZona      := MGPE029VAL("zona",@oTituloElei) //RA_CTDEPSA
            _cSecao     := MGPE029VAL("secao",@oTituloElei) //RA_CTDEPSA

            //Dados da Certidão de Nascimento
            _cCertUF    := Upper(Alltrim(MGPE029VAL("248d9da4-0c8e-4c87-9b18-27f2de2aa21a",@oCertNasc))) //RA_UFCERT         
            _cCertCidad := Alltrim(Subs(_cCertUF,1,Len(_cCertUF)-2))
            _cCertCidad := Alltrim(Subs(_cCertCidad,1,Len(_cCertUF)-1))            
            _cCertUF    := Subs(_cCertUF,Len(_cCertUF)-2,2)
            
            _dCertEmiss := MGPE029VAL("75434699-a826-4ad3-923c-cf63c20d1b8f",@oCertNasc,"D") 
            _cCertMatri := MGPE029VAL("a3be2caa-d478-433f-b344-4da8de876483",@oCertNasc) 
            _cCertLivro := MGPE029VAL("ad660256-af17-4183-a6bc-70cd127846e9",@oCertNasc)
            _cCertFolha := MGPE029VAL("03418867-cabb-4f0a-94ae-78fa335a3257",@oCertNasc)
            _cCertCart  := MGPE029VAL("797f8d13-0c8f-41df-b5b5-4c91e7422d9d",@oCertNasc)

            //Dados do Comprovante de Residência
            _cRua       := U_CRMA980VCP(MGPE029VAL("tipo",@oCompResid),"",.T.,.T.) + Space(1) + U_CRMA980VCP(MGPE029VAL("logradouro",@oCompResid),"",.T.,.T.) //U_CRMA980VCP(MGPE029VAL("addressStreet",@oCandidate),"",.T.,.T.))
            _cNr        := MGPE029VAL("numero",@oCompResid)
            _cCompl     := U_CRMA980VCP(MGPE029VAL("complemento",@oCompResid),"",.T.,.T.)
            _cBairro    := U_CRMA980VCP(MGPE029VAL("bairro",@oCompResid),"",.T.,.T.)
            _cCidade    := U_CRMA980VCP(MGPE029VAL("cidade",@oCompResid),"",.T.,.T.)
            _cCep       := StrTran(MGPE029VAL("cep",@oCompResid),"-","")
            _cPais      := U_CRMA980VCP(MGPE029VAL("pais",@oCompResid),"",.T.,.T.)
            _cEstado    := U_CRMA980VCP(MGPE029VAL("estado",@oCompResid),"",.T.,.T.) 

            _cDepartam  := MGPE029VAL("name",@oDepartment)
            _cCargo     := MGPE029VAL("name",@oRole)
            _cFuncao    := MGPE029VAL("name",@oJob) 
            _cCC        := MGPE029VAL("code",@oCostCenter)
            _cPis       := MGPE029C(MGPE029VAL("numero",@oPis))
                        
            _cSexo      := Iif(MGPE029VAL("gender",@oCandidate) == "Male","M","F")            
            _cDtAdmis   := MGPE029VAL("hiringDate",@oCandidate,"D")
            _cCel       := MGPE029VAL("mobileNumber",@oCandidate)
            _cEmail     := UPPER(MGPE029VAL("email",@oCandidate))

            _cCertRes   := MGPE029VAL("numero-ra",@oCertReserv)
            _cDeficiente := Iif(MGPE029VAL("deficiente",@oInfPessoais) == "Sim","1","2")

            //Dados Bancarios
            _cBanco     := _cCodBco+MGPE029VAL("agencia",@oDadosbco)
            _cConta     := MGPE029VAL("conta",@oDadosbco)+MGPE029VAL("digito",@oDadosbco)

            _cLogrTp    := MGPE029W(_cRua)

            DBSelectArea("CCH")
            DbSetOrder(2)
            If DbSeek(xFilial("CCH")+_cRGPaisNa)
               _cRGNacion    := Alltrim(CCH->CCH_CODIGO)
            EndIf

            //=====================================================

            _cAliasSX5 := GetNextAlias()

            //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
            _cQry := "SELECT X5_CHAVE"
            _cQry += "	FROM " + RetSqlName("SX5")+" SX5 "
            _cQry += "	WHERE X5_FILIAL = '"+xFilial("SX5")+"' "
            _cQry += "	  AND X5_TABELA = '12' "
            _cQry += "	  AND X5_DESCRI = '"+_cRGEstNas+"' "
            _cQry += "	  AND D_E_L_E_T_ = ' ' "

            _cQry := ChangeQuery(_cQry)

            MPSysOpenQuery( _cQry,_cAliasSX5 )

            If (_cAliasSX5)->( !EOF() ) 
               _cRGUFNasc := Alltrim((_cAliasSX5)->X5_CHAVE)
            EndIf 

            (_cAliasSX5)->(DbCloseArea())
            

            //=====================================================

            _cAliasCert := GetNextAlias()
            //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
            _cQry := "SELECT CC2_CODMUN"
            _cQry += "	FROM " + RetSqlName("CC2") + " CC2 "
            _cQry += "	WHERE CC2_FILIAL = '" + xFilial("CC2") + "' "
            _cQry += "	  AND CC2_EST = '" + _cCertUF + "' "
            _cQry += "	  AND CC2_MUN = '" + _cCertCidad + "' 

            _cQry := ChangeQuery(_cQry)

            MPSysOpenQuery( _cQry,_cAliasCert )

            If (_cAliasCert)->( !EOF() ) 
               _cCertCodMun := (_cAliasCert)->CC2_CODMUN
            EndIf

            (_cAliasCert)->(DbCloseArea())
            //=====================================================

            _cAliasNasc := GetNextAlias()
            //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
            _cQry := "SELECT CC2_CODMUN"
            _cQry += "	FROM " + RetSqlName("CC2") + " CC2 "
            _cQry += "	WHERE CC2_FILIAL = '" + xFilial("CC2") + "' "
            _cQry += "	  AND CC2_EST = '" + _cRGUFNasc + "' "
            _cQry += "	  AND CC2_MUN = '" + _cRGCidNas + "' 

            _cQry := ChangeQuery(_cQry)

            MPSysOpenQuery( _cQry,_cAliasNasc )

            If (_cAliasNasc)->( !EOF() ) 
               _cRGCodMunNa := (_cAliasNasc)->CC2_CODMUN
            EndIf

            (_cAliasNasc)->(DbCloseArea())
            //=====================================================

            _cAliasUF := GetNextAlias()

            //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
            _cQry := "SELECT X5_CHAVE"
            _cQry += "	FROM " + RetSqlName("SX5")+" SX5 "
            _cQry += "	WHERE X5_FILIAL = '"+xFilial("SX5")+"' "
            _cQry += "	  AND X5_TABELA = '12' "
            _cQry += "	  AND X5_DESCRI = '"+_cEstado+"' "
            _cQry += "	  AND D_E_L_E_T_ = ' ' "

            _cQry := ChangeQuery(_cQry)

            MPSysOpenQuery( _cQry,_cAliasUF )

            If (_cAliasUF)->( !EOF() ) 
               _cUF := (_cAliasUF)->X5_CHAVE
            EndIf 

            (_cAliasUF)->(DbCloseArea())

            //=====================================================

            _cCidade := Upper(U_CRMA980VCP(_cCidade,"",.T.,.T.)) 

            _cAliasCC2 := GetNextAlias()

            //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
            _cQry := "SELECT CC2_CODMUN"
            _cQry += "	FROM " + RetSqlName("CC2")+" CC2 "
            _cQry += "	WHERE CC2_FILIAL = '" + xFilial("CC2") + "' "
            _cQry += "	  AND CC2_EST = '" + _cUF + "' "
            _cQry += "	  AND CC2_MUN = '" + _cCidade + "' "

            _cQry := ChangeQuery(_cQry)

            MPSysOpenQuery( _cQry,_cAliasCC2 )

            If (_cAliasCC2)->( !EOF() ) 
               _cCodMun := (_cAliasCC2)->CC2_CODMUN
            EndIf 

            (_cAliasCC2)->(DbCloseArea())

            //=====================================================
            If SUBS(_cTipoAdmiss,1,2) == "9B"
               _nHrMen := 220
               _nHrSem := _nHrMen / 5
               _nHrDia := _nHrMen / 30
               _cCatSEFIP := "01" 
               _cVincEmpR := "10"
            ElseIf SUBS(_cTipoAdmiss,1,2)  == "3A"
               _nHrMen := 100
               _nHrSem := _nHrMen / 5
               _nHrDia := _nHrMen / 30
               _cCatSEFIP := "07"
               _cVincEmpR := "55"
            EndIf

            _cNome := Iif(Empty(Alltrim(_cNome)),_cRGNomeCp,_cNome)

            /////////////////////////////////////////////////////
            //Alimentação de Dados da Tabela Z35
            /////////////////////////////////////////////////////
            aadd(_aCposZ35, {"Z35_FILIAL" , _cFilial	               , Nil})
            
            If ValType(_nFilialId) == "N" 
               aAdd(_aCposZ35, {"Z35_FILID"	, _nFilialId		      , Nil})
            EndIf
            
            aAdd(_aCposZ35, {"Z35_FILNOM"	, _cNomFilial		         , Nil})
            aAdd(_aCposZ35, {"Z35_NOME"	, _cNome 	               , Nil})
            aAdd(_aCposZ35, {"Z35_DPTO"	, _cDepartam		         , Nil})
            aAdd(_aCposZ35, {"Z35_CARGO"	, _cCargo		            , Nil})
            aAdd(_aCposZ35, {"Z35_FUNCAO"	, _cFuncao		            , Nil})
            aAdd(_aCposZ35, {"Z35_CPF"	   , _cCic		               , Nil})
            aadd(_aCposZ35, {"Z35_IDINTE" , _cIDInte	               , Nil})
            aAdd(_aCposZ35, {"Z35_STATUS" , "N"			               , Nil})
            aAdd(_aCposZ35, {"Z35_DDDCEL" , Subs(_cCel,4,2)				, Nil})
            aAdd(_aCposZ35, {"Z35_NUMCEL" , Subs(_cCel,6,9)				, Nil})
            aAdd(_aCposZ35, {"Z35_EMAIL"  , _cEmail			         , Nil})
            aAdd(_aCposZ35, {"Z35_SEXO"	, _cSexo                   , Nil})
            aAdd(_aCposZ35, {"Z35_ESTCIV"  , _cEstCivil              , Nil})        
            aAdd(_aCposZ35, {"Z35_RACACO"  , _cRaca			         , Nil})
            aAdd(_aCposZ35, {"Z35_PIS"     , _cPIS				         , Nil})
            aAdd(_aCposZ35, {"Z35_GRINRA"  , _cGrauInst		         , Nil}) // Cod. Grau Instrucao RAIS
            aAdd(_aCposZ35, {"Z35_DTADMI"  , _dDataAdmiss		      , Nil}) 
            aAdd(_aCposZ35, {"Z35_TIPOAD"  , _cTipoAdmiss		      , Nil}) 
            aAdd(_aCposZ35, {"Z35_CC"      , _cCC		               , Nil}) 
            aAdd(_aCposZ35, {"Z35_PROCES"  , _cProcesso   		      , Nil})
            aAdd(_aCposZ35, {"Z35_TIPOPG"  , _cTipoPgto		         , Nil})
            aAdd(_aCposZ35, {"Z35_CATFUN"  , _cCatFun		            , Nil})
            aAdd(_aCposZ35, {"Z35_AUTFR"   , _cAutoFret		         , Nil})
            aAdd(_aCposZ35, {"Z35_TPCONT"  , _cTipoCont	 	         , Nil})
            aAdd(_aCposZ35, {"Z35_HOPARC"  , _cHoraParc              , Nil})
            aAdd(_aCposZ35, {"Z35_COMPSA"  , _cCompeSab 	            , Nil})
            aAdd(_aCposZ35, {"Z35_HRSEMA"  , _nHrSem     		      , Nil})
            aAdd(_aCposZ35, {"Z35_HRSMES"  , _nHrMen                 , Nil})
            aAdd(_aCposZ35, {"Z35_HRSDIA"  , _nHrDia     		      , Nil})
            aAdd(_aCposZ35, {"Z35_CATEG"   , _cCatSEFIP  		      , Nil})
            aAdd(_aCposZ35, {"Z35_VIEMRA"  , _cVincEmpR 		         , Nil})
            aAdd(_aCposZ35, {"Z35_REGRA"   , _cRegra  		         , Nil})
            aAdd(_aCposZ35, {"Z35_RESERV"  , _cCertRes               , Nil})
            aAdd(_aCposZ35, {"Z35_DEFIFI"  , _cDeficiente            , Nil}) //RA_DEFIFIS
            aAdd(_aCposZ35, {"Z35_BCDEPS"  , _cBanco                 , Nil}) 
            aAdd(_aCposZ35, {"Z35_CTDEPS"  , _cConta                 , Nil}) 
            aAdd(_aCposZ35, {"Z35_CLAURE"  , _cClausAss              , Nil}) 
            aAdd(_aCposZ35, {"Z35_SALARI"  , _nSalario               , Nil})//RA_SALARIO
            aAdd(_aCposZ35, {"Z35_TPDEFF"	 , _cTipoDef               , Nil})//RA_TPDEFFI
            aAdd(_aCposZ35, {"Z35_OBSDEF"	 , _cObsDef	               , Nil})//RA_OBSDEFI

            //Comprovante de Residencia
            aAdd(_aCposZ35, {"Z35_END"    , _cRua							, Nil})
            aAdd(_aCposZ35, {"Z35_LOGRNU" , _cNr							, Nil})
            aAdd(_aCposZ35, {"Z35_COMPL"  , _cCompl						, Nil})
            aAdd(_aCposZ35, {"Z35_BAIRRO" , _cBairro						, Nil})
            aAdd(_aCposZ35, {"Z35_CODMUN" , _cCodMun 			         , Nil})
            aAdd(_aCposZ35, {"Z35_CIDADE" , _cCidade						, Nil})
            aAdd(_aCposZ35, {"Z35_UF"     , _cUF							, Nil})
            aAdd(_aCposZ35, {"Z35_PAIS"   , _cPais                   , Nil})
            aAdd(_aCposZ35, {"Z35_CEP"	   , _cCep							, Nil})
            aAdd(_aCposZ35, {"Z35_LOGRTP" , _cLogrTp						, Nil})

            //RG
            aAdd(_aCposZ35, {"Z35_RG"      , _cRGNumero  	         , Nil})
            aAdd(_aCposZ35, {"Z35_NOMECM"	 , _cRGNomeCp              , Nil})//RA_NOMECMP
            aAdd(_aCposZ35, {"Z35_DTNASC"  , _cRGDtNasc		         , Nil})
            aAdd(_aCposZ35, {"Z35_ORGEMR"  , _cRGOrgEmi		         , Nil}) 
            aAdd(_aCposZ35, {"Z35_DTRGEX"  , _cRGDtExp		         , Nil}) 
            aAdd(_aCposZ35, {"Z35_MAE"     , _cRGNomMae		         , Nil}) 
            aAdd(_aCposZ35, {"Z35_PAI"     , _cRGNomPai		         , Nil}) 
            aAdd(_aCposZ35, {"Z35_NAC"     , Iif(_cRGNacion   ="01058","10","")  , Nil})
            aAdd(_aCposZ35, {"Z35_NACION"  , _cRGNacion              , Nil})
            aAdd(_aCposZ35, {"Z35_NATURA"  , _cRGUFNasc              , Nil}) //
            aAdd(_aCposZ35, {"Z35_CMUNAS"  , _cRGCodMunNa            , Nil})//RA_CODMUNN
            aAdd(_aCposZ35, {"Z35_UFRG"	 , _cRGUfEmis              , Nil})//RA_UFRG
            aAdd(_aCposZ35, {"Z35_PAISOR"  , _cRGNacion              , Nil})

            //CNH
            aAdd(_aCposZ35, {"Z35_HABILI"  , _cHabNr		           , Nil}) 
            aAdd(_aCposZ35, {"Z35_CATCNH"  , _cHabCateg             , Nil}) 
            aAdd(_aCposZ35, {"Z35_CNHORG"  , _cHabOrgEmi            , Nil}) 
            aAdd(_aCposZ35, {"Z35_UFCNH"   , _cHabUFEmis            , Nil}) 
            aAdd(_aCposZ35, {"Z35_DTEMCN"  , _cHabDtEmis            , Nil}) 
            aAdd(_aCposZ35, {"Z35_DTVCCN"  , _cHabDtVal             , Nil}) 
            aAdd(_aCposZ35, {"Z35_DTINCO"  , _cHabDtPriH            , Nil})//RA_DTINCON

            //Titulo de Eleitor
            aAdd(_aCposZ35, {"Z35_TITULO"  , _cTituloNr             , Nil})//RA_TITULOE
            aAdd(_aCposZ35, {"Z35_ZONA"    , _cZona                 , Nil})//RA_ZONASEC
            aAdd(_aCposZ35, {"Z35_SECAO"   , _cSecao                , Nil})//RA_SECAO

            //Certidão de Nascimento
            aAdd(_aCposZ35, {"Z35_MATCER"	   , _cCertMatri							, Nil})
            aAdd(_aCposZ35, {"Z35_LIVCER"	   , _cCertLivro							, Nil})
            aAdd(_aCposZ35, {"Z35_FOLCER"	   , _cCertFolha							, Nil})
            aAdd(_aCposZ35, {"Z35_CARCER"	   , _cCertCart							, Nil})
            aAdd(_aCposZ35, {"Z35_EMICER"	   , _dCertEmiss							, Nil})
            aAdd(_aCposZ35, {"Z35_UFCERT"	   , _cCertUF  							, Nil})
            aAdd(_aCposZ35, {"Z35_CDMUCE"	   , _cCertCodMun							, Nil})
            aAdd(_aCposZ35, {"Z35_MUNCER"	   , _cCertCidad							, Nil})


            /////////////////////////////////////////////////////
            //Alimentação de Dados da Tabela Z36
            /////////////////////////////////////////////////////
            aadd(_aCposZ36, {"Z36_FILIAL" , _cFilial                 , Nil})
            aadd(_aCposZ36, {"Z36_IDINTE" , _cIDInte                 , Nil})
            aAdd(_aCposZ36, {"Z36_HORA"   , TIME()							, Nil})
            aAdd(_aCposZ36, {"Z36_DATA"   , Date()							, Nil})
            aAdd(_aCposZ36, {"Z36_CPF"	   , _cCic							, Nil})
            aAdd(_aCposZ36, {"Z36_NOME"	, _cRGNomeCp	            , Nil})
            aAdd(_aCposZ36, {"Z36_DTNASC" , _cRGDtNasc		         , Nil})
            aAdd(_aCposZ36, {"Z36_ETAPA"  , _cEtapa	               , Nil})
            aAdd(_aCposZ36, {"Z36_STATUS" , "N"								, Nil})
            aAdd(_aCposZ36, {"Z36_PAYLOA" , _cBody							, Nil})

            oDependents := oDocuments:GetJsonObject("dependents")
            oValues := Nil
            If Valtype(oDependents) == "A"
               For _nI := 1 To len(oDependents)
                  
                  _cDep_Nome := Upper(U_CRMA980VCP(oDependents[_nI]:GetJsonObject("name"),"Z37_NOME",.T.,.T.)) //MGPE029VAL("name",oDependents[_nI],_aNames)	
                  
                  If Len(oDependents[_nI]["documents"]) > 0
                     _aCposZ37 := {}
                     oDocDepend  := oDependents[_nI]:GetJsonObject("documents")
                     oValues     := oDocDepend[1]:GetJsonObject("values")
                     _aNames     := oValues:GetNames()

                     _cDep_CIC    := U_ITKEY(MGPE029C(MGPE029VAL("cpf",@oValues))	,"Z37_DEPCPF") 
                     _cDep_Sexo   := MGPE029VAL("gender",@oValues)
                     _cDep_DtNasc := MGPE029VAL("birthDate",@oValues,"D")

                     _cDep_Estado := U_CRMA980VCP(MGPE029VAL("stateOfOrigin",@oValues),"",.T.,.T.)
                     _cDep_Cidade := U_CRMA980VCP(MGPE029VAL("cityOfOrigin",@oValues),"",.T.,.T.)

                     //=====================================================

                     _cAliasDEST := GetNextAlias()

                     //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
                     _cQry := "SELECT X5_CHAVE"
                     _cQry += "	FROM " + RetSqlName("SX5")+" SX5 "
                     _cQry += "	WHERE X5_FILIAL = '"+xFilial("SX5")+"' "
                     _cQry += "	  AND X5_TABELA = '12' "
                     _cQry += "	  AND X5_DESCRI = '"+_cDep_Estado+"' "
                     _cQry += "	  AND D_E_L_E_T_ = ' ' "

                     _cQry := ChangeQuery(_cQry)

                     MPSysOpenQuery( _cQry,_cAliasDEST )

                     If (_cAliasDEST)->( !EOF() ) 
                        _cDep_UF := (_cAliasDEST)->X5_CHAVE
                     EndIf 

                     (_cAliasDEST)->(DbCloseArea())
                     

                     //=====================================================


                     _cAliasDMun := GetNextAlias()
                     //Utilizando a query pois se usar DBSeek o Execauto de Funcionario retorna erro no campo de Cod Municipio
                     _cQry := "SELECT CC2_CODMUN"
                     _cQry += "	FROM " + RetSqlName("CC2") + " CC2 "
                     _cQry += "	WHERE CC2_FILIAL = '" + xFilial("CC2") + "' "
                     _cQry += "	  AND CC2_EST = '" + _cDep_UF + "' "
                     _cQry += "	  AND CC2_MUN = '" + _cDep_Cidade + "' "

                     _cQry := ChangeQuery(_cQry)

                     MPSysOpenQuery( _cQry,_cAliasDMun )

                     If (_cAliasDMun)->( !EOF() ) 
                        _cDep_CodMun := (_cAliasDMun)->CC2_CODMUN
                     EndIf

                     (_cAliasDMun)->(DbCloseArea())
                     //=====================================================

                     If !Empty(Alltrim(_cDep_Nome))
                        aadd(_aCposZ37, {"Z37_FILIAL" , _cFilial     , Nil})
                        aadd(_aCposZ37, {"Z37_IDINTE" , _cIDInte     , Nil})
                        aAdd(_aCposZ37, {"Z37_CPF"    , _cCic		   , Nil}) 
                        aAdd(_aCposZ37, {"Z37_DEPCPF" , _cDep_CIC		, Nil}) // CIC
                        aAdd(_aCposZ37, {"Z37_NOME"   , _cDep_Nome	, Nil}) // Nome
                        aAdd(_aCposZ37, {"Z37_SEXO"   , Subs(_cDep_Sexo,1,1) , Nil}) // Sexo
                        aAdd(_aCposZ37, {"Z37_DTNASC" , _cDep_DtNasc	, Nil}) // Dt Nascimento
                        aAdd(_aCposZ37, {"Z37_ESTNAS" , _cDep_UF	   , Nil}) 
                        aAdd(_aCposZ37, {"Z37_CDMUN"  , _cDep_CodMun	, Nil}) 

                        aAdd(_aRegsZ37,_aCposZ37)
                     EndIf
                     
                  EndIf
               Next
            EndIf
            
            _lContinua := MGPE029GRV("Z36",_aCposZ36,.T.,@_cErro)
            If _lContinua
               DbSelectArea("Z35")
               DbSetOrder(1)
               If Dbseek(_cFilial+Alltrim(_cCic))
                  If Z35->Z35_STATUS == "I"
                     _lContinua := .F.
                     _cErro += " Integração já efetuada!"
                  EndIf
                  _lInclui := .F.
               Else
                  _lInclui := .T.
               EndIf

               If _lContinua
                  _lContinua := MGPE029GRV("Z35",_aCposZ35,_lInclui,@_cErro)
               
                  If _lContinua
                     If !_lInclui
                        DbSelectArea("Z37")
                        DbSetOrder(1)
                        If DbSeek(_cFilial+_cCic)
                           Do While _cFilial+_cCic == Z37->(Z37_FILIAL+Z37_CPF) .AND. Z37->(!EOF())
                              RecLock("Z37",.F.)
                              Z37->( DBDelete() )
                              Z37->( MsUnLock() )

                              Z37->(DbSkip())
                           EndDo
                        EndIf
                     EndIf 
                     For _nI := 1 To Len(_aRegsZ37)
                        _lContinua := MGPE029GRV("Z37",_aRegsZ37[_nI],.T.,@_cErro)
                        If !_lContinua
                           Exit
                        EndIf
                     Next
                  Endif
               EndIf
            EndIf
            
            If _lContinua			
               _cResposta := "{"
               _cResposta += '"retorno":"200",'
               _cResposta += '"mensagem":"dados incluidos com sucesso",'
               _cResposta += "}"
            Else
               _cResposta := "{"
               _cResposta += '"retorno":"200",'
               _cResposta += '"mensagem":"Integrado Falha da inclusao dos dados.",'
               _cResposta += '"erro":"'+_cErro+'"'
               _cResposta += "}"
            EndIf

            aAdd(_aRespZ36, {"Z36_RESPON", _cResposta				, Nil})

            MGPE029GRV("Z36",_aRespZ36,.F.,@_cErro)

         Else
            _cResposta := "{"
            _cResposta += '"retorno":"200",'
            _cResposta += '"mensagem":"Status da movimentacao nao corresponte a Contratacao. Portanto não sera efetuada inclusao de dados nesta integracao.",'
            _cResposta += "}"
         EndIf
      Else
         _cResposta := "{"
         _cResposta += '"retorno":"200",'
         _cResposta += '"mensagem":"Grupo ou Filial enviadas na requisição não correspondem as dos Protheus. Portanto não sera efetuada inclusao de dados nesta integracao.",'
         _cResposta += "}"

         lContinua := .F.
         
         FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "REST"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE029"/*cMsgId*/, _cResposta/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

      EndIf
   Else
      lContinua := .F.

      _cResposta := "{"
      _cResposta += '"retorno":"500",'
      _cResposta += '"mensagem":"Falha da inclusao dos dados.",'
      _cResposta += '"erro":"Falha na Deserializacao do JSON"'
      _cResposta += "}"

      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "REST"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE029"/*cMsgId*/, _cResposta/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

   EndIf

Return lContinua

/*
===============================================================================================================================
Programa----------: MGPE029GRV
Autor-------------: Igor Melgaço
Data da Criacao---: 04/02/2025
Descrição---------: Realiza gravação das tabelas Muro
Parametros--------: 
Retorno-----------:   
===============================================================================================================================
*/ 
Static Function MGPE029GRV(_cAlias As Character,_aAux As Array,_lInclui As Logical,_cErro As Character) As Logical   
   Local _ni := 0 As Numeric
   Local _lRet := .F. As Logical

   Begin Transaction

      If !_lInclui .AND. &("_nRecno"+_cAlias) > 0 .AND. &("_nRecno"+_cAlias) <> (_cAlias)->(Recno())
         (_cAlias)->(DbGoTo(&("_nRecno"+_cAlias)))
      EndIf

      If (_cAlias)->(RecLock(_cAlias,_lInclui))
         For _ni := 1 To Len(_aAux)
            (_cAlias)->&(_aAux[_ni,1]) := _aAux[_ni,2]
         Next
         (_cAlias)->(MsUnLock())

         &("_nRecno"+_cAlias) := (_cAlias)->(Recno())

         _lRet := .T.
      Else
         _cErro += Iif(Empty(Alltrim(_cErro)),"",Chr(13)+Chr(10)) + "Falha no lock do registro "+ AllTrim(Str((_cAlias)->(Recno()))) + " da Tabela " + _cAlias
         DisarmTransaction()
      EndIf

   End Transaction

Return(_lRet)


/*
===============================================================================================================================
Programa----------: MGPE029GNU
Autor-------------: Igor Melgaço
Data da Criacao---: 06/02/2025
Descrição---------: Retorna proximo numero de integração
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function MGPE029GNU() As Character
   Local _cRetorno := "" As Character
   Local _cQuery   := "" As Character
   Local _cAliasTemp := GetNextAlias() As Character
   Local _nTamCampo := TamSx3("Z35_IDINTE")[1] As Numeric
   //////////////////////////////////////////////////////
   //Resgata ID de integração
   //////////////////////////////////////////////////////		
   _cQuery := " SELECT MAX(Z35_IDINTE) AS ID "
   _cQuery += " FROM " + RetSqlName("Z35")
   _cQuery += " WHERE D_E_L_E_T_ <> '*'"

   MPSysOpenQuery( _cQuery , _cAliasTemp)

   DbSelectArea(_cAliasTemp)
   DbGoTop()

   _cRetorno := StrZero(Val(Right(Alltrim((_cAliasTemp)->ID),_nTamCampo))+1,_nTamCampo)

   Do While !MayIUseCode( "Z35_IDINTE"+xFilial("Z35")+_cRetorno)  //verifica se esta na memoria, sendo usado
      _cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
   EndDo

   DbSelectArea(_cAliasTemp)
   DbCloseArea()

Return _cRetorno

/*
===============================================================================================================================
Programa----------: MGPE029MAT
Autor-------------: Igor Melgaço
Data da Criacao---: 06/02/2025
Descrição---------: Retorna proximo numero de matricula
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function MGPE029MAT() As Character
   Local _cRetorno := "" As Character
   Local _cQuery   := "" As Character
   Local _cAliasTemp := GetNextAlias() As Character
   Local _nTamCampo := TamSx3("RA_MAT")[1] As Numeric

   //////////////////////////////////////////////////////
   //Resgata MAT de integração
   //////////////////////////////////////////////////////		
   _cQuery := " SELECT MAX(RA_MAT) AS ID "
   _cQuery += " FROM " + RetSqlName("SRA")
   _cQuery += " WHERE D_E_L_E_T_ <> '*'"

   MPSysOpenQuery( _cQuery , _cAliasTemp)

   DbSelectArea(_cAliasTemp)
   DbGoTop()

   _cRetorno := StrZero(Val(Right(Alltrim((_cAliasTemp)->ID),_nTamCampo))+1,_nTamCampo)

   Do While !MayIUseCode( "RA_MAT"+xFilial("SRA")+_cRetorno)  //verifica se esta na memoria, sendo usado
      _cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
   EndDo

   DbSelectArea(_cAliasTemp)
   DbCloseArea()

Return _cRetorno




/*
===============================================================================================================================
Programa----------: MGPE029VAL
Autor-------------: Igor Melgaço
Data da Criacao---: 06/02/2025
Descrição---------: Retorna conteudo do campo dentro do objeto
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function MGPE029VAL(_cName As Character,oObjJson As Object,_cTipo As Character)
Local _cRetorno := "" As Character
Local _aNames := {} As Array
Default _cTipo := "C" 

_cRetorno := Iif(_cTipo == "D",CToD(""),"")

If Valtype(oObjJson) == "J"
   _aNames := oObjJson:GetNames()
   _cRetorno := IIf( (_nI := Ascan(_aNames,{|x| UPPER(Alltrim(x)) == UPPER(Alltrim(_cName))})) > 0,oObjJson[_aNames[_nI]],"")

   If _cTipo == "D"
      _cRetorno := Iif(Empty(Alltrim(_cRetorno)),CToD("") ,CToD(Subs(_cRetorno,9,2) + "/"+Subs(_cRetorno,6,2)+"/"+Subs(_cRetorno,1,4)))
   ElseIf Valtype(_cRetorno) == "C"
      _cRetorno := Upper(Alltrim(_cRetorno))
   EndIf
EndIf

If Valtype(_cRetorno) == "U"
   _cRetorno := Iif(_cTipo == "D",CToD(""),"")
EndIf

Return _cRetorno

/*
===============================================================================================================================
Programa----------: MGPE029C
Autor-------------: Igor Melgaço
Data da Criacao---: 06/02/2025
Descrição---------: Retorna conteudo numerico em formato de texto
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function MGPE029C(_cDado As Character) As Character 
Local _cRetorno := "" As Character
Local i := 0 As Numeric

For i := 1 to Len(_cDado)
   If Subs(_cDado,i,1) $ "0123456789"
      _cRetorno += Subs(_cDado,i,1)
   EndIf
Next

Return _cRetorno


/*
===============================================================================================================================
Programa----------: MGPE029C
Autor-------------: Igor Melgaço
Data da Criacao---: 06/08/2025
Descrição---------: Retorna array de tipos de logradouro baseado em tabela do IBGE
Parametros--------: 
Retorno-----------: aDados   
===============================================================================================================================
*/
User Function MGPE029X()
Local aDados := {} As Array

   AADD(aDados,{"A","Area"})
   AADD(aDados,{"AC","Acesso"})
   AADD(aDados,{"ACA","Acampamento"})
   AADD(aDados,{"ACL","Acesso Local"})
   AADD(aDados,{"AD","Adro"})
   AADD(aDados,{"AE","Aerea Especial"})
   AADD(aDados,{"AER","Aeroporto"})
   AADD(aDados,{"AL","Alameda"})
   AADD(aDados,{"ALD","Aldeia"})
   AADD(aDados,{"AMD","Avenida Marginal Direita"})
   AADD(aDados,{"AME","Avenida Marginal Esquerda"})
   AADD(aDados,{"AN","Anel Viario"})
   AADD(aDados,{"ANT","Antiga Estrada"})
   AADD(aDados,{"ART","Arteria"})
   AADD(aDados,{"AT","Alto"})
   AADD(aDados,{"ATL","Atalho"})
   AADD(aDados,{"A V","Area Verde"})
   AADD(aDados,{"AVC","Avenida Contorno"})
   AADD(aDados,{"AVM","Avenida Marginal"})
   AADD(aDados,{"AVV","Avenida Velha"})
   AADD(aDados,{"AV","Avenida"})

   AADD(aDados,{"BAL","Balneario"})
   AADD(aDados,{"BC","Beco"})
   AADD(aDados,{"BCO","Buraco"})
   AADD(aDados,{"BEL","Belvedere"})
   AADD(aDados,{"BL","Bloco"})
   AADD(aDados,{"BLO","Balao"})
   AADD(aDados,{"BLS","Blocos"})
   AADD(aDados,{"BLV","Bulevar"})
   AADD(aDados,{"BSQ","Bosque"})
   AADD(aDados,{"BVD","Boulevard"})
   AADD(aDados,{"BX","Baixa"})
   AADD(aDados,{"C","Cais"})
   AADD(aDados,{"CAL","Calçada"})
   AADD(aDados,{"CAM","Caminho"})
   AADD(aDados,{"CAN","Canal"})
   AADD(aDados,{"CH","Chacara"})
   AADD(aDados,{"CHA","Chapadao"})
   AADD(aDados,{"CIC","Ciclovia"})
   AADD(aDados,{"CIR","Circular"})
   
   AADD(aDados,{"CJM","Conjunto Mutirao"})
   AADD(aDados,{"CMP","Complexo Viario"})
   AADD(aDados,{"COL","Colonia"})
   AADD(aDados,{"COM","Comunidade"})
   AADD(aDados,{"CON","Condominio"})
   AADD(aDados,{"COND","Condominio"})
   AADD(aDados,{"COR","Corredor"})
   AADD(aDados,{"CPO","Campo"})
   AADD(aDados,{"CRG","Corrego"})
   AADD(aDados,{"CTN","Contorno"})
   AADD(aDados,{"CJ","Conjunto"})

   AADD(aDados,{"DSC","Descida"})
   AADD(aDados,{"DSV","Desvio"})
   AADD(aDados,{"DT","Distrito"})
   AADD(aDados,{"EB","Entre Bloco"})
   AADD(aDados,{"EIM","Estrada Intermunicipal"})
   AADD(aDados,{"ENS","Enseada"})
   AADD(aDados,{"ENT","Entrada Particular"})
   AADD(aDados,{"EQ","Entre Quadra"})
   AADD(aDados,{"ESC","Escada"})
   AADD(aDados,{"ESD","Escadaria"})
   AADD(aDados,{"ESE","Estrada Estadual"})
   AADD(aDados,{"ESI","Estrada Vicinal"})
   AADD(aDados,{"ESL","Estrada de Ligaçao"})
   AADD(aDados,{"ESM","Estrada Municipal"})
   AADD(aDados,{"ESP","Esplanada"})
   AADD(aDados,{"ESS","Estrada de Servidao"})
   AADD(aDados,{"ESV","Estrada Velha"})
   AADD(aDados,{"ETA","Estrada Antiga"})
   AADD(aDados,{"ETC","Estaçao"})
   AADD(aDados,{"ETD","Estadio"})
   AADD(aDados,{"ETN","Estancia"})
   AADD(aDados,{"ETP","Estrada Particular"})
   AADD(aDados,{"ETT","Estacionamento"})
   AADD(aDados,{"EVA","Evangelica"})
   AADD(aDados,{"EVD","Elevada"})
   AADD(aDados,{"EST","Estrada"})

   AADD(aDados,{"EX","Eixo Industrial"})
   AADD(aDados,{"FAV","Favela"})
   AADD(aDados,{"FAZ","Fazenda"})
   AADD(aDados,{"FER","Ferrovia"})
   AADD(aDados,{"FNT","Fonte"})
   AADD(aDados,{"FRA","Feira"})
   AADD(aDados,{"FTE","Forte"})
   AADD(aDados,{"GAL","Galeria"})
   AADD(aDados,{"GJA","Granja"})
   AADD(aDados,{"HAB","Nucleo Habitacional"})
   AADD(aDados,{"IA","Ilha"})
   AADD(aDados,{"IGP","Igarape"})
   AADD(aDados,{"IND","Indeterminado"})
   AADD(aDados,{"IOA","Ilhota"})
   AADD(aDados,{"JD","Jardim"})
   AADD(aDados,{"JDE","Jardinete"})
   AADD(aDados,{"LD","Ladeira"})
   AADD(aDados,{"LGA","Lagoa"})
   AADD(aDados,{"LGO","Lago"})
   AADD(aDados,{"LOT","Loteamento"})
   AADD(aDados,{"LRG","Largo"})
   AADD(aDados,{"LT","Lote"})
   AADD(aDados,{"MER","Mercado"})
   AADD(aDados,{"MNA","Marina"})
   AADD(aDados,{"MOD","Modulo"})
   AADD(aDados,{"MRG","Projeçao"})
   AADD(aDados,{"MRO","Morro"})
   AADD(aDados,{"MTE","Monte"})
   AADD(aDados,{"NUR","Nucleo Rural"})
   AADD(aDados,{"NUC","Nucleo"})

   AADD(aDados,{"O","Outros"})
   AADD(aDados,{"OUT","Outeiro"})
   AADD(aDados,{"PAR","Paralela"})
   AADD(aDados,{"PAS","Passeio"})
   AADD(aDados,{"PAT","Patio"})
   AADD(aDados,{"PC","Praça"})
   AADD(aDados,{"PCE","Praça de Esportes"})
   AADD(aDados,{"PDA","Parada"})
   AADD(aDados,{"PDO","Paradouro"})
   AADD(aDados,{"PNT","Ponta"})
   AADD(aDados,{"PR","Praia"})
   AADD(aDados,{"PRL","Prolongamento"})
   AADD(aDados,{"PRM","Parque Municipal"})
   AADD(aDados,{"PRQ","Parque"})
   AADD(aDados,{"PRR","Parque Residencial"})
   AADD(aDados,{"PSA","Passarela"})
   AADD(aDados,{"PSP","Passagem de Pedestre"})
   AADD(aDados,{"PSS","Passagem Subterranea"})
   AADD(aDados,{"PTE","Ponte"})
   AADD(aDados,{"PTO","Porto"})
   AADD(aDados,{"PSG","Passagem"})

   AADD(aDados,{"Q","Quadra"})
   AADD(aDados,{"QTA","Quinta"})
   AADD(aDados,{"QTS","Quintas"})

   AADD(aDados,{"R I","Rua Integraçao"})
   AADD(aDados,{"R L","Rua de Ligaçao"})
   AADD(aDados,{"R P","Rua Particular"})
   AADD(aDados,{"R V","Rua Velha"})
   AADD(aDados,{"RAM","Ramal"})
   AADD(aDados,{"RCR","Recreio"})
   AADD(aDados,{"REC","Recanto"})
   AADD(aDados,{"RER","Retiro"})
   AADD(aDados,{"RES","Residencial"})
   AADD(aDados,{"RET","Reta"})
   AADD(aDados,{"RLA","Ruela"})
   AADD(aDados,{"RMP","Rampa"})
   AADD(aDados,{"ROA","Rodo Anel"})
   AADD(aDados,{"ROD","Rodovia"})
   AADD(aDados,{"ROT","Rotula"})
   AADD(aDados,{"RPE","Rua de Pedestre"})
   AADD(aDados,{"R","Rua"})

   AADD(aDados,{"RPR","Margem"})
   AADD(aDados,{"RTN","Retorno"})
   AADD(aDados,{"RTT","Rotatoria"})
   AADD(aDados,{"SEG","Segunda Avenida"})
   AADD(aDados,{"SIT","Sitio"})
   AADD(aDados,{"SRV","Servidao"})
   AADD(aDados,{"ST","Setor"})
   AADD(aDados,{"SUB","Subida"})
   AADD(aDados,{"TCH","Trincheira"})
   AADD(aDados,{"TER","Terminal"})
   AADD(aDados,{"TR","Trecho"})
   AADD(aDados,{"TRV","Trevo"})
   AADD(aDados,{"TUN","Tunel"})

   AADD(aDados,{"TVP","Travessa Particular"})
   AADD(aDados,{"TVV","Travessa Velha"})
   AADD(aDados,{"TV","Travessa"})

   AADD(aDados,{"UNI","Unidade"})
   
   AADD(aDados,{"V C","Via Coletora"})
   AADD(aDados,{"V L","Via Local"})
   AADD(aDados,{"VAC","Via de Acesso"})
   AADD(aDados,{"VAL","Vala"})
   AADD(aDados,{"VCO","Via Costeira"})
   AADD(aDados,{"VD","Viaduto"})
   AADD(aDados,{"V-E","Via Expressa"})
   
   AADD(aDados,{"VER","Vereda"})
   AADD(aDados,{"VEV","Via Elevado"})
   AADD(aDados,{"VLA","Viela"})
   AADD(aDados,{"VLE","Vale"})
   AADD(aDados,{"VLT","Via Litoranea"})
   AADD(aDados,{"VPE","Via de Pedestre"})
   AADD(aDados,{"V","Via"})
   AADD(aDados,{"VL","Vila"})
   
   AADD(aDados,{"VRT","Variante"})
   AADD(aDados,{"ZIG","Zigue-Zague"})

Return aDados

/*
===============================================================================================================================
Programa----------: MGPE029W
Autor-------------: Igor Melgaço
Data da Criacao---: 06/08/2025
Descrição---------: Retorna tipo de logradouro baseado em tabela do IBGE
Parametros--------: 
Retorno-----------: _cLogra   
===============================================================================================================================
*/
Static Function MGPE029W(_cEnd As Character) As Character
   Local aDados := U_MGPE029X() As Array
   Local _nI := 0 As Numeric
   Local _cLogra := "" As Character 
   
   For _nI := 1 To Len(aDados)
      If UPPER(aDados[_nI,2]) $ _cEnd
         _cEnd := Alltrim(StrTran(_cEnd,UPPER(aDados[_nI,2]),""))
         _cLogra := aDados[_nI,1]
         Exit
      EndIf
   Next

Return _cLogra 
