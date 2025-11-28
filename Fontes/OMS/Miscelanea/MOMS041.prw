/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |12/03/2024| Chamado 45575. Ajuste para conversão de texto do Assunto do email em padrao UTF8.
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função U_ITEncode por FWHttpEncode
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Jose Gavetti  |26/11/2025| Chamado 51341. __cUserId não deve ter seu conteúdo alterado orientação TOTVS. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MOMS041
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/12/2018
Descrição---------: Rotina responsavel pelo envio de workflow de liberação de clientes bloqueados(Inativo).
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS041

Local _aArea		:= FWGetArea()
Local _lWFHTML		:= .T.
Local _lSolic		:= .F.
Local _lCliBlq		:= .F.

Local _cGetSol		:= Space(100)
Local _oGetSol
Local _oSaySol
Local _oSBtCan
Local _oSBtOk
Local _nOpca		:= 0
Local _CBLQCRE      := .F.
Local nPosicao		:= 0
Private _cHostWF	:= ""
Private _dDtIni		:= ""
Private _LExecSelect   := .T.
Private _oDlg
Private _aAprCredito  := {}
Private _cAprCredito  := ""

_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
_dDtIni		:= DToS(SuperGetMV("IT_WFDTINI",.F.,"26/11/2025"))

_lWFHTML	:= GetMv("MV_WFHTML")

PutMV("MV_WFHTML",.T.)

If SA1->A1_MSBLQL == "1"
	_lCliBlq := .T.
EndIf

//===============================
//Pega os dados dos aprovadores
//===============================
_cQryZY0 := "SELECT * "
_cQryZY0 += "FROM " + RetSqlName("ZY0") + " "
_cQryZY0 += "WHERE ZY0_FILIAL = '" + xFilial("ZY0") + "' "
_cQryZY0 += "  AND ZY0_ATIVO = 'S' "
_cQryZY0 += "  AND D_E_L_E_T_ = ' ' "

If Select("TRBZY0") > 0
   TRBZY0->(DBCloseArea())
EndIf

_cQryZY0 := ChangeQuery(_cQryZY0)
MPSysOpenQuery(_cQryZY0,"TRBZY0")

DBSelectArea("TRBZY0")
TRBZY0->(DBGoTop())

While !TRBZY0->(Eof())  
   If TRBZY0->ZY0_TIPO = 'C'//Solicita Liberação por Crédito
      aAdd(_aAprCredito,{TRBZY0->ZY0_CODUSR,AllTrim(TRBZY0->ZY0_NOMINT),TRBZY0->ZY0_EMAIL})
      _cAprCredito   +=AllTrim(TRBZY0->ZY0_NOMINT)+", "
   EndIf
   
   TRBZY0->(DBSkip())
EndDo

_cAprCredito:= LEFT(_cAprCredito,Len(_cAprCredito)-2)
  
DBSelectArea("TRBZY0")
TRBZY0->(DBCloseArea())

//================================
// Solicita Liberação por Crédito
//================================
If _lCliBlq

	DEFINE MSDIALOG _oDlg TITLE "Solicita Liberação por Cliente Bloqueado" FROM 000, 000  To 090, 500 COLORS 0, 16777215 PIXEL

		@ 005, 004 Say _oSaySol PROMPT "Motivo da Solicitação:" SIZE 055, 007 OF _oDlg COLORS 0, 16777215 PIXEL
		@ 017, 003 MSGET _oGetSol VAR _cGetSol SIZE 242, 010 OF _oDlg PICTURE "@!" COLORS 0, 16777215 PIXEL
		DEFINE SBUTTON _oSBtOk FROM 031, 185 Type 01 OF _oDlg ENABLE ACTION (_nOpca := 1, _oDlg:End())
		DEFINE SBUTTON _oSBtCan FROM 031, 216 Type 02 OF _oDlg ENABLE ACTION (_nOpca := 2, _oDlg:End())

	ACTIVATE MSDIALOG _oDlg CENTERED

	If _nOpca == 1
       nPosicao:=0                                          
       _LExecSelect:=.T.
       For nPosicao:= 1 To Len(_aAprCredito)
  		   FWMsgRun(,{|| U_MOMS041P(_cBlqCre, _lCliBlq, _cGetSol,nPosicao, (nPosicao=Len(_aAprCredito)) )},,"Enviando Solicitação de Lib. Cliente Bloqueado para "+_aAprCredito[nPosicao,2]+"...")
           _LExecSelect:=.F.
       Next
		_lSolic := .T.
	Else
		U_ITMsg('Operação cancelada pelo usuário.',"Atenção",,1)
	EndIf
EndIf

If _lSolic
   U_ITMsg("Sua solicitação foi enviada ao Aprovador com sucesso.","Atenção",,3)
Else
   U_ITMsg("Não há necessidade de solicitação de liberação para este cliente.","Atenção",,1)
EndIf

PutMV("MV_WFHTML",_lWFHTML)

U_ItConOut('MOMS041 - Termino do envio do workflow de liberação de clientes na data: ' + DToC(Date()) + ' - ' + Time())


FWRestArea(_aArea)

Return        

/*
===============================================================================================================================
Programa----------: MOMS041R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/01/2019
Descrição---------: Rotina responsável pela execução do retorno do workflow
Parametros--------: _oProcess - Processo inicializado do workflow
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS041R( _oProcess )

   Local _cFilial		   := Space(2) 
   Local _cNumPV		   := Space(6) 
   Local _cCodCli       := _oProcess:oHtml:RetByName("cCodCli")
   Local _cLojaCli      := _oProcess:oHtml:RetByName("cLojCli")
   Local _cOpcao		   := If("APROVAR" $ Upper(_oProcess:oHtml:RetByName("OPCAO")), "APROVADO", "REJEITADO")//na variavel vem escrito "APROVAR (Aguarde...)"
   Local _cCodSol		   := _oProcess:oHtml:RetByName("cCodSol")
   Local _cObs			   := AllTrim(SubStr(Upper(_oProcess:oHtml:RetByName("CR_OBS")),1,100))
   Local _cArqHtm		   := SubStr(_oProcess:oHtml:RetByName("WFMAILID"),3,Len(_oProcess:oHtml:RetByName("WFMAILID")))
   Local _cTipRet		   := AllTrim(_oProcess:oHtml:RetByName("CTIPOPER"))
   Local _cHtmlMode	   := "\Workflow\htm\Cli_concluido.htm"
   Local _cQryZY0		   := ""
   Local _cCodApr		   := _oProcess:oHtml:RetByName("cCodApr")
   Local _cTipo		   := _cTipRet
   Local _cCliente	   := ""
   Local _lSoAprvador   := .F.
   Local _aAvaliacao    := {}
   Local cMailZY0       := ""
   Local _aOrd          := SaveOrd({"SA1"}) 
   Local _nRegAtu       := SA1->(Recno())
   Local _cAlias        := GetNextAlias()

   _cQryZY0 := "SELECT ZY0_TIPO,ZY0_EMAIL "
   _cQryZY0 += "FROM " + RetSqlName("ZY0") + " "
   _cQryZY0 += "WHERE ZY0_FILIAL = '" + xFilial("ZY0") + "' "
   _cQryZY0 += "  AND ZY0_CODUSR = '" + _cCodApr + "' "
   _cQryZY0 += "  AND ZY0_ATIVO = 'S' "
   _cQryZY0 += "  AND D_E_L_E_T_ = ' ' "

   _cQryZY0 := ChangeQuery(_cQryZY0)
   MPSysOpenQuery(_cQryZY0,_cAlias)

   cMailZY0 := AllTrim((_cAlias)->ZY0_EMAIL)

   SA1->(DBSetOrder(1))
   SA1->(DBSeek(xFilial("SA1")+ U_ItKey(_cCodCli,"A1_COD") + U_ItKey(_cLojaCli,"A1_LOJA") ))

   _cCliente := SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + AllTrim(SA1->A1_NOME) + " - " + AllTrim(SA1->A1_NREDUZ)
   _cCodCli  := SA1->A1_COD
   _cLojaCli := SA1->A1_LOJA

   _lSoAprvador := .F.
   _aAvaliacao  := {}

   //Se o cliente está bloqueado faz o desbloqueio
   If _cOpcao == "APROVADO"                                                        	
      If SA1->A1_MSBLQL == "1"
         SA1->(RecLock("SA1", .F.))
         SA1->A1_MSBLQL := "2"
         SA1->A1_I_ACRED := SA1->A1_I_ACRED +  CHR(13)+CHR(10) + "Desbloqueado via workflow de liberação de cliente  em " + DToC(Date()) + " por " + AllTrim(UsrFullName(IIF(!Empty(_cCodApr), _cCodApr, __cUserId)))
         SA1->(MSUnLock())
      EndIf

      //Se a data do limite de crédito está vencida atualiza até o dia atual
      _npos    := SA1->(Recno())
      _ccodcli := SA1->A1_COD

      SA1->(DBSetOrder(1))
            
      If SA1->(DBSeek(xFilial("SA1")+_ccodcli))
         While SA1->A1_FILIAL == xFilial("SA1") .And. SA1->A1_COD == _ccodcli
            If SA1->A1_VENCLC < Date() 
               SA1->(RecLock("SA1", .F.))
               SA1->A1_VENCLC := Date()
               SA1->A1_I_ACRED := SA1->A1_I_ACRED +  CHR(13)+CHR(10) + "Data de vencimento atualizada via  workflow de liberação de crédito do pedido "
               SA1->A1_I_ACRED := SA1->A1_I_ACRED + SC5->C5_NUM + " em " + DToC(Date()) + " por " + AllTrim(UsrFullName(IIF(!Empty(_cCodApr), _cCodApr, __cUserId))) 
               SA1->(MSUnLock())
            EndIf   
            SA1->(DBSkip())
         EndDo			 
      EndIf      
      SA1->(DBGoTo(_npos))
   EndIf  
      
   (_cAlias)->(DBCloseArea())

   //==================================================
   //Finalize a tarefa anterior para não ficar pendente
   //==================================================
   _oProcess:Finish()

   //========================================================================================
   //Faz a cópia do arquivo de aprovação para .old, e cria o arquivo de processo já concluído
   //========================================================================================
   If File("\workflow\emp01\" + _cArqHtm + ".htm")
      If __CopyFile("\workflow\emp01\" + _cArqHtm + ".htm", "\workflow\emp01\" + _cArqHtm + ".old")
         If __CopyFile(_cHtmlMode, "\workflow\emp01\" + _cArqHtm + ".htm")
            u_itconout("MOMS041 - Cópia de arquivo de conclusão efetuada com sucesso.")
         Else
            u_itconout("MOMS041 - Problema na cópia de arquivo de conclusão.")
         EndIf
      Else
         u_itconout("MOMS041 - Não foi possível renomear o arquivo " + _cArqHtm + ".htm.")
      EndIf
   EndIf

   //=====================================================================
   //Envia e-mail ao Aprovadores e/ou Solicitante com o status do cliente
   //=====================================================================
   U_MOMS41ML(_cFilial, _cNumPV, _cOpcao, _cObs, _cCodApr, _cCodSol, _cTipo, _cCliente, _lSoAprvador, _aAvaliacao, cMailZY0, _cCodCli, _cLojaCli)

   U_ItConOut("MOMS041 - ////////////////////// FIM DA MOMS041R ///////////////////////")

   RestOrd(_aOrd)          
   SA1->(DBGoTo(_nRegAtu))

Return

/*
===============================================================================================================================
Programa----------: MOMS041P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/01/2019
Descrição---------: Rotina responsável por montar o formulário de aprovação e o envio do link gerado. (Liberação Clientes).
Parametros--------: _cAliasSCR - Recebe o alias aberto das aprovações da liberação de clientes bloqueados.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS041P(_cBlqCre, _lCliBlq, _cGetSol,nPosicao,lEnviaEmailSolic)

Static _nValAtraso	:= 0

Local _aArea		:= FWGetArea()
Local _cLogo		
Local _nMCusto		:= 0
Local _cMailApr		:= ""
Local _cCodiApr		:= ""
Local _cNomeApr		:= ""
Local _cMailSol		:= ""
Local _nMCustoCli	:= 0
Local _nLimCred		:= 0
Local _nSalPed 		:= 0
Local _nSalPedL		:= 0
Local _nSalDupM		:= 0
Local _nLcFin		:= 0
Local _nSalFinM		:= 0
Local _nSalDup		:= 0
Local _nSalFin		:= 0
Local _nMoeda		:= 0
Local _cFilial      := SM0->M0_CODFIL
Local _cMailID		:= ""
Local _cTaskID		:= ""
Local _cCodUser   := ""

_cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
_cLogo		:= _cHostWF + "htm/logo_novo.jpg"    

//Codigo do processo cadastrado no CFG
_cCodProce := "LIBCLI" 

// Arquivo html template utilizado para montagem da aprovação
_cHtmlMode := "\Workflow\htm\lib_cliente.htm"

// Assunto da mensagem
_cAssunto := "Solicitação de Desbloqueio do Cliente " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NREDUZ

// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
_oProcess := TWFProcess():New(_cCodProce,"Liberação de Clientes Bloqueados")
_oProcess:NewTask("Liberacao_CLIENTE", _cHtmlMode)

//==========================
//Pega os dados do aprovador
//==========================
_cCodiApr	:= _aAprCredito[nPosicao,1] // TRBZY0->ZY0_CODUSR
_cNomeApr	:= _aAprCredito[nPosicao,2] // AllTrim(TRBZY0->ZY0_NOMINT)
_cMailApr	:= _aAprCredito[nPosicao,3] // AllTrim(UsrRetMail(TRBZY0->ZY0_CODUSR)) + ";" + TRBZY0->ZY0_EMAIL
  
//======================
//Dados do Solicitante
//======================
If Empty(__cUserId) 
   If Type("_cEmailZZL") == "C"
      _cCodUser := _cCodUsuario
   EndIf
EndIf

//======================================
//Dados do cabeçalho dos clientes
//======================================
_oProcess:oHtml:ValByName("cLogo"			, _cLogo			)
_oProcess:oHtml:ValByName("cCodSol"			, IIF(!Empty(_cCodUser), _cCodUser, __cUserId))
_oProcess:oHtml:ValByName("cNomSol"			, AllTrim(UsrFullName(IIF(!Empty(_cCodUser), _cCodUser, __cUserId))))
_oProcess:oHtml:ValByName("cMaiSol"			, AllTrim(UsrRetMail(IIF(!Empty(_cCodUser), _cCodUser, __cUserId))))
_oProcess:oHtml:ValByName("cFilSol"			, SM0->M0_CODFIL + ' - ' + AllTrim(FWFilialName(cEmpAnt,SM0->M0_CODFIL,1)))  
_oProcess:oHtml:ValByName("cCodCli"		   , SA1->A1_COD )        
_oProcess:oHtml:ValByName("cLojCli"	      , SA1->A1_LOJA)        
_oProcess:oHtml:ValByName("cDtAtu"			, DToC(Date()) + " - " + Time())

_oProcess:oHtml:ValByName("cTipOper"		, "CLIENTE"	)             

//==================
//Dados do Aprovador
//==================
_oProcess:oHtml:ValByName("cCodApr"			, _cCodiApr			)
_oProcess:oHtml:ValByName("cNomApr"			, AllTrim(_cNomeApr))

DBSelectArea("SE4")
DBSetOrder(1)
DBSeek(xFilial("SE4") + SA1->A1_COND)
_oProcess:oHtml:ValByName("cCondPgPad"		, SE4->E4_CODIGO + " - " + SE4->E4_DESCRI	)
_oProcess:oHtml:ValByName("cRespPed"		, Posicione("SRA",1,SC5->C5_I_CDUSU,"RA_NOME")	) 

//================
//Dados do Cliente
//================
_oProcess:oHtml:ValByName("cNomCli"			, SA1->A1_NOME				)
_oProcess:oHtml:ValByName("cNomRed"			, SA1->A1_NREDUZ			)
_oProcess:oHtml:ValByName("cCodCli"			, SA1->A1_COD				)
_oProcess:oHtml:ValByName("cLojCli"			, SA1->A1_LOJA				)
_oProcess:oHtml:ValByName("cCnpjCli"		, MOMS041CPF(SA1->A1_CGC)	)
_oProcess:oHtml:ValByName("cGrpVen"			, SA1->A1_GRPVEN + " - " + Posicione("ACY",1,xFilial("ACY") + SA1->A1_GRPVEN, "ACY_DESCRI")				)
_oProcess:oHtml:ValByName("cContatCli"		, SA1->A1_CONTATO			)
_oProcess:oHtml:ValByName("cFoneCli"		, SA1->A1_TEL				)
_oProcess:oHtml:ValByName("cEmailCli"		, SA1->A1_EMAIL				)
_oProcess:oHtml:ValByName("cCidCli"			, SA1->A1_MUN				)
_oProcess:oHtml:ValByName("cEstCli"			, SA1->A1_EST				)
_oProcess:oHtml:ValByName("cEndCli"			, SA1->A1_END				)
_oProcess:oHtml:ValByName("cAnaCre"			, SA1->A1_I_ACRED			)

If SA1->A1_MSBLQL == "2"
	_oProcess:oHtml:ValByName("cBloq"			, "NÃO"			)
ElseIf SA1->A1_MSBLQL == "1"
	_oProcess:oHtml:ValByName("cBloq"			, "SIM"			)
	_oProcess:oHtml:ValByName("cMenBlq"			, " - APROVANDO ESTA LIBERAÇÃO , O CLIENTE SERÁ AUTOMATICAMENTE DESBLOQUEADO."			)
Else
	_oProcess:oHtml:ValByName("cBloq"			, ""			)
EndIf

//========================
//Informarções Financeiras
//========================
_ccodcli := SA1->A1_COD
_ncliente := SA1->(Recno())

_nvalor := Val(SuperGetMv("MV_MCUSTO"))

While SA1->(!Eof()) .And. SA1->A1_COD == _ccodcli 

	_nMCustoCli	:= IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC	, _nvalor )
	_nLimCred	+= xMoeda( SA1->A1_LC							, _nMCustoCli , _nMCusto , Date() )
	_nSalPed 	+= xMoeda( SA1->A1_SALPED + SA1->A1_SALPEDB		, _nMCustoCli , _nMCusto , Date() )
	_nSalPedL	+= xMoeda( SA1->A1_SALPEDL						, _nMCustoCli , _nMCusto , Date() )
	_nSalDupM	+= xMoeda( SA1->A1_SALDUPM						, _nMCustoCli , _nMCusto , Date() )
	_nLcFin		+= xMoeda( SA1->A1_LCFIN						, _nMCustoCli , _nMCusto , Date() )
	_nSalFinM	+= xMoeda( SA1->A1_SALFINM						, _nMCustoCli , _nMCusto , Date() )
	_nSalDup	+= SA1->A1_SALDUP
	_nSalFin	+= SA1->A1_SALFIN
		
	SA1->( DBSkip() )
EndDo

SA1->(DBGoTo(_ncliente))

_nMCusto 	:= IIf( SA1->A1_MOEDALC > 0 , SA1->A1_MOEDALC , Val( SuperGetMv("MV_MCUSTO") ) )
If _lExecSelect
   _nValAtraso	:= MOMS041VSC( SA1->A1_COD ) 
EndIf
_nMoeda		:= 1

_oProcess:oHtml:ValByName("nLimCrd"			, TRansform(_nLimCred,PesqPict("SA1","A1_LC",17,1)))
_oProcess:oHtml:ValByName("nTitAber"		, TRansform(_nSalDup,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nTitVenc"		, TRansform(_nSalPedL,PesqPict("SA1","A1_SALPEDL",17,1)))
_oProcess:oHtml:ValByName("nSLimCrd"		, TRansform(_nLimCred-_nSaldupM-_nSalPedL,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nSalNFat"		, TRansform(_nSalPed ,PesqPict("SA1","A1_SALPED",17,1)))
_oProcess:oHtml:ValByName("nLimCChe"		, TRansform(_nLcFin ,PesqPict("SA1","A1_LCFIN",17,1)))
_oProcess:oHtml:ValByName("nSldChq"			, TRansform(_nSalFin ,PesqPict("SA1","A1_SALDUP",17,1)))
_oProcess:oHtml:ValByName("nTitProt"		, Str(SA1->A1_TITPROT,3))
_oProcess:oHtml:ValByName("nChqDev"			, Str(SA1->A1_CHQDEVO,3))
_oProcess:oHtml:ValByName("nMComp"			, Transform(SA1->A1_MCOMPRA ,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
_oProcess:oHtml:ValByName("nMDuplic"		, Transform(SA1->A1_MAIDUPL ,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
_oProcess:oHtml:ValByName("nMAtras"			, Transform(SA1->A1_METR ,PesqPict("SA1","A1_METR",7)))
_oProcess:oHtml:ValByName("cVenLCr"			, DToC(SA1->A1_VENCLC))
_oProcess:oHtml:ValByName("cDtLiLib"		, DToC(SToD("")))
_oProcess:oHtml:ValByName("nAtraAtu"		, TRansform(_nValAtraso ,PesqPict("SA1","A1_SALDUP",17,1)))

//==================
//Posição do Cliente
//==================
_oProcess:oHtml:ValByName("nLimCrl"			, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",14,_nMCusto)))
_oProcess:oHtml:ValByName("nSldHist"		, TRansform(SA1->A1_SALDUP,PesqPict("SA1","A1_SALDUP",14,1)))
_oProcess:oHtml:ValByName("nLimcSec"		, TRansform(Round(Noround(xMoeda(SA1->A1_LCFIN,_nMcusto,1,dDataBase,MsDecimais(1)+1),2),MsDecimais(1)),PesqPict("SA1","A1_LCFIN",14,1)),TRansform(SA1->A1_LCFIN,PesqPict("SA1","A1_LCFIN",14,_nMcusto)))
_oProcess:oHtml:ValByName("nSldLcSe"		, TRansform(SA1->A1_SALFIN,PesqPict("SA1","A1_SALFIN",14,1)))
_oProcess:oHtml:ValByName("nMaiCom"			, TRansform(Round(Noround(xMoeda(SA1->A1_MCOMPRA, _nMcusto ,1, dDataBase,MsDecimais(1)+1),2),MsDecimais(1)),PesqPict("SA1","A1_MCOMPRA",14,1)),TRansform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",14,_nMcusto)))
_oProcess:oHtml:ValByName("nMaiSld"			, TRansform(Round(Noround(xMoeda(SA1->A1_MSALDO, _nMcusto ,1, dDataBase,MsDecimais(1)+1 ),2),MsDecimais(1)),PesqPict("SA1","A1_MSALDO",14,1)))
_oProcess:oHtml:ValByName("cPriCom"			, DToC(SA1->A1_PRICOM))
_oProcess:oHtml:ValByName("cUltCom"			, DToC(SA1->A1_ULTCOM))
_oProcess:oHtml:ValByName("nMaiAtr"			, Transform(SA1->A1_MATR,PesqPict("SA1","A1_MATR",14)))
_oProcess:oHtml:ValByName("nMedAtr"			, PADC(Str(SA1->A1_METR,7,2),22))
_oProcess:oHtml:ValByName("cGrauRis"		, SA1->A1_RISCO)

If _lExecSelect
   //=================================
   //Informações dos Títulos em Aberto
   //=================================
   cQrySE1 := "SELECT E1_LOJA, E1_FILORIG, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_CLIENTE, E1_EMISSAO, E1_VENCTO, E1_BAIXA, E1_VENCREA, E1_MOEDA, E1_VALOR, E1_VLCRUZ, E1_SDACRES, E1_SDDECRE, E1_VALJUR, E1_MULTA, E1_JUROS, E1_SALDO, E1_NATUREZ, E1_PORTADO, E1_NUMBCO, E1_NUMLIQ, E1_HIST, E1_SITUACA, SE1.R_E_C_N_O_ SE1RECNO "
   cQrySE1 += ", SX5.X5_DESCRI "
   cQrySE1 += "FROM "+RetSqlName("SE1")+" SE1,"
   cQrySE1 +=         RetSqlName("SX5")+" SX5 "
   cQrySE1 += "WHERE SE1.E1_CLIENTE = '"+SA1->A1_COD+"' AND "
   cQrySE1 +=       "SE1.E1_EMISSAO >= ' ' AND "
   cQrySE1 +=       "SE1.E1_EMISSAO <= 'Z' AND "
   cQrySE1 +=       "SE1.E1_VENCREA >= ' ' AND "
   cQrySE1 +=       "SE1.E1_VENCREA <= 'Z' AND "
   cQrySE1 += "SE1.E1_TIPO <> 'PR ' AND "
   cQrySE1 += "SE1.E1_PREFIXO >= '" + Space(TamSX3("E1_PREFIXO")[1]) + "' AND "
   cQrySE1 += "SE1.E1_PREFIXO <= '" + Replicate("Z",TamSX3("E1_PREFIXO")[1]) + "' AND "
   cQrySE1 += "SE1.E1_SALDO > 0 AND "
   cQrySE1 += "SE1.D_E_L_E_T_ = ' ' AND "
   cQrySE1 += "SX5.X5_FILIAL = '" +xFilial("SX5") + "' AND "
   cQrySE1 += "SX5.X5_TABELA = '07' AND "
   cQrySE1 += "SX5.X5_CHAVE = SE1.E1_SITUACA AND "
   cQrySE1 += "SX5.D_E_L_E_T_ = ' ' "

   cQrySE1 += "AND SE1.E1_TIPO NOT LIKE '__-' UNION ALL " + cQrySE1
   cQrySE1 += "AND SE1.E1_TIPO LIKE '__-' "
   cQrySE1 += "ORDER BY E1_CLIENTE,E1_LOJA,E1_PREFIXO,E1_NUM,E1_PARCELA,SE1RECNO"

   If Select("TRBSE1") > 0
      TRBSE1->(DBCloseArea())
   EndIf
   dbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQrySE1 ) , "TRBSE1" , .T., .F. )
EndIf //_lExecSelect

DBSelectArea("TRBSE1")
TRBSE1->(DBGoTop())
If !TRBSE1->(Eof())
	While !TRBSE1->(Eof())
	
		aAdd( _oProcess:oHtml:ValByName("Itens1.FilOrig"	), TRBSE1->E1_FILORIG										)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Pref" 		), TRBSE1->E1_PREFIXO									 	)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Num"		), TRBSE1->E1_NUM											)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Parc"		), TRBSE1->E1_PARCELA										)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Tipo"		), TRBSE1->E1_TIPO											)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Emissao"	), DToC(SToD(TRBSE1->E1_EMISSAO))							)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Vencto"		), DToC(SToD(TRBSE1->E1_VENCTO))							)
		aAdd( _oProcess:oHtml:ValByName("Itens1.VencRea"   	), DToC(SToD(TRBSE1->E1_VENCREA))							)
		aAdd( _oProcess:oHtml:ValByName("Itens1.VlrTit"		), Transform(TRBSE1->E1_VALOR, PesqPict("SE1","E1_VALOR"))	)
		aAdd( _oProcess:oHtml:ValByName("Itens1.SldRec"		), Transform(TRBSE1->E1_SALDO, PesqPict("SE1","E1_SALDO"))	)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Natur"		), TRBSE1->E1_NATUREZ										)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Portad"		), TRBSE1->E1_PORTADO										)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Banco"		), TRBSE1->E1_NUMBCO										)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Hist"   	), AllTrim(TRBSE1->E1_HIST)									)
		aAdd( _oProcess:oHtml:ValByName("Itens1.Atraso"		), Str(dDataBase - SToD(TRBSE1->E1_VENCTO),6)				)
	
		TRBSE1->(DBSkip())
	End
Else
	aAdd( _oProcess:oHtml:ValByName("Itens1.FilOrig"	), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Pref"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Num"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Parc"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Tipo"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Emissao"	), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Vencto"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.VencRea"	), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.VlrTit"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.SldRec"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Natur"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Portad"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Banco"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Hist"		), "" )
	aAdd( _oProcess:oHtml:ValByName("Itens1.Atraso"		), "" )
EndIf

_oProcess:oHtml:ValByName("cGetSol"		, _cGetSol			)
//=========================================================================
// Informe o nome da função de retorno a ser executada quando a mensagem de
// respostas retornar ao Workflow:
//=========================================================================
_oProcess:bReturn := "U_MOMS041R"
		
//========================================================================
// Após ter repassado todas as informacões necessárias para o Workflow,
// execute o método Start() para gerar todo o processo e enviar a mensagem
// ao destinatário.
//========================================================================
_cMailID	:= _oProcess:Start("\workflow\emp01")
_cLink		:= _cMailID

If File("\workflow\emp01\" + _cMailID + ".htm")
	u_itconout("MOMS041 - Arquivo da Task copiado com sucesso.")
EndIf

//====================================
//Codigo do processo cadastrado no CFG
//====================================
_cCodProce := "LIBCLI" 

//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
_oProcess := TWFProcess():New(_cCodProce,"Liberação Cliente Bloqueado")

//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
_oProcess:NewTask("LINK", "\workflow\htm\cliente_link.htm")

_chtmlfile	:= _cLink + ".htm"
_cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(GetMV('MV_WFMLBOX')), "WF7_ENDERE"))
_chtmltexto	:= wfloadfile("\workflow\emp01\" + _chtmlfile )
_chtmltexto	:= StrTran( _chtmltexto, _cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + _chtmlfile, _chtmltexto)

_cLink := _cHostWF + "emp01/" + _cLink + ".htm"

//=====================================
// Populo as variáveis do template html
//=====================================
_oProcess:oHtml:ValByName("cLogo"		, _cLogo)
_oProcess:oHtml:ValByName("A_FILIAL"	, _cFilial + " - " + FWFilialName(cEmpAnt,_cFilial,1))
_oProcess:oHtml:ValByName("cCodCli"	    , SA1->A1_COD)                                                         
_oProcess:oHtml:ValByName("cLojCli"	    , SA1->A1_LOJA)                                                        
_oProcess:oHtml:ValByName("A_LINK"		, _cLink)
_oProcess:oHtml:ValByName("A_CLIENTE"	, SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME)
_oProcess:oHtml:ValByName("A_LIMCRED"	, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",17,1)))
_oProcess:oHtml:ValByName("A_TITPRO"	, Str(SA1->A1_TITPROT,3))
_oProcess:oHtml:ValByName("A_MCOMP"		, Transform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
_oProcess:oHtml:ValByName("A_MDUPL"		, Transform(SA1->A1_MAIDUPL,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
_oProcess:oHtml:ValByName("A_VLCRED"	, DToC(SA1->A1_VENCLC))
_oProcess:oHtml:ValByName("A_DTLIMLB"	, DToC(SToD("")))
_oProcess:oHtml:ValByName("A_PCOMP"		, DToC(SA1->A1_PRICOM))
_oProcess:oHtml:ValByName("A_UCOMP"		, DToC(SA1->A1_ULTCOM))
_oProcess:oHtml:ValByName("A_GRISC"		, SA1->A1_RISCO)
_oProcess:oHtml:ValByName("cGetSol"		, _cGetSol)

//================================================================
// Informamos o destinatário (aprovador) do email contendo o link.  
//================================================================
_oProcess:cTo := _cMailApr

//===============================
// Informamos o assunto do email.  
//===============================
_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

_cMailID	:= _oProcess:fProcessId
_cTaskID	:= _oProcess:fTaskID

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
_oProcess:Start()
			
U_ItConOut("MOMS041 - Email enviado para o aprovador: " + _cMailApr + ", enviado com sucesso! Data: " + DToC(dDataBase) + " hora: " + Time() + " Cliente: " + SA1->A1_COD + " Loja: " + SA1->A1_LOJA + " Nome: " + SA1->A1_NOME)

//==========================================================
//Monta e faz o envio ao solicitante da aprovação de Crédito
//==========================================================

_chtmlfile	:= _cLink + ".htm"
_cMailTo	:= "mailto:" + AllTrim(Posicione("WF7", 1, xFilial("WF7") + AllTrim(GetMV('MV_WFMLBOX')), "WF7_ENDERE"))
_chtmltexto	:= wfloadfile("\workflow\emp01\" + _chtmlfile )
_chtmltexto	:= StrTran( _chtmltexto, _cmailto, "WFHTTPRET.APL" )
wfsavefile("\workflow\emp"+cEmpAnt+"\" + _chtmlfile, _chtmltexto)
_cLink := _cHostWF + "/emp01/" + _cLink + ".htm"

If lEnviaEmailSolic                                                                                                                      
   
   //======================================================================
   // Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
   //======================================================================
   _oProcess := TWFProcess():New("LIBCLI","Liberação de Clientes Bloqueados - Solicitante")
   
   //SC5->(DBGoTo(_nRecnoSC5)) // Ao rodar o comando TWFProcess():New, a tabela SC5 estava sendo desposicionada. Esta instrução reposiciona a tabela SC5.  

   //=================================================================
   // Criamos o link para o arquivo que foi gerado na tarefa anterior.  
   //=================================================================
   _oProcess:NewTask("LINK", "\workflow\htm\cliente_solic.htm")

   //=====================================
   // Populo as variáveis do template html
   //=====================================
   _oProcess:oHtml:ValByName("cLogo"		, _cLogo)
   _oProcess:oHtml:ValByName("A_FILIAL"	    , _cFilial + " - " + FWFilialName(cEmpAnt,_cFilial,1))
   _oProcess:oHtml:ValByName("cCodCli"	    , SA1->A1_COD)                                                  
   _oProcess:oHtml:ValByName("cLojCli"	    , SA1->A1_LOJA)                                                 
   _oProcess:oHtml:ValByName("A_CLIENTE"	, SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME)
   _oProcess:oHtml:ValByName("A_LIMCRED"	, TRansform(SA1->A1_LC,PesqPict("SA1","A1_LC",17,1)))
   _oProcess:oHtml:ValByName("A_TITPRO"	    , Str(SA1->A1_TITPROT,3))
   _oProcess:oHtml:ValByName("A_MCOMP"		, Transform(SA1->A1_MCOMPRA,PesqPict("SA1","A1_MCOMPRA",17,_nMCusto)))
   _oProcess:oHtml:ValByName("A_MDUPL"		, Transform(SA1->A1_MAIDUPL,PesqPict("SA1","A1_MAIDUPL",17,_nMCusto)))
   _oProcess:oHtml:ValByName("A_VLCRED"	    , DToC(SA1->A1_VENCLC))
   _oProcess:oHtml:ValByName("A_DTLIMLB"	, DToC(SToD("")))
   _oProcess:oHtml:ValByName("A_PCOMP"		, DToC(SA1->A1_PRICOM))
   _oProcess:oHtml:ValByName("A_UCOMP"		, DToC(SA1->A1_ULTCOM))
   _oProcess:oHtml:ValByName("A_GRISC"		, SA1->A1_RISCO)
   _oProcess:oHtml:ValByName("cGetSol"		, _cGetSol)
   _oProcess:oHtml:ValByName("Texto01"		, "Aprovadores:")
   _oProcess:oHtml:ValByName("Texto02"		, _cAprCredito)

   //================================================================
   // Informamos o destinatário (aprovador) do email contendo o link.  
   //================================================================
   _cMailSol := AllTrim(UsrRetMail( IIF(!Empty(_cCodUser), _cCodUser, __cUserId)))
   
   If Empty(_cMailSol) 
      If Type("_cEmailZZL") == "C"
         _cMailSol := _cEmailZZL
      EndIf
   EndIf

   _oProcess:cTo := _cMailSol

   //===============================
   // Informamos o assunto do email.  
   //===============================
   _oProcess:cSubject	:= FWHttpEncode(_cAssunto)

   _cMailID	:= _oProcess:fProcessId
   _cTaskID	:= _oProcess:fTaskID

   //=======================================================
   // Iniciamos a tarefa e enviamos o email ao destinatário.
   //=======================================================
   _oProcess:Start()
			
   u_itconout("MOMS041 - Email enviado para o solicitante: " + _cMailSol + ", enviado com sucesso! Data: " + DToC(dDataBase) + " hora: " + Time() + " Cliente: " + SA1->A1_COD + " Loja: " + SA1->A1_LOJA + " Nome: " + SA1->A1_NOME) 

   DBSelectArea("TRBSE1")
   TRBSE1->(DBCloseArea()) 

EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MOMS041CPF
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2016
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function MOMS041CPF(_cCPFCNPJ)

Local _cCampFormat := ""	//Armazena o CPF ou CNPJ formatado
																														   
If Len(AllTrim(_cCPFCNPJ)) == 11			//CPF
	_cCampFormat:=SubStr(_cCPFCNPJ,1,3) + "." + SubStr(_cCPFCNPJ,4,3) + "." + SubStr(_cCPFCNPJ,7,3) + "-" + SubStr(_cCPFCNPJ,10,2) 
Else									//CNPJ
	_cCampFormat:=SubStr(_cCPFCNPJ,1,2)+"."+SubStr(_cCPFCNPJ,3,3)+"."+SubStr(_cCPFCNPJ,6,3)+"/"+SubStr(_cCPFCNPJ,9,4)+"-"+ SubStr(_cCPFCNPJ,13,2)
EndIf
																															
Return(_cCampFormat)

/*
===============================================================================================================================
Programa----------: MOMS041VSC
Autor-------------: Darcio Sporl
Data da Criacao---: 17/02/2014
Descrição---------: Recupera saldo atual em aberto do Cliente.
Parametros--------: cCodCli := codigo do cliente. 
Retorno-----------: nValUso := valor em aberto do cliente.  
===============================================================================================================================
*/
Static Function MOMS041VSC( _cCodCli )

Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ""
Local _nValUso	:= 0

Default _cCodCli	:= ""

//-- Verifica o saldo atual em aberto do Cliente --//
_cQuery := " SELECT "
_cQuery += "     SUM( SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE ) AS VALUSO "
_cQuery += " FROM "+ RetSqlName("SE1") +" SE1 "
_cQuery += " WHERE "
_cQuery += "     SE1.E1_CLIENTE	= '"+ _cCodCli +"' " 
_cQuery += " AND SE1.D_E_L_E_T_	= ' ' "
_cQuery += " AND SE1.E1_TIPO		NOT IN ('RA','NCC') "
_cQuery += " AND SE1.E1_SALDO + SE1.E1_SDACRES - SE1.E1_SDDECRE > 0 "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->(!Eof()) .And. (_cAlias)->VALUSO > 0
	_nValUso := (_cAlias)->VALUSO
EndIf

(_cAlias)->( DBCloseArea() )

Return(_nValUso)

/*
===============================================================================================================================
Programa----------: MOMS41ML
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 07/04/2016
Descrição---------: Função criada para enviar e-mail ao Aprovador e ao Solicitante com o status do Cliente.
Parametros--------: _cFilial	- Filial do  de Vendas
------------------: _cNumPV		- Número do Pedido de Vendas
------------------: _cOpcao		- Status de Aprovação/Rejeição
------------------: _cObs		- Observação da Aprovação/Rejeição
------------------: _cCodApr	- Código do Aprovador
------------------: _cCodSol	- Código do Solicitante
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS41ML(_cFilial, _cNumPV, _cOpcao, _cObs, _cCodApr, _cCodSol, _cTipo, _cCliente, _lSoAprvador, _aAvaliacao, cMailZY0, _cCodCli, _cLojaCli)

Local _cHostWF 	:= SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
Local _cLogo	:= _cHostWF + "htm/logo_novo.jpg"
Local _chtmfile	:= ""
Local oProc	:= Nil

u_itconout("MOMS041 - ********************** INICIO DA MOMS41ML ***********************")

u_itconout("MOMS041 - _cNumPV----: " + _cNumPV)

_chtmfile	:= _cHostWF + "htm/cliente_retorno.htm"
//====================================
// Codigo do processo cadastrado no CFG
//====================================
_cCodProce := "LIBPVCRE"
	
//====================
// Assunto da mensagem
//====================
_cAssunto := 'Retorno da Solicitação de Cliente Bloqueado - ' + _cFilial + " - " + AllTrim(FWFilialName(cEmpAnt, _cFilial,1)) + ' - Cliente ' + _cCliente + ' - ' + '"' + _cOpcao + '"'

//======================================================================
// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
//======================================================================
oProc := TWFProcess():New(_cCodProce,"Liberação de Clientes Bloqueados - Retorno")
	
//=================================================================
// Criamos o link para o arquivo que foi gerado na tarefa anterior.  
//=================================================================
oProc:NewTask("SendMail", "/workflow/htm/cliente_retorno.htm")

//=====================================
// Populo as variáveis do template html
//=====================================
oProc:oHtml:ValByName("cLogo"		, _cLogo)
oProc:oHtml:ValByName("cCodCli"   	, _cCodCli)   
oProc:oHtml:ValByName("cLojCli"	    , _cLojaCli)  
oProc:oHtml:ValByName("A_CLIENTE"	, _cCliente)
oProc:oHtml:ValByName("A_STATUS"	, _cOpcao)
oProc:oHtml:ValByName("A_OBSERV"	, AllTrim(_cObs))
If _lSoAprvador//Quando já foi re/aprovado por outro aprovador
   oProc:oHtml:ValByName("A_TESTE01", "***JÁ FOI EXECUTADO POR OUTRO APROVADOR***")
   oProc:oHtml:ValByName("A_DATA"	, _aAvaliacao[1,1])
   oProc:oHtml:ValByName("A_HORA"	, _aAvaliacao[1,2])
   oProc:oHtml:ValByName("A_APROV"	, _aAvaliacao[1,3])
Else
   oProc:oHtml:ValByName("A_TESTE01", "Foi efetivado")
   oProc:oHtml:ValByName("A_DATA"	, DToC(Date()))
   oProc:oHtml:ValByName("A_HORA"	, Time())
   oProc:oHtml:ValByName("A_APROV"	, Posicione("ZY0",1,xFilial("ZY0") + _cCodApr,"ZY0_NOMINT"))
EndIf

//================================================================
// Informamos o destinatário (aprovador) do email contendo o link.  
//================================================================
oProc:cTo := cMailZY0
U_ItConOut("MOMS041 - Email de retorno enviado para o aprovador: " + oProc:cTo + " com sucesso! Data: " + DToC(dDataBase) + " hora: " + Time() + " Cliente: " + SA1->A1_COD + " Loja: " + SA1->A1_LOJA + "Nome: " + SA1->A1_NOME)

If !_lSoAprvador//Quando já foi re/aprovado por outro aprovador
   oProc:cCc := AllTrim(UsrRetMail(_cCodSol))
   U_ItConOut("MOMS041 - Email de retorno enviado para o solicitante: " + oProc:cCc + " com sucesso! Data: " + DToC(dDataBase) + " hora: " + Time() + " Cliente: " + SA1->A1_COD + " Loja: " + SA1->A1_LOJA + "Nome: " + SA1->A1_NOME)
EndIf
//===============================
// Informamos o assunto do email.  
//===============================
oProc:cSubject	:= FWHttpEncode(_cAssunto)

//===============================================
// Informamos o arquivo a ser atachado no e-mail.
//===============================================
//_oProcess:AttachFile(cConsulta)

_cMailID	:= oProc:fProcessId
_cTaskID	:= oProc:fTaskID

//=======================================================
// Iniciamos a tarefa e enviamos o email ao destinatário.
//=======================================================
oProc:Start()
			
u_itconout("MOMS041 - ********************** FIM DA MOMS41ML ***********************")

Return

/*
===============================================================================================================================
Programa----------: MOMS041Z
Autor-------------: Josué Danich Prestes
Data da Criacao---: 17/05/2017
Descrição---------: Chamada de rotina via tela de pedidos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS041Z

SA1->(DBSetOrder(1))

If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
	U_MOMS041()
Else
	U_ITMsg("Cliente do pedido não localizado","Atenção",,1)
EndIf

Return
