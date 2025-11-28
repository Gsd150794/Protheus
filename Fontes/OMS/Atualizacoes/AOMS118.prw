/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     | 08/03/2024 | Chamado 45006. Ajustar variável __cUserId em ambiente Scheduller p/ Protheus criar e preencher
Julio Paz     | 27/03/2024 | Chamado 46748. Ajustar as integrações Protheus x Sistema Krona p/funcionar no novo servidor Linux
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Jose Gavetti  | 26/11/2025 | Chamado 51341. __cUserId não deve ter seu conteúdo alterado orientação TOTVS. 
===============================================================================================================================
*/

#Include "TOTVS.ch" 
#Include "FWMVCDEF.CH"
#Include "XMLXFUN.CH"
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: AOMS118
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/12/2019
Descrição---------: Rotina de Envio dos Dados da Carga via webservice REST para o sistema Krona. Chamado 31535.
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS118(_cChamada)  
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000002")  
Local _cDirJSon                                                 
Local _cCabLogin
Local _cDetViagem
Local _cDetDestA, _cDetDestB, _cDetDestC
Local _cDetMotorista
Local _cDetOrigem
Local _cDetTransportador
Local _cDetVeiculo, _cReboque1, _cReboque2, _cReboque3, _cVeiculo 
Local _cClieDest
Local _cViagem
Local _cJSonEnv
Local _cRodaPe   
Local _nStart := 0
Local _nRetry := 0
Local _cJSonRet := Nil
Local _nTimOut	:= 120
Local _cRetHttp    := ''
Local _aHeadOut := {}   
Local _cLinkWS  
Local _aErroRet := {}, _nI
Local _cMsgErro , _cMsgInt, _cProtocolo  // _oRetJSon,
Local _cIniViagem, _cFimViagem, _cDestFim, _cUf_Munic
Local _cObserv, _cTransp, _cLjTransp
Local _nPrcMinCarga := U_ItGetMv("ITPRCMINCAR",100000) 
Local _lAltViagem := .F., _cTextoMsg := ""
Local _cNrNotas
Local _aDadosViagem, _lUsuarioTransp, _lTemZG9
Local _aPvTrcNf, _lDestItalac//, _cNotaTRCNf
Local _dDataAux, _cHoraAux, _dDtFinal, _cHoraFinal, _nDias
Local _cUsrZG9, _cPswZG9, _cFornZG9, _cLojaZG9, _lAchouForn  
Local _aPedidoDAI , _nJ
Local _cFilCarreg := ""

//==========================================
//  Login JSon
//==========================================
Private _cUsuario       := ""
Private _cSenha         := ""
Private _cUsrMaster     := ""
Private _cSenhaMaster   := ""

//==========================================
//  Transportador
//==========================================
Private _cTipoTransp      := "" 
Private _cCNPJTransp      := "" 
Private _cRazaoTransp     := "" 
Private _cNomeFTransp     := ""  
Private _cUnidTransp      := "" 
Private _cCodigoTransp    := "" 
Private _cRuaTransp       := ""
Private _cNumeroTransp    := ""
Private _cComplemTransp   := "" 
Private _cBairroTransp    := "" 
Private _cCidadeTransp    := ""
Private _cUfTransp        := ""
Private _cCepTransp       := ""  
Private _cLatitudeTransp  := "" 
Private _cLogitudeTransp  := "" 
Private _cPhone1Transp    := "" 
Private _cPhone2Transp    := "" 
Private _cResponTransp    := ""
Private _cRespCargoTranp  := ""
Private _cRespPhoneTransp := ""
Private _cRespCelTransp   := "" 
Private _cRespEmailTransp := ""

//==========================================
// Motorista_1
//==========================================
Private _cNomeMoto        := ""   
Private _cCpfMoto         := "" 
Private _cRgMoto          := ""  
Private _cOrgaoEmissMoto  := "" 
Private _cDtNascMoto      := ""  
Private _cNomeMaeMoto     := "" 
Private _cEstadoCivMoto   := "" 
Private _cEscolarMoto     := "" 
Private _cCnhMoto         := "" 
Private _cCategCnhMoto    := "" 
Private _cValidCnhMoto    := "" 
Private _cRuaMoto         := "" 
Private _cNrEndMoto       := ""
Private _cComplemMoto     := ""
Private _cBairoMoto       := ""
Private _cCidMoto         := ""
Private _cUfMoto          := ""
Private _cCepMoto         := ""
Private _cTelFixoMoto     := "" 
Private _cCelMoto         := "" 
Private _cNextelMoto      := ""
Private _cMoppMoto        := ""
Private _cAsoMoto         := ""
Private _cCddMoto         := ""
Private _cCapacMoto       := ""
Private _cVincMoto        := ""

//==========================================
// Veiculo
//==========================================  
Private _cPlacaVeic       := ""   
Private _cRenavVeic       := ""  
Private _cMarcaVeic       := ""  
Private _cModeloVeic      := ""  
Private _cCorVeic         := ""  
Private _cAnoVeic         := ""   
Private _cTipoVeic        := "" 
Private _cCapacidVeic     := ""  
Private _cNrAnttVeic      := ""  
Private _cValAnttVeic     := ""  
Private _cNrFrotaVeic     := ""  
Private _cTrFrotVeic      := ""  
Private _cPropretVeic     := ""  
Private _cCpfCgcPVeic     := "" 
Private _cRuaPVeic        := ""  
Private _cNrRuaPVeic      := ""  
Private _cComplPVeic      := "" 
Private _cBairroPVeic     := ""  
Private _cCidPVeic        := "" 
Private _cUfPVeic         := ""
Private _cCepPVeic        := "" 
Private _cTecnoPVeic      := "" 
Private _cIdRastrVeic     := "" 
Private _cComunPVeic      := ""  
Private _cTecSecVeic      := ""  
Private _cIdRSecVeic      := ""  
Private _cComSecVeic      := "" 
Private _cFixoVeic        := ""

//==========================================
// Reboque 1
//==========================================  
Private _c1PlacaVeic       := ""   
Private _c1RenavVeic       := ""  
Private _c1MarcaVeic       := ""  
Private _c1ModeloVeic      := ""  
Private _c1CorVeic         := ""  
Private _c1AnoVeic         := ""   
Private _c1TipoVeic        := "" 
Private _c1CapacidVeic     := ""  
Private _c1NrAnttVeic      := ""  
Private _c1ValAnttVeic     := ""  
Private _c1NrFrotaVeic     := ""  
Private _c1TrFrotVeic      := ""  
Private _c1PropretVeic     := ""  
Private _c1CpfCgcPVeic     := "" 
Private _c1RuaPVeic        := ""  
Private _c1NrRuaPVeic      := ""  
Private _c1ComplPVeic      := "" 
Private _c1BairroPVeic     := ""  
Private _c1CidPVeic        := "" 
Private _c1UfPVeic         := ""
Private _c1CepPVeic        := "" 
Private _c1TecnoPVeic      := "" 
Private _c1IdRastrVeic     := "" 
Private _c1ComunPVeic      := ""  
Private _c1TecSecVeic      := ""  
Private _c1IdRSecVeic      := ""  
Private _c1ComSecVeic      := "" 
Private _c1FixoVeic        := ""

//==========================================
// Reboque 2
//==========================================  
Private _c2PlacaVeic       := ""   
Private _c2RenavVeic       := ""  
Private _c2MarcaVeic       := ""  
Private _c2ModeloVeic      := ""  
Private _c2CorVeic         := ""  
Private _c2AnoVeic         := ""   
Private _c2TipoVeic        := "" 
Private _c2CapacidVeic     := ""  
Private _c2NrAnttVeic      := ""  
Private _c2ValAnttVeic     := ""  
Private _c2NrFrotaVeic     := ""  
Private _c2TrFrotVeic      := ""  
Private _c2PropretVeic     := ""  
Private _c2CpfCgcPVeic     := "" 
Private _c2RuaPVeic        := ""  
Private _c2NrRuaPVeic      := ""  
Private _c2ComplPVeic      := "" 
Private _c2BairroPVeic     := ""  
Private _c2CidPVeic        := "" 
Private _c2UfPVeic         := ""
Private _c2CepPVeic        := "" 
Private _c2TecnoPVeic      := "" 
Private _c2IdRastrVeic     := "" 
Private _c2ComunPVeic      := ""  
Private _c2TecSecVeic      := ""  
Private _c2IdRSecVeic      := ""  
Private _c2ComSecVeic      := "" 
Private _c2FixoVeic        := ""

//==========================================
// Reboque 3
//==========================================  
Private _c3PlacaVeic       := ""   
Private _c3RenavVeic       := ""  
Private _c3MarcaVeic       := ""  
Private _c3ModeloVeic      := ""  
Private _c3CorVeic         := ""  
Private _c3AnoVeic         := ""   
Private _c3TipoVeic        := "" 
Private _c3CapacidVeic     := ""  
Private _c3NrAnttVeic      := ""  
Private _c3ValAnttVeic     := ""  
Private _c3NrFrotaVeic     := ""  
Private _c3TrFrotVeic      := ""  
Private _c3PropretVeic     := ""  
Private _c3CpfCgcPVeic     := "" 
Private _c3RuaPVeic        := ""  
Private _c3NrRuaPVeic      := ""  
Private _c3ComplPVeic      := "" 
Private _c3BairroPVeic     := ""  
Private _c3CidPVeic        := "" 
Private _c3UfPVeic         := ""
Private _c3CepPVeic        := "" 
Private _c3TecnoPVeic      := "" 
Private _c3IdRastrVeic     := "" 
Private _c3ComunPVeic      := ""  
Private _c3TecSecVeic      := ""  
Private _c3IdRSecVeic      := ""  
Private _c3ComSecVeic      := "" 
Private _c3FixoVeic        := ""

//==========================================
// Origem  
//==========================================
Private _cTipoOrig        := "" 
Private _cCnpjOrig        := ""
Private _cRazaoSOrig      := ""
Private _cNomeFOrig       := "" 
Private _cUnidOrig        := "" 
Private _cCodUndOrig      := "" 
Private _cEnderOrig       := "" 
Private _cNrEndOrig       := ""
Private _cComplEndOrig    := ""
Private _cBairEndOrig     := "" 
Private _cCidEndOrig      := "" 
Private _cUfEndOrig       := ""
Private _cCepEndOrig      := "" 
Private _cLatiEndOrg      := "" 
Private _cLongEndOrig     := "" 
Private _cTel1EndOrig     := "" 
Private _cTel2EndOrig     := "" 
Private _cRespEndOrig     := ""
Private _cRespCEOrig      := "" 
Private _cTelEndOrig      := "" 
Private _CelEndOrig       := ""
Private _cMailEndOrig     := ""

//==========================================
// Destinos
//==========================================
Private _cTipoDest        := ""  
Private _cCnpjDest        := "" 
Private _cRazaoDest       := "" 
Private _cNomeFanDest     := "" 
Private _cUnidDest        := "" 
Private _cCodUniDest      := "" 
Private _cRuaDest         := "" 
Private _cNrDest          := ""
Private _cComplDest       := "" 
Private _cBairroDest      := "" 
Private _cCidDest         := "" 
Private _cUfDest          := ""
Private _cCepDest         := "" 
Private _cLatitDest       := "" 
Private _cLongiDest       := "" 
Private _cTel1Dest        := ""
Private _cTel2Dest        := "" 
Private _cRespDest        := ""
Private _cCargoRDest      := "" 
Private _cTelRDest        := "" 
Private _cCelRDest        := ""
Private _cMailRDest       := ""
//=========================================
// Dados Adicionais
//=========================================
//----- Remetente 
Private _cTipoRem   := ""
Private _cCnpjRem   := ""
Private _cRazaoRem  := ""
Private _cNomeRem   := ""
Private _cUnidRem   := ""
Private _cCodRem    := ""
Private _cEndRem    := ""
Private _cNumEndRem := ""
Private _cComplRem  := ""
Private _cBairroRem := ""
Private _cCidRem    := ""
Private _cUfRem     := ""
Private _cCepRem    := ""
Private _cLatRem    := ""
Private _cLongRem   := ""
Private _cFone1Rem  := ""
Private _cFone2Rem  := ""
Private _cResponRem := ""
Private _cCargReRem := ""
Private _cFoneReRem := ""
Private _cCelReRem  := "" 
Private _cMailReRem := ""
//------ Mercadoria
Private _cMercadoria  := "" // 1 = Generos alimenticios.
Private _cValorMerc   := ""
Private _cNormaMerc   := "" // "NBR15635" norma técnica de produção de alimentos.
Private _cGrupNorMerc := ""
Private _cNotaMerc    := ""
Private _cObservMerc  := ""

//==========================================
// Viagem  
//========================================== 
Private _cIdViagem       := ""
Private _cTipoViag       := "" 
Private _cRastreViag     := ""  
Private _cPercurViag     := ""
Private _cTipoClViag     := "" 
Private _cDocOrgViag     := "" 
Private _cFppViag        := "" 
Private _cMercIdViag     := "" 
Private _cValorViag      := ""
Private _cRotaViag       := "" 
Private _cIniPrViag      := ""  
Private _cFimPrViag      := "" 
Private _cLiberViag      := "" 
Private _cNrCliViag      := "" 
Private _cObsViag        := "" 
Private _cLoc11Viag      := "" 
Private _cIdLoc11Viag    := "" 
Private _cLoc12Viag      := "" 
Private _cIdLoc12Viag    := "" 
Private _cLoc13Viag      := "" 
Private _cIdLoc13Viag    := "" 
Private _cLoc21Viag      := "" 
Private _cIdLoc21Viag    := "" 
Private _cLoc22Viag      := "" 
Private _cIdLoc22Viag    := "" 
Private _cLoc23Viag      := "" 
Private _cIdLoc23Viag    := "" 
Private _cLoc31Viag      := "" 
Private _cIdLoc31Viag    := "" 
Private _cLoc321Viag     := "" 
Private _cIdLoc32Viag    := "" 
Private _cLoc33Viag      := ""
Private _cIdLoc33Viag    := ""   

Private _nMotorista, _nDestinos

Default _cChamada := "M" // Chamada do menu.

Begin Sequence       
   //=======================================================================================================
   // Lista de erros de retorno na integração com o sistema Krona.
   //=======================================================================================================
   aAdd(_aErroRet,{'ERRO_LOGIN_001'        , 'Chave não encontrada para o Login.'})                                                           // Erro_login_001
   aAdd(_aErroRet,{'ERRO_LOGIN_002'        , 'Usuario ou senha incorretos ou não existem.'})                                                  // Erro_login_002
   aAdd(_aErroRet,{'ERRO_ENTRADA'          , 'URL ou método incorreto.'})                                                                     // Erro_entrada
   aAdd(_aErroRet,{'ERRO_TRANSPORTADOR_001', 'Chave não encontrada para transportador.'})                                                     // Erro_transportador_001
   aAdd(_aErroRet,{'ERRO_TRANSPORTADOR_002', 'Não foi possível adicionar transportador.'})                                                    // Erro_transportador_002
   aAdd(_aErroRet,{'ERRO_MOTORISTA_1_001'  , 'Chave não encontrada para o motorista.'})                                                       // Erro_motorista_1_001
   aAdd(_aErroRet,{'ERRO_MOTORISTA_01_002' , 'Não foi possível adicionar motorista 1.'})                                                      // Erro_motorista_01_002
   aAdd(_aErroRet,{'ERRO_MOTORISTA_02_002' , 'Não foi possível adicionar motorista 2.'})                                                      // Erro_motorista_02_002
   aAdd(_aErroRet,{'ERRO_VEICULO_001'      , 'Chave não encontrada para veículo.'})                                                           // Erro_veiculo_001
   aAdd(_aErroRet,{'ERRO_VEICULO_002'      , 'Não foi possível adicionar veículo.'})                                                          // Erro_veiculo_002
   aAdd(_aErroRet,{'ERRO_REBOQUE_1_002'    , 'Não encontrado ou não foi possível adicionar Reboque_1'})                                       // Erro_reboque_1_002
   aAdd(_aErroRet,{'ERRO_REBOQUE_2_002'    , 'Não encontrado ou não foi possível adicionar Reboque_2'})                                       // Erro_reboque_2_002
   aAdd(_aErroRet,{'ERRO_REBOQUE_3_002'    , 'Não encontrado ou não foi possível adicionar Reboque_3'})                                       // Erro_reboque_3_002
   aAdd(_aErroRet,{'ERRO_ORIGEM_001'       , 'Chave não encontrada para origem.'})                                                            // Erro_origem_001
   aAdd(_aErroRet,{'ERRO_ORIGEM_002'       , 'Não foi possível adicionar origem.'})                                                           // Erro_origem_002
   aAdd(_aErroRet,{'ERRO_DESTINO_1_001'    , 'Chave não encontrada para destino.'})                                                           // Erro_destino_1_001
   aAdd(_aErroRet,{'ERRO_DESTINO_1_002'    , 'Não foi possível adicionar destino.'})                                                          // Erro_destino_1_002
   aAdd(_aErroRet,{'ERRO_DESTINO_N_002'    , 'Origem nco encontrado ou nco foi possmvel adicionar.'})                                         // Erro_destino_N_002
   aAdd(_aErroRet,{'ERRO_VIAGEM_LIBERACAO' , 'Código de liberação da viagem não enviado.'})                                                   // Erro_viagem_liberacao
   aAdd(_aErroRet,{'ERRO_VIAGEM_001'       , 'Chave não encontrada para viagem.'})                                                            // Erro_viagem_001
   aAdd(_aErroRet,{'ERRO_VIAGEM_002'       , 'Não foi possível cadastrar a viagem.'})                                                         // Erro_viagem_002
   aAdd(_aErroRet,{'ERRO_VIAGEM_003'       , 'Consulta de Maxxi Cadastro não aprovada para a viagem.'})                                                       // Erro_viagem_003
   aAdd(_aErroRet,{'ERRO_VIAGEM_004'       , 'Tecnologia PRINCIPAL não é compatível com as tecnologias validas para a viagem.'})                              // Erro_viagem_004
   aAdd(_aErroRet,{'ERRO_VIAGEM_005'       , 'Tecnologia REDUNDANTE FIXA DO VEICULO / REBOQUE não é compatível com as tecnologias validas para Viagem.'})     // Erro_viagem_005
   aAdd(_aErroRet,{'ERRO_VIAGEM_006'       , 'Erro ao cadastrar resultados da pesquisa do Maxxi Cadastro para a viagem.'})                                    // Erro_viagem_006
   aAdd(_aErroRet,{'ERRO_VIAGEM_007'       , 'Tecnologias LOCALIZADOR / ISCA não é compatível com as tecnologias validas para a viagem.'})                    // Erro_viagem_007
   aAdd(_aErroRet,{'ERRO_VIAGEM_008'       , 'Tecnologias LOCALIZADOR / ISCA não informada para a viagem.'})                                                  // Erro_viagem_008    
   aAdd(_aErroRet,{'ERRO_PERFIL_001'       , 'Valor da SM(Solicitação de Monitoramento) informada esta acima do valor maximo permitido para esta operação!'}) // Erro_perfil_001

   //============================================================
   // Validações Iniciais.
   //============================================================
   _lUsuarioTransp := .T. // Pegar usuário e senha da Transportadora.

   //================================================================
   // Solicitação do Vanderlei. Por enquanto sempre pegar 
   // usuário e senha da transportadora.
   // Deixar o trecho abaixo comentado por enquanto. Chamado 33979
   //================================================================
   If DAK->DAK_VALOR < _nPrcMinCarga
      _lUsuarioTransp := .F. // Valor de carga abaixo do estipulado. Pegar usuário e senha das tabelas ZG9 e ZZM conforme regras de armazens.  
   EndIf
   
   If DAK->DAK_I_PREC == "1"
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Esta é uma pré-carga. Não é permitido integrar uma pré-carga para o sistema Krona.","Atenção","É necessário efetivar a pré-carga para poder integrar para o sistema Krona.",1)
      Else
         U_ItConOut("[AOMS118] - Esta é uma pré-carga. Não é permitido integrar uma pré-carga para o sistema Krona.")
      EndIf 
         
      Break      
   EndIf

   _lAltViagem := .F.                                    
   If DAK->DAK_I_ENVK == "S"  .And. _cChamada == "M" // Chamada via menu.
      U_ITMsg("A carga seleciondada já foi integrada para o sistema Krona.","Atenção","Clique em OK para exibir os dados da integração.",2)   
    
      U_AOMS118V(DAK->DAK_COD, DAK->DAK_I_JSON, DAK->DAK_I_RETK, DAK->DAK_I_MSGK, DAK->DAK_I_PROT)

      If ! Empty(DAK->DAK_I_PROT)
         _lAltViagem := .T.
      EndIf 
   Else
      If ! Empty(DAK->DAK_I_PROT)
         _lAltViagem := .T.
      EndIf 
   EndIf                                     

   If _cChamada == "M" // Chamada via menu.
      If _lAltViagem
         _cTextoMsg := "Confirma o envio de alterações de dados da carga/viagem posicionada para o sistema Krona?"
      Else
         _cTextoMsg := "Confirma o envio dos dados da carga/viagem posicionada para o sistema Krona?"
      EndIf

      If ! U_ITMsg(_cTextoMsg,"Atenção", ,2 , 2)  
         Break
      EndIf              
   EndIf 

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := ZFM->ZFM_LOCXML 
      _cLinkWS  := ZFM->ZFM_LINK01
   Else 
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Empresa WebService para envio dos dados não localizada.")
      EndIf 

      Break
   EndIf
   
   If Empty(_cDirJSon)
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      EndIf 

      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo JSON e os transforma em String.
   //================================================================================
   _cCabLogin := U_AOMS118X(_cDirJSon+"Krona1_Cab_Login.txt") 
   If Empty(_cCabLogin)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho de envio e login da integração Krona.","Atenção",,1) 
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON modelo do cabeçalho de envio e login da integração Krona.")
      EndIf 

      Break
   EndIf

   _cDetViagem := U_AOMS118X(_cDirJSon+"Krona1_Det_Altera_Viagem.txt") 

   If Empty(_cDetViagem)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Viagem da integração Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Viagem da integração Krona.")
      EndIf

      Break
   EndIf
   
   _cDetDestA := U_AOMS118X(_cDirJSon+"Krona1_Det_Destino_A.txt") 
   If Empty(_cDetDestA)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Destino (A), da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Destino (A), da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   _cDetDestB := U_AOMS118X(_cDirJSon+"Krona1_Det_Destino_B.txt") 
   If Empty(_cDetDestB)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Destino (B), da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Destino (B), da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   _cDetDestC := U_AOMS118X(_cDirJSon+"Krona1_Det_Destino_C.txt") 
   If Empty(_cDetDestC)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Destino (C), da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Destino (C), da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   _cDetMotorista := U_AOMS118X(_cDirJSon+"Krona1_Det_Motorista.txt") 
   If Empty(_cDetMotorista)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Motorista, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Motorista, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   _cDetOrigem := U_AOMS118X(_cDirJSon+"Krona1_Det_Origem.txt") 
   If Empty(_cDetOrigem)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Origem, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Origem, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   _cDetTransportador := U_AOMS118X(_cDirJSon+"Krona1_Det_Transportador.txt") 
   If Empty(_cDetTransportador)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe de Transportador, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON detalhe de Transportador, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   //_cDetVeiculo := U_AOMS118X(_cDirJSon+"Krona1_Det_Veículo.txt") 
   _cDetVeiculo := U_AOMS118X(_cDirJSon+"Krona1_Det_Veiculo.txt") 
   If Empty(_cDetVeiculo)
      If _cChamada == "M" // Chamada via menu.    
         U_ITMsg("Erro na leitura do arquivo modelo JSON do detalhe de Veículo, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON do detalhe de Veículo, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf

   
   _cReboque1 := U_AOMS118X(_cDirJSon+"Krona1_Det_Reboque_1.txt") 
   If Empty(_cReboque1)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON do reboque_1 de Veículo, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON do reboque_1 de Veículo, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   
   _cReboque2 := U_AOMS118X(_cDirJSon+"Krona1_Det_Reboque_2.txt") 
   If Empty(_cReboque2)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON do reboque_2 de Veículo, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON do reboque_2 de Veículo, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
    
   _cReboque3 := U_AOMS118X(_cDirJSon+"Krona1_Det_Reboque_3.txt") 
   If Empty(_cReboque3)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON do reboque_3 de Veículo, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON do reboque_3 de Veículo, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf
   _cRodaPe := U_AOMS118X(_cDirJSon+"Krona1_Rodape.txt") 
   If Empty(_cRodaPe)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON do rodape, da integração REST Italac x Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - Erro na leitura do arquivo modelo JSON do rodape, da integração REST Italac x Krona.")
      EndIf 

      Break
   EndIf

   //==========================================================================================
   // O valor da carga é inferior ao valor estipulado em parêmetro. Usuário e senha NÃO é 
   // por transportadora. 
   // O usuário e senha devem ser lidos da tabela ZG9 e ZZM conforme regras de Armazens:
   // - Se existir um item do pedido de vendas com armazem cadastrado na tabela ZG9, pegar
   //   usuário e senha Krona da tabela ZG9.
   // - Se NÃO existir item do pedido de venda com armazem cadastrado na tabele ZG9, pegar
   //   usuário e senha Krona da tabela ZZM.
   //========================================================================================== 
   _cUsrZG9   := ""
   _cPswZG9   := ""
   _cFornZG9  := ""
   _cLojaZG9  := ""

   SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
   ZZM->(DBSetOrder(1)) // ZZM_FILIAL+ZZM_CODIGO   
   ZG9->(DBSetOrder(1)) // ZG9_FILIAL+ZG9_CODFIL+ZG9_ARMAZE 
   DAI->(DBSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO  
   DAI->(DBSeek(DAK->DAK_FILIAL+DAK->DAK_COD))
      
   _lTemZG9 := .F.
   _aPedidoDAI := {}

   While ! DAI->(Eof()) .And. DAI->(DAI_FILIAL+DAI_COD) == DAK->DAK_FILIAL+DAK->DAK_COD      
      
      _nI := aScan(_aPedidoDAI,DAI->DAI_FILIAL+DAI->DAI_PEDIDO)
      If _nI > 0
         DAI->(DBSkip())
         Loop 
      EndIf 
      aAdd(_aPedidoDAI,DAI->DAI_FILIAL+DAI->DAI_PEDIDO) 

      SC6->(MsSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))   
         
      While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == DAI->DAI_FILIAL+DAI->DAI_PEDIDO
         If ZG9->(DBSeek(xFilial("ZG9")+SC6->C6_FILIAL+SC6->C6_LOCAL))   
            _cUsrZG9   := ZG9->ZG9_USRKRO
            _cPswZG9   := ZG9->ZG9_PSWKRO            
            _cFornZG9  := ZG9->ZG9_CODFOR
            _cLojaZG9  := ZG9->ZG9_LOJFOR
            _lTemZG9  := .T. 
            Exit 
         EndIf 

         SC6->(DBSkip())
      EndDo
         
      If _lTemZG9
         Exit 
      EndIf 

      //------------------------------------------------------
      If ! Empty(DAI->DAI_NFISCA)
         SD2->(MsSeek(DAI->DAI_FILIAL+DAI->DAI_NFISCA+DAI->DAI_SERIE))   
         While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE) == DAI->DAI_FILIAL+DAI->DAI_NFISCA+DAI->DAI_SERIE
            If DAI->DAI_PEDIDO == SD2->D2_PEDIDO
               If ZG9->(DBSeek(xFilial("ZG9")+SD2->D2_FILIAL+SD2->D2_LOCAL))   
                  _cUsrZG9   := ZG9->ZG9_USRKRO
                  _cPswZG9   := ZG9->ZG9_PSWKRO            
                  _cFornZG9  := ZG9->ZG9_CODFOR
                  _cLojaZG9  := ZG9->ZG9_LOJFOR
                  _lTemZG9  := .T.  
                  Exit 
               EndIf 

            EndIf
         
            SD2->(DBSkip())
         EndDo
      
         If _lTemZG9
            Exit 
         EndIf
      EndIf 

      //------------------------------------------------------

      DAI->(DBSkip()) 

   EndDo          

   If ! _lTemZG9 .Or. Empty(_cUsrZG9 )   
      If ZZM->(DBSeek(xFilial("ZZM")+DAK->DAK_FILIAL))
         _cUsrZG9   := ZZM->ZZM_USRKRO
         _cPswZG9   := ZZM->ZZM_PSWKRO     
      EndIf 
   EndIf 

   //=============================================================
   // Inicializando contador Motorista e Destino
   //=============================================================
   _nMotorista := 1
   _nDestinos  := 0 
   
   //--------------------------->> 1 - Login
   _cLinkWS  := AllTrim(_cLinkWS) 
   
   _cTransp   := ""
   _cLjTransp := ""
   
   //--------------------------->> 3 - Motorista 1 
   // _cDetMotorista           
   DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD   
   If DA4->(DBSeek(xFilial("DA4")+DAK->DAK_MOTORI))
      _cNomeMoto        := DA4->DA4_NOME  
      _cCpfMoto         := Transform(DA4->DA4_CGC,"@R 999.999.999-99")  // DA4->DA4_CGC   
      _cRgMoto          := Transform(DA4->DA4_RG,"@R 999.999.999-!!")      
      _cOrgaoEmissMoto  := DA4->DA4_RGORG 
      _cDtNascMoto      := DA4->DA4_DATNAS 
      _cNomeMaeMoto     := DA4->DA4_MAE    
      _cEstadoCivMoto   := DA4->DA4_ESTCIV
      _cEscolarMoto     := "" 
      _cCnhMoto         := DA4->DA4_NUMCNH 
      _cCategCnhMoto    := DA4->DA4_CATCNH 
      _cValidCnhMoto    := DA4->DA4_DTVCNH
      _cRuaMoto         := DA4->DA4_END    
      _cNrEndMoto       := U_AOMS118N(DA4->DA4_END) 
      _cComplemMoto     := ""
      _cBairoMoto       := DA4->DA4_BAIRRO
      _cCidMoto         := DA4->DA4_MUN   
      _cUfMoto          := DA4->DA4_EST   
      _cCepMoto         := Transform(DA4->DA4_CEP,"@R 99999-999")
      _cTelFixoMoto     := DA4->DA4_TELREC
      _cCelMoto         := DA4->DA4_TEL
      _cNextelMoto      := ""
      _cMoppMoto        := ""
      _cAsoMoto         := ""
      _cCddMoto         := ""
      _cCapacMoto       := ""
      _cVincMoto        := ""
      //----------------------------------------------//
      _cTransp   := DA4->DA4_FORNECE
      _cLjTransp := DA4->DA4_LOJA     
   Else
      _cNomeMoto        := ""   
      _cCpfMoto         := "" 
      _cRgMoto          := ""  
      _cOrgaoEmissMoto  := "" 
      _cDtNascMoto      := ""  
      _cNomeMaeMoto     := "" 
      _cEstadoCivMoto   := "" 
      _cEscolarMoto     := "" 
      _cCnhMoto         := "" 
      _cCategCnhMoto    := "" 
      _cValidCnhMoto    := "" 
      _cRuaMoto         := "" 
      _cNrEndMoto       := ""
      _cComplemMoto     := ""
      _cBairoMoto       := ""
      _cCidMoto         := ""
      _cUfMoto          := ""
      _cCepMoto         := ""
      _cTelFixoMoto     := "" 
      _cCelMoto         := "" 
      _cNextelMoto      := ""
      _cMoppMoto        := ""
      _cAsoMoto         := ""
      _cCddMoto         := ""
      _cCapacMoto       := ""
      _cVincMoto        := ""
   EndIf

   //=====================================================
   // Transportador
   //=====================================================
   If Empty(_cTransp)
      If _cChamada == "M" // Chamada via menu.   
         U_ITMsg("A carga seleciondada não possui transportadora informada. Não será possível integrar para o sistema Krona.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[AOMS118] - A carga seleciondada não possui transportadora informada. Não será possível integrar para o sistema Krona.")
      EndIf 

      Break   
   EndIf             
   
   //--------------------------->> 2 - Transportador
   // _cDetTransportador      
   SA2->(DBSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
   
   If SA2->(DBSeek(xFilial("SA2")+_cTransp + _cLjTransp)) 
      _cTipoTransp      := "TRANSPORTADOR"
      _cCNPJTransp      := "0"+Transform(SA2->A2_CGC,"@R! NN.NNN.NNN/NNNN-99") // Na Krona os CNPJ são cadastrados com 15 digitos + as pontuações.
      _cRazaoTransp     := SA2->A2_NOME 
      _cNomeFTransp     := SA2->A2_NREDUZ  
      _cUnidTransp      := SA2->A2_LOJA
      _cCodigoTransp    := SA2->A2_COD 
      _cRuaTransp       := SA2->A2_END
      _cNumeroTransp    := U_AOMS118N(SA2->A2_END) // SA2->A2_NR_END 
      _cComplemTransp   := SA2->A2_COMPLEM                                 
      _cBairroTransp    := SA2->A2_BAIRRO 
      _cCidadeTransp    := SA2->A2_MUN    
      _cUfTransp        := SA2->A2_EST    
      _cCepTransp       := Transform(SA2->A2_CEP,"@R 99999-999") 
      _cLatitudeTransp  := "" 
      _cLogitudeTransp  := "" 
      _cPhone1Transp    := "(" + SA2->A2_DDD + ")" + SA2->A2_TEL 
      _cPhone2Transp    := "" 
      _cResponTransp    := SA2->A2_CONTATO
      _cRespCargoTranp  := ""
      _cRespPhoneTransp := ""
      _cRespCelTransp   := "" 
      _cRespEmailTransp := SA2->A2_EMAIL  
      If _lUsuarioTransp
         _cUsuario         := SA2->A2_I_USRKR
         _cSenha           := SA2->A2_I_PSWKR
      Else
         _cUsuario         := ""
         _cSenha           := ""
      EndIf 
   Else
      _cTipoTransp      := "" 
      _cCNPJTransp      := "" 
      _cRazaoTransp     := "" 
      _cNomeFTransp     := ""  
      _cUnidTransp      := "" 
      _cCodigoTransp    := "" 
      _cRuaTransp       := ""
      _cNumeroTransp    := ""
      _cComplemTransp   := "" 
      _cBairroTransp    := "" 
      _cCidadeTransp    := ""
      _cUfTransp        := ""
      _cCepTransp       := ""  
      _cLatitudeTransp  := "" 
      _cLogitudeTransp  := "" 
      _cPhone1Transp    := "" 
      _cPhone2Transp    := "" 
      _cResponTransp    := ""
      _cRespCargoTranp  := ""
      _cRespPhoneTransp := ""
      _cRespCelTransp   := "" 
      _cRespEmailTransp := ""
      _cUsuario         := ""
      _cSenha           := ""
   EndIf
         
   //=====================================================
   // Transportador: Login e Senha.
   //=====================================================
   //If Empty(_cUsuario) .Or. Empty(_cSenha)
   //   U_ITMsg("Não foram informados nome de usuário e senha para o transportador: Codigo: '"+ _cTransp + "' e Loja: '" + _cLjTransp + "', acessar o sistema Krona.",;
   //           "Atenção","Acesse o cadastro de fornecedores, localize o transportador e informe nome de usuário e senha.",1)
   //   Break   
   //EndIf 
   
   //--------------------------->> 4 - Veiculo  
   // _cDetVeiculo                              
   //==========================================
   // Veiculo
   //========================================== 
   //DAK->DAK_CAMINH ---> DA3
   _cVeiculo := ""
   DA3->(DBSetOrder(1)) // DA3_FILIAL+DA3_COD    
   If DA3->(DBSeek(xFilial("DA3")+DAK->DAK_CAMINH))
      //=====================================================================================
      // // 2 = Caminhão / 4 = Utilitário
      //=====================================================================================
      If DA3->DA3_I_TPVC == "2" .Or. DA3->DA3_I_TPVC == "4"  // 2 = Caminhao / 4=Utilitário
         _cVeiculo         := "CAMINHAO/UTILITARIO"
         _cPlacaVeic       := Transform(DA3->DA3_PLACA, "@R !!!-!!!!")
         _cRenavVeic       := DA3->DA3_RENAVA 
         _cMarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _cModeloVeic      := DA3->DA3_DESC    
         _cCorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _cAnoVeic         := DA3->DA3_ANOFAB          
         _cTipoVeic        := If(DA3->DA3_I_TPVC == "2","TRUCK","UTILITARIO LEVE")   // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _cCapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _cCidPVeic        := DA3->DA3_MUNPLA // "SAO PAULO" 
         _cUfPVeic         := DA3->DA3_ESTPLA //"SP" 
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _cNrAnttVeic      := "A00001"  
         _cValAnttVeic     := "2030"  
         _cNrFrotaVeic     := "00001"  
         _cTrFrotVeic      := "00000"  
         _cPropretVeic     := "PROPRIETEARIO TESTE"  
         _cCpfCgcPVeic     := "00000000000" 
         _cRuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _cNrRuaPVeic      := "001"  
         _cComplPVeic      := "" 
         _cBairroPVeic     := "CENTRO"  
         _cCepPVeic        := "00000-000" 
         _cTecnoPVeic      := "SATE" 
         _cIdRastrVeic     := "1234567890" 
         _cComunPVeic      := "12345"  
         _cTecSecVeic      := "TESTE01"  
         _cIdRSecVeic      := "TESTE02"  
         _cComSecVeic      := "TESTE03" 
         _cFixoVeic        := "TESTE04"
      
      //=====================================================================================
      // 1 = Carreta
      //=====================================================================================
      ElseIf DA3->DA3_I_TPVC == "1" // 1 = Carreta
         _cVeiculo         := "CARRETA"
         _cPlacaVeic       := Transform(DA3->DA3_I_PLCV, "@R !!!-!!!!")
         _cRenavVeic       := DA3->DA3_RENAVA 
         _cMarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _cModeloVeic      := DA3->DA3_DESC    
         _cCorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _cAnoVeic         := DA3->DA3_ANOFAB          
         _cTipoVeic        := "CARRETA ABERTA" // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _cCapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _cCidPVeic        := DA3->DA3_I_MUCV
         _cUfPVeic         := DA3->DA3_I_UFCV
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _cNrAnttVeic      := "A00001"  
         _cValAnttVeic     := "2030"  
         _cNrFrotaVeic     := "00001"  
         _cTrFrotVeic      := "00000"  
         _cPropretVeic     := "PROPRIETEARIO TESTE"  
         _cCpfCgcPVeic     := "00000000000" 
         _cRuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _cNrRuaPVeic      := "001"  
         _cComplPVeic      := "" 
         _cBairroPVeic     := "CENTRO"  
         _cCepPVeic        := "00000-000" 
         _cTecnoPVeic      := "SATE" 
         _cIdRastrVeic     := "1234567890" 
         _cComunPVeic      := "12345"  
         _cTecSecVeic      := "TESTE01"  
         _cIdRSecVeic      := "TESTE02"  
         _cComSecVeic      := "TESTE03" 
         _cFixoVeic        := "TESTE04"
         //==========================================
         // Reboque 1
         //==========================================        
         _c1PlacaVeic       := Transform(DA3->DA3_PLACA, "@R !!!-!!!!")
         _c1RenavVeic       := DA3->DA3_RENAVA 
         _c1MarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _c1ModeloVeic      := DA3->DA3_DESC    
         _c1CorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _c1AnoVeic         := DA3->DA3_ANOFAB          
         _c1TipoVeic        := "CARRETA ABERTA" // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _c1CapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _c1CidPVeic        := DA3->DA3_MUNPLA   
         _c1UfPVeic         := DA3->DA3_ESTPLA  
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _c1NrAnttVeic      := "A00001"  
         _c1ValAnttVeic     := "2030"  
         _c1NrFrotaVeic     := "00001"  
         _c1TrFrotVeic      := "00000"  
         _c1PropretVeic     := "PROPRIETEARIO TESTE"  
         _c1CpfCgcPVeic     := "00000000000" 
         _c1RuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _c1NrRuaPVeic      := "001"  
         _c1ComplPVeic      := "" 
         _c1BairroPVeic     := "CENTRO"  
         _c1CepPVeic        := "00000-000" 
         _c1TecnoPVeic      := "SATE" 
         _c1IdRastrVeic     := "1234567890" 
         _c1ComunPVeic      := "12345"  
         _c1TecSecVeic      := "TESTE01"  
         _c1IdRSecVeic      := "TESTE02"  
         _c1ComSecVeic      := "TESTE03" 
         _c1FixoVeic        := "TESTE04"

      //=====================================================================================
      // 3 = BiTrem
      //=====================================================================================
      ElseIf DA3->DA3_I_TPVC == "3" 
         _cVeiculo         := "BITREM"
         _cPlacaVeic       := Transform(DA3->DA3_I_PLCV, "@R !!!-!!!!")
         _cRenavVeic       := DA3->DA3_RENAVA 
         _cMarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _cModeloVeic      := DA3->DA3_DESC    
         _cCorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _cAnoVeic         := DA3->DA3_ANOFAB          
         _cTipoVeic        := "CARRETA BITREM" // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _cCapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _cCidPVeic        := DA3->DA3_I_MUCV
         _cUfPVeic         := DA3->DA3_I_UFCV
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _cNrAnttVeic      := "A00001"  
         _cValAnttVeic     := "2030"  
         _cNrFrotaVeic     := "00001"  
         _cTrFrotVeic      := "00000"  
         _cPropretVeic     := "PROPRIETEARIO TESTE"  
         _cCpfCgcPVeic     := "00000000000" 
         _cRuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _cNrRuaPVeic      := "001"  
         _cComplPVeic      := "" 
         _cBairroPVeic     := "CENTRO"  
         _cCepPVeic        := "00000-000" 
         _cTecnoPVeic      := "SATE" 
         _cIdRastrVeic     := "1234567890" 
         _cComunPVeic      := "12345"  
         _cTecSecVeic      := "TESTE01"  
         _cIdRSecVeic      := "TESTE02"  
         _cComSecVeic      := "TESTE03" 
         _cFixoVeic        := "TESTE04"
         //==========================================
         // Reboque 1
         //==========================================        
         _c1PlacaVeic       := Transform(DA3->DA3_PLACA, "@R !!!-!!!!")
         _c1RenavVeic       := DA3->DA3_RENAVA 
         _c1MarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _c1ModeloVeic      := DA3->DA3_DESC    
         _c1CorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _c1AnoVeic         := DA3->DA3_ANOFAB          
         _c1TipoVeic        := "CARRETA BITREM" // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _c1CapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _c1CidPVeic        := DA3->DA3_MUNPLA   
         _c1UfPVeic         := DA3->DA3_ESTPLA  
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _c1NrAnttVeic      := "A00001"  
         _c1ValAnttVeic     := "2030"  
         _c1NrFrotaVeic     := "00001"  
         _c1TrFrotVeic      := "00000"  
         _c1PropretVeic     := "PROPRIETEARIO TESTE"  
         _c1CpfCgcPVeic     := "00000000000" 
         _c1RuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _c1NrRuaPVeic      := "001"  
         _c1ComplPVeic      := "" 
         _c1BairroPVeic     := "CENTRO"  
         _c1CepPVeic        := "00000-000" 
         _c1TecnoPVeic      := "SATE" 
         _c1IdRastrVeic     := "1234567890" 
         _c1ComunPVeic      := "12345"  
         _c1TecSecVeic      := "TESTE01"  
         _c1IdRSecVeic      := "TESTE02"  
         _c1ComSecVeic      := "TESTE03" 
         _c1FixoVeic        := "TESTE04"          
         //==========================================
         // Reboque 2
         //==========================================        
         _c2PlacaVeic       := Transform(DA3->DA3_I_PLVG, "@R !!!-!!!!")
         _c2RenavVeic       := DA3->DA3_RENAVA 
         _c2MarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _c2ModeloVeic      := DA3->DA3_DESC    
         _c2CorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _c2AnoVeic         := DA3->DA3_ANOFAB          
         _c2TipoVeic        := "CARRETA BITREM" //Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _c2CapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _c2CidPVeic        := DA3->DA3_I_MUVG
         _c2UfPVeic         := DA3->DA3_I_UFVG  
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _c2NrAnttVeic      := "A00001"  
         _c2ValAnttVeic     := "2030"  
         _c2NrFrotaVeic     := "00001"  
         _c2TrFrotVeic      := "00000"  
         _c2PropretVeic     := "PROPRIETEARIO TESTE"  
         _c2CpfCgcPVeic     := "00000000000" 
         _c2RuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _c2NrRuaPVeic      := "001"  
         _c2ComplPVeic      := "" 
         _c2BairroPVeic     := "CENTRO"  
         _c2CepPVeic        := "00000-000" 
         _c2TecnoPVeic      := "SATE" 
         _c2IdRastrVeic     := "1234567890" 
         _c2ComunPVeic      := "12345"  
         _c2TecSecVeic      := "TESTE01"  
         _c2IdRSecVeic      := "TESTE02"  
         _c2ComSecVeic      := "TESTE03" 
         _c2FixoVeic        := "TESTE04"

      //=====================================================================================
      // 5 = RodoTrem
      //=====================================================================================
      ElseIf DA3->DA3_I_TPVC == "5"
         _cVeiculo         := "RODOTREM"
         _cPlacaVeic       := Transform(DA3->DA3_I_PLCV, "@R !!!-!!!!")
         _cRenavVeic       := DA3->DA3_RENAVA 
         _cMarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _cModeloVeic      := DA3->DA3_DESC    
         _cCorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _cAnoVeic         := DA3->DA3_ANOFAB          
         _cTipoVeic        := "CARRETA TRITREM" // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _cCapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _cCidPVeic        := DA3->DA3_I_MUCV
         _cUfPVeic         := DA3->DA3_I_UFCV
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _cNrAnttVeic      := "A00001"  
         _cValAnttVeic     := "2030"  
         _cNrFrotaVeic     := "00001"  
         _cTrFrotVeic      := "00000"  
         _cPropretVeic     := "PROPRIETEARIO TESTE"  
         _cCpfCgcPVeic     := "00000000000" 
         _cRuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _cNrRuaPVeic      := "001"  
         _cComplPVeic      := "" 
         _cBairroPVeic     := "CENTRO"  
         _cCepPVeic        := "00000-000" 
         _cTecnoPVeic      := "SATE" 
         _cIdRastrVeic     := "1234567890" 
         _cComunPVeic      := "12345"  
         _cTecSecVeic      := "TESTE01"  
         _cIdRSecVeic      := "TESTE02"  
         _cComSecVeic      := "TESTE03" 
         _cFixoVeic        := "TESTE04"

         //==========================================
         // Reboque 1
         //==========================================        
         _c1PlacaVeic       := Transform(DA3->DA3_PLACA, "@R !!!-!!!!")
         _c1RenavVeic       := DA3->DA3_RENAVA 
         _c1MarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _c1ModeloVeic      := DA3->DA3_DESC    
         _c1CorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _c1AnoVeic         := DA3->DA3_ANOFAB          
         _c1TipoVeic        := "CARRETA TRITREM" //Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _c1CapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _c1CidPVeic        := DA3->DA3_MUNPLA   
         _c1UfPVeic         := DA3->DA3_ESTPLA  
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _c1NrAnttVeic      := "A00001"  
         _c1ValAnttVeic     := "2030"  
         _c1NrFrotaVeic     := "00001"  
         _c1TrFrotVeic      := "00000"  
         _c1PropretVeic     := "PROPRIETEARIO TESTE"  
         _c1CpfCgcPVeic     := "00000000000" 
         _c1RuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _c1NrRuaPVeic      := "001"  
         _c1ComplPVeic      := "" 
         _c1BairroPVeic     := "CENTRO"  
         _c1CepPVeic        := "00000-000" 
         _c1TecnoPVeic      := "SATE" 
         _c1IdRastrVeic     := "1234567890" 
         _c1ComunPVeic      := "12345"  
         _c1TecSecVeic      := "TESTE01"  
         _c1IdRSecVeic      := "TESTE02"  
         _c1ComSecVeic      := "TESTE03" 
         _c1FixoVeic        := "TESTE04"          

         //==========================================
         // Reboque 2
         //==========================================        
         _c2PlacaVeic       := Transform(DA3->DA3_I_PLVG, "@R !!!-!!!!")
         _c2RenavVeic       := DA3->DA3_RENAVA 
         _c2MarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _c2ModeloVeic      := DA3->DA3_DESC    
         _c2CorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _c2AnoVeic         := DA3->DA3_ANOFAB          
         _c2TipoVeic        := "CARRETA TRITREM" //Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _c2CapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _c2CidPVeic        := DA3->DA3_I_MUVG
         _c2UfPVeic         := DA3->DA3_I_UFVG  
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _c2NrAnttVeic      := "A00001"  
         _c2ValAnttVeic     := "2030"  
         _c2NrFrotaVeic     := "00001"  
         _c2TrFrotVeic      := "00000"  
         _c2PropretVeic     := "PROPRIETEARIO TESTE"  
         _c2CpfCgcPVeic     := "00000000000" 
         _c2RuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _c2NrRuaPVeic      := "001"  
         _c2ComplPVeic      := "" 
         _c2BairroPVeic     := "CENTRO"  
         _c2CepPVeic        := "00000-000" 
         _c2TecnoPVeic      := "SATE" 
         _c2IdRastrVeic     := "1234567890" 
         _c2ComunPVeic      := "12345"  
         _c2TecSecVeic      := "TESTE01"  
         _c2IdRSecVeic      := "TESTE02"  
         _c2ComSecVeic      := "TESTE03" 
         _c2FixoVeic        := "TESTE04"
         
         //==========================================
         // Reboque 3
         //==========================================        
         _c2PlacaVeic       := Transform(DA3->DA3_I_PLV3, "@R !!!-!!!!")
         _c2RenavVeic       := DA3->DA3_RENAVA 
         _c2MarcaVeic       := Tabela("M6",DA3->DA3_MARVEI,.F.) 
         _c2ModeloVeic      := DA3->DA3_DESC    
         _c2CorVeic         := Tabela("M7",DA3->DA3_CORVEI,.F.)                                                                                
         _c2AnoVeic         := DA3->DA3_ANOFAB          
         _c2TipoVeic        := "CARRETA TRITREM" // Posicione("DUT",1,xFilial("DUT")+DA3->DA3_TIPVEI,'DUT_DESCRI ')                                                   
         _c2CapacidVeic     := Str(DA3->DA3_CAPACM,9,2)    
         _c2CidPVeic        := DA3->DA3_I_MUV3
         _c2UfPVeic         := DA3->DA3_I_UFV3  
         //---------------------------------------------> Dados para teste de sistemas. Serão preenchidos manualmente no sistema Krona.
         _c2NrAnttVeic      := "A00001"  
         _c2ValAnttVeic     := "2030"  
         _c2NrFrotaVeic     := "00001"  
         _c2TrFrotVeic      := "00000"  
         _c2PropretVeic     := "PROPRIETEARIO TESTE"  
         _c2CpfCgcPVeic     := "00000000000" 
         _c2RuaPVeic        := "RUA TESTE DESENVOL SISTEMAS"  
         _c2NrRuaPVeic      := "001"  
         _c2ComplPVeic      := "" 
         _c2BairroPVeic     := "CENTRO"  
         _c2CepPVeic        := "00000-000" 
         _c2TecnoPVeic      := "SATE" 
         _c2IdRastrVeic     := "1234567890" 
         _c2ComunPVeic      := "12345"  
         _c2TecSecVeic      := "TESTE01"  
         _c2IdRSecVeic      := "TESTE02"  
         _c2ComSecVeic      := "TESTE03" 
         _c2FixoVeic        := "TESTE04"
      EndIf 
   Else
      _cPlacaVeic       := ""   
      _cRenavVeic       := ""  
      _cMarcaVeic       := ""  
      _cModeloVeic      := ""  
      _cCorVeic         := ""  
      _cAnoVeic         := ""   
      _cTipoVeic        := "" 
      _cCapacidVeic     := ""  
      _cNrAnttVeic      := ""  
      _cValAnttVeic     := ""  
      _cNrFrotaVeic     := ""  
      _cTrFrotVeic      := ""  
      _cPropretVeic     := ""  
      _cCpfCgcPVeic     := "" 
      _cRuaPVeic        := ""  
      _cNrRuaPVeic      := ""  
      _cComplPVeic      := "" 
      _cBairroPVeic     := ""  
      _cCidPVeic        := "" 
      _cUfPVeic         := ""
      _cCepPVeic        := "" 
      _cTecnoPVeic      := "" 
      _cIdRastrVeic     := "" 
      _cComunPVeic      := ""  
      _cTecSecVeic      := ""  
      _cIdRSecVeic      := ""  
      _cComSecVeic      := "" 
      _cFixoVeic        := ""
   
      //==========================================
      // Reboque 1
      //==========================================  
      _c1PlacaVeic       := ""   
      _c1RenavVeic       := ""  
      _c1MarcaVeic       := ""  
      _c1ModeloVeic      := ""  
      _c1CorVeic         := ""  
      _c1AnoVeic         := ""   
      _c1TipoVeic        := "" 
      _c1CapacidVeic     := ""  
      _c1NrAnttVeic      := ""  
      _c1ValAnttVeic     := ""  
      _c1NrFrotaVeic     := ""  
      _c1TrFrotVeic      := ""  
      _c1PropretVeic     := ""  
      _c1CpfCgcPVeic     := "" 
      _c1RuaPVeic        := ""  
      _c1NrRuaPVeic      := ""  
      _c1ComplPVeic      := "" 
      _c1BairroPVeic     := ""  
      _c1CidPVeic        := "" 
      _c1UfPVeic         := ""
      _c1CepPVeic        := "" 
      _c1TecnoPVeic      := "" 
      _c1IdRastrVeic     := "" 
      _c1ComunPVeic      := ""  
      _c1TecSecVeic      := ""  
      _c1IdRSecVeic      := ""  
      _c1ComSecVeic      := "" 
      _c1FixoVeic        := ""

      //==========================================
      // Reboque 2
      //==========================================  
      _c2PlacaVeic       := ""   
      _c2RenavVeic       := ""  
      _c2MarcaVeic       := ""  
      _c2ModeloVeic      := ""  
      _c2CorVeic         := ""  
      _c2AnoVeic         := ""   
      _c2TipoVeic        := "" 
      _c2CapacidVeic     := ""  
      _c2NrAnttVeic      := ""  
      _c2ValAnttVeic     := ""  
      _c2NrFrotaVeic     := ""  
      _c2TrFrotVeic      := ""  
      _c2PropretVeic     := ""  
      _c2CpfCgcPVeic     := "" 
      _c2RuaPVeic        := ""  
      _c2NrRuaPVeic      := ""  
      _c2ComplPVeic      := "" 
      _c2BairroPVeic     := ""  
      _c2CidPVeic        := "" 
      _c2UfPVeic         := ""
      _c2CepPVeic        := "" 
      _c2TecnoPVeic      := "" 
      _c2IdRastrVeic     := "" 
      _c2ComunPVeic      := ""  
      _c2TecSecVeic      := ""  
      _c2IdRSecVeic      := ""  
      _c2ComSecVeic      := "" 
      _c2FixoVeic        := ""

      //==========================================
      // Reboque 3
      //==========================================  
      _c3PlacaVeic       := ""   
      _c3RenavVeic       := ""  
      _c3MarcaVeic       := ""  
      _c3ModeloVeic      := ""  
      _c3CorVeic         := ""  
      _c3AnoVeic         := ""   
      _c3TipoVeic        := "" 
      _c3CapacidVeic     := ""  
      _c3NrAnttVeic      := ""  
      _c3ValAnttVeic     := ""  
      _c3NrFrotaVeic     := ""  
      _c3TrFrotVeic      := ""  
      _c3PropretVeic     := ""  
      _c3CpfCgcPVeic     := "" 
      _c3RuaPVeic        := ""  
      _c3NrRuaPVeic      := ""  
      _c3ComplPVeic      := "" 
      _c3BairroPVeic     := ""  
      _c3CidPVeic        := "" 
      _c3UfPVeic         := ""
      _c3CepPVeic        := "" 
      _c3TecnoPVeic      := "" 
      _c3IdRastrVeic     := "" 
      _c3ComunPVeic      := ""  
      _c3TecSecVeic      := ""  
      _c3IdRSecVeic      := ""  
      _c3ComSecVeic      := "" 
      _c3FixoVeic        := ""
   EndIf
   
   //--------------------------->> 5 - Origem 
   // _cDetOrigem
   //==========================================
   // Origem  
   //========================================== 
   _lAchouForn  := .F.
   If Empty(_cFornZG9)
      ZZM->(DBSetOrder(1))
      ZZM->(DBSeek(xFilial("ZZM")+DAK->DAK_FILIAL))
      SA2->(DBSetOrder(3)) // A2_FILIAL+A2_CGC 
      If SA2->(DBSeek(xFilial("SA2")+ZZM->ZZM_CGC))
         _lAchouForn  := .T. 
      EndIf 
   Else 
      SA2->(DBSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
      If SA2->(DBSeek(xFilial("SA2")+_cFornZG9 + _cLojaZG9))
         _lAchouForn  := .T. 
      EndIf 
   EndIf 

   If _lAchouForn
      _cTipoOrig        := "EMBARCADOR" 
      _cCnpjOrig        := "0"+Transform(SA2->A2_CGC,"@R! NN.NNN.NNN/NNNN-99") //"0"+Transform(ZZM->ZZM_CGC,"@R! NN.NNN.NNN/NNNN-99") // Na Krona os CNPJ são cadastrados com 15 digitos + as pontuações.
      _cRazaoSOrig      := SA2->A2_NOME
      _cNomeFOrig       := SA2->A2_NREDUZ 
      _cUnidOrig        := SA2->A2_LOJA
      _cCodUndOrig      := SA2->A2_COD 
      _cEnderOrig       := SA2->A2_END
      _cNrEndOrig       := U_AOMS118N(SA2->A2_END) //SA2->A2_NR_END 
      _cComplEndOrig    := SA2->A2_COMPLEM
      _cBairEndOrig     := SA2->A2_BAIRRO  
      _cCidEndOrig      := SA2->A2_MUN     
      _cUfEndOrig       := SA2->A2_EST
      _cCepEndOrig      := Transform(SA2->A2_CEP,"@R 99999-999") 
      _cLatiEndOrg      := "" 
      _cLongEndOrig     := "" 
      _cTel1EndOrig     := "("+SA2->A2_DDD+") "+SA2->A2_TEL 
      _cTel2EndOrig     := "("+SA2->A2_DDD+") "+SA2->A2_TEL  
      _cRespEndOrig     := SA2->A2_CONTATO
      _cRespCEOrig      := SA2->A2_CONTATO
      _cTelEndOrig      := "" 
      _CelEndOrig       := ""
      _cMailEndOrig     := SA2->A2_EMAIL

      //=========================================
      // Dados Adicionais - Remetente
      //=========================================      
      _cTipoRem   := "EMBARCADOR"
      _cCnpjRem   := "0"+Transform(SA2->A2_CGC,"@R! NN.NNN.NNN/NNNN-99") // "0"+Transform(ZZM->ZZM_CGC,"@R! NN.NNN.NNN/NNNN-99") // Na Krona os CNPJ são cadastrados com 15 digitos + as pontuações.
      _cRazaoRem  := SA2->A2_NOME
      _cNomeRem   := SA2->A2_NREDUZ 
      _cUnidRem   := SA2->A2_LOJA
      _cCodRem    := SA2->A2_COD 
      _cEndRem    := SA2->A2_END
      _cNumEndRem := U_AOMS118N(SA2->A2_END) 
      _cComplRem  := SA2->A2_COMPLEM
      _cBairroRem := SA2->A2_BAIRRO
      _cCidRem    := SA2->A2_MUN
      _cUfRem     := SA2->A2_EST
      _cCepRem    := Transform(SA2->A2_CEP,"@R 99999-999") 
      _cLatRem    := ""
      _cLongRem   := ""
      _cFone1Rem  := "("+SA2->A2_DDD+") "+SA2->A2_TEL 
      _cFone2Rem  := "("+SA2->A2_DDD+") "+SA2->A2_TEL 
      _cResponRem := SA2->A2_CONTATO
      _cCargReRem := ""
      _cFoneReRem := ""
      _cCelReRem  := "" 
      _cMailReRem := SA2->A2_EMAIL
   Else
      _cTipoOrig        := "" 
      _cCnpjOrig        := ""
      _cRazaoSOrig      := ""
      _cNomeFOrig       := "" 
      _cUnidOrig        := "" 
      _cCodUndOrig      := "" 
      _cEnderOrig       := "" 
      _cNrEndOrig       := ""
      _cComplEndOrig    := ""
      _cBairEndOrig     := "" 
      _cCidEndOrig      := "" 
      _cUfEndOrig       := ""
      _cCepEndOrig      := "" 
      _cLatiEndOrg      := "" 
      _cLongEndOrig     := "" 
      _cTel1EndOrig     := "" 
      _cTel2EndOrig     := "" 
      _cRespEndOrig     := ""
      _cRespCEOrig      := "" 
      _cTelEndOrig      := "" 
      _CelEndOrig       := ""
      _cMailEndOrig     := ""
      
      //=========================================
      // Dados Adicionais - Remetente
      //=========================================      
      _cTipoRem   := ""
      _cCnpjRem   := ""
      _cRazaoRem  := ""
      _cNomeRem   := ""
      _cUnidRem   := ""
      _cCodRem    := ""
      _cEndRem    := ""
      _cNumEndRem := ""
      _cComplRem  := ""
      _cBairroRem := ""
      _cCidRem    := ""
      _cUfRem     := ""
      _cCepRem    := ""
      _cLatRem    := ""
      _cLongRem   := ""
      _cFone1Rem  := ""
      _cFone2Rem  := ""
      _cResponRem := ""
      _cCargReRem := ""
      _cFoneReRem := ""
      _cCelReRem  := "" 
      _cMailReRem := ""

   EndIf
   
   _cClieDest  := ""
   _cViagem    := ""
   _cIniViagem := ""
   _cFimViagem := ""
   _nI         := 1
   _cUf_Munic  := ""
   _cObserv    := ""     
   _lDestItalac := .F. 
   
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM  
   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
   SA1->(DBSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA     
   //SF2->(DBSetOrder(20)) // F2_FILIAL+F2_I_PEDID // K
   
   //===============================================================================================
   // Faz agrupamento de dados para pedido de vendas Troca Nota.
   //===============================================================================================      
   // DAK_FILIAL+DAK_COD+DAK_SEQCAR                                                                                                                                    
   DAI->(DBSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO  
      
   _aPvTrcNf := {}
   
   DAI->(DBSeek(DAK->DAK_FILIAL+DAK->DAK_COD))
   While ! DAI->(Eof()) .And. DAI->(DAI_FILIAL+DAI_COD) == DAK->DAK_FILIAL+DAK->DAK_COD    
      SC5->(DBSeek(DAI->(DAI_FILIAL+DAI_PEDIDO)))
      If SC5->C5_I_TRCNF == "S" .And. !Empty(SC5->C5_I_PDFT)
         aAdd(_aPvTrcNf, {DAI->DAI_FILIAL,;  // 1
                          DAI->DAI_PEDIDO,;  // 2 
                          SC5->C5_I_FILFT,;  // 3
                          SC5->C5_I_PDFT,;   // 4
                          DAI->DAI_NFISCA,;  // 5
                          DAI->DAI_SERIE,;   // 6
                          DAI->DAI_DTSAID,;  // 7
                          DAI->(Recno()),;   // 8
                          SC5->(Recno()),;   // 9
                          "00:00:00"} )      // 10 
      EndIf 

      DAI->(DBSkip())
   EndDo 
   
   DAI->(DBSetOrder(4)) // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
   
   _aItensCarga := {}
   
   _dDtFinal   := Ctod("  /  /  ")
   _cHoraFinal := "00:00"

   For _nJ := 1 To Len(_aPvTrcNf)
       SC5->(DBSeek(_aPvTrcNf[_nJ,3]+_aPvTrcNf[_nJ,4]))  
       SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
      
       _nValMerc := 0
       While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->(C5_FILIAL+C5_NUM)
          _nValMerc += SC6->C6_VALOR

          SC6->(DBSkip())
       EndDo

       //-------------------------------------------------------------------//
       _cIniViagem := FWTimeStamp( 3, _aPvTrcNf[_nJ,7], _aPvTrcNf[_nJ,10])

      _cFimViagem := "" //Ctod("  /  /  ") 
                   
                   //         Nota Fiscal                      Serie
      _cNrNotas := AllTrim(_aPvTrcNf[_nJ,5]) + "-" + AllTrim(_aPvTrcNf[_nJ,6])+"; "
                        
                        // Filial    + Pedido de vendas
      If DAI->(DBSeek(_aPvTrcNf[_nJ,3]+_aPvTrcNf[_nJ,4]))

         _cFilCarreg := SC5->C5_FILIAL
         If ! Empty(SC5->C5_I_FLFNC)
            _cFilCarreg :=SC5->C5_I_FLFNC
         EndIf 

         _nDias := U_AOMS118D(SC5->C5_I_DTENT, SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_LOJACLI,_cFilCarreg,SC5->C5_I_OPER,SC5->C5_I_TPVEN) // Calcula o transit time do pedido de vendas
         
         If _nDias < 0 // Não pode calcular transit time
            _nDias := 0 
         EndIf 

         _dDtFinal   := DAI->DAI_DTCHEG
         _cHoraFinal := DAI->DAI_CHEGAD  
         
         If ! Empty(DAI->DAI_NFISCA)
            _cNrNotas += DAI->DAI_NFISCA + "-" + DAI->DAI_SERIE + "; "
                        
            _dDataAux := Posicione("SF2",1,DAI->(DAI_FILIAL+DAI_NFISCA+DAI_SERIE+DAI_CLIENT+DAI_LOJA),'F2_EMISSAO') // F2_DTENTR
            _cHoraAux := Posicione("SF2",1,DAI->(DAI_FILIAL+DAI_NFISCA+DAI_SERIE+DAI_CLIENT+DAI_LOJA),'F2_HORA')
            
         Else 
            _dDataAux := Date()     // SC5->C5_I_DTENT
            _cHoraAux := "00:00:00" // SC5->C5_I_HOREN
         EndIf 

         If DToS(_dDataAux + _nDias) < DToS(SC5->C5_I_DTENT)
            _dDataAux := SC5->C5_I_DTENT
         Else
            _dDataAux := _dDataAux + _nDias
         EndIf

         If ! Empty(_dDataAux)
            _cFimViagem := FWTimeStamp( 3, _dDataAux, _cHoraAux)
            _dDtFinal   := _dDataAux
            _cHoraFinal := _cHoraAux
         Else
            _cFimViagem := FWTimeStamp( 3, DAI->DAI_DTCHEG, DAI->DAI_CHEGAD)
            _dDtFinal   := DAI->DAI_DTCHEG
            _cHoraFinal := DAI->DAI_CHEGAD
         EndIf 
      
         If ! Empty(DAI->DAI_I_OPLO)
            _nI := aScan(_aItensCarga, {|x| x[1] == DAI->DAI_I_OPLO .And. x[2] == DAI->DAI_I_LOPL }) 
            If _nI == 0 
                                //    1                  2             3        4          5              6          7           8
               aAdd(_aItensCarga, {DAI->DAI_I_OPLO, DAI->DAI_I_LOPL, "SA2", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
            Else
               If ! Empty(_cNrNotas)
                  _aItensCarga[_nI, 4] += _cNrNotas                  
               EndIf 
               _aItensCarga[_nI, 7] += _nValMerc
            EndIf

         ElseIf !Empty(DAI->DAI_I_TRED)
            _nI := aScan(_aItensCarga, {|x| x[1] == DAI->DAI_I_TRED .And. x[2] == DAI->DAI_I_LTRE }) 
            If _nI == 0
                                //    1                  2             3        4          5              6          7           8
               aAdd(_aItensCarga, {DAI->DAI_I_TRED, DAI->DAI_I_LTRE, "SA2", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
            Else
               If ! Empty(_cNrNotas)
                  _aItensCarga[_nI, 4] += _cNrNotas
               EndIf 
               _aItensCarga[_nI, 7] += _nValMerc
            EndIf
         Else
            _nI := aScan(_aItensCarga, {|x| x[1] == DAI->DAI_CLIENT .And. x[2] == DAI->DAI_LOJA }) 
            If _nI == 0
                                //    1                  2             3        4          5              6          7          8
               aAdd(_aItensCarga, {DAI->DAI_CLIENT, DAI->DAI_LOJA, "SA1", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
            Else
               If ! Empty(_cNrNotas)
                  _aItensCarga[_nI, 4] += _cNrNotas
               EndIf 
               _aItensCarga[_nI, 7] += _nValMerc
            EndIf
         EndIf 
      Else 
         _nI := aScan(_aItensCarga, {|x| x[1] == SC5->C5_CLIENTE .And. x[2] == SC5->C5_LOJACLI }) 
         If _nI == 0
                             //    1                  2             3        4          5              6          7            8
            aAdd(_aItensCarga, {SC5->C5_CLIENTE, SC5->C5_LOJACLI, "SA1", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
         Else
            _aItensCarga[_nI, 7] += _nValMerc
         EndIf
      EndIf 

   Next

   //===============================================================================================
   // Faz agrupamento de dados para pedido de vendas normais.
   //===============================================================================================
   // DAK_FILIAL+DAK_COD+DAK_SEQCAR                                                                                                                                    
   DAI->(DBSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO  
   DAI->(DBSeek(DAK->DAK_FILIAL+DAK->DAK_COD))
  
   //_aItensCarga := {}
   //_cNotaTRCNf  := ""
   
   _dDtFinal   := Ctod("  /  /  ")
   _cHoraFinal := "00:00"
  
   While ! DAI->(Eof()) .And. DAI->(DAI_FILIAL+DAI_COD) == DAK->DAK_FILIAL+DAK->DAK_COD    
      
      //===============================================================================================
      // Verifica se o pedido de vendas do item da carga já foi processado como Troca nota.
      //===============================================================================================
      _nI := aScan(_aPvTrcNf, {|x| x[1] == DAI->DAI_FILIAL .And. x[2] == DAI->DAI_PEDIDO }) 
      If _nI > 0
         DAI->(DBSkip())
         Loop
      EndIf

      //===============================================================================================
      // Faz o processamento dos pedidos de vendas normais contidos na carga.
      //===============================================================================================
      SC5->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))
      SC6->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))
      
       _nValMerc := 0
       While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == DAI->DAI_FILIAL+DAI->DAI_PEDIDO
          _nValMerc += SC6->C6_VALOR

          SC6->(DBSkip())
       EndDo

       _cFilCarreg := SC5->C5_FILIAL
       If ! Empty(SC5->C5_I_FLFNC)
          _cFilCarreg :=SC5->C5_I_FLFNC
       EndIf

       _nDias := U_AOMS118D(SC5->C5_I_DTENT, SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_LOJACLI,_cFilCarreg,SC5->C5_I_OPER,SC5->C5_I_TPVEN) // Calcula o transit time do pedido de vendas
         
       If _nDias < 0 // Não pode calcular transit time
          _nDias := 0 
       EndIf

      _cIniViagem := FWTimeStamp( 3, DAI->DAI_DTSAID, "00:00:00")   // DAI->DAI_HORA    

      _cFimViagem := "" 
      _dDtFinal   := DAI->DAI_DTCHEG
      _cHoraFinal := DAI->DAI_CHEGAD
      
      _cNrNotas := ""
      If ! Empty(DAI->DAI_NFISCA)
         _cNrNotas := DAI->DAI_NFISCA+"-"+DAI->DAI_SERIE+"; "
          
         _dDataAux := Posicione("SF2",1,DAI->(DAI_FILIAL+DAI_NFISCA+DAI_SERIE+DAI_CLIENT+DAI_LOJA),'F2_EMISSAO')
         _cHoraAux := Posicione("SF2",1,DAI->(DAI_FILIAL+DAI_NFISCA+DAI_SERIE+DAI_CLIENT+DAI_LOJA),'F2_HORA')         
      Else 
         _dDataAux := Date()
         _cHoraAux := "00:00:00"  
      EndIf 
      
      If DToS(_dDataAux + _nDias) < DToS(SC5->C5_I_DTENT)
         _dDataAux := SC5->C5_I_DTENT
      Else
         _dDataAux := _dDataAux + _nDias
      EndIf

      If ! Empty(_dDataAux)
         _cFimViagem := FWTimeStamp( 3, _dDataAux, _cHoraAux)
         _dDtFinal   := _dDataAux
         _cHoraFinal := _cHoraAux
      Else
         _cFimViagem := FWTimeStamp( 3, DAI->DAI_DTCHEG, DAI->DAI_CHEGAD)
         _dDtFinal   := DAI->DAI_DTCHEG
         _cHoraFinal := DAI->DAI_CHEGAD
      EndIf 

      If ! Empty(DAI->DAI_I_OPLO)
         _nI := aScan(_aItensCarga, {|x| x[1] == DAI->DAI_I_OPLO .And. x[2] == DAI->DAI_I_LOPL }) 
         If _nI == 0             
                             //    1                  2             3        4          5              6          7           8
            aAdd(_aItensCarga, {DAI->DAI_I_OPLO, DAI->DAI_I_LOPL, "SA2", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
         Else
            _aItensCarga[_nI, 7]    += _nValMerc

            If ! Empty(_cNrNotas)
               _aItensCarga[_nI, 4] += _cNrNotas
            EndIf 
         EndIf

      ElseIf !Empty(DAI->DAI_I_TRED)
         _nI := aScan(_aItensCarga, {|x| x[1] == DAI->DAI_I_TRED .And. x[2] == DAI->DAI_I_LTRE }) 
         If _nI == 0
                            //    1                  2             3        4          5              6          7             8
            aAdd(_aItensCarga, {DAI->DAI_I_TRED, DAI->DAI_I_LTRE, "SA2", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
         Else    
            _aItensCarga[_nI, 7]    += _nValMerc        

            If ! Empty(_cNrNotas)
               _aItensCarga[_nI, 4] += _cNrNotas
            EndIf 
         EndIf
      
      Else
         _nI := aScan(_aItensCarga, {|x| x[1] == DAI->DAI_CLIENT .And. x[2] == DAI->DAI_LOJA }) 
         If _nI == 0
                           //    1                  2             3        4          5              6          7             8
            aAdd(_aItensCarga, {DAI->DAI_CLIENT, DAI->DAI_LOJA, "SA1", _cNrNotas , _cIniViagem, _cFimViagem, _nValMerc, _dDtFinal})
         Else
            _aItensCarga[_nI, 7]    += _nValMerc

            If ! Empty(_cNrNotas)
               _aItensCarga[_nI, 4] += _cNrNotas
            EndIf 
         EndIf
      EndIf 
     
      DAI->(DBSkip()) 

   EndDo          
   
   //========================================================
   // Determina a maior data de entrega.
   //========================================================
   _cFimViagem := " "
   _dDtFinal   := Ctod("  /  /  ")
   
   If Len(_aItensCarga) > 0
      _dDtFinal   := _aItensCarga[1,8]
      _cFimViagem := _aItensCarga[1,6]
   EndIf 

   For _nI := 1 To Len(_aItensCarga)
       If DToS(_aItensCarga[_nI,8]) > DToS(_dDtFinal)
          _cFimViagem := _aItensCarga[_nI,6]
       EndIf
   Next 

   For _nI := 1 To Len(_aItensCarga)
       _aItensCarga[_nI,6] := _cFimViagem
   Next 
   
   //========================================================
   // Grava os dados dos destinos.
   //========================================================
   For _nI := 1 To Len(_aItensCarga)
       
       If _aItensCarga[_nI,3] == "SA1"
          SA1->(DBSeek(xFilial("SA1")+_aItensCarga[_nI,1]+_aItensCarga[_nI,2]))
          //--------------------------->> 6 - Destino 
          // _cDetDestino
          //==========================================
          // Destinos
          //==========================================
          _lDestItalac := U_AOMS118F(SA1->A1_CGC)

          _cTipoDest        := If(Len(_aItensCarga) > 1, "ENTREGA FRACIONADA", "ENTREGA UNICA")
          _cCnpjDest        := "0"+Transform(SA1->A1_CGC,"@R! NN.NNN.NNN/NNNN-99") // Na Krona os CNPJ são cadastrados com 15 digitos + as pontuações.
          _cRazaoDest       := SA1->A1_NOME
          _cNomeFanDest     := SA1->A1_NREDUZ  
          _cUnidDest        := SA1->A1_LOJA 
          _cCodUniDest      := SA1->A1_COD 
          _cRuaDest         := SA1->A1_END 
          _cNrDest          := U_AOMS118N(SA1->A1_END) // SA1->A1_I_NUMER
          _cComplDest       := SA1->A1_COMPLEM
          _cBairroDest      := SA1->A1_BAIRRO 
          _cCidDest         := SA1->A1_MUN    
          _cUfDest          := SA1->A1_EST    
          _cCepDest         := Transform(SA1->A1_CEP,"@R 99999-999")
          _cLatitDest       := "" 
          _cLongiDest       := "" 
          _cTel1Dest        := "("+AllTrim(SA1->A1_DDD)+") "+SA1->A1_TEL    
          _cTel2Dest        := "("+AllTrim(SA1->A1_DDD)+") "+SA1->A1_TEL    
          _cRespDest        := SA1->A1_CONTATO
          _cCargoRDest      := SA1->A1_CARGO1 
          _cTelRDest        := "("+AllTrim(SA1->A1_DDD)+") "+SA1->A1_TEL    
          _cCelRDest        := ""
          _cMailRDest       := SA1->A1_EMAIL
      
          If _nI == 1     
             _cIniViagem := _aItensCarga[_nI,5]
          EndIf                                                                                                                                                        
                          
          _cFimViagem := _aItensCarga[_nI,6]
          _cDestFim   := " ATE " + AllTrim(SA1->A1_MUN) + "/" + AllTrim(SA1->A1_BAIRRO)
      
          _cUf_Munic := Upper(AllTrim(SA1->A1_EST)+AllTrim(SA1->A1_MUN)) 

          //==========================================
          // Dados Complementares
          //==========================================  
          _cMercadoria      := "" //"1" // Generos alimenticios.
          _cValorMerc       := AllTrim(Str(_aItensCarga[_nI, 7],12,2)) // SOMATORIA DE C6_VALOR
          _cNormaMerc       := "" //"NBR15635" // norma técnica de produção de alimentos.
          _cGrupNorMerc     := ""
          
          If ! Empty(_aItensCarga[_nI, 4])
             _cNotaMerc        += _aItensCarga[_nI, 4]  // If(!Empty(DAI->DAI_NFISCA),DAI->DAI_NFISCA + "-" + DAI->DAI_SERIE,"")
          EndIf 
          _cObservMerc      := ""

       Else // "SA2"

          SA2->(DBSeek(xFilial("SA2")+_aItensCarga[_nI,1]+_aItensCarga[_nI,2]))
          //--------------------------->> 6 - Destino 
          // _cDetDestino
          //==========================================
          // Destinos
          //==========================================
          _lDestItalac := U_AOMS118F(SA2->A2_CGC)

          _cTipoDest        := If(Len(_aItensCarga) > 1, "ENTREGA FRACIONADA", "ENTREGA UNICA")
          _cCnpjDest        := "0"+Transform(SA2->A2_CGC,"@R! NN.NNN.NNN/NNNN-99") // Na Krona os CNPJ são cadastrados com 15 digitos + as pontuações.
          _cRazaoDest       := SA2->A2_NOME
          _cNomeFanDest     := SA2->A2_NREDUZ  
          _cUnidDest        := SA2->A2_LOJA 
          _cCodUniDest      := SA2->A2_COD 
          _cRuaDest         := SA2->A2_END 
          _cNrDest          := U_AOMS118N(SA2->A2_END) // SA1->A1_I_NUMER
          _cComplDest       := SA2->A2_COMPLEM
          _cBairroDest      := SA2->A2_BAIRRO 
          _cCidDest         := SA2->A2_MUN    
          _cUfDest          := SA2->A2_EST    
          _cCepDest         := Transform(SA2->A2_CEP,"@R 99999-999")
          _cLatitDest       := "" 
          _cLongiDest       := "" 
          _cTel1Dest        := "("+AllTrim(SA2->A2_DDD)+") "+SA2->A2_TEL    
          _cTel2Dest        := "("+AllTrim(SA2->A2_DDD)+") "+SA2->A2_TEL    
          _cRespDest        := SA2->A2_CONTATO
          _cCargoRDest      := SA2->A2_CARGO 
          _cTelRDest        := "("+AllTrim(SA2->A2_DDD)+") "+SA2->A2_TEL    
          _cCelRDest        := ""
          _cMailRDest       := SA2->A2_EMAIL
      
          If _nI == 1     
             _cIniViagem := _aItensCarga[_nI,5]
          EndIf                                                                                                                                                        
                          
          _cFimViagem := _aItensCarga[_nI,6]
          _cDestFim   := " ATE " + AllTrim(SA2->A2_MUN) + "/" + AllTrim(SA2->A2_BAIRRO)
      
          _cUf_Munic := Upper(AllTrim(SA2->A2_EST)+AllTrim(SA2->A2_MUN)) 

          //==========================================
          // Dados Complementares
          //==========================================  
          _cMercadoria      := ""//"1" // Generos alimenticios.
          _cValorMerc       := AllTrim(Str(_aItensCarga[_nI, 7],12,2)) // SOMATORIA DE C6_VALOR
          _cNormaMerc       := ""//"NBR15635"  // norma técnica de produção de alimentos.
          _cGrupNorMerc     := ""
          
          If ! Empty(_aItensCarga[_nI, 4])
             _cNotaMerc        += _aItensCarga[_nI, 4]  // If(!Empty(DAI->DAI_NFISCA),DAI->DAI_NFISCA + "-" + DAI->DAI_SERIE,"")
          EndIf 
          _cObservMerc      := ""
       
       EndIf

       //==================================================
       // Incrementando contador de destino e viagens
       //==================================================   
       _nDestinos += 1   
                           
       //==========================================================================================
       // Realiza a macro substituição de valores nos modelos JSON e agrupa na variável _cClieDest
       //==========================================================================================   
       _cClieDest := _cClieDest + If(!Empty(_cClieDest),',', "") + &(_cDetDestB)       
   
   Next 

/* 
   //==========================================================================================
   // O valor da carga é inferior ao valor estipulado em parêmetro. Usuário e senha NÃO é 
   // por transportadora. 
   // O usuário e senha devem ser lidos da tabela ZG9 e ZZM conforme regras de Armazens:
   // - Se existir um item do pedido de vendas com armazem cadastrado na tabela ZG9, pegar
   //   usuário e senha Krona da tabela ZG9.
   // - Se NÃO existir item do pedido de venda com armazem cadastrado na tabele ZG9, pegar
   //   usuário e senha Krona da tabela ZZM.
   //========================================================================================== 
   _cUsrZG9   := ""
   _cPswZG9   := ""
   _cFornZG9  := ""
   _cLojaZG9  := ""

   ZZM->(DBSetOrder(1)) // ZZM_FILIAL+ZZM_CODIGO   
   ZG9->(DBSetOrder(1)) // ZG9_FILIAL+ZG9_CODFIL+ZG9_ARMAZE 
   DAI->(DBSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO  
   DAI->(DBSeek(DAK->DAK_FILIAL+DAK->DAK_COD))
      
   _lTemZG9 := .F.

   While ! DAI->(Eof()) .And. DAI->(DAI_FILIAL+DAI_COD) == DAK->DAK_FILIAL+DAK->DAK_COD      
      
      SC6->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))   
         
      While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == DAI->DAI_FILIAL+DAI->DAI_PEDIDO
         If ZG9->(DBSeek(xFilial("ZG9")+SC6->C6_FILIAL+SC6->C6_LOCAL))   
            //_cUsuario := ZG9->ZG9_USRKRO
            //_cSenha   := ZG9->ZG9_PSWKRO
            _cUsrZG9   := ZG9->ZG9_USRKRO
            _cPswZG9   := ZG9->ZG9_PSWKRO            
            _cFornZG9  := ZG9->ZG9_CODFOR
            _cLojaZG9  := ZG9->ZG9_LOJFOR

            _lTemZG9  := .T.
            Exit 
         EndIf 

         SC6->(DBSkip())
      EndDo
         
      If _lTemZG9
         Exit 
      EndIf 

      DAI->(DBSkip()) 

   EndDo          

   If ! _lTemZG9 .Or. Empty(_cUsuario)   
      If ZZM->(DBSeek(xFilial("ZZM")+DAK->DAK_FILIAL))
         //_cUsuario  := ZZM->ZZM_USRKRO
         //_cSenha    := ZZM->ZZM_PSWKRO
         _cUsrZG9   := ZZM->ZZM_USRKRO
         _cPswZG9   := ZZM->ZZM_PSWKRO           
      EndIf 
   EndIf 
   
*/
   //=========================================================
   // Atualiza usuário e senha quando não é da transportadora
   //=========================================================
   If ! _lUsuarioTransp   
      _cUsuario := _cUsrZG9  
      _cSenha   := _cPswZG9  
   EndIf 

   //=====================================================
   // Transportador: Login e Senha.
   //=====================================================
   If Empty(_cUsuario) .Or. Empty(_cSenha)
      If _lUsuarioTransp
         If _cChamada == "M" // Chamada via menu.   
            U_ITMsg("Não foram informados nome de usuário e senha para o transportador: Codigo: '"+ _cTransp + "' e Loja: '" + _cLjTransp + "', para acessar o sistema Krona.",;
                    "Atenção","Acesse o cadastro de fornecedores no Protheus, localize o transportador e informe nome de usuário e senha.",1)
         Else // Chamada via Scheduller
            U_ItConOut("[AOMS118] - Não foram informados nome de usuário e senha para o transportador: Codigo: '"+ _cTransp + "' e Loja: '" + _cLjTransp + "', para acessar o sistema Krona.")
         EndIf 
      Else 
         If _cChamada == "M" // Chamada via menu.   
            U_ITMsg("Não foram informados nome de usuário e senha nos cadastros: Endereço Embarcador Mercadorias(ZG9) e Cadastro de Filiais Scheduller(ZZM).",;
                    "Atenção","Acesse no Protheus os cadastros: Endereço Embarcador Mercadorias(ZG9) e Cadastro de Filiais Scheduller(ZZM), localize e preencha os campos Usuário e Senha Krona.",1)
         Else // Chamada via Scheduller
            U_ItConOut("[AOMS118] - Não foram informados nome de usuário e senha nos cadastros: Endereço Embarcador Mercadorias(ZG9) e Cadastro de Filiais Scheduller(ZZM).")
         EndIf         
      EndIf 

      Break   
   EndIf 

   //--------------------------->> 7 - Viagem  
   // _cDetViagem
   //==========================================
   // Viagem  
   //========================================== 
   _cIdViagem := "" 
   If _lAltViagem
      _cIdViagem := DAK->DAK_I_PROT
      If _cChamada == "S" // Chamada via Scheduller 
         _aDadosViagem := U_AOMS118P("I",_cIdViagem , .F.,"S") 

         If !Empty(_aDadosViagem) .And. AllTrim(_cTransp) == AllTrim(_aDadosViagem[2]) .And.;
            AllTrim(_cLjTransp) == AllTrim(_aDadosViagem[3]) .And. AllTrim(DAK->DAK_FILIAL+DAK->DAK_COD) == AllTrim(_aDadosViagem[4])
         
            //_cIdViagem := AllTrim(_aDadosViagem[1] ) // Numero de Protocolo já registrado. 
         
            If ! Empty(_aDadosViagem[1]) .And. AllTrim(Upper(_aDadosViagem[5])) == "CANCELADA"
               _cUserIncl :=  AllTrim(_aDadosViagem[6])
               _cInicPrev :=  AllTrim(_aDadosViagem[7])

               DAK->(RecLock("DAK",.F.))
               DAK->DAK_I_MSGK := "PROTOCOLO ATUALIZADO ATRAVES DA ROTINA SCHEDULLER DE MONITORAMENTO DE CARGAS [ROMS118]. VIAGEM CANCELADA. PROTOCOLO REMOVIDO: " + DAK->DAK_I_PROT
               DAK->DAK_I_JSON := "PROTOCOLO ATUALIZADO ATRAVES DA ROTINA SCHEDULLER DE MONITORAMENTO DE CARGAS [ROMS118]."+ CRLF +;
                                  "USUARIO/INCLUSAO VIAGEM " + _cUserIncl + CRLF +;
                                  "INICIO PREVISTO: " +  _cInicPrev + CRLF +;
                                  "VIAGEM CANCELADA. PROTOCOLO REMOVIDO: " + DAK->DAK_I_PROT
               DAK->DAK_I_ENVK := "S"
               DAK->DAK_I_PROT := ""
               DAK->(MSUnLock())
               _lAltViagem := .T.
               Break
            EndIf
         EndIf 
      EndIf 
   Else 
      //==========================================================================================================
      // Pela placa do veículo, verifica-se a não existencia de uma viagem em aberto. Se existir uma viagem em 
      // aberto para a mesma transportadora, a carga que está sendo integrada e que ainda não foi enviada, 
      // recebe o numero de protocolo em trânsito e realiza uma alteração na viagem do sistema Krona.
      //========================================================================================================== 
      _cIdViagem    := ""
      _aDadosViagem := U_AOMS118P("P", _cPlacaVeic , .F. ) 
      If Empty(_aDadosViagem)
         If _cChamada == "M" // Chamada via menu.   
            U_ITMsg("Inclusão de nova viagem no sistema Krona. Para a placa de Veículo: " +_cPlacaVeic + " não foram encontradas viagens em aberto." , "Atenção","",1)
         Else // Chamada via Scheduller
            U_ItConOut("[AOMS118] - Inclusão de nova viagem no sistema Krona. Para a placa de Veículo: " +_cPlacaVeic + " não foram encontradas viagens em aberto.")
         EndIf 
      Else
         If _cChamada == "M" // Chamada via menu.   
            If ! U_ITMsg("Inclusão de nova viagem no sistema Krona. Para a placa de veículo: " +_cPlacaVeic + ", foi encontrado a viagem: " + _aDadosViagem[1] +;
                        ", para transportadora de codigo/loja: " + _aDadosViagem[2] + "/" + _aDadosViagem[3] + ;
                        " Código carga Protheus: " + _aDadosViagem[4] + ", com Status: " + _aDadosViagem[5] + ; 
                        ". Deseja continuar a integração para o sitema Krona?","Atenção", ,2 , 2)  
               Break
            EndIf
         EndIf              
      EndIf 

      If !Empty(_aDadosViagem) .And. AllTrim(_cTransp) == AllTrim(_aDadosViagem[2]) .And.;
         AllTrim(_cLjTransp) == AllTrim(_aDadosViagem[3]) .And. AllTrim(DAK->DAK_FILIAL+DAK->DAK_COD) == AllTrim(_aDadosViagem[4])
         
         _cIdViagem := AllTrim(_aDadosViagem[1] ) // Numero de Protocolo já registrado. 
         
         If ! Empty(_cIdViagem)
            DAK->(RecLock("DAK",.F.))
            DAK->DAK_I_PROT := _cIdViagem
            DAK->(MSUnLock())
            _lAltViagem := .T.
         EndIf
      EndIf 
//--------------------------------------------------------------------------------
   EndIf 
    
   If _lDestItalac
      _cTipoViag       := "TRANSFERENCIA"
   Else    
      _cTipoViag       := If(Len(_aItensCarga) > 1, "ENTREGA FRACIONADA", "ENTREGA UNICA") // "ENTREGA FRACIONADA"
   EndIf 

   _cRastreViag     := If(DAK->DAK_VALOR < _nPrcMinCarga,"N" ,"S") 

   If Upper(AllTrim(_cUfEndOrig)+AllTrim(_cCidEndOrig)) == _cUf_Munic   
      _cPercurViag     := "URBANO"  
   Else
      _cPercurViag     := "RODOVIARIO"  
   EndIf
   _cTipoClViag     := "OUTROS" 
   _cDocOrgViag     := "0" 
   _cFppViag        := "0" 
   _cMercIdViag     := "1" // 1=Generos Alimentícios
   _cValorViag      := AllTrim(Str(DAK->DAK_VALOR,12,2)) 
   _cRotaViag       := _cDestFim      
   _cIniPrViag      := _cIniViagem    
   _cFimPrViag      := _cFimViagem    
   _cLiberViag      := DAK->DAK_FILIAL+DAK->DAK_COD   
   _cNrCliViag      := DAK->DAK_FILIAL+DAK->DAK_COD 
   _cObsViag        := "" 
   _cLoc11Viag      := "" 
   _cIdLoc11Viag    := "" 
   _cLoc12Viag      := "" 
   _cIdLoc12Viag    := "" 
   _cLoc13Viag      := "" 
   _cIdLoc13Viag    := "" 
   _cLoc21Viag      := "" 
   _cIdLoc21Viag    := "" 
   _cLoc22Viag      := "" 
   _cIdLoc22Viag    := "" 
   _cLoc23Viag      := "" 
   _cIdLoc23Viag    := "" 
   _cLoc31Viag      := "" 
   _cIdLoc31Viag    := "" 
   _cLoc321Viag     := "" 
   _cIdLoc32Viag    := "" 
   _cLoc33Viag      := ""
   _cIdLoc33Viag    := ""                         
   
   //========================================================================================================
   // Se a variável _cViagem estiver vazia, monta uma estrutura sem valores para manter a estrutura JSON.
   //========================================================================================================
   _cViagem :=   &(_cDetViagem)  
      
   //========================================================================================================
   // Se a variável _cClieDest estiver vazia, monta uma estrutura sem valores para manter a estrutura JSON.
   //========================================================================================================
   If Empty(_cClieDest)
      _cClieDest := _cClieDest + _cDetDestA + &(_cDetDestB) + _cDetDestC
   Else
      _cClieDest := _cDetDestA +_cClieDest + _cDetDestC
   EndIf
   
   _cJSonEnv := ""
   _cJSonEnv := _cJSonEnv + &(_cCabLogin) 
   _cJSonEnv := _cJSonEnv + &(_cDetTransportador)
   _cJSonEnv := _cJSonEnv + &(_cDetMotorista) 

   If _cVeiculo == "CAMINHAO/UTILITARIO" 
      _cJSonEnv := _cJSonEnv + &(_cDetVeiculo) 
   ElseIf _cVeiculo == "CARRETA" 
      _cJSonEnv := _cJSonEnv + &(_cDetVeiculo) + &(_cReboque1)
   ElseIf _cVeiculo == "BITREM"
      _cJSonEnv := _cJSonEnv + &(_cDetVeiculo) + &(_cReboque1) + &(_cReboque2)
   ElseIf _cVeiculo == "RODOTREM"
      _cJSonEnv := _cJSonEnv + &(_cDetVeiculo) + &(_cReboque1) + &(_cReboque2) + &(_cReboque3)
   EndIf

   _cJSonEnv := _cJSonEnv + &(_cDetOrigem) 
   _cJSonEnv := _cJSonEnv + _cClieDest   
   _cJSonEnv := _cJSonEnv + _cViagem
   _cJSonEnv := _cJSonEnv + _cRodaPe   
   _cJSonEnv := AllTrim(_cJSonEnv)
   
   _cLinkWS := AllTrim(_cLinkWS)
   
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil
   _nTimOut	 	:= 120

   _cRetHttp    := ''
   
   _aHeadOut := {}              
   // Google Chrome está atualizado
   //Versão 79.0.3945.88 (Versão oficial) 64 bits
   
   //aAdd(_aHeadOut,'User-Agent: Google Chrome/79.0.3945.88 ( compatible; Protheus '+GetBuild()+')') 
   aAdd(_aHeadOut,'Content-Type: application/json')

   _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) )
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   //===========================================================================
   // Verifica retorno de erros na integração.
   //===========================================================================
   _cMsgErro := ""
   _cMsgInt    := ""
   _cProtocolo := ""

   For _nI := 1 To Len(_aErroRet)
       If _aErroRet[_nI,1] $ Upper(_cRetHttp)
          _cMsgErro += If(!Empty(_cMsgErro),CRLF,"") + "Erro na Integração com o sistema Krona: "+ _aErroRet[_nI,2]+" - Codigo do erro: "+_aErroRet[_nI,1] + ". " 
       EndIf
   Next   

   If Empty(_cRetHttp) .And. Empty(_cMsgErro)
      _cMsgErro := "Erro na Integração com o sistema Krona. Não houve nenhum retorno do sistema Krona."
   EndIf 
   
   If Empty(_cMsgErro) .And. "ERRO" $ Upper(_cRetHttp)
      _cMsgErro := _cRetHttp
   EndIf
   
   If Empty(_cMsgErro)        
      //FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon) 

      _cRetHttp := StrTran(_cRetHttp,'[','')
      _cRetHttp := StrTran(_cRetHttp,']','')
      _cRetHttp := Upper(_cRetHttp)

      _oJson := JsonObject():new()

      _cRet := _oJson:FromJson(_cRetHttp)

      If ! ValType(_cRet) == "U"
         _cMsgErro := "[FALSO] Erro ao popular o JSon de retorno da Krona. Problemas no JSon de retorno."
      EndIf 
   EndIf

   DAK->(RecLock("DAK",.F.))
   DAK->DAK_I_ENVK := "S"
   DAK->DAK_I_JSON := _cJSonEnv
   DAK->DAK_I_RETK := _cRetHttp
   
   If Empty(_cMsgErro) 
      _cMsgInt        := "Integrado com sucesso para o sistema Krona." 

      _aNames := _oJson:GetNames()
      _nI := aScan(_aNames,'PROTOCOLO')

      If _nI == 0
         _nI := aScan(_aNames,'Protocolo') 
      EndIf
      
      _cProtocolo := ""
      If _nI > 0 .And. !Empty(_oJson[_aNames[_nI]])
         _cProtocolo := _oJson[_aNames[_nI]] // _oRetJSon:protocolo
      EndIf 

      If ! _lAltViagem
         DAK->DAK_I_PROT := _cProtocolo 
      EndIf 

      DAK->DAK_I_MSGK := _cMsgInt + " - Protocolo: " + _cProtocolo
   Else
      DAK->DAK_I_MSGK := _cMsgErro
      _cMsgInt        := _cMsgErro
   EndIf
   
   DAK->(MSUnLock())    
   
   If _cChamada == "M" // Chamada via menu.   
      U_AOMS118V(DAK->DAK_COD, _cJSonEnv, _cRetHttp, _cMsgInt, _cProtocolo)
    
      U_ITMsg("Termino de processamento.","Atenção",,1)   
   Else // Chamada via Scheduller
      U_ItConOut("[AOMS118] - Termino de processamento.")
   EndIf 

End Sequence

Return                

/*
===============================================================================================================================
Função-------------: AOMS118X
Autor--------------: Julio de Paula Paz
Data da Criacao----: 30/12/2019
Descrição---------: Lê o arquivo JSON modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq = diretório + nome do arquivo a ser lido.
Retorno-----------: _cRet
===============================================================================================================================
*/  
User Function AOMS118X(_cArq)
Local _cRet := ""
Local _nStatusArq 
Local _cLine 

Begin Sequence
   _nStatusArq := FT_FUse(_cArq)
      
   // Se houver erro de abertura abandona processamento
   If _nStatusArq = -1  
      Break
   EndIf
   
   // Posiciona na primeria linha
   FT_FGoTop()

  
   While !FT_FEOF()   
      _cLine  := FT_FReadLn() 
      
      _cRet +=  _cLine
   
      FT_FSKIP()
   End

   // Fecha o Arquivo
   FT_FUSE()

End Sequence

Return _cRet                      

/*
===============================================================================================================================
Função-------------: AOMS118V
Autor--------------: Julio de Paula Paz
Data da Criacao----: 07/01/2020
Descrição----------: Exibe os dados da integração passados por parâmetros. 
Parametros--------: _cArq = diretório + nome do arquivo a ser lido.
Retorno-----------: _cRet
===============================================================================================================================
*/         
User Function AOMS118V(_cCodCarga, _cJSonEnv, _cRetHttp, _cMsgInt, _cProtocolo )
Local _lRet

Begin Sequence

   Define MsDialog oDlgInt Title "Dados da Integração Protheus x Sistema Krona." From 000, 000  To 615, 984 COLORS 0, 16777215 Pixel

	  @ 005, 006 Say oCarga PROMPT "Codigo Carga:" Size 040, 007 Of oDlgInt COLORS 0, 16777215 Pixel
	  @ 005, 050 MsGet oCodCarga Var _cCodCarga Size 40, 010 Of oDlgInt Picture "@!" When .F.  COLORS 0, 16777215 Pixel
      
      @ 05, 150 Say oRetorno PROMPT "Protocolo:" Size 022, 007 Of oDlgInt COLORS 0, 16777215 Pixel
	  @ 05, 180 MsGet _oRetHttp Var _cProtocolo Size 256, 010 Of oDlgInt Picture "@!" COLORS 0, 16777215 Pixel   
	  
	  @ 025, 006 Say oRetorno PROMPT "Mensagem da Integração:" Size 100, 007 Of oDlgInt COLORS 0, 16777215 Pixel
	  @ 025, 080 MsGet _oRetHttp Var _cMsgInt Size 390, 010 Of oDlgInt Picture "@!" COLORS 0, 16777215 Pixel

	  @ 051, 006 Say oJSon PROMPT "Dados no Formato JSon:" Size 060, 007 Of oDlgInt COLORS 0, 16777215 Pixel
	  _oScrAux1	:= TSimpleEditor():New( 061 , 006 , oDlgInt , 450 , 100 ,,,,, .T. )
	  _oScrAux1:Load( _cJSonEnv )
	  
	  @ 180, 006 Say oJSon PROMPT "Dados de Retorno:" Size 050, 007 Of oDlgInt COLORS 0, 16777215 Pixel
	  _oScrAux2	:= TSimpleEditor():New( 190 , 006 , oDlgInt , 450 , 50 ,,,,, .T. )
	  _oScrAux2:Load( _cRetHttp )
	  
	  @ 265, 245 Button oButCan PROMPT "&Finalizar"	Size 037, 012 OF oDlgInt Action (oDlgInt:End() ) Pixel

   Activate MsDialog oDlgInt Centered

End Sequence

Return _lRet    

/*
===============================================================================================================================
Função-------------: AOMS118P
Autor--------------: Julio de Paula Paz
Data da Criacao----: 10/01/2020
Descrição----------: Pesquisa e retorna o status da viagem integrada para o Sistema Krona.
Parametros---------: _cTipoPesq  = Tipo de Pesquisa = "C" = Por carga.
                                                      "P" = Por placa.
                                                      "N" = Por Nota.
                                                      "I" = Id Viagem.
                     _cChavePesq = Chave de Pesquisa
                     _lExibeTela = .T. = Exibe mensagens, perguntas e telas.
                                   .F. = Não exibe mensagens, perguntas e telas.
                     _cChamada   = "M" = Chamada via menu
                                   "S" = Chamada via Scheduller
Retorno------------: _aRet = Retorna vazio ou o {numero de protocolo/viagem Krona,        1
                                                 Codigo Transportadora,                   2
                                                 Loja Transportadora,                     3
                                                 Numero Cliente/Filial+Codigo Carga,      4
                                                 Status,                                  5
                                                 Operacao / Usuário que incluiu a viagem, 6
                                                 Inicio Previsto = Data e Hora            7  
                                                 }
===============================================================================================================================
*/  
User Function AOMS118P(_cTipoPesq, _cChavePesq , _lExibeTela, _cChamada)  
Local _aRet := {}
Local  _nI//_aErroRet := {},
Local _cMsgErro //, _cMsgInt , _oRetJSon
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000002")  
Local _cDirJSon, _cPesqViagem
Local _cLoginStatus
Local _cUsuario, _cSenha
//Local _cParam
Local _cLinha
Local _cCodMotor

Local _oDlgL
Local _cTitulo  
Local _nCol1,_nCol2, _nCol3, _nCol4, _nLinha
Local _oNrViagem, _NrViagem     //      "numero_viagem":"3637591",
Local _oNrCliente, _NrCliente   //      "numero_cliente":"01151381",
Local _oNrPamcary, _NrPamcary   //      "numero_pamcary":"0",
Local _oStatus, _Status         //      "status":"AGENDADA",
Local _oEveDataH, _EveDataH     //      "evento_datahora":null,
Local _oEveTipo, _EveTipo       //      "evento_tipo":null,
Local _oReferencia, _Referencia //      "referencia":null,
Local _oLatitude, _Latitude     //      "latitude":null,
Local _oLongitude, _Longitude   //      "longitude":null,
Local _oDistancia, _Distancia   //      "distancia":null,
Local _oDirecao, _Direcao       //      "direcao":null,
Local _oInicPrev, _InicPrev     //      "inicio_previsto":"31\/08\/2019 00:00:00",
Local _oInicReal, _InicReal     //      "inicio_real":"",
Local _oChegDest, _ChegDest     //      "chegada_destino_datahora":"",
Local _oSaidaDest, _SaidaDest   //      "saida_destino_datahora":"",
Local _otempoEntr, _tempoEntr   //      "tempo_entrega":"",
Local _oFimPrev, _FimPrev       //      "fim_previsto":"31\/08\/2019 08:00:00",
Local _oFimReal, _FimReal       //      "fim_real":"",
Local _oTempoTot, _TempoTot     //      "tempo_total":"", 
Local _NomeDest                 //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
//Local _ChegDest                 //      "chegada_destino_datahora":null,
//Local _SaidaDest                //      "saida_destino_datahora":null,  
Local _TempCheSaid              //      "tempo_chegada_saida_destino":null,
Local _ordem                    //      "ordem":"1"
Local _operacao

Local _cTransp := "", _cLjTransp := ""
Local _nRegAtu := DAK->(Recno())
Local _cExcecao := ""

Private _cIdPesquisa   

Default _cTipoPesq := "C", _lExibeTela := .T. , _cChamada := "M"

Begin Sequence        
   
   If Type("_cUsrMaster") == "U" .Or. Empty(_cUsrMaster)
      _cUsrMaster    := U_ItGetMv("ITUSRMASTKR","ITALAC.INTEGRACAO")  // Usuário Master da Integração com o Sistema Krona
      _cSenhaMaster  := U_ItGetMv("ITPSWMASTKR","123456")             // Senha do usuário master da integração com o sistem krona.
   EndIf
                        
   If _cTipoPesq == "C" // Pesquisa por carga posicionada.
   
      If DAK->DAK_I_ENVK <> "S"  
         If _lExibeTela
            U_ITMsg("A carga seleciondada ainda não foi integrada para o sistema Krona.","Atenção",,1) 
         Else
            U_ItConOut("[AOMS118P] - A carga seleciondada ainda não foi integrada para o sistema Krona.")  
         EndIf 
         Break
      EndIf  
   
      If Empty(DAK->DAK_I_PROT)
         If _lExibeTela
            U_ITMsg("Não existe numero de protocolo gerado para a carga selecionada.","Atenção",;
                    "Para consultar o status de uma viagem, um protocolo precisa ser gerado na integração da carga para o sistema Krona.",1) 
         Else
            U_ItConOut("[AOMS118P] - Não existe numero de protocolo gerado para a carga selecionada.")
         EndIf 
         Break
      EndIf
   
      _cIdPesquisa := DAK->DAK_I_PROT  
      
   EndIf
   
   If _lExibeTela
      If ! U_ITMsg("Confirma a consulta de status de viagem no sistema Krona ?","Atenção", ,2 , 2)  
         Break
      EndIf              
   EndIf  

   _cLinkWS := ""
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := ZFM->ZFM_LOCXML 
      _cLinkWS  := ZFM->ZFM_LINK02
   Else
      If _lExibeTela
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else 
         U_ItConOut("[AOMS118P] - Empresa WebService para envio dos dados não localizada.") 
      EndIf 
      Break
   EndIf
   /*
   If _cTipoPesq == "C" // Pesquisa por carga posicionada.
      //_cLinkWS  := "http://grupokrona.dyndns.org/k1/api/viagem_status.php"     
            
      //--------------------------->> 3 - Motorista 1 
      // _cDetMotorista           
      DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD   
      If DA4->(DBSeek(xFilial("DA4")+DAK->DAK_MOTORI))
         //----------------------------------------------//
         _cTransp   := DA4->DA4_FORNECE
         _cLjTransp := DA4->DA4_LOJA   
      EndIf

      //--------------------------->> 2 - Transportador
      // _cDetTransportador      
      SA2->(DBSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
   
      If SA2->(DBSeek(xFilial("SA2")+_cTransp + _cLjTransp)) 
         _cUsuario := SA2->A2_I_USRKR
         _cSenha   := SA2->A2_I_PSWKR
      EndIf

   Else
      _cUsuario := _cUsrMaster 
      _cSenha   := _cSenhaMaster
   EndIf
   */
   
   //=======================================================
   // Para pesquisa, o usuário e senha sempre são a Master.
   //=======================================================
   _cUsuario := _cUsrMaster 
   _cSenha   := _cSenhaMaster

   If Empty(_cDirJSon)
      If _lExibeTela
         U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      Else 
         U_ItConOut("[AOMS118P] - Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      EndIf 
      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf
   
   //================================================================================
   // Lê o arquivo modelo JSON de Login e o transforma em String.
   //================================================================================
   _cLoginStatus := U_AOMS118X(_cDirJSon+"Krona1_Login_2.txt") 
   If Empty(_cLoginStatus)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo de Login da integração Krona.","Atenção",,1)
      Else 
         U_ItConOut("[AOMS118P] - Erro na leitura do arquivo modelo JSON modelo de Login da integração Krona.") 
      EndIf 
      Break
   EndIf

   //================================================================================
   // Lê os arquivos modelo JSON e os transforma em String.
   //================================================================================
   _cPesqViagem := U_AOMS118X(_cDirJSon+"Krona1_Requisicao_Status.txt") 
   If Empty(_cPesqViagem)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo de Requisição de Status da integração Krona.","Atenção",,1)
      Else 
         U_ItConOut("[AOMS118P] - Erro na leitura do arquivo modelo JSON modelo de Requisição de Status da integração Krona.")
      EndIf 
      Break
   EndIf
   
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120
   _cJSonEnv    := &(_cPesqViagem)     
   
   _cRetHttp    := ''
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Content-Type: application/json') 
     
   aAdd(_aHeadOut,"usuario: " + AllTrim(_cUsuario))
   aAdd(_aHeadOut,"senha: "+ AllTrim(_cSenha)) 
   
   If _cTipoPesq == "C" // Pesquisa por carga posicionada.
      _cLinkWS := AllTrim(_cLinkWS) + "?id_pesquisa="+AllTrim(_cIdPesquisa) +"&tipo_entrada=plano_k1"   
   ElseIf _cTipoPesq == "P" .Or. _cTipoPesq == "N"           
      _cLinkWS := AllTrim(_cLinkWS) + "?id_pesquisa="+AllTrim(_cChavePesq) +"&tipo_entrada=placa"  
   ElseIf _cTipoPesq == "D" 
      _cLinkWS := AllTrim(_cLinkWS) + "?id_pesquisa="+AllTrim(_cChavePesq) +"&tipo_entrada=documento_cliente"  
   Else
      _cLinkWS := AllTrim(_cLinkWS) + "?id_pesquisa="+AllTrim(_cChavePesq) +"&tipo_entrada=plano_k1" 
   EndIf
   
 // IGV-8924
   
   _cGetParms := "" 
   
   _cRetHttp := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet)) 
   
   //[{"numero_viagem":"3637591","numero_cliente":"01151381","numero_pamcary":"0","status":"AGENDADA","evento_datahora":null,"evento_tipo":null,"referencia":null,"latitude":null,"longitude":null,"distancia":null,"direcao":null,"inicio_previsto":"31\/08\/2019 00:00:00","inicio_real":"","chegada_destino_datahora":"","saida_destino_datahora":"","tempo_entrega":"","fim_previsto":"31\/08\/2019 08:00:00","fim_real":"","tempo_total":"","destinos":[{"nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS","chegada_destino_datahora":null,"saida_destino_datahora":null,"tempo_chegada_saida_destino":null,"ordem":"1"}]}]
   
   //_cRetHttp := '[{"numero_viagem":"3637591","numero_cliente":"01151381","numero_pamcary":"0","status":"AGENDADA","evento_datahora":null,"evento_tipo":null,"referencia":null,"latitude":null,"longitude":null,"distancia":null,"direcao":null,"inicio_previsto":"31\/08\/2019 00:00:00","inicio_real":"","chegada_destino_datahora":"","saida_destino_datahora":"","tempo_entrega":"","fim_previsto":"31\/08\/2019 08:00:00","fim_real":"","tempo_total":"","destinos":[{"nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS","chegada_destino_datahora":null,"saida_destino_datahora":null,"tempo_chegada_saida_destino":null,"ordem":"1"}]}]'
   
   //_cRetHttp := '[{"numero_viagem":"3637591","numero_cliente":"01151381","numero_pamcary":"0","status":"AGENDADA","evento_datahora":null,"evento_tipo":null,"referencia":null,"latitude":null,"longitude":null,"distancia":null,"direcao":null,"inicio_previsto":"31\/08\/2019 00:00:00","inicio_real":"","chegada_destino_datahora":"","saida_destino_datahora":"","tempo_entrega":"","fim_previsto":"31\/08\/2019 08:00:00","fim_real":"","tempo_total":"","destinos":[{"nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS","chegada_destino_datahora":null,"saida_destino_datahora":null,"tempo_chegada_saida_destino":null,"ordem":"1"}]}]'
   //_cRetHttp :=  '{"numero_viagem":"3637591","numero_cliente":"01151381","numero_pamcary":"0","status":"AGENDADA","evento_datahora":null,"evento_tipo":null,"referencia":null,"latitude":null,"longitude":null,"distancia":null,"direcao":null,"inicio_previsto":"31\/08\/2019 00:00:00","inicio_real":"","chegada_destino_datahora":"","saida_destino_datahora":"","tempo_entrega":"","fim_previsto":"31\/08\/2019 08:00:00","fim_real":"1","tempo_total":"1.1","operacao":"TESTE123","destinos":{"1":[{"nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS","chegada_destino_datahora":null,"saida_destino_datahora":null,"tempo_chegada_saida_destino":null,"ordem":"1"},"2":{"nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS","chegada_destino_datahora":null,"saida_destino_datahora":null,"tempo_chegada_saida_destino":null,"ordem":"1"}}]}' 
   //_cRetHttp :=  '{"numero_viagem":"4541142","numero_cliente":"90262509","operacao":"ITALAC.ITAPETININGA.RODOVIACRUZ","numero_pamcary":"0","status":"CANCELADA","evento_datahora":null,"evento_tipo":null,"referencia":null,"latitude":null,"longitude":null,"distancia":null,"direcao":null,"inicio_previsto":"16\/02\/2021 00:00:00","inicio_real":"","chegada_destino_datahora":"","saida_destino_datahora":"","tempo_entrega":"","fim_previsto":"18\/02\/2021 13:24:00","fim_real":"","tempo_total":"","liberado":"NÃƒO","porcentagem_percorrida":null,"tendencia_atraso":null,"destinos":{"nome":"TENDA ATACADO LTDA  - SUZANO\/SP","chegada_destino_datahora":null,"saida_destino_datahora":null,"tempo_chegada_saida_destino":null,"ordem":"1"},"status_logs":{"destinos":{"ordem_destino":"1","cnpj":"001.157.555\/0044-44","razao_social":"TENDA ATACADO","entrada_destino":null,"saida_destino":null}}}'
   
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   //===========================================================================
   // Verifica retorno de erros na integração.
   //===========================================================================
   _cMsgErro := ""

   If ! ("NUMERO_VIAGEM" $ Upper(_cRetHttp) )
      If Empty(_cRetHttp) 
         _cMsgErro := "[FALSO] Erro na consulta de Status Viagem no sistema Krona. Não houve nenhum retorno de dados do sistema Krona. "
      Else
         _cMsgErro := "[FALSO] Erro na consulta de Status Viagem no sistema Krona: " + AllTrim(_cRetHttp) + ". " 
      EndIf
      Break                                          
   EndIf
   
   _cRetHttp := StrTran(_cRetHttp,'[','')
   _cRetHttp := StrTran(_cRetHttp,']','')

   //FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)  

   //================================= Utilizando JSonObject  
   _oJson := JsonObject():new()

   _cRet := _oJson:FromJson(_cRetHttp)

   If ! ValType(_cRet) == "U"
      _cMsgErro := "[FALSO] Erro ao popular o JSon de retorno da Krona. Problemas no JSon de retorno."
      Break
   EndIf 
   
   _aNames := _oJson:GetNames()

/*
   _nI := Len(_oRetJSon)   
   
   If ! _nI > 0
      _cMsgErro := "[FALSO] Erro na leitura dos dados da consulta de Status Viagem no sistema Krona." 
      Break                                          
   EndIf
*/
   _NrViagem    := Space(20)  //      "numero_viagem":"3637591",
   _NrCliente   := Space(20)  //      "numero_cliente":"01151381",
   _NrPamcary   := Space(20)  //      "numero_pamcary":"0",
   _Status      := Space(20)  //      "status":"AGENDADA",
   _EveDataH    := Space(20)  //      "evento_datahora":null,
   _EveTipo     := Space(20)  //      "evento_tipo":null,
   _Referencia  := Space(20)  //      "referencia":null,
   _Latitude    := "0"        //Space(20)  //      "latitude":null,
   _Longitude   := "0"        //Space(20)  //      "longitude":null,
   _Distancia   := Space(20)  //      "distancia":null,
   _Direcao     := Space(20)  //      "direcao":null,
   _InicPrev    := Space(20)  //      "inicio_previsto":"31\/08\/2019 00:00:00",
   _InicReal    := Space(20)  //      "inicio_real":"",
   _ChegDest    := Space(20)  //      "chegada_destino_datahora":"",
   _SaidaDest   := Space(20)  //      "saida_destino_datahora":"",
   _tempoEntr   := Space(20)  //      "tempo_entrega":"",
   _FimPrev     := Space(20)  //      "fim_previsto":"31\/08\/2019 08:00:00", 
   _FimReal     := Space(20)  //      "fim_real":"",
   _TempoTot    := Space(20)  //      "tempo_total":"", 

   _NomeDest    := Space(20)   //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
   _ChegDest    := Space(20)   //      "chegada_destino_datahora":null,
   _SaidaDest   := Space(20)   //      "saida_destino_datahora":null,  
   _TempCheSaid := Space(20)   //      "tempo_chegada_saida_destino":null,
   _ordem       := Space(20)   //      "ordem":"1"
   _operacao    := Space(20)   //      "operacao":"ITALAC.TRANS LAG
  
   //_aNames := _oJson:GetNames()
   _nI := aScan(_aNames,'numero_viagem')

   If _nI > 0 .And. !Empty(_oJson[_aNames[_nI]])

      //--------------------------->> 3 - Motorista 1 
      //_cCodMotor := Posicione("DAK",1,AllTrim(_oRetJSon[1]:numero_cliente),'DAK_MOTORI')
      _nJ := aScan(_aNames, 'numero_cliente')
      If _nJ > 0
         _NrCliente := AllTrim(_oJson[_aNames[_nJ]])
         _cCodMotor := Posicione("DAK",1, _NrCliente,'DAK_MOTORI')
      EndIf 

      If Empty(_cTransp)
         DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD   
         If DA4->(DBSeek(xFilial("DA4")+_cCodMotor))
            //----------------------------------------------//
            _cTransp   := DA4->DA4_FORNECE
            _cLjTransp := DA4->DA4_LOJA   
         EndIf
      EndIf

      _nJ := aScan(_aNames, 'status')
      If _nJ > 0
         _Status := _oJson[_aNames[_nJ]]
      EndIf

      _NrViagem    := _oJson[_aNames[_nI]] //_oRetJSon[1]:numero_viagem
      
      _aRet        := {_NrViagem, _cTransp, _cLjTransp, _NrCliente , _Status }
   EndIf 

   _nI := aScan(_aNames,'numero_cliente')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon.numero_cliente)
      _NrCliente   := _oJson[_aNames[_nI]] // _oRetJSon[1]:numero_cliente                          //      "numero_cliente":"01151381",
   EndIf
   
   _nI := aScan(_aNames,'numero_pamcary')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) //  ! Empty(_oRetJSon[1]:numero_pamcary)
      _NrPamcary   := _oJson[_aNames[_nI]] // _oRetJSon[1]:numero_pamcary                          //      "numero_pamcary":"0",
   EndIf
   
   _nI := aScan(_aNames,'status')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) //  ! Empty(_oRetJSon[1]:status)
      _Status      := _oJson[_aNames[_nI]] // _oRetJSon[1]:status                                  //      "status":"AGENDADA",
   EndIf
   
   _nI := aScan(_aNames,'operacao')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) //  ! Empty(_oRetJSon[1]:operacao)
      _operacao    := _oJson[_aNames[_nI]] // _oRetJSon[1]:operacao                                //      "operacao":"ITALAC.TRANS LAG (LAGOINHA)"
   EndIf 

   If _cChamada == "M" // Chamada via menu
      _cExcecao := "FINALIZADA/ENCERRADA/FINAL/CANCELADA"
   Else // Chamada via Scheduller 
      _cExcecao := "FINALIZADA/ENCERRADA/FINAL"
   EndIf 
   
   _nI := aScan(_aNames,'evento_datahora')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:evento_datahora)
      _EveDataH    := _oJson[_aNames[_nI]] // _oRetJSon[1]:evento_datahora                         //      "evento_datahora":null,
   EndIf
   
   _nI := aScan(_aNames,'evento_tipo')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) //  ! Empty(_oRetJSon[1]:evento_tipo)
      _EveTipo     := _oJson[_aNames[_nI]] // _oRetJSon[1]:evento_tipo                             //      "evento_tipo":null,
   EndIf

   _nI := aScan(_aNames,'referencia')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) //  ! Empty(_oRetJSon[1]:referencia)
      _Referencia  := _oJson[_aNames[_nI]] // _oRetJSon[1]:referencia                              //      "referencia":null,
   EndIf
   
   _nI := aScan(_aNames,'latitude')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:latitude)
      _Latitude    := _oJson[_aNames[_nI]] // _oRetJSon[1]:latitude                                //      "latitude":null,
   EndIf

   _nI := aScan(_aNames,'longitude')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:longitude)
      _Longitude   := _oJson[_aNames[_nI]] // _oRetJSon[1]:longitude                               //      "longitude":null,
   EndIf

   _nI := aScan(_aNames,'distancia')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:distancia)
      _Distancia   := _oJson[_aNames[_nI]] // _oRetJSon[1]:distancia                               //      "distancia":null,
   EndIf

   _nI := aScan(_aNames,'direcao')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:direcao)
      _Direcao     := _oJson[_aNames[_nI]] // _oRetJSon[1]:direcao                                 //      "direcao":null,
   EndIf
 
   _nI := aScan(_aNames,'inicio_previsto')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:inicio_previsto)
      _InicPrev    := _oJson[_aNames[_nI]] // _oRetJSon[1]:inicio_previsto                         //      "inicio_previsto":"31\/08\/2019 00:00:00",
   EndIf
   
   _nI := aScan(_aNames,'inicio_real')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:inicio_real)
      _InicReal    := _oJson[_aNames[_nI]] // _oRetJSon[1]:inicio_real                             //      "inicio_real":"",
   EndIf
   
   _nI := aScan(_aNames,'chegada_destino_datahora')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:chegada_destino_datahora)
      _ChegDest    := _oJson[_aNames[_nI]] // _oRetJSon[1]:chegada_destino_datahora                //      "chegada_destino_datahora":"",
   EndIf

   _nI := aScan(_aNames,'saida_destino_datahora')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) //  ! Empty(_oRetJSon[1]:saida_destino_datahora)
      _SaidaDest   := _oJson[_aNames[_nI]] // _oRetJSon[1]:saida_destino_datahora                  //      "saida_destino_datahora":"",
   EndIf

   _nI := aScan(_aNames,'tempo_entrega')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:tempo_entrega)
      _tempoEntr   := _oJson[_aNames[_nI]] // _oRetJSon[1]:tempo_entrega                           //      "tempo_entrega":"",
   EndIf

   _nI := aScan(_aNames,'fim_previsto')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:fim_previsto)
      _FimPrev     := _oJson[_aNames[_nI]] // _oRetJSon[1]:fim_previsto                            //      "fim_previsto":"31\/08\/2019 08:00:00",
   EndIf
    
   _nI := aScan(_aNames,'fim_real') 
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:fim_real)
      _FimReal     := _oJson[_aNames[_nI]] // _oRetJSon[1]:fim_real                                //      "fim_real":"",
   EndIf

   _nI := aScan(_aNames,'tempo_total')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:tempo_total)
      _TempoTot    := _oJson[_aNames[_nI]] // _oRetJSon[1]:tempo_total                             //      "tempo_total":"",
   EndIf
   
   _nI := aScan(_aNames,'numero_viagem')
   If _nI > 0 .And. ! Empty(_oJson[_aNames[_nI]]) // ! Empty(_oRetJSon[1]:numero_viagem)
      aAdd(_aRet, _operacao)
      aAdd(_aRet, _InicPrev)
   EndIf
   
   If Upper(AllTrim(_Status)) $ _cExcecao
      _aRet := {} 
   EndIf 

   _cLinha := ""

   _oDestinos := _oJson:GetJsonObject("destinos")

   _aDestinos := _oDestinos:GetNames()
/*
   _oItemDest := _oDestinos:GetJsonObject(_aDestinos[1]) 

   _aItemNames := _oItemDest:GetNames()

   _cItem1 := _oItemDest[_aItemNames[1]]  
   _cItem2 := _oItemDest[_aItemNames[2]]
   _cItem3 := _oItemDest[_aItemNames[3]]
   _cItem4 := _oItemDest[_aItemNames[4]]
*/

   _nJ := aScan(_aDestinos,"nome")
   If _nJ > 0 // Isso indica que só há um destino
      _NomeDest    := ""   //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
      _ChegDest    := ""   //      "chegada_destino_datahora":null,
      _SaidaDest   := ""   //      "saida_destino_datahora":null,  
      _TempCheSaid := ""   //      "tempo_chegada_saida_destino":null,
      _ordem       := ""   //      "ordem":"1"
       
      _nJ := aScan(_aDestinos,'nome')
      If _nJ > 0 .And. !Empty(_oDestinos[_aDestinos[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:nome)
         _NomeDest    := _oDestinos[_aDestinos[_nJ]] // _oRetJSon[1]:destinos[_nI]:nome                        //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
      EndIf       
       
      _nJ := aScan(_aDestinos,'chegada_destino_datahora')
      If _nJ > 0 .And. !Empty(_oDestinos[_aDestinos[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:chegada_destino_datahora)
         _ChegDest    := _oDestinos[_aDestinos[_nJ]] // _oRetJSon[1]:destinos[_nI]:chegada_destino_datahora    //      "chegada_destino_datahora":null,
      EndIf
       
      _nJ := aScan(_aDestinos,'saida_destino_datahora')
      If _nJ > 0 .And. !Empty(_oDestinos[_aDestinos[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:saida_destino_datahora)
         _SaidaDest   := _oDestinos[_aDestinos[_nJ]] // _oRetJSon[1]:destinos[_nI]:saida_destino_datahora      //      "saida_destino_datahora":null,  
      EndIf
       
      _nJ := aScan(_aDestinos,'tempo_chegada_saida_destino')
      If _nJ > 0 .And. !Empty(_oDestinos[_aDestinos[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:tempo_chegada_saida_destino )
         _TempCheSaid := _oDestinos[_aDestinos[_nJ]] // _oRetJSon[1]:destinos[_nI]:tempo_chegada_saida_destino //      "tempo_chegada_saida_destino":null,
      EndIf
       
      _nJ := aScan(_aDestinos,'ordem')
      If _nJ > 0 .And. !Empty(_oDestinos[_aDestinos[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:ordem)
         _Ordem       := _oDestinos[_aDestinos[_nJ]] // _oRetJSon[1]:destinos[_nI]:ordem                       //      "ordem":"1"
      EndIf
       
      _cLinha      += "Nome: " + _NomeDest + " - Chegada ao Destino: " + _ChegDest + " - Saida Destino: " + _SaidaDest + " - Tempo Entre Chegada e Saída Dest.: " + ;
                      _TempCheSaid + " - Ordem: " + _Ordem + CRLF
   Else // isso indica que há mais de um destino.
      For _nI := 1 To Len(_aDestinos) // Len(_oRetJSon[1]:destinos)
          _oItemDest := _oDestinos:GetJsonObject(_aDestinos[_nI]) 
       
          _aItemNames := _oItemDest:GetNames() 

          _NomeDest    := ""   //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
          _ChegDest    := ""   //      "chegada_destino_datahora":null,
          _SaidaDest   := ""   //      "saida_destino_datahora":null,  
          _TempCheSaid := ""   //      "tempo_chegada_saida_destino":null,
          _ordem       := ""   //      "ordem":"1"
       
          _nJ := aScan(_aItemNames,'nome')
          If _nJ > 0 .And. !Empty(_oItemDest[_aItemNames[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:nome)
             _NomeDest    := _oItemDest[_aItemNames[_nJ]] // _oRetJSon[1]:destinos[_nI]:nome                        //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
          EndIf       
       
          _nJ := aScan(_aItemNames,'chegada_destino_datahora')
          If _nJ > 0 .And. !Empty(_oItemDest[_aItemNames[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:chegada_destino_datahora)
             _ChegDest    := _oItemDest[_aItemNames[_nJ]] // _oRetJSon[1]:destinos[_nI]:chegada_destino_datahora    //      "chegada_destino_datahora":null,
          EndIf
       
          _nJ := aScan(_aItemNames,'saida_destino_datahora')
          If _nJ > 0 .And. !Empty(_oItemDest[_aItemNames[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:saida_destino_datahora)
             _SaidaDest   := _oItemDest[_aItemNames[_nJ]] // _oRetJSon[1]:destinos[_nI]:saida_destino_datahora      //      "saida_destino_datahora":null,  
          EndIf
       
          _nJ := aScan(_aItemNames,'tempo_chegada_saida_destino')
          If _nJ > 0 .And. !Empty(_oItemDest[_aItemNames[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:tempo_chegada_saida_destino )
             _TempCheSaid := _oItemDest[_aItemNames[_nJ]] // _oRetJSon[1]:destinos[_nI]:tempo_chegada_saida_destino //      "tempo_chegada_saida_destino":null,
          EndIf
       
          _nJ := aScan(_aItemNames,'ordem')
          If _nJ > 0 .And. !Empty(_oItemDest[_aItemNames[_nJ]]) // ! Empty(_oRetJSon[1]:destinos[_nI]:ordem)
             _Ordem       := _oItemDest[_aItemNames[_nJ]] // _oRetJSon[1]:destinos[_nI]:ordem                       //      "ordem":"1"
          EndIf
       
          _cLinha      += "Nome: " + _NomeDest + " - Chegada ao Destino: " + _ChegDest + " - Saida Destino: " + _SaidaDest + " - Tempo Entre Chegada e Saída Dest.: " + ;
                       _TempCheSaid + " - Ordem: " + _Ordem + CRLF
      Next
   
   EndIf

   _cTitulo := "Status da Viagem" 
   _nCol1   := 5
   _nCol2   := 60
   _nCol3   := 260
   _nCol4   := 315
   _nLinha  := 10 
   
   If _lExibeTela
      Define Dialog _oDlgL Title _cTitulo From 00,00 To 600,1060 Pixel   
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Nr.Viagem" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oNrViagem VAR _NrViagem SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Nr.Cliente" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oNrCliente VAR _NrCliente SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15     
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Nr.Pancary" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oNrPamcary VAR _NrPamcary SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Status" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oStatus VAR _Status SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Evento Data/Hora" SIZE 060, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oEveDataH VAR _EveDataH SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Evento Tipo" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oEveTipo VAR _EveTipo SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15

         @ _nLinha, _nCol1 Say _oSId	PROMPT "Referência" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oReferencia VAR _Referencia SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Latitude" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oLatitude VAR _Latitude SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Longitude" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oLongitude  VAR _Longitude SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Distância" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oDistancia VAR _Distancia SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Direção" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oDirecao VAR _Direcao SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Inicio Previsto" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oInicPrev VAR _InicPrev SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Inicio Real" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oInicReal VAR _InicReal SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Chegada ao Destino" SIZE 060, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oChegDest VAR _ChegDest SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Saída do Destino" SIZE 060, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oSaidaDest VAR _SaidaDest SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Tempo de Entrega" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _otempoEntr VAR _tempoEntr SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Final Previsto" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oFimPrev VAR _FimPrev  SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	      @ _nLinha, _nCol3 Say _oSUsrI	PROMPT "Final Real" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol4 MSGET _oFimReal VAR _FimReal SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
         _nLinha += 15
      
         @ _nLinha, _nCol1 Say _oSId	PROMPT "Tempo Total" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	      @ _nLinha, _nCol2 MSGET _oTempoTot VAR _TempoTot SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	      _nLinha += 15             
	      _nLinha += 15
	  
	      Define Font _oFont Name "Courrier New" Size 7, 12
	  
	      @ _nLinha, _nCol1 Say _oSUsrI	PROMPT "Destinos:" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL 
	      _nLinha += 15
	  
	      @ _nLinha, _nCol1 Get _oLinha Var _cLinha Memo Size 510, 50 Of _oDlgL COLORS 16711680, 16777215 PIXEL
         _oLinha:bRClicked := { || AllwaysTrue() }
	      _oLinha:oFont     := _oFont

         @ 260,120 BUTTON "Finalizar" SIZE 080, 018 PIXEL OF _oDlgL ACTION (_oDlgL:End()) 
         @ 260,220 BUTTON "Visualizar Mapa" SIZE 080, 018 PIXEL OF _oDlgL ACTION (U_AOMS118M(_Latitude,_Longitude)) // (U_AOMS118M("-23.566051","-46.6494041")) // (U_AOMS118M(_cLatitude,_cLongitude))
     
      Activate Dialog _oDlgL Centered   
   EndIf

End Sequence

If ! Empty(_cMsgErro) .And. _lExibeTela
   U_ITMsg(_cMsgErro,"Atenção",,1)
EndIf

DAK->(DBGoTo(_nRegAtu))

Return _aRet     

/*
===============================================================================================================================
Função-------------: AOMS118N
Autor--------------: Julio de Paula Paz
Data da Criacao----: 10/01/2020
Descrição----------: Retorna o numero de um endereço passado por parâmetro.
Parametros---------: _cEndereco = Endereço passado por Parâmetro.
Retorno------------: _cNumero = Numero do endereço passado por parâmetro.
===============================================================================================================================
*/  
User Function AOMS118N(_cEndereco)
Local _cRet := "0000"    
Local _nI, _nPosIni
Local _cNum := ""

Begin Sequence                   
   If Empty(_cEndereco)
      Break
   EndIf              
       
   _cEndereco := _cEndereco + " "
   
   _cEndereco := Upper(_cEndereco)
   
   _nPosIni := At("," , _cEndereco) 
   If _nPosIni > 0 
      For _nI := (_nPosIni + 1) To Len(_cEndereco)
          If Empty(_cNum) .And. SubStr(_cEndereco,_nI,1) == Space(1)
             Loop
          EndIf
          
          _cNum += SubStr(_cEndereco,_nI,1)
      Next
   Else
      _nPosIni := At("S/N" , _cEndereco) 
      If _nPosIni > 0
         _cNum := "S/N"
      EndIf   
   EndIf
   
   If Empty(_cNum)
      _nPosIni := At(Space(1), _cEndereco)
      For _nI := (_nPosIni + 1) To Len(_cEndereco)
          If SubStr(_cEndereco,_nI,1) $ "0123456789"
             _cNum += SubStr(_cEndereco,_nI,1)
          EndIf
      Next
   EndIf
   
   If Empty(_cNum)
      _cRet := "S/N" 
   Else
      _cRet := _cNum
   EndIf

End Sequence

Return _cRet

/*
===============================================================================================================================
Função-------------: AOMS118L
Autor--------------: Julio de Paula Paz
Data da Criacao----: 14/01/2020
Descrição----------: Pesquisa e verifica situação e localização do Veiculo/Motorista.                                              
                     Pesquisa e Verifica mensagens da integração com o sistema Krona.
                     Permite exibir mapa de localização do veículo.
Parametros---------: _cChamada = "V" - Pesquisa e verifica localização do veiculo.
                     -cChamada = "M" - Pesquisa e verifica mensagens de integração com o sistema Krona.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118L(_cChamada)   
/*
Local _aErroRet := {}, _nI
Local _oRetJSon, _cMsgErro , _cMsgInt
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000003")  
Local _cDirJSon, _cPesqViagem
Local _oDlgL
Local _cTitulo  
Local _nCol1,_nCol2, _nCol3, _nCol4, _nLinha
Local _cId, _oId
Local _cUserId, _oUserId
Local _cLatitude, _oLatitude
Local _cLongitude, _oLongitude
Local _cPrecisÃ£o, _oPrecisÃ£o 
Local _cAltitude, _oAltitude 
Local _cComportamento, _oComportamento  
Local _cVelocidade, _oVelocidade  
Local _cTempo, _oTempo      
Local _cTempoDecorrido, _oTempoDecorrido 
Local _cModo, _oModo           
Local _cIdStatMotor, _oIdStatMotor    
Local _cStatusMotorista, _oStatusMotorista
Local _cIdViagem, _oIdViagem
Local _cIdStatViagem, _oIdStatViagem
Local _cStatusViagem, _oStatusViagem
Local _cTipo, _oTipo
Local _cBateria, _oBateria
Local _cIntroduzido, _oIntroduzido
Local _cVencimento, _oVencimento
Local _cAssinatura, _oAssinatura
Local _cIdDocumento, _oIdDocumento

Private _cIdPesquisa

Begin Sequence        
*/
//-------------------------------------------------------------------------------------------------------------------------
Local  _nI ,_nJ//_aErroRet := {},
Local _oRetJSon //, _cMsgErro, _cMsgInt
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000003")  
Local _cDirJSon//, _cPesqViagem
Local _cLoginStatus
Local _cUsuario, _cSenha
//Local _cParam
Local _cLinha, _cAutentic 
Local _cId, _cRetHttpD, _cRetHttpA
//Local _oDlgL
Local _cTitulo  
Local _nTotLinJSon
Local _aSizeAut  := MsAdvSize(.T.) 
Local  _lInverte   //_aCmp,
Local _cDirImg

Private _oMark, _cMarca := GetMark(), _oMarkJSon

Begin Sequence        

   If ! U_ITMsg("Confirma a consulta das posições dos Motoristas/Veículos no sistema Krona ?","Atenção", ,2 , 2)  
      Break
   EndIf              
   
   _cLinkWS := ""
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon    := ZFM->ZFM_LOCXML 
      _cLinkWSLog := AllTrim(ZFM->ZFM_LINK06) // Link de Login
      _cLinkWSMot := AllTrim(ZFM->ZFM_LINK07) // Link posição dos motoristas
   Else
      U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Break
   EndIf
     
   If Empty(_cDirJSon)
      U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf
   
   _cDirImg := U_ItGetMv("ITDIRIMGKRO","\data\Italac\jsonKrona\Imagens\")

   //================================================================================
   // Lê o arquivo modelo JSON de Login e o transforma em String.
   //================================================================================
   _cLoginStatus := U_AOMS118X(_cDirJSon+"Krona1_Login_2.txt") 
   If Empty(_cLoginStatus)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo de Login da integração Krona.","Atenção",,1)
      Break
   EndIf                                                                                                                                        

   _cUsuario := U_ItGetMv("ITUSRMASTKR","ITALAC.INTEGRACAO")  
   _cSenha   := U_ItGetMv("ITPSWMASTKR","123456")            
   
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil
   _nTimOut	 	:= 120

   _cRetHttp    := ''
   
   _cJSonEnv    := &(_cLoginStatus)
   
   _aHeadOut := {}              
   aAdd(_aHeadOut,'Content-Type: application/json')

   _cRetHttp := AllTrim( HttpPost( _cLinkWSLog, '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) )
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   _cId := " "
   If ! Empty(_cJSonRet)
      _nLinhas := MLCOUNT(_cJSonRet)
      For _nI := 1 to _nLinhas
          _cLinha := MemoLine(_cJSonRet,100, _nI) 
          If "x-auth-token" $ _cLinha
             _nJ := AT( ":" , _cLinha)
             _cId := SubStr(_cLinha, _nJ + 2, Len(_cLinha))
             Exit
          EndIf
      Next 
   EndIf       
   _cId := AllTrim(_cId)  
   _cAutentic := AllTrim(_cLinha)
 
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120
   
   _cRetHttp    := ''
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Content-Type: application/json')     
   aAdd(_aHeadOut, _cAutentic)
   
   _cLinkWS := AllTrim(_cLinkWS) 
   
   _cGetParms := "" 
   
   _cRetHttp := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
   
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf        

   If ! ("documentid" $ Lower(_cRetHttp) )   
      U_ITMsg("Não há dados de entregas disponíveis para visualizão.","Atenção",,1)
      Break
   EndIf
   
   FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon) 

   //==========================================================================
   // Cria Tabela Temporária para armazenar dados do JSon
   //==========================================================================
   _aStruct := {}
   aAdd(_aStruct,{"id"        ,"C",30	,0 })  // :"591b2bf8fb6c25358f68248d",
   aAdd(_aStruct,{"documentId","C",20	,0 })  // :"7897123883022",
   aAdd(_aStruct,{"docType"   ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"accountId" ,"C",30	,0 })  // :"5834f7718273f92cc326f620",
   aAdd(_aStruct,{"companyId" ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"companyNam","C",30	,0 })  // :null,
   aAdd(_aStruct,{"motoristId","C",30	,0 })  // :"58d90705346b164247cf83fc",
   aAdd(_aStruct,{"motorDocId","C",20	,0 })  // :"99570378620",
   aAdd(_aStruct,{"status"    ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"observatio","C",30	,0 })  // :null,
   aAdd(_aStruct,{"latitude"  ,"C",20	,0 })  // :-23.5748342,
   aAdd(_aStruct,{"longitude" ,"C",20	,0 })  // :-46.6452698,
   aAdd(_aStruct,{"hasDocImag","C",10	,0 })  // :true,
   aAdd(_aStruct,{"hasSigImag","C",10	,0 })  // :true,
   aAdd(_aStruct,{"imgAmount" ,"C",10	,0 })  // :1,
   aAdd(_aStruct,{"docImage"  ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"signaImage","C",30	,0 })  // :null,
   aAdd(_aStruct,{"statusText","C",30	,0 })  // :"ENTREGUE",
   aAdd(_aStruct,{"sendStatus","C",30	,0 })  // :null,
   aAdd(_aStruct,{"docImgPath","C",30	,0 })  // :null,
   aAdd(_aStruct,{"sigImgPath","C",30	,0 })  // :null,
   aAdd(_aStruct,{"created"   ,"C",20	,0 })  // :1494952939528,
   aAdd(_aStruct,{"inserted"  ,"C",20	,0 })  // :1494952952192,
   aAdd(_aStruct,{"imgExpiry" ,"C",30	,0 })  // :null
   aAdd(_aStruct,{"JSONDOCDIG","M",10	,0 })  // :null
   aAdd(_aStruct,{"JSONASSDIG","M",10	,0 })  // :null
   aAdd(_aStruct,{"NOMDOCDIG" ,"C",20	,0 })  // :null
   aAdd(_aStruct,{"NOMASSDIG" ,"C",20	,0 })  // :null

   //================================================================================
   // Abre o arquivo TRBZF5 criado dentro do banco de dados protheus.
   //================================================================================
   _oTemp := FWTemporaryTable():New( "TRBJSON",  _aStruct )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _oTemp:AddIndex( "01", {"id"} )
   _oTemp:Create()
   
   //================================================================================
   // Cria os indices da tabela temporária.
   //================================================================================
   DBSelectArea("TRBJSON")    

   //====================================================================
   // Dar carga nos dados.
   //====================================================================
   _nTotLinJSon := Len(_oRetJSon) 
   
   For _nJ := 1 To _nTotLinJSon    
       
       _cId := (_oRetJSon[_nJ]:id )
       
       //=====================================================================
       // Obter JSON de documentos Digitalizados
       //=====================================================================
       _cLinkWS := AllTrim(_cLinkWSDoc) + "?id=" + AllTrim(_cId) + "&index=0"
   
       //========================================================================
       // Inicia a Transmissão de dados.
       //========================================================================
       _nStart 		:= 0
       _nRetry 		:= 0
       _cJSonRet 	:= Nil 
       _nTimOut	 	:= 120
     
       _cRetHttpD    := ''
   
       _aHeadOut := {}              
   
       aAdd(_aHeadOut,'Content-Type: application/json') 
       aAdd(_aHeadOut,_cAutentic)
   
       _cLinkWS := AllTrim(_cLinkWS)
   
       _cGetParms := "" 
   
       _cRetHttpD := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
   
       If ! Empty(_cRetHttpD)
          varinfo("WebPage-http ret.", _cRetHttpD)
       EndIf
   
       If ! Empty(_cJSonRet)
          varinfo("WebPage-json ret.", _cJSonRet)
       EndIf
       
       If Empty(_cRetHttpD)
          _cRetHttpD := "[FALSO] Documentos Digitalizados não encontrados."
       EndIf
       
       //=====================================================================
       // Obter JSON de assinaturas digitalizadas.
       //=====================================================================
       _cLinkWS := AllTrim(_cLinkWSAss) + "?id=" + AllTrim(_cId)
   
       //========================================================================
       // Inicia a Transmissão de dados.
       //========================================================================
       _nStart 		:= 0
       _nRetry 		:= 0
       _cJSonRet 	:= Nil 
       _nTimOut	 	:= 120
     
       _cRetHttpA   := ''
   
       _aHeadOut := {}              
   
       aAdd(_aHeadOut,'Content-Type: application/json') 
       aAdd(_aHeadOut,_cAutentic)
   
       _cLinkWS := AllTrim(_cLinkWS)
   
       _cGetParms := "" 
   
       _cRetHttpA := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
   
       If ! Empty(_cRetHttpA)
          varinfo("WebPage-http ret.", _cRetHttpA)
       EndIf
   
       If ! Empty(_cJSonRet)
          varinfo("WebPage-json ret.", _cJSonRet)
       EndIf
       
       If Empty(_cRetHttpA)
          _cRetHttpA := "[Falso] Assinaturas digitalizadas não encontradas."          
       EndIf

       //====================================================================================================
       // Cada vez que a Krona retorna um JSON de consulta das Entregas, existe um fila de dados que
       // substitui os dados já acessados por novos dados. Então é preciso gravar os dados em 
       // uma tabela de histórico. Pois no proxímo acesso os dados serão outros, até zerar a fila de dados.
       //==================================================================================================== 
       ZM3->(RecLock("ZM3",.T.))
       ZM3->ZM3_FILIAL := xFilial("ZM3")
       ZM3->ZM3_DATA   := Date()
	    ZM3->ZM3_HORA   := Time()
	    ZM3->ZM3_TOKEN  := _cAutentic
	    ZM3->ZM3_ID     := _oRetJSon[_nJ]:id                          // id
       ZM3->ZM3_DOCID  := If(Empty(_oRetJSon[_nJ]:documentId)        , "", _oRetJSon[_nJ]:documentId)          // documentId
       ZM3->ZM3_DOCTYP := If(Empty(_oRetJSon[_nJ]:documentType)      , "", _oRetJSon[_nJ]:documentType)        // docType
       ZM3->ZM3_ACCID  := If(Empty(_oRetJSon[_nJ]:accountId)         , "", _oRetJSon[_nJ]:accountId)           // accountId
       ZM3->ZM3_COMPID := If(Empty(_oRetJSon[_nJ]:companyId)         , "", _oRetJSon[_nJ]:companyId)           // companyId
       ZM3->ZM3_COMPNA := If(Empty(_oRetJSon[_nJ]:companyName)       , "", _oRetJSon[_nJ]:companyName)         // companyNam
       ZM3->ZM3_MOTOID := If(Empty(_oRetJSon[_nJ]:motoristId)        , "", _oRetJSon[_nJ]:motoristId)          // motoristId
       ZM3->ZM3_MODCID := If(Empty(_oRetJSon[_nJ]:motoristDocumentId), "", _oRetJSon[_nJ]:motoristDocumentId)  // motorDocId
       ZM3->ZM3_STATUS := If(Empty(_oRetJSon[_nJ]:status)            , "", _oRetJSon[_nJ]:status)              // status
       ZM3->ZM3_OBSERV := If(Empty(_oRetJSon[_nJ]:observation)       , "", _oRetJSon[_nJ]:observation)         // observatio
       ZM3->ZM3_LATITU := _oRetJSon[_nJ]:latitude                                                             // latitude      // numerico
       ZM3->ZM3_LONGIT := _oRetJSon[_nJ]:longitude                                                            // longitude     // numerico
       ZM3->ZM3_HASDCI := _oRetJSon[_nJ]:hasDocumentImage                                                     // hasDocImag    // logico
       ZM3->ZM3_HASSII := _oRetJSon[_nJ]:listImages                                                           // hasSigImag    // logico
       ZM3->ZM3_IMGAMO := _oRetJSon[_nJ]:imagesAmount                                                         // imgAmount     // numerico
       ZM3->ZM3_DOCIMG := If(Empty(_oRetJSon[_nJ]:documentImage)     , "", _oRetJSon[_nJ]:documentImage)      // docImage
       ZM3->ZM3_SIGIMG := If(Empty(_oRetJSon[_nJ]:signatureImage)    , "", _oRetJSon[_nJ]:signatureImage)      // signaImage
       ZM3->ZM3_STATEX := If(Empty(_oRetJSon[_nJ]:statusText)        , "", _oRetJSon[_nJ]:statusText)         // statusText
       ZM3->ZM3_SENDST := If(Empty(_oRetJSon[_nJ]:sendStatus)        , "", _oRetJSon[_nJ]:sendStatus)         // sendStatus
       ZM3->ZM3_DOCIPH := If(Empty(_oRetJSon[_nJ]:documentImagePath) , "", _oRetJSon[_nJ]:documentImagePath)  // docImgPath
       ZM3->ZM3_SIGIPH := If(Empty(_oRetJSon[_nJ]:signatureImagePath), "", _oRetJSon[_nJ]:signatureImagePath)  // sigImgPath
       ZM3->ZM3_CREATE := _oRetJSon[_nJ]:created                                                              // created        // numerico
       ZM3->ZM3_INSERT := _oRetJSon[_nJ]:inserted                                                             // inserted       // numerico
       ZM3->ZM3_IMGEXP := If(Empty(_oRetJSon[_nJ]:imagesExpiry)      , "", _oRetJSon[_nJ]:imagesExpiry)        // imgExpiry  
       ZM3->ZM3_JSONEN := _cRetHttp                                                                           // JSON de entregas
       ZM3->ZM3_JSONDC := _cRetHttpD                                                                          // JSON documentos digitalizados
	    ZM3->ZM3_JSONAS := _cRetHttpA  
       
       If ! "FALSO" $ Upper(_cRetHttpD)
          ZM3->ZM3_NDOCDI := "DOCDIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf

       If ! "FALSO" $ Upper(_cRetHttpA)
          ZM3->ZM3_NASSDI := "ASSINADIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf
                                                                               // JSON assinaturas digitalizados      
       ZM3->(MSUnLock())

       //=====================================================================
       // Grava tabela terporária com os dados do JSon principal.
       //=====================================================================   
       TRBJSON->(RecLock("TRBJSON",.T.)) 
       TRBJSON->id         := _oRetJSon[_nJ]:id                                                                    // id
       TRBJSON->documentId := If(Empty(_oRetJSon[_nJ]:documentId)         ,"", _oRetJSon[_nJ]:documentId)          // documentId
       TRBJSON->docType    := If(Empty(_oRetJSon[_nJ]:documentType)       ,"", _oRetJSon[_nJ]:documentType)        // docType
       TRBJSON->accountId  := If(Empty(_oRetJSon[_nJ]:accountId)          ,"", _oRetJSon[_nJ]:accountId)           // accountId
       TRBJSON->companyId  := If(Empty(_oRetJSon[_nJ]:companyId)          ,"", _oRetJSon[_nJ]:companyId)           // companyId
       TRBJSON->companyNam := If(Empty(_oRetJSon[_nJ]:companyName)        ,"", _oRetJSon[_nJ]:companyName)         // companyNam
       TRBJSON->motoristId := If(Empty(_oRetJSon[_nJ]:motoristId)         ,"", _oRetJSon[_nJ]:motoristId)          // motoristId
       TRBJSON->motorDocId := If(Empty(_oRetJSon[_nJ]:motoristDocumentId) ,"", _oRetJSon[_nJ]:motoristDocumentId)  // motorDocId
       TRBJSON->status     := If(Empty(_oRetJSon[_nJ]:status)             ,"", _oRetJSon[_nJ]:status)              // status
       TRBJSON->observatio := If(Empty(_oRetJSon[_nJ]:observation)        ,"", _oRetJSon[_nJ]:observation)         // observatio
       TRBJSON->latitude   := AllTrim(Str(_oRetJSon[_nJ]:latitude,16,9))                                           // latitude      // numerico
       TRBJSON->longitude  := AllTrim(Str(_oRetJSon[_nJ]:longitude,16,9))                                          // longitude     // numerico
       TRBJSON->hasDocImag := If(_oRetJSon[_nJ]:hasDocumentImage,"Verdadeiro","Falso")                             // hasDocImag    // logico
       TRBJSON->hasSigImag := If(_oRetJSon[_nJ]:listImages,"Verdadeiro","Falso")                                   // hasSigImag    // logico
       TRBJSON->imgAmount  := AllTrim(Str(_oRetJSon[_nJ]:imagesAmount,16))                                         // imgAmount     // numerico
       TRBJSON->docImage   := If(Empty(_oRetJSon[_nJ]:documentImage)      ,"", _oRetJSon[_nJ]:documentImage)       // docImage
       TRBJSON->signaImage := If(Empty(_oRetJSon[_nJ]:signatureImage)     ,"", _oRetJSon[_nJ]:signatureImage)      // signaImage
       TRBJSON->statusText := If(Empty(_oRetJSon[_nJ]:statusText)         ,"", _oRetJSon[_nJ]:statusText)          // statusText
       TRBJSON->sendStatus := If(Empty(_oRetJSon[_nJ]:sendStatus)         ,"", _oRetJSon[_nJ]:sendStatus)          // sendStatus
       TRBJSON->docImgPath := If(Empty(_oRetJSon[_nJ]:documentImagePath)  ,"", _oRetJSon[_nJ]:documentImagePath)   // docImgPath
       TRBJSON->sigImgPath := If(Empty(_oRetJSon[_nJ]:signatureImagePath) ,"", _oRetJSon[_nJ]:signatureImagePath)  // sigImgPath
       TRBJSON->created    := AllTrim(Str(_oRetJSon[_nJ]:created,16))                                              // created        // numerico
       TRBJSON->inserted   := AllTrim(Str(_oRetJSon[_nJ]:inserted,16))                                             // inserted       // numerico
       TRBJSON->imgExpiry  := If(Empty(_oRetJSon[_nJ]:imagesExpiry)       ,"",_oRetJSon[_nJ]:imagesExpiry )        // imgExpiry  

       If ! "FALSO" $ Upper(_cRetHttpD)
          TRBJSON->NOMDOCDIG := "DOCDIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf

       If ! "FALSO" $ Upper(_cRetHttpA)
          TRBJSON->NOMASSDIG := "ASSINADIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf                     
       
       TRBJSON->JSONDOCDIG := _cRetHttpD                                                                           // JSON documentos digitalizados
       TRBJSON->JSONASSDIG := _cRetHttpA                                                                           // JSON assinaturas digitalizados
       
       TRBJSON->(MSUnLock())                                                

       //==================================================================================
       // Grava os arquivos de imagens para posterior exibição.
       //==================================================================================
       If ! "FALSO" $ Upper(_cRetHttpD)
          _cArq := AllTrim(_cDirImg) + "DOCDIG"+StrZero(ZM3->(Recno()),10)+".png"      
          MemoWrite(_cArq,_cRetHttpD)
       EndIf

       If ! "FALSO" $ Upper(_cRetHttpA)
          _cArq := AllTrim(_cDirImg) + "ASSINADIG"+StrZero(ZM3->(Recno()),10)+".png"  
          MemoWrite(_cArq,_cRetHttpA) 
       EndIf
       
   Next
       
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFQ 
   //================================================================================                  
   _aCmpJSon := {}
   aAdd( _aCmpJSon , {"id"        ,    , "ID"                  ,"@!"})  // :"591b2bf8fb6c25358f68248d",
   aAdd( _aCmpJSon , {"documentId",    , "Document ID"         ,"@!"})  // :"7897123883022",
   aAdd( _aCmpJSon , {"docType"   ,    , "Document Type"       ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"accountId" ,    , "Account ID"          ,"@!"})  // :"5834f7718273f92cc326f620",
   aAdd( _aCmpJSon , {"companyId" ,    , "Company ID"          ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"companyNam",    , "Company Name"        ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"motoristId",    , "Motorist ID"         ,"@!"})  // :"58d90705346b164247cf83fc",  
   aAdd( _aCmpJSon , {"motorDocId",    , "Motorist Docum.Id."  ,"@!"})  // :"99570378620",
   aAdd( _aCmpJSon , {"status"    ,    , "Status"              ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"observatio",    , "Observation"         ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"latitude"  ,    , "Latitude"            ,"@!"})  // :-23.5748342,
   aAdd( _aCmpJSon , {"longitude" ,    , "Longitude"           ,"@!"})  // :-46.6452698,
   aAdd( _aCmpJSon , {"hasDocImag",    , "Has.Document Image"  ,"@!"})  // :true,
   aAdd( _aCmpJSon , {"hasSigImag",    , "Has.Signature Image" ,"@!"})  // :true,
   aAdd( _aCmpJSon , {"imgAmount" ,    , "Image Amount"        ,"@!"})  // :1,
   aAdd( _aCmpJSon , {"docImage"  ,    , "Document Image"      ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"signaImage",    , "Signature Image"     ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"statusText",    , "Status Text"         ,"@!"})  // :"ENTREGUE",
   aAdd( _aCmpJSon , {"sendStatus",    , "Send Status"         ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"docImgPath",    , "Document Image Path" ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"sigImgPath",    , "Signature Image Path","@!"})  // :null,
   aAdd( _aCmpJSon , {"created"   ,    , "Created"             ,"@!"})  // :1494952939528,
   aAdd( _aCmpJSon , {"inserted"  ,    , "Inserted"            ,"@!"})  // :1494952952192,
   aAdd( _aCmpJSon , {"imgExpiry" ,    , "Image Expiry"        ,"@!"})  // :null     

   _bOk := {|| _oDlgJ:End()}
   _bCancel := {|| _oDlgJ:End()}
   
   _aButtons := {}
   aAdd(_aButtons,{"",{|| U_AOMS118T() },"Visualizar","Visualizar" })    
   aAdd(_aButtons,{"",{|| U_AOMS118H() },"Histórico Entregas Krona","Histórico Entregas Krona"})
                
   TRBJSON->(DBGoTop())
                                             
   _cTitulo := "Entregas Realizadas - Integração Sistema Krona"
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgJ Title _cTitulo From 0,0 To 200,80 Of oMainWnd 

      _oMarkJSon:= MsSelect():New("TRBJSon","","",_aCmpJSon,@_lInverte, @_cMarca,{_aSizeAut[7]+50, 10, _aSizeAut[4], _aSizeAut[3]})
      _oMarkJSon:bAval := {|| U_AOMS118T()}
      _oDlgJ:lMaximized:=.T.
      
   Activate MsDialog _oDlgJ On Init (EnchoiceBar(_oDlgJ,_bOk,_bCancel,,_aButtons), _oMarkJSon:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkJSon:oBrowse:Refresh() )
 
End Sequence

Return

/*
===============================================================================================================================
Função-------------: AOMS118M
Autor--------------: Julio de Paula Paz
Data da Criacao----: 14/01/2020
Descrição----------: Permite visualizar um endereço no Google Maps, passando como parâmetros a latitude e a longitude.
Parametros---------: _cLatitude  = Coordenadas da latitude.
                     _cLongitude = Coordenadas da longitude.
                     _cZoom      = Zoom do mapa. Valor máximo 22.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118M(_cLatitude, _cLongitude, _cZoom)
Local _oDlgM
Local _cUrl := "" // "https://maps.google.com" 
Local _cTitulo 
Local _oSButtonOk

Private _oWebChannel
Private _oWebEngine   

Default _cZoom := "18.5"

Begin Sequence
   _cTitulo := "Localização de Veiculo - Latitude: "+ AllTrim(_cLatitude) + ", Longitude: " + AllTrim(_cLongitude) 
   
   //_cUrl := "https://www.google.com.br/maps/@-23.566051,-46.6494041,19.1z/" //data=!4m5!3m4!8m2!3d-23.5646161!4d-46.6517168"
   //_cUrl := "https://www.google.com.br/maps/@" + AllTrim(_cLatitude) + "," + AllTrim(_cLongitude) + "," + AllTrim(_cZoom) + "z/" //data=!4m5!3m4!8m2!3d-23.5646161!4d-46.6517168"
   _cUrl := "https://www.google.com.br/maps/place/" + AllTrim(_cLatitude) + "," + AllTrim(_cLongitude) //+ "," + AllTrim(_cZoom) + "z/" //data=!4m5!3m4!8m2!3d-23.5646161!4d-46.6517168"

   Define Dialog _oDlgM Title _cTitulo From 00,00 To 600,860 Pixel   
      // Prepara o conector WebSocket

      _oWebChannel := TWebChannel():New()

      nPort := _oWebChannel::connect()

      // Cria componente

      _oWebEngine := TWebEngine():New(_oDlgM, 02, 02, 420, 270,, nPort) // test:Content

      _oWebEngine:bLoadFinished := {|self,url| conout("Termino da carga do pagina: " + url) }

      _oWebEngine:navigate(_cUrl)

      _oWebEngine:Align := CONTROL_ALIGN_CENTER // CONTROL_ALIGN_ALLCLIENT
     
      Define SButton _oSButtonOk From 280, 200 Type 01 Of _oDlgM Enable Action (_oDlgM:End())

   //Activate Dialog _oDlgM On Init EnchoiceBar(_oDlgM,{|| oDlg1:End() }) Centered
   Activate Dialog _oDlgM Centered

End Sequence

Return              

/*
===============================================================================================================================
Função-------------: AOMS118E
Autor--------------: Julio de Paula Paz
Data da Criacao----: 02/03/2020
Descrição----------: Pesquisa e retorna os dados das entregas do Sistema Krona.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118E()  
Local  _nI ,_nJ//_aErroRet := {},
Local _oRetJSon//, _cMsgErro , _cMsgInt
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000003")  
Local _cDirJSon//, _cPesqViagem
Local _cLoginStatus
Local _cUsuario, _cSenha
//Local _cParam
Local _cLinha, _cAutentic 
Local _cId, _cRetHttpD, _cRetHttpA
//Local _oDlgL
Local _cTitulo  
Local _nTotLinJSon
Local _aSizeAut  := MsAdvSize(.T.) 
Local  _lInverte   //_aCmp,
Local _cDirImg

Private _oMark, _cMarca := GetMark(), _oMarkJSon

Begin Sequence        

   If ! U_ITMsg("Confirma a consulta de entregas registradas no sistema Krona ?","Atenção", ,2 , 2)  
      Break
   EndIf      

   _cDirImg   := U_ItGetMv("ITDIRIMGKRO","\data\Italac\jsonKrona\Imagens\")         
   
   _cLinkWS := ""
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon    := ZFM->ZFM_LOCXML 
      _cLinkWS    := AllTrim(ZFM->ZFM_LINK03) // Link Entregas
      _cLinkWSDoc := AllTrim(ZFM->ZFM_LINK04) // Link Documentos Digitalizados
      _cLinkWSAss := AllTrim(ZFM->ZFM_LINK05) // Link Assinaturas Digitalizadas
      _cLinkWSLog := AllTrim(ZFM->ZFM_LINK06) // Link de Login
   Else
      U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Break
   EndIf
     
   If Empty(_cDirJSon)
      U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf
   
   //================================================================================
   // Lê o arquivo modelo JSON de Login e o transforma em String.
   //================================================================================
   _cLoginStatus := U_AOMS118X(_cDirJSon+"Krona1_Login_2.txt") 
   If Empty(_cLoginStatus)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo de Login da integração Krona.","Atenção",,1)
      Break
   EndIf                                                                                                                                        

   _cUsrMaster    := U_ItGetMv("ITUSRMASTKR","ITALAC.INTEGRACAO")  // Usuário Master da Integração com o Sistema Krona
   _cSenhaMaster  := U_ItGetMv("ITPSWMASTKR","123456")  
   _cUsuario      := _cUsrMaster 
   _cSenha        := _cSenhaMaster
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil
   _nTimOut	 	:= 120

   _cRetHttp    := ''
   
   _cJSonEnv    := &(_cLoginStatus)
   
   _aHeadOut := {}              
   aAdd(_aHeadOut,'Content-Type: application/json')

   _cRetHttp := AllTrim( HttpPost( _cLinkWSLog, '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) )
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   _cId := " "
   If ! Empty(_cJSonRet)
      _nLinhas := MLCOUNT(_cJSonRet)
      For _nI := 1 to _nLinhas
          _cLinha := MemoLine(_cJSonRet,100, _nI) 
          If "x-auth-token" $ _cLinha
             _nJ := AT( ":" , _cLinha)
             _cId := SubStr(_cLinha, _nJ + 2, Len(_cLinha))
             Exit
          EndIf
      Next 
   EndIf       
   _cId := AllTrim(_cId)  
   _cAutentic := AllTrim(_cLinha)
 
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120
   
   _cRetHttp    := ''
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Content-Type: application/json')     
   aAdd(_aHeadOut, _cAutentic)
   
   _cLinkWS := AllTrim(_cLinkWS) 
   
   _cGetParms := "" 
   
   _cRetHttp := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
   
   If U_ITMsg("Deseja utilizar JSON de Testes (dados fixos) ?","Atenção", ,2 , 2)  
 
      //_cRetHttp := '[{"id":"5e72756f26a0a8119d4a5569","documentId":"33343","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e4d67a626a0a80312c9a0d9","motoristDocumentId":"99570378620","status":null,"observation":null,"latitude":-23.2367096,"longitude":-45.8980124,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584559446726,"inserted":1584559471261,"imagesExpiry":null}]'
   
      //_cRetHttp := '[{"id":"5e6c1caa26a0a8119d46be42","documentId":"33305","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e4d67a626a0a80312c9a0d9","motoristDocumentId":"99570378620","status":null,"observation":null,"latitude":-21.7036667,"longitude":-43.4503461,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584143508794,"inserted":1584143530789,"imagesExpiry":null},{"id":"5e6c1d0b26a0a8119d46be67","documentId":"33305","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e4d67a626a0a80312c9a0d9","motoristDocumentId":"99570378620","status":null,"observation":null,"latitude":-21.7036697,"longitude":-43.4503303,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584143598705,"inserted":1584143627171,"imagesExpiry":null},{"id":"5e6c1d3526a0a8119d46be83","documentId":"31200325829482000460570010000333051184778098","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e4d67a626a0a80312c9a0d9","motoristDocumentId":"99570378620","status":null,"observation":null,"latitude":-21.703686,"longitude":-43.4503356,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584143653815,"inserted":1584143669357,"imagesExpiry":null}]'   
     
     _cAutentic := 'x-auth-token: d5b99267-ffb8-4d30-8fe7-4dbff7aba991'
        
     _cRetHttp := '[{"id":"5e73df4e26a0a8119d4b6824","documentId":"33310","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e73bab326a0a8119d4b422b","motoristDocumentId":"99604728687","status":null,"observation":null,"latitude":-21.6785984,"longitude":-45.9157537,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584652107821,"inserted":1584652110154,"imagesExpiry":null},{"id":"5e74ea5c26a0a8119d4c6ed0","documentId":"44499\n","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e3d5c8d26a0a87381324e89","motoristDocumentId":"02771095661","status":null,"observation":null,"latitude":-20.7058023,"longitude":-44.81574,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584720462402,"inserted":1584720476608,"imagesExpiry":null},{"id":"5e74eae226a0a8119d4c6f5f","documentId":"44500","documentType":null,"accountId":"5e188b6da216220aca104171","companyId":null,"companyName":null,"motoristId":"5e3d5c8d26a0a87381324e89","motoristDocumentId":"02771095661","status":null,"observation":null,"latitude":-20.7058064,"longitude":-44.8158438,"hasDocumentImage":true,"hasSignatureImage":false,"imagesAmount":1,"documentImage":null,"listImages":null,"signatureImage":null,"statusText":"ENTREGUE","sendStatus":null,"documentImagePath":null,"listImagesPaths":null,"signatureImagePath":null,"created":1584720602666,"inserted":1584720610829,"imagesExpiry":null}]'

   EndIf
   
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf        

   If ! ("documentid" $ Lower(_cRetHttp) )   
      U_ITMsg("Não há dados de entregas disponíveis para visualizão.","Atenção",,1)
      Break
   EndIf
   
   FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)

   //==========================================================================
   // Cria Tabela Temporária para armazenar dados do JSon
   //==========================================================================
   _aStruct := {}
   aAdd(_aStruct,{"id"        ,"C",30	,0 })  // :"591b2bf8fb6c25358f68248d",
   aAdd(_aStruct,{"documentId","C",20	,0 })  // :"7897123883022",
   aAdd(_aStruct,{"docType"   ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"accountId" ,"C",30	,0 })  // :"5834f7718273f92cc326f620",
   aAdd(_aStruct,{"companyId" ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"companyNam","C",30	,0 })  // :null,
   aAdd(_aStruct,{"motoristId","C",30	,0 })  // :"58d90705346b164247cf83fc",
   aAdd(_aStruct,{"motorDocId","C",20	,0 })  // :"99570378620",
   aAdd(_aStruct,{"status"    ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"observatio","C",30	,0 })  // :null,
   aAdd(_aStruct,{"latitude"  ,"C",20	,0 })  // :-23.5748342,
   aAdd(_aStruct,{"longitude" ,"C",20	,0 })  // :-46.6452698,
   aAdd(_aStruct,{"hasDocImag","C",10	,0 })  // :true,
   aAdd(_aStruct,{"hasSigImag","C",10	,0 })  // :true,
   aAdd(_aStruct,{"imgAmount" ,"C",10	,0 })  // :1,
   aAdd(_aStruct,{"docImage"  ,"C",30	,0 })  // :null,
   aAdd(_aStruct,{"signaImage","C",30	,0 })  // :null,
   aAdd(_aStruct,{"statusText","C",30	,0 })  // :"ENTREGUE",
   aAdd(_aStruct,{"sendStatus","C",30	,0 })  // :null,
   aAdd(_aStruct,{"docImgPath","C",30	,0 })  // :null,
   aAdd(_aStruct,{"sigImgPath","C",30	,0 })  // :null,
   aAdd(_aStruct,{"created"   ,"C",20	,0 })  // :1494952939528,
   aAdd(_aStruct,{"inserted"  ,"C",20	,0 })  // :1494952952192,
   aAdd(_aStruct,{"imgExpiry" ,"C",30	,0 })  // :null
   aAdd(_aStruct,{"JSONDOCDIG","M",10	,0 })  // :null
   aAdd(_aStruct,{"JSONASSDIG","M",10	,0 })  // :null
   aAdd(_aStruct,{"NOMDOCDIG" ,"C",20	,0 })  // :null
   aAdd(_aStruct,{"NOMASSDIG" ,"C",20	,0 })  // :null

   //================================================================================
   // Abre o arquivo TRBZF5 criado dentro do banco de dados protheus.
   //================================================================================
   _oTemp := FWTemporaryTable():New( "TRBJSON",  _aStruct )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _oTemp:AddIndex( "01", {"id"} )
   _oTemp:Create()
   
   //================================================================================
   // Cria os indices da tabela temporária.
   //================================================================================
   DBSelectArea("TRBJSON")    

   //====================================================================
   // Dar carga nos dados.
   //====================================================================
   _nTotLinJSon := Len(_oRetJSon) 
   
   For _nJ := 1 To _nTotLinJSon    
       
       _cId := (_oRetJSon[_nJ]:id )
       
       //=====================================================================
       // Obter JSON de documentos Digitalizados
       //=====================================================================
       _cLinkWS := AllTrim(_cLinkWSDoc) + "?id=" + AllTrim(_cId) + "&index=0"
   
       //========================================================================
       // Inicia a Transmissão de dados.
       //========================================================================
       _nStart 		:= 0
       _nRetry 		:= 0
       _cJSonRet 	:= Nil 
       _nTimOut	 	:= 120
     
       _cRetHttpD    := ''
   
       _aHeadOut := {}              
   
       aAdd(_aHeadOut,'Content-Type: application/json') 
       aAdd(_aHeadOut,_cAutentic)
   
       _cLinkWS := AllTrim(_cLinkWS)
   
       _cGetParms := "" 
   
       _cRetHttpD := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
   
       If ! Empty(_cRetHttpD)
          varinfo("WebPage-http ret.", _cRetHttpD)
       EndIf
   
       If ! Empty(_cJSonRet)
          varinfo("WebPage-json ret.", _cJSonRet)
       EndIf
       
       If Empty(_cRetHttpD)
          _cRetHttpD := "[FALSO] Documentos Digitalizados não encontrados."
       EndIf
       
       //=====================================================================
       // Obter JSON de assinaturas digitalizadas.
       //=====================================================================
       _cLinkWS := AllTrim(_cLinkWSAss) + "?id=" + AllTrim(_cId)
   
       //========================================================================
       // Inicia a Transmissão de dados.
       //========================================================================
       _nStart 		:= 0
       _nRetry 		:= 0
       _cJSonRet 	:= Nil 
       _nTimOut	 	:= 120
     
       _cRetHttpA   := ''
   
       _aHeadOut := {}              
   
       aAdd(_aHeadOut,'Content-Type: application/json') 
       aAdd(_aHeadOut,_cAutentic)
   
       _cLinkWS := AllTrim(_cLinkWS)
   
       _cGetParms := "" 
   
       _cRetHttpA := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
   
       If ! Empty(_cRetHttpA)
          varinfo("WebPage-http ret.", _cRetHttpA)
       EndIf
   
       If ! Empty(_cJSonRet)
          varinfo("WebPage-json ret.", _cJSonRet)
       EndIf
       
       If Empty(_cRetHttpA)
          _cRetHttpA := "[Falso] Assinaturas digitalizadas não encontradas."          
       EndIf

       //====================================================================================================
       // Cada vez que a Krona retorna um JSON de consulta das Entregas, existe um fila de dados que
       // substitui os dados já acessados por novos dados. Então é preciso gravar os dados em 
       // uma tabela de histórico. Pois no proxímo acesso os dados serão outros, até zerar a fila de dados.
       //==================================================================================================== 
       ZM3->(RecLock("ZM3",.T.))
       ZM3->ZM3_FILIAL := xFilial("ZM3")
       ZM3->ZM3_DATA   := Date()
	    ZM3->ZM3_HORA   := Time()
	    ZM3->ZM3_TOKEN  := _cAutentic
	    ZM3->ZM3_ID     := _oRetJSon[_nJ]:id                          // id
       ZM3->ZM3_DOCID  := If(Empty(_oRetJSon[_nJ]:documentId)        , "", _oRetJSon[_nJ]:documentId)          // documentId
       ZM3->ZM3_DOCTYP := If(Empty(_oRetJSon[_nJ]:documentType)      , "", _oRetJSon[_nJ]:documentType)        // docType
       ZM3->ZM3_ACCID  := If(Empty(_oRetJSon[_nJ]:accountId)         , "", _oRetJSon[_nJ]:accountId)           // accountId
       ZM3->ZM3_COMPID := If(Empty(_oRetJSon[_nJ]:companyId)         , "", _oRetJSon[_nJ]:companyId)           // companyId
       ZM3->ZM3_COMPNA := If(Empty(_oRetJSon[_nJ]:companyName)       , "", _oRetJSon[_nJ]:companyName)         // companyNam
       ZM3->ZM3_MOTOID := If(Empty(_oRetJSon[_nJ]:motoristId)        , "", _oRetJSon[_nJ]:motoristId)          // motoristId
       ZM3->ZM3_MODCID := If(Empty(_oRetJSon[_nJ]:motoristDocumentId), "", _oRetJSon[_nJ]:motoristDocumentId)  // motorDocId
       ZM3->ZM3_STATUS := If(Empty(_oRetJSon[_nJ]:status)            , "", _oRetJSon[_nJ]:status)              // status
       ZM3->ZM3_OBSERV := If(Empty(_oRetJSon[_nJ]:observation)       , "", _oRetJSon[_nJ]:observation)         // observatio
       ZM3->ZM3_LATITU := _oRetJSon[_nJ]:latitude                                                             // latitude      // numerico
       ZM3->ZM3_LONGIT := _oRetJSon[_nJ]:longitude                                                            // longitude     // numerico
       ZM3->ZM3_HASDCI := _oRetJSon[_nJ]:hasDocumentImage                                                     // hasDocImag    // logico
       ZM3->ZM3_HASSII := _oRetJSon[_nJ]:listImages                                                           // hasSigImag    // logico
       ZM3->ZM3_IMGAMO := _oRetJSon[_nJ]:imagesAmount                                                         // imgAmount     // numerico
       ZM3->ZM3_DOCIMG := If(Empty(_oRetJSon[_nJ]:documentImage)     , "", _oRetJSon[_nJ]:documentImage)      // docImage
       ZM3->ZM3_SIGIMG := If(Empty(_oRetJSon[_nJ]:signatureImage)    , "", _oRetJSon[_nJ]:signatureImage)      // signaImage
       ZM3->ZM3_STATEX := If(Empty(_oRetJSon[_nJ]:statusText)        , "", _oRetJSon[_nJ]:statusText)         // statusText
       ZM3->ZM3_SENDST := If(Empty(_oRetJSon[_nJ]:sendStatus)        , "", _oRetJSon[_nJ]:sendStatus)         // sendStatus
       ZM3->ZM3_DOCIPH := If(Empty(_oRetJSon[_nJ]:documentImagePath) , "", _oRetJSon[_nJ]:documentImagePath)  // docImgPath
       ZM3->ZM3_SIGIPH := If(Empty(_oRetJSon[_nJ]:signatureImagePath), "", _oRetJSon[_nJ]:signatureImagePath)  // sigImgPath
       ZM3->ZM3_CREATE := _oRetJSon[_nJ]:created                                                              // created        // numerico
       ZM3->ZM3_INSERT := _oRetJSon[_nJ]:inserted                                                             // inserted       // numerico
       ZM3->ZM3_IMGEXP := If(Empty(_oRetJSon[_nJ]:imagesExpiry)      , "", _oRetJSon[_nJ]:imagesExpiry)        // imgExpiry  
       ZM3->ZM3_JSONEN := _cRetHttp                                                                           // JSON de entregas
       ZM3->ZM3_JSONDC := _cRetHttpD                                                                          // JSON documentos digitalizados
	    ZM3->ZM3_JSONAS := _cRetHttpA  
       
       If ! "FALSO" $ Upper(_cRetHttpD)
          ZM3->ZM3_NDOCDI := "DOCDIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf

       If ! "FALSO" $ Upper(_cRetHttpA)
          ZM3->ZM3_NASSDI := "ASSINADIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf
                                                                               // JSON assinaturas digitalizados      
       ZM3->(MSUnLock())

       //=====================================================================
       // Grava tabela terporária com os dados do JSon principal.
       //=====================================================================   
       TRBJSON->(RecLock("TRBJSON",.T.)) 
       TRBJSON->id         := _oRetJSon[_nJ]:id                                                                    // id
       TRBJSON->documentId := If(Empty(_oRetJSon[_nJ]:documentId)         ,"", _oRetJSon[_nJ]:documentId)          // documentId
       TRBJSON->docType    := If(Empty(_oRetJSon[_nJ]:documentType)       ,"", _oRetJSon[_nJ]:documentType)        // docType
       TRBJSON->accountId  := If(Empty(_oRetJSon[_nJ]:accountId)          ,"", _oRetJSon[_nJ]:accountId)           // accountId
       TRBJSON->companyId  := If(Empty(_oRetJSon[_nJ]:companyId)          ,"", _oRetJSon[_nJ]:companyId)           // companyId
       TRBJSON->companyNam := If(Empty(_oRetJSon[_nJ]:companyName)        ,"", _oRetJSon[_nJ]:companyName)         // companyNam
       TRBJSON->motoristId := If(Empty(_oRetJSon[_nJ]:motoristId)         ,"", _oRetJSon[_nJ]:motoristId)          // motoristId
       TRBJSON->motorDocId := If(Empty(_oRetJSon[_nJ]:motoristDocumentId) ,"", _oRetJSon[_nJ]:motoristDocumentId)  // motorDocId
       TRBJSON->status     := If(Empty(_oRetJSon[_nJ]:status)             ,"", _oRetJSon[_nJ]:status)              // status
       TRBJSON->observatio := If(Empty(_oRetJSon[_nJ]:observation)        ,"", _oRetJSon[_nJ]:observation)         // observatio
       TRBJSON->latitude   := AllTrim(Str(_oRetJSon[_nJ]:latitude,16,9))                                           // latitude      // numerico
       TRBJSON->longitude  := AllTrim(Str(_oRetJSon[_nJ]:longitude,16,9))                                          // longitude     // numerico
       TRBJSON->hasDocImag := If(_oRetJSon[_nJ]:hasDocumentImage,"Verdadeiro","Falso")                             // hasDocImag    // logico
       TRBJSON->hasSigImag := If(_oRetJSon[_nJ]:listImages,"Verdadeiro","Falso")                                   // hasSigImag    // logico
       TRBJSON->imgAmount  := AllTrim(Str(_oRetJSon[_nJ]:imagesAmount,16))                                         // imgAmount     // numerico
       TRBJSON->docImage   := If(Empty(_oRetJSon[_nJ]:documentImage)      ,"", _oRetJSon[_nJ]:documentImage)       // docImage
       TRBJSON->signaImage := If(Empty(_oRetJSon[_nJ]:signatureImage)     ,"", _oRetJSon[_nJ]:signatureImage)      // signaImage
       TRBJSON->statusText := If(Empty(_oRetJSon[_nJ]:statusText)         ,"", _oRetJSon[_nJ]:statusText)          // statusText
       TRBJSON->sendStatus := If(Empty(_oRetJSon[_nJ]:sendStatus)         ,"", _oRetJSon[_nJ]:sendStatus)          // sendStatus
       TRBJSON->docImgPath := If(Empty(_oRetJSon[_nJ]:documentImagePath)  ,"", _oRetJSon[_nJ]:documentImagePath)   // docImgPath
       TRBJSON->sigImgPath := If(Empty(_oRetJSon[_nJ]:signatureImagePath) ,"", _oRetJSon[_nJ]:signatureImagePath)  // sigImgPath
       TRBJSON->created    := AllTrim(Str(_oRetJSon[_nJ]:created,16))                                              // created        // numerico
       TRBJSON->inserted   := AllTrim(Str(_oRetJSon[_nJ]:inserted,16))                                             // inserted       // numerico
       TRBJSON->imgExpiry  := If(Empty(_oRetJSon[_nJ]:imagesExpiry)       ,"",_oRetJSon[_nJ]:imagesExpiry )        // imgExpiry  

       If ! "FALSO" $ Upper(_cRetHttpD)
          TRBJSON->NOMDOCDIG := "DOCDIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf

       If ! "FALSO" $ Upper(_cRetHttpA)
          TRBJSON->NOMASSDIG := "ASSINADIG"+StrZero(ZM3->(Recno()),10)+".png"
       EndIf                     
       
       TRBJSON->JSONDOCDIG := _cRetHttpD                                                                           // JSON documentos digitalizados
       TRBJSON->JSONASSDIG := _cRetHttpA                                                                           // JSON assinaturas digitalizados
       
       TRBJSON->(MSUnLock())                                                

       //==================================================================================
       // Grava os arquivos de imagens para posterior exibição.
       //==================================================================================
       If ! "FALSO" $ Upper(_cRetHttpD)
          _cArq := AllTrim(_cDirImg) + "DOCDIG"+StrZero(ZM3->(Recno()),10)+".png"     
          MemoWrite(_cArq,_cRetHttpD)
       EndIf

       If ! "FALSO" $ Upper(_cRetHttpA)
          _cArq := AllTrim(_cDirImg) + "ASSINADIG"+StrZero(ZM3->(Recno()),10)+".png"  
          MemoWrite(_cArq,_cRetHttpA) 
       EndIf
       
   Next
       
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFQ 
   //================================================================================                  
   _aCmpJSon := {}
   aAdd( _aCmpJSon , {"id"        ,    , "ID"                  ,"@!"})  // :"591b2bf8fb6c25358f68248d",
   aAdd( _aCmpJSon , {"documentId",    , "Document ID"         ,"@!"})  // :"7897123883022",
   aAdd( _aCmpJSon , {"docType"   ,    , "Document Type"       ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"accountId" ,    , "Account ID"          ,"@!"})  // :"5834f7718273f92cc326f620",
   aAdd( _aCmpJSon , {"companyId" ,    , "Company ID"          ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"companyNam",    , "Company Name"        ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"motoristId",    , "Motorist ID"         ,"@!"})  // :"58d90705346b164247cf83fc",  
   aAdd( _aCmpJSon , {"motorDocId",    , "Motorist Docum.Id."  ,"@!"})  // :"99570378620",
   aAdd( _aCmpJSon , {"status"    ,    , "Status"              ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"observatio",    , "Observation"         ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"latitude"  ,    , "Latitude"            ,"@!"})  // :-23.5748342,
   aAdd( _aCmpJSon , {"longitude" ,    , "Longitude"           ,"@!"})  // :-46.6452698,
   aAdd( _aCmpJSon , {"hasDocImag",    , "Has.Document Image"  ,"@!"})  // :true,
   aAdd( _aCmpJSon , {"hasSigImag",    , "Has.Signature Image" ,"@!"})  // :true,
   aAdd( _aCmpJSon , {"imgAmount" ,    , "Image Amount"        ,"@!"})  // :1,
   aAdd( _aCmpJSon , {"docImage"  ,    , "Document Image"      ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"signaImage",    , "Signature Image"     ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"statusText",    , "Status Text"         ,"@!"})  // :"ENTREGUE",
   aAdd( _aCmpJSon , {"sendStatus",    , "Send Status"         ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"docImgPath",    , "Document Image Path" ,"@!"})  // :null,
   aAdd( _aCmpJSon , {"sigImgPath",    , "Signature Image Path","@!"})  // :null,
   aAdd( _aCmpJSon , {"created"   ,    , "Created"             ,"@!"})  // :1494952939528,
   aAdd( _aCmpJSon , {"inserted"  ,    , "Inserted"            ,"@!"})  // :1494952952192,
   aAdd( _aCmpJSon , {"imgExpiry" ,    , "Image Expiry"        ,"@!"})  // :null     

   _bOk := {|| _oDlgJ:End()}
   _bCancel := {|| _oDlgJ:End()}
   
   _aButtons := {}
   aAdd(_aButtons,{"",{|| U_AOMS118T() },"Visualizar","Visualizar" })    
   aAdd(_aButtons,{"",{|| U_AOMS118H() },"Histórico Entregas Krona","Histórico Entregas Krona"})
                
   TRBJSON->(DBGoTop())
                                             
   _cTitulo := "Entregas Realizadas - Integração Sistema Krona"
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgJ Title _cTitulo From 0,0 To 200,80 Of oMainWnd 

      _oMarkJSon:= MsSelect():New("TRBJSon","","",_aCmpJSon,@_lInverte, @_cMarca,{_aSizeAut[7]+50, 10, _aSizeAut[4], _aSizeAut[3]})
      _oMarkJSon:bAval := {|| U_AOMS118T()}
      _oDlgJ:lMaximized:=.T.
      
   Activate MsDialog _oDlgJ On Init (EnchoiceBar(_oDlgJ,_bOk,_bCancel,,_aButtons), _oMarkJSon:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkJSon:oBrowse:Refresh() )
       
End Sequence

U_ITMsg("Final da integração Deliveres.","Atenção",,1) 

Return     

/*
===============================================================================================================================
Função-------------: AOMS118T
Autor--------------: Julio de Paula Paz
Data da Criacao----: 19/03/2020
Descrição----------: Exibe tela com os dados das entregas e permite visualizar mapa, documentos Digitalizado, e assinaturas
                     digitalizadas.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118T() 
Local _cDocDig, _cAssinatDig
Local _nCol1, _nCol2, _nCol3, _nCol4, _nLinha 
Local id, documentId, docType, accountId, companyId, companyNam, motoristId, motorDocId
Local status, observatio, latitude, longitude, hasDocImag, hasSigImag, imgAmount, docImage
Local signaImage, statusText, sendStatus, docImgPath, sigImgPath, created,inserted, imgExpiry
Local _cDirImg

Begin Sequence

   id         := TRBJSon->id           // ID           
   documentId := TRBJSon->documentId   // Document ID  
   docType    := TRBJSon->docType      // Document Type 
   accountId  := TRBJSon->accountId    // Account ID  
   companyId  := TRBJSon->companyId    // Company ID   
   companyNam := TRBJSon->companyNam   // Company Name 
   motoristId := TRBJSon->motoristId   // Motorist ID         
   motorDocId := TRBJSon->motorDocId   // Motorist Docum.Id.  
   status     := TRBJSon->status       // Status      
   observatio := TRBJSon->observatio   // Observation 
   latitude   := TRBJSon->latitude     // Latitude     
   longitude  := TRBJSon->longitude    // Longitude   
   hasDocImag := TRBJSon->hasDocImag   // Has.Document Image    
   hasSigImag := TRBJSon->hasSigImag   // Has.Signature Image   
   imgAmount  := TRBJSon->imgAmount    // Image Amount      
   docImage   := TRBJSon->docImage     // Document Image    
   signaImage := TRBJSon->signaImage   // Signature Image   
   statusText := TRBJSon->statusText   // Status Text      
   sendStatus := TRBJSon->sendStatus   // Send Status      
   docImgPath := TRBJSon->docImgPath   // Document Image Path   
   sigImgPath := TRBJSon->sigImgPath   // Signature Image Path  
   created    := TRBJSon->created      // Created          
   inserted   := TRBJSon->inserted     // Inserted         
   imgExpiry  := TRBJSon->imgExpiry    // Image Expiry
               
   _cDirImg   := U_ItGetMv("ITDIRIMGKRO","\data\Italac\jsonKrona\Imagens\") 

   If ! Empty(TRBJSON->NOMDOCDIG)
      _cDocDig := AllTrim(_cDirImg) + AllTrim(TRBJSON->NOMDOCDIG)
   EndIf 
   
   If ! Empty(TRBJSON->NOMASSDIG)
      _cAssinatDig := AllTrim(_cDirImg) + AllTrim(TRBJSON->NOMASSDIG)
   EndIf

   _cTitulo := "Entregas - Sistema Krona" 
   _nCol1   := 5
   _nCol2   := 60
   _nCol3   := 260
   _nCol4   := 315
   _nLinha  := 10 

   Define Dialog _oDlgL Title _cTitulo From 00,00 To 600,1060 Pixel   
      
      @ _nLinha, _nCol1 Say _oSId	PROMPT "ID" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oID VAR id  SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSDocId	PROMPT "Document ID" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _odocumentId VAR documentId SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15     
      
      @ _nLinha, _nCol1 Say _oSDocType	PROMPT "Document Type" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _odocType VAR docType SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSAccId	PROMPT "Account ID" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _oaccountId VAR accountId SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
      
      @ _nLinha, _nCol1 Say _oSCompID   PROMPT "Company ID" SIZE 060, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _ocompanyId VAR companyId SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSCompName	PROMPT "Company Name" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _ocompanyNam VAR companyNam SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15

      @ _nLinha, _nCol1 Say _oSMotorId	PROMPT "Motorist ID" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _omotoristId VAR motoristId SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSMotordoc	PROMPT "Motorist Docum.Id." SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _omotorDocId VAR motorDocId SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
      
      @ _nLinha, _nCol1 Say _oSStatus   PROMPT "Status" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _ostatus  VAR status SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSObs   	PROMPT "Observation" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _oobservatio VAR observatio SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
                                    
      @ _nLinha, _nCol1 Say _oSLatit	PROMPT "Latitude" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _olatitude VAR latitude SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
          
      @ _nLinha, _nCol3 Say _oSLongit	PROMPT "Longitude" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _olongitude  VAR longitude SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
       
      @ _nLinha, _nCol1 Say _oSHasDocI	PROMPT "Has.Document Image" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _ohasDocImag VAR hasDocImag SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSHasSigI	PROMPT "Has.Signature Image" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _ohasSigImag VAR hasSigImag SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
      
      @ _nLinha, _nCol1 Say _oSImgAmout	PROMPT "Image Amount" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oimgAmount VAR imgAmount SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSDocImg	PROMPT "Document Image" SIZE 060, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _odocImage VAR docImage SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
      
      @ _nLinha, _nCol1 Say _oSSigImg	PROMPT "Signature Image" SIZE 060, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _osignaImage VAR signaImage SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSStatText	PROMPT "Status Text" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _ostatusText VAR statusText SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
      
      @ _nLinha, _nCol1 Say _oSSendStat	PROMPT "Send Status" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _osendStatus VAR sendStatus  SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSDocImgP	PROMPT "Document Image Path" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _odocImgPath VAR docImgPath SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15    
      
      @ _nLinha, _nCol1 Say _oSSigImgP  PROMPT "Signature Image Path" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _osigImgPath VAR sigImgPath  SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSCreat	PROMPT "Created" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _ocreated VAR created SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
      
      @ _nLinha, _nCol1 Say _oSInsert   PROMPT "Inserted" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oinserted VAR inserted  SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
	  
	   @ _nLinha, _nCol3 Say _oSImgExp	PROMPT "Image Expiry" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol4 MSGET _oimgExpiry VAR imgExpiry SIZE 100, 012 OF _oDlgL WHEN .F. PIXEL
      _nLinha += 15
	   _nLinha += 15
	  
	   @ 260,020 BUTTON "Finalizar" SIZE 080, 018 PIXEL OF _oDlgL ACTION (_oDlgL:End()) 
      @ 260,120 BUTTON "Visualizar Mapa" SIZE 080, 018 PIXEL OF _oDlgL ACTION (U_AOMS118M(latitude,longitude))     // (U_AOMS118M("-23.566051","-46.6494041")) 
      @ 260,220 BUTTON "Documentos Digitalizados " SIZE 080, 018 PIXEL OF _oDlgL ACTION (U_AOMS118I(_cDocDig, "DOCUMENTOS_DIG"))    
      @ 260,320 BUTTON "Assinaturas Digitalizadas" SIZE 080, 018 PIXEL OF _oDlgL ACTION (U_AOMS118I(_cAssinatDig, "ASSINATURA_DIG"))
     
   Activate Dialog _oDlgL Centered   

End Sequence 

Return

/*
===============================================================================================================================
Função-------------: AOMS118I
Autor--------------: Julio de Paula Paz
Data da Criacao----: 02/03/2020
Descrição----------: Permite a visualização de imagens digitalizadas do Sistema Krona.
Parametros---------: _cArqImage = Diretório e nome dos arquivos digitalizados.
                     _cChamada  = Botão que chamou a função.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118I(_cArqImage,_cChamada)  
Local _oDlgI
Local _cTitulo  
Local _oTBitmap

Begin Sequence  
   
   If Empty(_cArqImage)
      U_ITMsg("Não há imagens a serem exibidas.","Atenção",,1) 
   EndIf

   If _cChamada == "DOCUMENTOS_DIG"
      _cTitulo := "Imagens dos Documentos Digitalizados" 
   Else // ASSINATURA_DIG
      _cTitulo := "Imagens das Assinaturas Digitalizadas"
   EndIf

   DEFINE DIALOG _oDlgI TITLE _cTitulo FROM 00,00 TO 600,1060 PIXEL 

      _oTBitmap := TBitmap():New(01,01,1040,860,,_cArqImage,.T.,_oDlgI, , ,.F.,.F.,,,.F.,,.T.,,.F.)
      _oTBitmap:lAutoSize := .F.

      @ 270,200 BUTTON "Finalizar" SIZE 080, 018 PIXEL OF _oDlgI ACTION (_oDlgI:End()) 
 
   ACTIVATE DIALOG _oDlgI CENTERED
        
End Sequence

Return 

/*
===============================================================================================================================
Função-------------: AOMS118H
Autor--------------: Julio de Paula Paz
Data da Criacao----: 13/04/2020
Descrição----------: Carrega histórico de dados para visualização em tela, conforme período informado.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118H()
Local _cTitulo 
Local _nCol1, _nCol2, _nLinha
Local _cQry, _nOpc 
Local _dDtIni, _oDtIni, _dDtFim, _oDtFim

Begin Sequence

   _cTitulo := "Lê e Carrega os Dados de Histórico" 
   _nCol1   := 5
   _nCol2   := 60
   //_nCol3   := 260
   //_nCol4   := 315
   _nLinha  := 10 

   _dDtIni := Ctod("  /  /  ")
   _dDtFim := Ctod("  /  /  ")
   _nOpc   := 0

   Define Dialog _oDlgL Title _cTitulo From 00,00 To 200,400 Pixel   
      
      @ _nLinha, _nCol1 Say _oSDtIn	PROMPT "Data Inicial" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oDtIni VAR _dDtIni SIZE 40, 012 Picture "@D" OF _oDlgL PIXEL
	   _nLinha += 15

	   @ _nLinha, _nCol1 Say _oSDtFim	PROMPT "Data Final" SIZE 046, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oDtFim VAR _dDtFim SIZE 40, 012 Picture "@D" OF _oDlgL PIXEL
      _nLinha += 15     
      _nLinha += 15

      @ _nLinha,20 BUTTON "Confirma" SIZE 060, 018 PIXEL OF _oDlgL ACTION (_nOpc := 1, _oDlgL:End()) 
      @ _nLinha,100 BUTTON "Cancela" SIZE 060, 018 PIXEL OF _oDlgL ACTION (_nOpc := 0, _oDlgL:End()) 
     
   Activate Dialog _oDlgL Centered   
   
   If _nOpc == 1
      //ZM3->(DBSetOrder(1)) // ZM3_FILIAL+DToS(ZM3_DATA)+ZM3_HORA+ZM3_ID 

      _cQry := "SELECT ZM3.R_E_C_N_O_ NRRECNO" // Filial do Pedido de vendas
      _cQry += " FROM " + RETSQLNAME("ZM3") + " ZM3 "
      _cQry += " WHERE 
      _cQry += " ZM3.D_E_L_E_T_ = ' ' "

      If ! Empty(_dDtIni)
         _cQry += " AND ZM3_DATA >= '" + DToS(_dDtIni) + "' "
      EndIf 

      If ! Empty(_dDtFim)
         _cQry += " AND ZM3_DATA <= '" + DToS(_dDtFim) + "' "
      EndIf
    
      If Select("TRBZM3") > 0
         TRBZM3->(DBCloseArea())
      EndIf

      DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "TRBZM3" , .F. , .T. )
      //DBSelectArea("TRBSC5")
   
      TCSetField( "TRBZM3", "ZM3_DATA", "D", 8 )
   
      Count To _nTotRegs

      If _nTotRegs == 0
         U_ITMsg("Não há dados que satisfaçam as condições de filtro para exibir o histórico.","Atenção",,1) 
         Break
      EndIf
      
      TRBJSON->(DBGoTop())
      While ! TRBJSON->(Eof())
         TRBJSON->(RecLock("TRBJSON",.F.))
         TRBJSON->(DbDelete())
         TRBJSON->(MSUnLock())

         TRBJSON->(DBSkip())
      EndDo

      TRBZM3->(DBGoTop())

      While ! TRBZM3->(Eof())
         
         ZM3->(DBGoTo(TRBZM3->NRRECNO))

         TRBJSON->(RecLock("TRBJSON",.T.))
         TRBJSON->id         := ZM3->ZM3_ID                              // id
         TRBJSON->documentId := ZM3->ZM3_DOCID                           // documentId
         TRBJSON->docType    := ZM3->ZM3_DOCTYP                          // docType
         TRBJSON->accountId  := ZM3->ZM3_ACCID                           // accountId
         TRBJSON->companyId  := ZM3->ZM3_COMPID                          // companyId
         TRBJSON->companyNam := ZM3->ZM3_COMPNA                          // companyNam
         TRBJSON->motoristId := ZM3->ZM3_MOTOID                          // motoristId
         TRBJSON->motorDocId := ZM3->ZM3_MODCID                          // motorDocId
         TRBJSON->status     := ZM3->ZM3_STATUS                          // status
         TRBJSON->observatio := ZM3->ZM3_OBSERV                          // observatio
         TRBJSON->latitude   := AllTrim(Str(ZM3->ZM3_LATITU,16,9))       // latitude      // numerico
         TRBJSON->longitude  := AllTrim(Str(ZM3->ZM3_LONGIT,16,9))       // longitude     // numerico
         TRBJSON->hasDocImag := If(ZM3->ZM3_HASDCI,"Verdadeiro","Falso") // hasDocImag    // logico
         TRBJSON->hasSigImag := If(ZM3->ZM3_HASSII,"Verdadeiro","Falso") // hasSigImag    // logico 
         TRBJSON->imgAmount  := AllTrim(Str(ZM3->ZM3_IMGAMO,16,9))       // imgAmount     // numerico
         TRBJSON->docImage   := ZM3->ZM3_DOCIMG                          // docImage
         TRBJSON->signaImage := ZM3->ZM3_SIGIMG                          // signaImage
         TRBJSON->statusText := ZM3->ZM3_STATEX                          // statusText
         TRBJSON->sendStatus := ZM3->ZM3_SENDST                          // sendStatus
         TRBJSON->docImgPath := ZM3->ZM3_DOCIPH                          // docImgPath
         TRBJSON->sigImgPath := ZM3->ZM3_SIGIPH                          // sigImgPath
         TRBJSON->created    := AllTrim(Str(ZM3->ZM3_CREATE,16))         // created        // numerico
         TRBJSON->inserted   := AllTrim(Str(ZM3->ZM3_INSERT,16))         // inserted       // numerico
         TRBJSON->imgExpiry  := ZM3->ZM3_IMGEXP                          // imgExpiry  
         TRBJSON->NOMDOCDIG  := ZM3->ZM3_NDOCDI 
         TRBJSON->NOMASSDIG  := ZM3->ZM3_NASSDI
         TRBJSON->(MSUnLock())
         
         TRBZM3->(DBSkip())
      EndDo
      
      TRBJSON->(DBGoTop())
      _oMarkJSon:oBrowse:Refresh()

   EndIf

End Sequence 

If Select("TRBZM3") > 0
   TRBZM3->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Função-------------: AOMS118A
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/03/2020
Descrição----------: Envia o cancelamento da viagem integrada para o Sistema Krona.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118A()  

Local _aErroRet := {}, _nI
Local _oRetJSon, _cMsgErro , _cMsgInt
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000002")  
Local _cDirJSon//, _cPesqViagem

//==========================================
//  Login JSon
//==========================================
Private _cUsuario    := ""
Private _cSenha      := ""

//==========================================
//  Variáveis de Cancelamento JSon
//==========================================
Private _cIdViagem   := ""
Private _cCancelar   := "1"
Private _cMotivoCanc := Space(100)

Begin Sequence        
   
   If DAK->DAK_I_ENVK <> "S"  
      U_ITMsg("A carga seleciondada ainda não foi integrada para o sistema Krona.","Atenção",,1) 
      Break
   EndIf  
   
   If Empty(DAK->DAK_I_PROT)
      U_ITMsg("Não existe numero de protocolo gerado para a carga selecionada.","Atenção",;
              "Para consultar o status de uma viagem, um protocolo precisa ser gerado na integração da carga para o sistema Krona.",1) 
      Break
   EndIf
   
   _cIdViagem := DAK->DAK_I_PROT  
   
   If ! U_ITMsg("Confirma o cancelamento viagem/carga integrada para o sistema Krona ?","Atenção", ,2 , 2)  
      Break
   EndIf        
   
//--------------------------------------------------------------------------------------------------------------------------------//   

   _cTitulo := "Motivo do Cancelamento da Viagem/Carga" 
   _nCol1   := 5
   _nCol2   := 60
   _nLinha  := 20 
   _nOpc    := 0
   Define Dialog _oDlgL Title _cTitulo From 00,00 To 200,600 Pixel   
      
      @ _nLinha, _nCol1 Say _oSId	PROMPT "Motivo Cancelamento" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	  @ _nLinha, _nCol2 MSGET _oGId VAR _cMotivoCanc SIZE 200, 012 OF _oDlgL  PIXEL
	  _nLinha += 25

      @ _nLinha,050 BUTTON "OK" SIZE 080, 018 PIXEL OF _oDlgL ACTION (_nOpc := 1,_oDlgL:End()) 
      @ _nLinha,150 BUTTON "Cancela" SIZE 080, 018 PIXEL OF _oDlgL ACTION (_nOpc := 1,_oDlgL:End()) 
     
   Activate Dialog _oDlgL Centered
  
   If _nOpc == 0
      U_ITMsg("Rotina de cancelamento de viagem integrada para o sistema Krona interrompida.","Atenção",,1) 
      Break
   EndIf    
                                                    
   If Empty(_cMotivoCanc)
      U_ITMsg("O preenchimento do motivo de cancelamento de viagem é obrigatório. Rotina interrompida.","Atenção",,1) 
      Break
   EndIf
   
   //--------------------------->> 3 - Motorista 1 
   DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD   
   If DA4->(DBSeek(xFilial("DA4")+DAK->DAK_MOTORI))
      //----------------------------------------------//
      _cTransp   := DA4->DA4_FORNECE
      _cLjTransp := DA4->DA4_LOJA   
   EndIf

   //--------------------------->> 2 - Transportador
   SA2->(DBSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
   
   If SA2->(DBSeek(xFilial("SA2")+_cTransp + _cLjTransp)) 
      _cUsuario := SA2->A2_I_USRKR
      _cSenha   := SA2->A2_I_PSWKR
   EndIf
         
   //--------------------------------------------------------------------------------------------------------------------------------//   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK01)
   Else
      U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Break
   EndIf
     
   If Empty(_cDirJSon)
      U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo JSON e os transforma em String.
   //================================================================================      
   _cCabLogin := U_AOMS118X(_cDirJSon+"Krona1_Cab_Login.txt") 
   If Empty(_cCabLogin)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho de envio e login da integração Krona.","Atenção",,1)
      Break
   EndIf

   _cCancelViagem := U_AOMS118X(_cDirJSon+"Krona1_Cancelamento_viagem.txt") 
   If Empty(_cCancelViagem)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo de cancelamento de viagem da integração Krona.","Atenção",,1)
      Break
   EndIf

   _cRodaPe := U_AOMS118X(_cDirJSon+"Krona1_Rodape.txt") 
   If Empty(_cRodaPe)
      U_ITMsg("Erro na leitura do arquivo modelo JSON do rodape, da integração REST Italac x Krona.","Atenção",,1)
      Break
   EndIf
   
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120 
   _cJSonEnv    := &(_cCabLogin) + &(_cCancelViagem) + _cRodaPe

   _cRetHttp    := ''
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Content-Type: application/json')

   _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) )   
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   //=================================================================================
   // Atualiza Tabela DAK com os dados da integração de Cancelamento de viagem Krona
   //=================================================================================                                                              
   DAK->(RecLock("DAK", .F.))    
   DAK->DAK_I_MOTC := _cMotivoCanc
   DAK->DAK_I_DTCK := Date()
   DAK->DAK_I_HRCK := Time()
   DAK->DAK_I_XMLC := _cJSonEnv
   If ! Empty(_cRetHttp)
      DAK->DAK_I_RETC := _cRetHttp
   Else
      DAK->DAK_I_RETC := _cJSonRet
   EndIf
   DAK->(MSUnLock())  
   
   //===========================================================================
   // Verifica retorno de erros na integração.
   //===========================================================================
   _cMsgErro := ""
   _cMsgInt    := ""
      
   For _nI := 1 To Len(_aErroRet)
       If _aErroRet[_nI,1] $ Upper(_cRetHttp)
          _cMsgErro += If(!Empty(_cMsgErro),CRLF,"") + "Erro na Integração com o sistema Krona: "+ _aErroRet[_nI,2]+" - Codigo do erro: "+_aErroRet[_nI,1] + ". " 
       EndIf
   Next   
   
   If Empty(_cMsgErro)        
      //FWJsonDeserialize(DecodeUtf8(cJson2),@oJson)
      FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
   EndIf                
   
   /* --------------------------> Modelo de Retorno.
    { 
      "numero_viagem" : "2821313" ,
      "numero_cliente" : "" ,
      "numero_pamcary" : "0" ,
      "status" : "FINALIZADA" ,
      "evento_datahora" : "2019-02-18 10:30:10" ,
      "evento_tipo" : "POSIÇÃO AUTOMATICA" ,
      "referencia" : "0 metros de TORRA TORRA - LOJA 37 JUNDIAI - SP" ,
      "latitude" : "-23.186685" ,
      "longitude" : "-46.88426333333334" ,
      "distancia" : null ,
      "direcao" : "SUDESTE" ,
      "inicio_previsto" : "18 \ / 02 \ / 2019 08:42:41" ,
      "inicio_real" : "18 \ / 02 \ / 2019 09:24:58" ,
      "chegada_destino_datahora" : "18 \ / 02 \ / 2019 10:29:02" ,
      "saida_destino_datahora" : "" ,
      "tempo_entrega" : "" ,
      "fim_previsto" : "19 \ / 02 \ / 2019 00:00:00" ,
      "fim_real" : "18 \ / 02 \ / 2019 10:29:23" ,
      "tempo_total" : "01:04:25"
    } 
   */       
   
   /* 
    Descrição dos Status de Retorno:
    ================================
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Rascunho – O usuário cadastrou uma viagem, porém algumas informações estão faltando.                                                                                              |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Preenchida  –  O usuário cadastrou uma viagem por completo, ou completou os dados de uma viagem que estava com status de rascunho, nesse estágio o cliente tem a opção de enviar  |
    |                a viagem para a confirmação de sinal.                                                                                                                              |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Agendada  –  Viagem com todos os dados necessários, porém foi enviada para confirmação de sinal com um o veículo associado a outra viagem, sendo assim a viagem permanece nesse   |
    |              status até que a viagem anterior seja finalizada, não há limite no agendamento de viagens.                                                                           |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Confirmação de Sinal  –  Viagem aguardando confirmação de sinal pela tecnologia ou manualmente pelo usuário.                                                                  |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Check List  –  Viagem com o sinal confirmado, porem  expirou o tempo determinado para realização de check-list (configurável na operação).                                    |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Check List Reprovado  –  Viagem com check-list reprovado (no  preenchimento  do check-list foi pontuado que o sensor ou atuador não funciona).                                    |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Aprovação – Viagem com sinal confirmado, aguardando aprovação pelo usuário.                                                                                                   |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Emb. Configuração  –  viagem que a configuração está com a opção de configuração por viagem, aguardando o envio da configuração pelo usuário.                                 |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Escolta  –  Viagem cuja opção de escolta rastreada está selecionada  na aba escolta  e aguarda o  posicionamento do veículo  de escolta  no perímetro (configurável) antes    |
    |                 de passar para o próximo status.                                                                                                                                  |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Inicio Viagem – Viagem com sinal confirmado, aprovada aguardando o envio da macro de início de viagem.                                                                        |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
   */

End Sequence  

U_ITMsg("Final da integração Cancelamento de Viagem.","Atenção",,1)

Return     

/*
===============================================================================================================================
Função-------------: AOMS118B
Autor--------------: Julio de Paula Paz
Data da Criacao----: 10/01/2020
Descrição----------: Envia liberação de inicio viagem para o Sistema Krona.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118B()  

Local _aErroRet := {}, _nI
Local _oRetJSon, _cMsgErro , _cMsgInt
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000002")  
Local _cDirJSon//, _cPesqViagem

Private _cIdPesquisa    

//==========================================
//  Login JSon
//==========================================
Private _cUsuario := ""
Private _cSenha   := ""

//==========================================
//  Liberação Viagem
//==========================================
Private _cIdViagem := ""   
Private _cInicioViagem := "1"


Begin Sequence        
   
   If DAK->DAK_I_ENVK <> "S"  
      U_ITMsg("A carga seleciondada ainda não foi integrada para o sistema Krona.","Atenção",,1) 
      Break
   EndIf  
   
   If Empty(DAK->DAK_I_PROT)
      U_ITMsg("Não existe numero de protocolo gerado para a carga selecionada.","Atenção",;
              "Para consultar o status de uma viagem, um protocolo precisa ser gerado na integração da carga para o sistema Krona.",1) 
      Break
   EndIf
   
   _cIdViagem := DAK->DAK_I_PROT  
   
   If ! U_ITMsg("Confirma a solicitação de liberação de viagem/carga no sistema Krona ?","Atenção", ,2 , 2)  
      Break
   EndIf   
   
   //=====================================================================
   // Obtem usuário e senha.                                                                     
   //=====================================================================
   
   //--------------------------->> 3 - Motorista 1 
   DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD   
   If DA4->(DBSeek(xFilial("DA4")+DAK->DAK_MOTORI))
      //----------------------------------------------//
      _cTransp   := DA4->DA4_FORNECE
      _cLjTransp := DA4->DA4_LOJA   
   EndIf

   //--------------------------->> 2 - Transportador
   SA2->(DBSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
   
   If SA2->(DBSeek(xFilial("SA2")+_cTransp + _cLjTransp)) 
      _cUsuario := SA2->A2_I_USRKR
      _cSenha   := SA2->A2_I_PSWKR
   EndIf           
   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK01)
   Else
      U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Break
   EndIf
   
   //_cLinkWS  := "http://grupokrona.dyndns.org/k1/api/viagem_status.php"
   
   If Empty(_cDirJSon)
      U_ITMsg("Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)     
      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo JSON e os transforma em String.
   //================================================================================
   _cCabLogin := U_AOMS118X(_cDirJSon+"Krona1_Cab_Login.txt") 
   If Empty(_cCabLogin)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho de envio e login da integração Krona.","Atenção",,1)
      Break
   EndIf

   _cLiberaViagem := U_AOMS118X(_cDirJSon+"Krona1_Liberacao_Inicio_Viagem.txt") 
   If Empty(_cLiberaViagem)
      U_ITMsg("Erro na leitura do arquivo modelo JSON modelo de liberação de incio de viagem da integração Krona.","Atenção",,1)
      Break
   EndIf

   _cRodaPe := U_AOMS118X(_cDirJSon+"Krona1_Rodape.txt") 
   If Empty(_cRodaPe)
      U_ITMsg("Erro na leitura do arquivo modelo JSON do rodape, da integração REST Italac x Krona.","Atenção",,1)
      Break
   EndIf
   
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120 
   _cJSonEnv    := &(_cCabLogin) + &(_cLiberaViagem) + _cRodaPe

   _cRetHttp    := ''
   
   _aHeadOut := {}              
   // Google Chrome está atualizado
   //Versão 79.0.3945.88 (Versão oficial) 64 bits
   
   //aAdd(_aHeadOut,'User-Agent: Google Chrome/79.0.3945.88 ( compatible; Protheus '+GetBuild()+')') 
   aAdd(_aHeadOut,'Content-Type: application/json')

   _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) )
   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   //=================================================================================
   // Atualiza Tabela DAK com os dados da integração de Cancelamento de viagem Krona
   //=================================================================================                                                              
   DAK->(RecLock("DAK", .F.))      
   DAK->DAK_I_DLBK := Date()
   DAK->DAK_I_HRLK := Time()
   DAK->DAK_I_XMLL := _cJSonEnv
   If ! Empty(_cRetHttp)
      DAK->DAK_I_RETL := _cRetHttp
   Else
      DAK->DAK_I_RETL := _cJSonRet
   EndIf
   DAK->(MSUnLock())  
   
   //===========================================================================
   // Verifica retorno de erros na integração.
   //===========================================================================
   _cMsgErro := ""
   _cMsgInt    := ""
      
   For _nI := 1 To Len(_aErroRet)
       If _aErroRet[_nI,1] $ Upper(_cRetHttp)
          _cMsgErro += If(!Empty(_cMsgErro),CRLF,"") + "Erro na Integração com o sistema Krona: "+ _aErroRet[_nI,2]+" - Codigo do erro: "+_aErroRet[_nI,1] + ". " 
       EndIf
   Next   
   
   If Empty(_cMsgErro)        
      //FWJsonDeserialize(DecodeUtf8(cJson2),@oJson)
      FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
   EndIf                
   
   /* --------------------------> Modelo de Retorno.
    { 
      "numero_viagem" : "2821313" ,
      "numero_cliente" : "" ,
      "numero_pamcary" : "0" ,
      "status" : "FINALIZADA" ,
      "evento_datahora" : "2019-02-18 10:30:10" ,
      "evento_tipo" : "POSIÇÃO AUTOMATICA" ,
      "referencia" : "0 metros de TORRA TORRA - LOJA 37 JUNDIAI - SP" ,
      "latitude" : "-23.186685" ,
      "longitude" : "-46.88426333333334" ,
      "distancia" : null ,
      "direcao" : "SUDESTE" ,
      "inicio_previsto" : "18 \ / 02 \ / 2019 08:42:41" ,
      "inicio_real" : "18 \ / 02 \ / 2019 09:24:58" ,
      "chegada_destino_datahora" : "18 \ / 02 \ / 2019 10:29:02" ,
      "saida_destino_datahora" : "" ,
      "tempo_entrega" : "" ,
      "fim_previsto" : "19 \ / 02 \ / 2019 00:00:00" ,
      "fim_real" : "18 \ / 02 \ / 2019 10:29:23" ,
      "tempo_total" : "01:04:25"
    } 
   */       
   
   /* 
    Descrição dos Status de Retorno:
    ================================
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Rascunho – O usuário cadastrou uma viagem, porém algumas informações estão faltando.                                                                                              |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Preenchida  –  O usuário cadastrou uma viagem por completo, ou completou os dados de uma viagem que estava com status de rascunho, nesse estágio o cliente tem a opção de enviar  |
    |                a viagem para a confirmação de sinal.                                                                                                                              |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Agendada  –  Viagem com todos os dados necessários, porém foi enviada para confirmação de sinal com um o veículo associado a outra viagem, sendo assim a viagem permanece nesse   |
    |              status até que a viagem anterior seja finalizada, não há limite no agendamento de viagens.                                                                           |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Confirmação de Sinal  –  Viagem aguardando confirmação de sinal pela tecnologia ou manualmente pelo usuário.                                                                  |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Check List  –  Viagem com o sinal confirmado, porem  expirou o tempo determinado para realização de check-list (configurável na operação).                                    |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Check List Reprovado  –  Viagem com check-list reprovado (no  preenchimento  do check-list foi pontuado que o sensor ou atuador não funciona).                                    |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Aprovação – Viagem com sinal confirmado, aguardando aprovação pelo usuário.                                                                                                   |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Emb. Configuração  –  viagem que a configuração está com a opção de configuração por viagem, aguardando o envio da configuração pelo usuário.                                 |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Escolta  –  Viagem cuja opção de escolta rastreada está selecionada  na aba escolta  e aguarda o  posicionamento do veículo  de escolta  no perímetro (configurável) antes    |
    |                 de passar para o próximo status.                                                                                                                                  |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
    - Ag. Inicio Viagem – Viagem com sinal confirmado, aprovada aguardando o envio da macro de início de viagem.                                                                        |
    |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
   */

End Sequence

Return     

/*
===============================================================================================================================
Função-------------: AOMS118C
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/03/2020
Descrição----------: Permite pesquisar o status de uma viagem informando uma placa, ou nota fiscal, ou Id de uma viagem.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118C()  

//Local _aErroRet := {}, _nI
//Local _oRetJSon, _cMsgErro , _cMsgInt
//Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000003")  
//Local _cDirJSon, _cPesqViagem
Local _aComboBx1, _cComboBx1

//==========================================
//  Login JSon
//==========================================
Private _cUsrMaster    := ""
Private _cSenhaMaster  := ""

//==========================================
//  Variáveis de Cancelamento JSon
//==========================================
Private _cIdViagem   := ""
Private _cCancelar   := "0"
Private _cMotivoCanc := Space(100)  

Private _cPlacaVeic, _cFilNf, _cNrNf, _cSerieNf//, _cIdViagem 
Private _cTipoVeic 

Private _oPlacaVeic, _oFilNf, _oNrNf, _oSId, _oIdViagem

Private _oNrCarga, _cNrCarga, _oFilCarga, _cFilCarga

Begin Sequence        

   _cTitulo := "Pesquisa Status Viagem - Informando Dados para Pesquisa" 
   _nCol1   := 5
   _nCol2   := 80  
   _nCol3   := 120
   _nCol4   := 180  
   _nCol5   := 240
   _nCol6   := 300  
   
   _nLinha  := 20 
   _nOpc    := 0                                            
   _aComboBx1 := {"PLACA DO VEICULO", "NOTA FISCAL", "ID VIAGEM", "FILIAL+NR_CARGA/DOC.CLIENTE"}
   
   _cPlacaVeic := Space(8)
   _cFilNf     := Space(2)
   _cNrNf      := Space(Len(SF2->F2_DOC))
   _cSerieNf   := Space(Len(SF2->F2_SERIE))
   _cIdViagem  := Space(20)
   _cFilCarga  := Space(2)
   _cNrCarga   := Space(6)
   
   _cComboBx1 := _aComboBx1[1]
      
   Define Dialog _oDlgL Title _cTitulo From 00,00 To 360,600 Pixel   
      
      @ _nLinha, _nCol1 Say _oSId	PROMPT "Tipo de Pesquisa" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
      @ _nLinha, _nCol2 ComboBox _cComboBx1	Items _aComboBx1  Valid U_AOMS118Z(_cComboBx1,"COMBOBOX") Size 140, 012 OF _oDlgL PIXEL
      _nLinha += 15
            
      @ _nLinha, _nCol1 Say _oSId	PROMPT "Placa do Veiculo" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oPlacaVeic VAR _cPlacaVeic Picture "@!" SIZE 050, 012 OF _oDlgL  PIXEL
	   _nLinha += 15
	  
	   @ _nLinha, _nCol1 Say _oSId	PROMPT "Filial Nota F." SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oFilNf VAR _cFilNf SIZE 30, 012 OF _oDlgL  PIXEL
	   _nLinha += 15
	  
	   @ _nLinha, _nCol1 Say _oSId	PROMPT "Nr.Nota Fiscal" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oNrNf VAR _cNrNf SIZE 60, 012 OF _oDlgL  PIXEL
	   _nLinha += 15
	  
	   @ _nLinha, _nCol1 Say _oSId	PROMPT "Serie Nota Fisc" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oSerieNf VAR _cSerieNf SIZE 20, 012 OF _oDlgL  PIXEL
	   _nLinha += 15
	  
	   @ _nLinha, _nCol1 Say _oSId	PROMPT "Id.Viagem/Protocolo" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oIdViagem VAR _cIdViagem SIZE 70, 012 OF _oDlgL  PIXEL
	   _nLinha += 15

      @ _nLinha, _nCol1 Say _oSFilCarga PROMPT "Filial da Carga/Doc.Cliente" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oFilCarga VAR _cFilCarga SIZE 30, 012 OF _oDlgL  PIXEL
	   _nLinha += 15
	  
	   @ _nLinha, _nCol1 Say _oSNRCARGA	PROMPT "Nr. da Carga/Doc.Cliente" SIZE 100, 012 OF _oDlgL COLORS 16711680, 16777215	PIXEL
	   @ _nLinha, _nCol2 MSGET _oNrCarga VAR _cNrCarga SIZE 60, 012 OF _oDlgL  PIXEL
	   _nLinha += 25
                            
      _oPlacaVeic:Enable()
      _oFilNf:Disable()
      _oNrNf:Disable()
      _oSerieNf:Disable()
      _oIdViagem:Disable()
      _oFilCarga:Disable()
      _oNrCarga:Disable()
         
      @ _nLinha,050 BUTTON "OK" SIZE 080, 018 PIXEL OF _oDlgL ACTION (If(U_AOMS118Z(_cComboBx1,"OK"),(_nOpc := 1,_oDlgL:End()),))
      @ _nLinha,150 BUTTON "Cancela" SIZE 080, 018 PIXEL OF _oDlgL ACTION (_nOpc := 0,_oDlgL:End()) 
     
   Activate Dialog _oDlgL Centered

   If _nOpc == 0
      U_ITMsg("Rotina de cancelamento de pesquisa de status de viagem cancelada pelo usuário.","Atenção",,1) 
      Break
   EndIf    
             
   //==========================================================================
   // Obtem a senha master da integração com o sistema Krona.
   //==========================================================================
   _cUsrMaster    := U_ItGetMv("ITUSRMASTKR","ITALAC.INTEGRACAO")  // Usuário Master da Integração com o Sistema Krona
   _cSenhaMaster  := U_ItGetMv("ITPSWMASTKR","123456")             // Senha do usuário master da integração com o sistem krona.
                                                   
   If AllTrim(_cComboBx1) == "PLACA DO VEICULO"
      U_AOMS118P("P", _cPlacaVeic)              
      
   ElseIf AllTrim(_cComboBx1) == "NOTA FISCAL" 
      SF2->(DBSetOrder(1))
      SF2->(DBSeek(U_ItKey(_cFilNf,"F2_FILIAL") + U_ItKey(_cNrNf,"F2_DOC") + U_ItKey(_cSerieNf,"F2_SERIE")))
      
      _cPlacaVeic := ""
      
      _cTipoVeic := Posicione("DA3",1,xFilial("DA3")+SF2->F2_VEICUL1,'DA3_I_TPVC')
      
      If _cTipoVeic $ "2/4" // 2=Caminhão / 4=Utilitario
         _cPlacaVeic := Posicione("DA3",1,xFilial("DA3")+SF2->F2_VEICUL1,'DA3_PLACA')
      Else // 1=Carreta; 3=Bi-Trem; 5=Rodo-Trem
         _cPlacaVeic := Posicione("DA3",1,xFilial("DA3")+SF2->F2_VEICUL1,'DA3_I_PLCV')
      EndIf 
      
      If ! ("-" $ _cPlacaVeic) .And. ! (SubStr(_cPlacaVeic,3,1) $ "0123456789") .And.  (SubStr(_cPlacaVeic,4,1) $ "0123456789")
         _cPlacaVeic := SubStr(_cPlacaVeic,1,3) + "-" + SubStr(_cPlacaVeic,4,Len(_cPlacaVeic))
      EndIf
      
      U_AOMS118P("N", _cPlacaVeic)
       
   ElseIf AllTrim(_cComboBx1) == "ID VIAGEM" 
      U_AOMS118P("I", _cIdViagem)

   ElseIf AllTrim(_cComboBx1) == "FILIAL+NR_CARGA/DOC.CLIENTE" 
      U_AOMS118P("D", _cFilCarga+_cNrCarga)

   EndIf 

End Sequence

Return

/*
===============================================================================================================================
Função-------------: AOMS118Z
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/03/2020
Descrição----------: Permite pesquisar o status de uma viagem informando uma placa, ou nota fiscal, ou Id de uma viagem.
Parametros---------: _cOpcao = Opcao selecionada para consulta.
                     _cChamada = Campo / Local da chamada da validação.
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118Z(_cOpcao, _cChamada)  
Local _lRet := .T.

Begin Sequence 

   If _cChamada == "COMBOBOX"   
   
      If AllTrim(_cOpcao) == "PLACA DO VEICULO" 
         _oPlacaVeic:Enable()
         _oFilNf:Disable()
         _oNrNf:Disable()
         _oSerieNf:Disable()
         _oIdViagem:Disable()
         _oFilCarga:Disable()
         _oNrCarga:Disable()
      EndIf
   
      If AllTrim(_cOpcao) == "NOTA FISCAL" 
         _oPlacaVeic:Disable()
         _oFilNf:Enable()
         _oNrNf:Enable()
         _oSerieNf:Enable()
         _oIdViagem:Disable()
         _oFilCarga:Disable()
         _oNrCarga:Disable()
      EndIf
      
      If AllTrim(_cOpcao) == "ID VIAGEM" 
         _oPlacaVeic:Disable()
         _oFilNf:Disable()
         _oNrNf:Disable()
         _oSerieNf:Disable()
         _oIdViagem:Enable()
         _oFilCarga:Disable()
         _oNrCarga:Disable()
      EndIf

      If AllTrim(_cOpcao) == "FILIAL+NR_CARGA/DOC.CLIENTE"
         _oFilCarga:Enable()
         _oNrCarga:Enable()
         _oPlacaVeic:Disable()
         _oFilNf:Disable()
         _oNrNf:Disable()
         _oSerieNf:Disable()
         _oIdViagem:Disable()
      EndIf
       
      Break
   EndIf

   If AllTrim(_cOpcao) == "PLACA DO VEICULO" 
      If Empty(_cPlacaVeic)
         U_ITMsg("O preenchimento da palca do veículo é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf 
   EndIf
   
   If AllTrim(_cOpcao) == "NOTA FISCAL" 
      If Empty(_cFilNf)
         U_ITMsg("O preenchimento da filial da nota fiscal é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf
      
      If Empty(_cNrNf)
         U_ITMsg("O preenchimento do número da nota fiscal é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf
      
      If Empty(_cSerieNf)
         U_ITMsg("O preenchimento da série da nota fiscal é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf
              
      If _lRet
         SF2->(DBSetOrder(1))
         If ! SF2->(DBSeek(U_ItKey(_cFilNf,"F2_FILIAL")+U_ItKey(_cNrNf,"F2_DOC")+U_ItKey(_cSerieNf,"F2_SERIE")))
            U_ITMsg("A nota fiscal informada não foi localizada no cadastro de notas fiscais.","Atenção",,1) 
            _lRet := .F.
         EndIf   
      EndIf
      
   EndIf
      
   If AllTrim(_cOpcao) == "ID VIAGEM" 
      If Empty(_cIdViagem)
         U_ITMsg("O preenchimento do Id da Viagem é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf 
   EndIf
   
   If AllTrim(_cOpcao) == "FILIAL+NR_CARGA/DOC.CLIENTE" 
      If Empty(_cFilCarga)
         U_ITMsg("O preenchimento da filial da carga / doc.cliente é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf
      
      If Empty(_cNrCarga)
         U_ITMsg("O preenchimento do número da carga / doc.cliente é obrigatório.","Atenção",,1) 
         _lRet := .F.
      EndIf
      
   EndIf 



End Sequence

Return _lRet 

/*
===============================================================================================================================
Função-------------: AOMS118F
Autor--------------: Julio de Paula Paz
Data da Criacao----: 07/05/2020
Descrição----------: Permite pesquisar se um CNPJ passado por parâmetro está cadastrado na tabela ZZM.
Parametros---------: _cCnpj = Cnpj a ser consultado na tabela ZZM                     
Retorno------------: _lRet = .T. = Cnpj Cadastrado na tabela ZZM
                             .F. = Cnpj não Cadastrado na tabela ZZM
===============================================================================================================================
*/  
User Function AOMS118F(_cCnpj)  
Local _lRet := .F.
Local _nRegAtu := ZZM->(Recno())

Begin Sequence
   //=============================================================================
   // Tabela ZZM cadastro customizado de filiais Italac. Possui poucos registros.
   // Utilizando While Simples no Lugar de uma Query.
   //=============================================================================
   If Empty(_cCnpj)
      Break
   EndIf 

   ZZM->(DBGoTop())
   While ! ZZM->(Eof())
      If AllTrim(ZZM->ZZM_CGC) == AllTrim(_cCnpj)
         _lRet := .T.
         Exit 
      EndIf 
      ZZM->(DBSkip())
   EndDo


End Sequence 

ZZM->(DBGoTo(_nRegAtu))

Return _lRet 

/*
===============================================================================================================================
Função-------------: AOMS118S
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2018
Descrição----------: Rotina para rodar em Scheduller e para fazer automaticamente as integrações de cargas do Protheus para o 
                     Sistema Krona.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118S()
Local _cQry
Local _nPrcMinCarga//, _nDiasScheKrona
Local _nDiasDescDt, _dDtInicInteg
//Local _cFilInte2

Begin Sequence

   //=============================================================================
   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   //=============================================================================
   RESET ENVIRONMENT
   RpcSetType(3)
   
    //=============================================================================
    // Inicia processamento com base nas filiais do parâmetro.
    //=============================================================================
	u_itconout( '[AOMS118] -  Abrindo o ambiente para filial 01...' )
 
   //===========================================================================================
   // Preparando o ambiente com a filial 01
   //===========================================================================================
   PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01" ; //USER 'Administrador' PASSWORD '' ;
               TABLES 'SC5','SC6',"DAK","DAI","SA2","SA1",'ZP1', "SF2", "SD2", "ZFM" MODULO 'OMS'
    
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
                   
   _cfilial := "01"
      
   cFilAnt := _cfilial 
    
	cUSUARIO := Space(06)+"Administrador  "
	cUserName:= "Schedule"

   U_ItConOut( '[AOMS118] - Iniciando schedule de integração de carga para o sistema Krona. ' )

   _nPrcMinCarga := U_ItGetMv("ITPRCMINCAR",100000) 
   _nDiasDescDt  := U_ItGetMv("ITDIASDESKR",5) 
   _dDtInicInteg := Date() - _nDiasDescDt

   _cQry := " SELECT DISTINCT F2_FILIAL, F2_CARGA "
   _cQry += " FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("DAK") + " DAK "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += " AND F2_EMISSAO >= '" + DToS(_dDtInicInteg) +"' AND DAK_FILIAL = F2_FILIAL "
   _cQry += " AND DAK_COD = F2_CARGA "  // AND DAK_I_PROT = ' ' 
   _cQry += " AND DAK_VALOR >= " + AllTrim(Str(_nPrcMinCarga,16,2))
   _cQry += " AND NOT EXISTS (SELECT 'X' FROM " + RetSqlName("DAI") + " DAI "
   _cQry += "                 WHERE DAI_FILIAL = DAK_FILIAL "
   _cQry += "                       AND DAI_COD= DAK_COD "
   _cQry += "                       AND DAI_NFISCA = ' ' "
   _cQry += "                       AND DAI.D_E_L_E_T_ = ' ' ) "

   If Select("TRBSF2") > 0
         TRBSF2->(DBCloseArea())
   EndIf

   DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "TRBSF2" , .F. , .T. )
   
   DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR 

   TRBSF2->(DBGoTop())
   While ! TRBSF2->(Eof())
      If DAK->(DBSeek(TRBSF2->F2_FILIAL+TRBSF2->F2_CARGA))
         U_AOMS118("S")  // Chama a integração Webservice Krona via Scheduller.
      EndIf 

      TRBSF2->(DBSkip())
   EndDo
/*   
   //===========================================================================================
   // Segunda rotina de integração para o Sistema Krona. Rotina temporária.
   // Integrar as filias do parâmetro IT_FILINT2K (Itapetininga) com cargas abaixo de 100.000.
   //===========================================================================================
   If Select("TRBSF2") > 0
      TRBSF2->(DBCloseArea())
   EndIf
   
   //_cFilInte2 := U_ItGetMv("IT_FILINT2K","9036;") 

   _cQry := " SELECT DISTINCT F2_FILIAL, F2_CARGA "
   _cQry += " FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("DAK") + " DAK "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += " AND F2_EMISSAO >= '" + DToS(_dDtInicInteg) +"' AND DAK_FILIAL = F2_FILIAL "
   _cQry += " AND DAK_COD = F2_CARGA "  // AND DAK_I_PROT = ' ' 
   _cQry += " AND DAK_VALOR < " + AllTrim(Str(_nPrcMinCarga,16,2))
   _cQry += " AND DAK_FILIAL = '90' AND DAK_I_FRDC = '90  ' "
   _cQry += " AND NOT EXISTS (SELECT 'X' FROM " + RetSqlName("DAI") + " DAI "
   _cQry += "                 WHERE DAI_FILIAL = DAK_FILIAL "
   _cQry += "                       AND DAI_COD= DAK_COD "
   _cQry += "                       AND DAI_NFISCA = ' ' "
   _cQry += "                       AND DAI.D_E_L_E_T_ = ' ' ) "

   DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "TRBSF2" , .F. , .T. )
   
   DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR 

   TRBSF2->(DBGoTop())
   While ! TRBSF2->(Eof())
      If DAK->(DBSeek(TRBSF2->F2_FILIAL+TRBSF2->F2_CARGA))
         U_AOMS118("S")  // Chama a integração Webservice Krona via Scheduller.
      EndIf 

      TRBSF2->(DBSkip())
   EndDo
*/  
	u_itconout( '[AOMS118] -  Finalizado schedule de integração de cargas para o sistema Krona. ' )
	
	u_itconout( '[AOMS118] -  Processo finalizado. ' )
 
 End Sequence 

 Return 

/*
===============================================================================================================================
Função-------------: AOMS118D
Autor--------------: Julio de Paula Paz
Data da Criacao----: 26/05/2020
Descrição----------: Calcula o transit time de uma data de um pedido de vendas.
Parametros---------:  _dDtEntrega   = Data de entrega do pedido de vendas.
                      _cFilPedVenda = Filial do pedido de vendas
                      _cNrPedVendas = Numero do pedido de vendas
                      _cCodCliPV    = Código do pedido de vendas
                      _cLojaCliPV   = Loja do cliente do pedido de vendas
                      _cFilCar      = Filial de Carregamento
                      _cOper        = Codigo da Operação
                      _cTPVEN       = Tipo de vendas.
Retorno------------:  _nRet = Retorna o número de dias de transit tima.
===============================================================================================================================
*/  
User Function AOMS118D(_dDtEntrega, _cFilPedVenda, _cNrPedVendas, _cCodCliPV, _cLojaCliPV,_cFilCar,_cOper,_cTPVEN)
Local _nRet := 0

Private aCols, aHeader

Begin Sequence
   //==============================================================================================
   // Análise de transit time
	// Calcula data de faturamento necessária para atender a entrega com base no transit time
	// Prepara aheader e acols para a função omsvldent
   //==============================================================================================
	aHeader := {}
	aAdd(aHeader,{1,"C6_ITEM"})
	aAdd(aHeader,{2,"C6_PRODUTO"})
	aAdd(aHeader,{3,"C6_LOCAL"})

	SC6->(DBSetOrder(1))
	SC6->(DBSeek(_cFilPedVenda + _cNrPedVendas))
	
	aCols := {}
		
	While SC6->(!Eof()) .And. _cFilPedVenda == SC6->C6_FILIAL .And. _cNrPedVendas == SC6->C6_NUM
		
		aAdd(aCols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
		
		SC6->(DBSkip())
			
	EndDo

	_nRet :=  U_OmsVldEnt(_dDtEntrega, _cCodCliPV, _cLojaCliPV, _cFilPedVenda, _cNrPedVendas, 1, ,_cFilCar,_cOper,_cTPVEN) // Carrega dias de transit time

End Sequence 

Return _nRet

/*
===============================================================================================================================
Função-------------: AOMS118R
Autor--------------: Julio de Paula Paz
Data da Criacao----: 21/05/2018
Descrição----------: Rotina para rodar em Scheduller e para fazer automaticamente as integrações de cargas do Protheus 
                     Exclusiva de Itapetininga para o Sistema Krona.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118R()
Local _cQry
Local _nPrcMinCarga//, _nDiasScheKrona
Local _nDiasDescDt, _dDtInicInteg
//Local _cFilInte2

Begin Sequence

   //=============================================================================
   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   //=============================================================================
   RESET ENVIRONMENT
   RpcSetType(3)
   
    //=============================================================================
    // Inicia processamento com base nas filiais do parâmetro.
    //=============================================================================
	u_itconout( '[AOMS118] -  Abrindo o ambiente para filial 01...' )
 
   //===========================================================================================
   // Preparando o ambiente com a filial 01
   //===========================================================================================
   PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01" ; //USER 'Administrador' PASSWORD '' ;
               TABLES 'SC5','SC6',"DAK","DAI","SA2","SA1",'ZP1', "SF2", "SD2", "ZFM" MODULO 'OMS'
    
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
                   
   _cfilial := "01"
      
   cFilAnt := _cfilial 
    
	cUSUARIO := Space(06)+"Administrador  "
	cUserName:= "Schedule"

   U_ItConOut( 'Iniciando schedule de integração de carga para o sistema Krona. ' )

   _nPrcMinCarga := U_ItGetMv("ITPRCMINCAR",100000) 
   _nDiasDescDt  := 2 // U_ItGetMv("ITDIASDESKR",5) // Condiderando 2 dias atrás 
   _dDtInicInteg := Date() - _nDiasDescDt 
   //===========================================================================================
   // Segunda rotina de integração para o Sistema Krona. Rotina temporária.
   // Integrar as filias do parâmetro IT_FILINT2K (Itapetininga) com cargas abaixo de 100.000.
   //===========================================================================================
   If Select("TRBSF2") > 0
      TRBSF2->(DBCloseArea())
   EndIf
   
   //_cFilInte2 := U_ItGetMv("IT_FILINT2K","9036;") 

   _cQry := " SELECT DISTINCT F2_FILIAL, F2_CARGA "
   _cQry += " FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("DAK") + " DAK "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += " AND F2_EMISSAO >= '" + DToS(_dDtInicInteg) +"' AND DAK_FILIAL = F2_FILIAL "
   _cQry += " AND DAK_COD = F2_CARGA "  // AND DAK_I_PROT = ' ' 
   _cQry += " AND DAK_VALOR < " + AllTrim(Str(_nPrcMinCarga,16,2))
   _cQry += " AND DAK_FILIAL = '90' AND DAK_I_FRDC = '90  ' "
   _cQry += " AND NOT EXISTS (SELECT 'X' FROM " + RetSqlName("DAI") + " DAI "
   _cQry += "                 WHERE DAI_FILIAL = DAK_FILIAL "
   _cQry += "                       AND DAI_COD= DAK_COD "
   _cQry += "                       AND DAI_NFISCA = ' ' "
   _cQry += "                       AND DAI.D_E_L_E_T_ = ' ' ) "
   _cQry += " ORDER BY F2_FILIAL, F2_CARGA "

   DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "TRBSF2" , .F. , .T. )
   
   DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR 

   TRBSF2->(DBGoTop())
   While ! TRBSF2->(Eof())
      If DAK->(DBSeek(TRBSF2->F2_FILIAL+TRBSF2->F2_CARGA))
         U_AOMS118("S")  // Chama a integração Webservice Krona via Scheduller.
      EndIf 

      TRBSF2->(DBSkip())
   EndDo
  
	u_itconout( 'Finalizado schedule de integração de cargas para o sistema Krona. ' )
	
 End Sequence 

 Return 

/*
===============================================================================================================================
Função-------------: AOMS118O
Autor--------------: Jonathan Torioni
Data da Criacao----: 30/10/2020
Descrição----------: Rotina para rodar em Scheduller e para fazer automaticamente as integrações de cargas do Protheus.
                     Função cópia da U_AOMS118R mudando somente a query.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS118O()
Local _cQry
Local _nPrcMinCarga//, _nDiasScheKrona
Local _nDiasDescDt, _dDtInicInteg
//Local _cFilInte2

Begin Sequence

   //=============================================================================
   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   //=============================================================================
   RESET ENVIRONMENT
   RpcSetType(3)
   
    //=============================================================================
    // Inicia processamento com base nas filiais do parâmetro.
    //=============================================================================
	u_itconout( 'Abrindo o ambiente para filial 01...' )
 
   //===========================================================================================
   // Preparando o ambiente com a filial 01
   //===========================================================================================
   PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01" ; //USER 'Administrador' PASSWORD '' ;
               TABLES 'SC5','SC6',"DAK","DAI","SA2","SA1",'ZP1', "SF2", "SD2", "ZFM" MODULO 'OMS'
    
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
                   
   _cfilial := "01"
      
   cFilAnt := _cfilial 
    
	//cUSUARIO := Space(06)+"Administrador  "
	//cUserName:= "Schedule"

   U_ItConOut( 'Iniciando schedule de integração de carga para o sistema Krona. ' )

   _nPrcMinCarga := U_ItGetMv("ITPRCMINCAR",100000) 
   _nDiasDescDt  := 2 // U_ItGetMv("ITDIASDESKR",5) // Condiderando 2 dias atrás 
   _dDtInicInteg := Date() - _nDiasDescDt 

   If Select("TRBSF2") > 0
      TRBSF2->(DBCloseArea())
   EndIf

   _cQry := " SELECT DISTINCT F2_FILIAL, F2_CARGA "
   _cQry += " FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("DAK") + " DAK "
   _cQry += " WHERE     SF2.D_E_L_E_T_ = ' ' "
   _cQry += "       AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += "       AND F2_EMISSAO >= '" + DToS(_dDtInicInteg) + "' "
   _cQry += "       AND DAK_FILIAL = F2_FILIAL "
   _cQry += "       AND DAK_COD = F2_CARGA "
   _cQry += "       AND DAK_VALOR < 100000 "
   _cQry += "       AND DAK_FILIAL = '90' "
   _cQry += "       AND DAK_I_PROT = ' ' "
//   _cQry += "       AND F2_CARGA = '248341' "
   _cQry += "       AND NOT EXISTS "
   _cQry += "                  (SELECT 'X' "
   _cQry += "                     FROM " + RetSqlName("DAI") + " DAI "
   _cQry += "                    WHERE     DAI_FILIAL = DAK_FILIAL "
   _cQry += "                          AND DAI_COD = DAK_COD "
   _cQry += "                          AND DAI_NFISCA = ' ' "
   _cQry += "                          AND DAI.D_E_L_E_T_ = ' ') "
   _cQry += "       AND NOT EXISTS "
   _cQry += "                  (SELECT 'x' "
   _cQry += "                     FROM " + RetSqlName("DAI") + " DAI, " + RetSqlName("SD2") + " SD2 "
   _cQry += "                    WHERE     DAI_FILIAL = DAK_FILIAL "
   _cQry += "                          AND DAI_COD = DAK_COD "
   _cQry += "                          AND DAI.D_E_L_E_T_ = ' ' "
   _cQry += "                          AND D2_FILIAL = DAI_FILIAL "
   _cQry += "                          AND D2_SERIE = DAI_SERIE "
   _cQry += "                          AND D2_DOC = DAI_NFISCA "
   _cQry += "                          AND D2_LOCAL IN ('36', '40', '42', '50', '52') "
   _cQry += "                          AND SD2.D_E_L_E_T_ = ' ') "
   _cQry += " ORDER BY F2_FILIAL, F2_CARGA "

   DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "TRBSF2" , .F. , .T. )

   TRBSF2->(DBGoTop())
   nConta:=0
   COUNT TO nConta
   
   DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR 

   TRBSF2->(DBGoTop())
   While ! TRBSF2->(Eof())
      If DAK->(DBSeek(TRBSF2->F2_FILIAL+TRBSF2->F2_CARGA))
         U_AOMS118("S")  // Chama a integração Webservice Krona via Scheduller.
      EndIf 

      TRBSF2->(DBSkip())
   EndDo
  
	u_itconout( 'Finalizado schedule de integração de cargas para o sistema Krona.' )
	
 End Sequence 

 Return 
