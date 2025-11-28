/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/07/2022| Chamado 40778. Tratamento para Extrato Seco Total (EST).
Lucas Borges  |17/04/2023| Chamado 43593. Corrigida validação de exclusão.
Lucas Borges  |30/09/2025| Chamado 52144. Incluído tratamento para o campo ZLX_PEDANT - Pedágio Antecipado
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"

/*
===============================================================================================================================
Programa----------: AGLT035
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para processamento da Recepção do Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035

Local _oBrowse		:= Nil As Object
Private _aRecnosZLD := {} As Array
Private _nTotVolume := 0 As Numeric
Private _cSalvaForn := "" As Character

//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()

_oBrowse:SetAlias( "ZLX" )
_oBrowse:SetMenuDef( 'AGLT035' )
_oBrowse:SetDescription( "Recepção de Leite de Terceiros" )
_oBrowse:DisableDetails()

_oBrowse:AddLegend( "ZLX_STATUS == '1' "	, "GREEN"	, "Pendente"		)
_oBrowse:AddLegend( "ZLX_STATUS == '2' "	, "YELLOW"	, "Classificada"	)
_oBrowse:AddLegend( "ZLX_STATUS == '3' "	, "RED"		, "Fechada"			)

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para configuração do menu na tela inicial
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef() As Array

Local _aRet	:= {} As Array

ADD OPTION _aRet Title 'Visualizar'		Action 'VIEWDEF.AGLT035'	OPERATION 2 ACCESS 0
ADD OPTION _aRet Title 'Incluir'   		Action 'VIEWDEF.AGLT035'	OPERATION 3 ACCESS 0
ADD OPTION _aRet Title 'Alterar'   		Action 'VIEWDEF.AGLT035'	OPERATION 4 ACCESS 0
ADD OPTION _aRet Title 'Desvincular'	Action 'U_AGLT035D()'		OPERATION 4 ACCESS 0
ADD OPTION _aRet Title 'Classificar'	Action 'U_AGLT035X(1)'		OPERATION 4 ACCESS 0
ADD OPTION _aRet Title 'Estornar Clas.'	Action 'U_AGLT035X(2)'		OPERATION 4 ACCESS 0
ADD OPTION _aRet Title 'Excluir'   		Action 'VIEWDEF.AGLT035'	OPERATION 5 ACCESS 0

Return( _aRet )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para construção do modelo de dados das telas de processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef() As Object

Local _oStruZLX	:= FWFormStruct( 1 , 'ZLX' ) As Object
Local _oModel	:= NIL As Object
Local _aGatAux	:= {} As Array

//====================================================================================================
// Monta a configuração de Gatilhos // FwStruTrigger: ( cDom, cCDom, cRegra, lSeek, cAlias, nOrdem, cChave, cCondic )
//====================================================================================================
_aGatAux := FwStruTrigger( 'ZLX_PRODLT' , 'ZLX_DESCPR'	, 'SB1->B1_DESC'	, .T. , 'SB1' , 1 , 'xFilial("SB1")+M->ZLX_PRODLT'					  		)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_FORNEC' , 'ZLX_NOMFOR'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZLX_FORNEC)'						)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_FORNEC' , 'ZLX_LJFORN'	, 'SA2->A2_LOJA'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->ZLX_FORNEC+AllTrim(M->ZLX_LJFORN)'	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_LJFORN' , 'ZLX_NOMFOR'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZLX_FORNEC+ZLX_LJFORN)'				)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_LJTRAN' , 'ZLX_NOMTRA'	, 'SA2->A2_NREDUZ'	, .T. , 'SA2' , 1 , 'xFilial("SA2")+M->(ZLX_TRANSP+ZLX_LJTRAN)'				)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_TEORAN'	, 'U_AGLT035A(M->ZLX_CODANA,1)' , .F.		  														)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_TEOEST'	, 'U_AGLT035A(M->ZLX_CODANA,2)' , .F.		  														)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )
              											
_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_DATAEN'	, 'ZZX->ZZX_DATA'	, .T. , 'ZZX' , 1 , 'xFilial("ZZX")+M->ZLX_CODANA'							)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_HRENTR'	, 'ZZX->ZZX_HORA' , .F. )
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_PLACA'	, 'ZZX->ZZX_PLACA' , .F. )
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_TRANSP'	, 'ZZX->ZZX_TRANSP' , .F. )
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_LJTRAN'	, 'ZZX->ZZX_LJTRAN' , .F. )
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_VLRCOM'	, 'U_AGLT035C(2,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CODANA'	, 'ZLX_VLRKM'	, 'U_AGLT035C(3,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PLACA'	, 'ZLX_VLRFRT'	, 'U_AGLT035C(1,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F. )
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PLACA'	, 'ZLX_ICMSFR'	, 'U_AGLT035E(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F. )
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//// 'ZLX_PESOCA'
_aGatAux := FwStruTrigger( 'ZLX_PESOCA'	, 'ZLX_PESOLI'	, 'M->( ZLX_PESOCA - ZLX_PESOVA )' , .F.							 					)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PESOCA'	, 'ZLX_VOLREC'	, 'Round( M->ZLX_PESOLI / Posicione("ZZX",1,xFilial("ZZX")+M->ZLX_CODANA,"ZZX_DENSID") , 0 )' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PESOCA'	, 'ZLX_DIFVOL'	, 'M->( ZLX_VOLREC - ZLX_VOLNF )' , .F.													)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PESOCA'	, 'ZLX_BALCAP'	, 'M->ZLX_VOLREC - Val(Posicione("ZZV",2,xFilial("ZZV")+M->(ZLX_TRANSP+ZLX_LJTRAN+ZLX_PLACA),"ZZV_CAPACI"))' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )
////'ZLX_PESOCA'

////'ZLX_MEDVAZ'
_aGatAux := FwStruTrigger( 'ZLX_PESOLI'	, 'ZLX_MEDVAZ'	, 'If(M->ZLX_PESOLI=0,M->ZLX_MEDVAZ,0)' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_MEDVAZ'	, 'ZLX_VOLREC'	, 'M->ZLX_MEDVAZ' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_MEDVAZ'	, 'ZLX_DIFVOL'	, 'M->( ZLX_VOLREC - ZLX_VOLNF )' , .F.													)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_MEDVAZ'	, 'ZLX_BALCAP'	, 'M->ZLX_VOLREC - Val(Posicione("ZZV",2,xFilial("ZZV")+M->(ZLX_TRANSP+ZLX_LJTRAN+ZLX_PLACA),"ZZV_CAPACI"))' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

////'ZLX_MEDVAZ'
_aGatAux := FwStruTrigger( 'ZLX_PESOVA'	, 'ZLX_PESOLI'	, 'M->( ZLX_PESOCA - ZLX_PESOVA )' , .F.							 					)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PESOVA'	, 'ZLX_VOLREC'	, 'Round( M->ZLX_PESOLI / Posicione("ZZX",1,xFilial("ZZX")+M->ZLX_CODANA,"ZZX_DENSID") , 0 )' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PESOVA'	, 'ZLX_DIFVOL'	, 'M->( ZLX_VOLREC - ZLX_VOLNF )' , .F.													)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PESOVA'	, 'ZLX_BALCAP'	, 'M->ZLX_VOLREC - Val(Posicione("ZZV",2,xFilial("ZZV")+M->(ZLX_TRANSP+ZLX_LJTRAN+ZLX_PLACA),"ZZV_CAPACI"))' , .F.	)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_PEDAGI'	, '0' , .F.																				)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_ADCFRT'	, '0' , .F.																				)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_VLRFRT'	, 'U_AGLT035C(1,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_VLRCOM'	, 'U_AGLT035C(2,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_VLRKM'	, 'U_AGLT035C(3,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_ICMSFR'	, 'U_AGLT035E(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,0,0)' , .F.						)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PGFRT'	, 'ZLX_TVLFRT'	, 'U_AGLT035T(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_ADCFRT'	, 'ZLX_VLRFRT'	, 'U_AGLT035C(1,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_ADCFRT'	, 'ZLX_ICMSFR'	, 'U_AGLT035E(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_ADCFRT'	, 'ZLX_TVLFRT'	, 'U_AGLT035T(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PEDAGI'	, 'ZLX_ICMSFR'	, 'U_AGLT035E(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PEDAGI'	, 'ZLX_TVLFRT'	, 'U_AGLT035T(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_VLRFRT'	, 'ZLX_TVLFRT'	, 'U_AGLT035T(M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT,M->ZLX_PEDAGI)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_VLRFRT'	, 'ZLX_VLRCOM'	, 'U_AGLT035C(2,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_VLRFRT'	, 'ZLX_VLRKM'	, 'U_AGLT035C(3,M->ZLX_PLACA,M->ZLX_FORNEC,M->ZLX_LJFORN,M->ZLX_TRANSP,M->ZLX_LJTRAN,M->ZLX_ADCFRT)' , .F.			)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_PRODLT'	, 'ZLX_DESCPR'	, 'Posicione("SB1",1,xFilial("SB1")+M->ZLX_PRODLT,"B1_DESC")' , .F.						)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_VOLNF'	, 'ZLX_DIFVOL'	, 'M->( ZLX_VOLREC - ZLX_VOLNF )' , .F.													)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZLX_CTE'	, 'ZLX_CTE'		, 'U_ITZERESQ( M->ZLX_CTE , "ZLX_CTE" , "ZLXMASTER" )' , .F.							)
_oStruZLX:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_oStruZLX:SetProperty( 'ZLX_VOLNF'   , MODEL_FIELD_WHEN, FWBuildFeature( STRUCT_FEATURE_WHEN, "Empty(M->ZLX_NRONF) .And. Empty(FwFldGet('ZLX_LISTA'))" ) )
_oStruZLX:SetProperty( 'ZLX_FORNEC'  , MODEL_FIELD_WHEN, FWBuildFeature( STRUCT_FEATURE_WHEN, "Empty(M->ZLX_NRONF) .And. Empty(FwFldGet('ZLX_LISTA'))" ) )
_oStruZLX:SetProperty( 'ZLX_LJFORN'  , MODEL_FIELD_WHEN, FWBuildFeature( STRUCT_FEATURE_WHEN, "Empty(M->ZLX_NRONF) .And. Empty(FwFldGet('ZLX_LISTA'))" ) )

_oStruZLX:SetProperty( 'ZLX_VOLNF'   , MODEL_FIELD_VALID, FWBuildFeature( STRUCT_FEATURE_VALID, 'U_AGLT035V(4)' ) )

//====================================================================================================
// Inicializa o Modelo de Dados
//====================================================================================================
_oModel := MpFormModel():New( 'AGLT035Z' ,/*bPre*/, {|_oModel| VALIDCOMIT(_oModel)} /*bPost*/, Nil /*bCommit*/, /*bCancel*/  )

_oModel:AddFields( 'ZLXMASTER' ,, _oStruZLX )
_oModel:SetPrimaryKey( { 'ZLX_FILIAL' , 'ZLX_CODIGO' } )
_oModel:SetDescription( 'Recepção Leite de Terceiros' )

_oModel:SetVldActivate( { |oModel| AGLT035VLD( _oModel ) } )

Return( _oModel )

/*
===============================================================================================================================
Programa----------: AGLT035
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para construção da View para exibição dos componentes
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef() As Object

Local _oStruZLX	:= FWFormStruct( 2 , 'ZLX' ) As Object
Local _oModel	:= FwLoadModel( 'AGLT035' ) As Object
Local _oView	:= FwFormView():New() As Object

//-- Agrupamento dos Campos --//
_oStruZLX:AddGroup( 'GRUPO01' , 'Dados da Recepção'				, '' , 2 )
_oStruZLX:AddGroup( 'GRUPO02' , 'Dados da Análise'				, '' , 2 )
_oStruZLX:AddGroup( 'GRUPO03' , 'Dados do Recebimento/Frete'	, '' , 2 )
_oStruZLX:AddGroup( 'GRUPO04' , 'Dados do Estoque'          	, '' , 2 )

//-- Definicao dos Campos para o Grupo 01 --//
_oStruZLX:SetProperty( 'ZLX_CODIGO'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_TIPOLT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_PRODLT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_DESCPR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_FORNEC'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_LJFORN'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_NOMFOR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_DTENTR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )
_oStruZLX:SetProperty( 'ZLX_STATUS'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO01' )

//-- Definicao dos Campos para o Grupo 02 --//
_oStruZLX:SetProperty( 'ZLX_CODANA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_TEORAN'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_TEOEST'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_DATAEN'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_HRENTR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_PLACA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_TRANSP'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_LJTRAN'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_NOMTRA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_DTSAID'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_HRSAID'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_NRONF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_SERINF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_ESPECI'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_VLRNF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )
_oStruZLX:SetProperty( 'ZLX_ICMSNF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO02' )

//-- Definicao dos Campos para o Grupo 03 --//
_oStruZLX:SetProperty( 'ZLX_PGFRT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PRCPRE'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_DIFPRC'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PRCNF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_VOLNF'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PESOCA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PESOVA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PESOLI'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_VOLREC'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_DIFVOL'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_BALCAP'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_CTE'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_CTESER'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PEDAGI'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_ADCFRT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_VLRFRT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_ICMSFR'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_TVLFRT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_OBS'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_MEDVAZ'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )
_oStruZLX:SetProperty( 'ZLX_PEDANT'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO03' )

//-- Definicao dos Campos para o Grupo 04 --//
_oStruZLX:SetProperty( "ZLX_TICKET"	, MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )//Ticket/Viagem
_oStruZLX:SetProperty( "ZLX_SETOR"  , MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )//Setor        
_oStruZLX:SetProperty( "ZLX_DTESTO"	, MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )//Dt Entr Estoq
_oStruZLX:SetProperty( "ZLX_ORIGEM"	, MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )//Origem Gerada
_oStruZLX:SetProperty( 'ZLX_LISTA'	, MVC_VIEW_GROUP_NUMBER , 'GRUPO04' )

_oView:SetModel( _oModel )
_oView:AddField( 'ZLXVIEW' , _oStruZLX , 'ZLXMASTER')

_oView:CreateHorizontalBox( 'BOX001' , 100 )
_oView:SetOwnerView( 'ZLXVIEW' , 'BOX001' )
_oView:EnableTitleView('ZLXVIEW' , 'Recepção de Leite de Terceiros' )

_oView:AddUserButton( 'Vincular Tickets' , 'Tickets' , {|oView| AGLT35Tickets(oView) } )

Return( _oView )

/*
===============================================================================================================================
Programa----------: AGLT035A
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para retornar a média de Gordura/Extrato Seco Total das análises do Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035A(_cAnalise As Character,_nTipo As Numeric) As Numeric

Local _nRet		:= 0 As Numeric
Local _nQuant	:= 0 As Numeric
Local _nValor	:= 0 As Numeric

DBSelectArea("ZAP")
ZAP->( DBSetOrder(1) )
If ZAP->( DBSeek( xFilial("ZAP") + _cAnalise ) )
    While !ZAP->( Eof() ) .And. ZAP->ZAP_CODIGO == _cAnalise
       _nQuant++
       _nValor += IIf(_nTipo == 1, ZAP->ZAP_GORD, ZAP->ZAP_EST)
    ZAP->( DBSkip() )
    EndDo
    _nRet := Round( _nValor/_nQuant , 2 )
EndIf

Return _nRet

/*
===============================================================================================================================
Programa----------: AGLT035C
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para retornar o valor do frete pela configuração na tabela de frete
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035C(_nOpc As Numeric,_cVeic As Character,_cFornec As Character,_cLojaF As Character,_cTransp As Character,_cLojaT As Character,_nValAdc As Numeric) As Numeric

Local _oModel 		:= FWModelActive() As Object
Local _lCobFrt		:= ( _oModel:GetValue( 'ZLXMASTER' , 'ZLX_PGFRT' ) == "S" ) As Logical
Local _cCapc 		:= "" As Character
Local _nFrete		:= 0 As Numeric

Default _nValAdc	:= 0

If _lCobFrt

	DBSelectArea("ZZV")
	ZZV->( DBSetOrder(1) )
	If ZZV->( DBSeek( xFilial("ZZV") + _cVeic + _cTransp + _cLojaT ) )
		_cCapc := ZZV->ZZV_FXCAPA
		DBSelectArea("ZZT")     
		ZZT->( DBSetOrder(1) )
		If ZZT->( DBSeek( xFilial("ZZT") + _cTransp + _cLojaT + _cCapc ) )
			DBSelectArea("ZZU")
			ZZU->( DBSetOrder(1) )
			If ZZU->( DBSeek( xFilial("ZZU") + _cTransp + _cLojaT + PadR( _cCapc , TamSX3('ZZU_CAPACI')[01] ) + _cFornec + _cLojaF ) )
				If _nOpc == 1
					If ZZU->ZZU_VLRKM <> 0
						_nFrete := Round( ( ZZU->ZZU_VLRKM * ZZU->ZZU_KMFORN ) , 2 )
					ElseIf ZZU->ZZU_VLRCOM <> 0
						_nFrete := ZZU->ZZU_VLRCOM
					EndIf
				ElseIf _nOpc == 2
					_nFrete := ZZU->ZZU_VLRCOM
                    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_VLRCOM' , _nFrete)
				ElseIf _nOpc == 3
					_nFrete := ZZU->ZZU_VLRKM
                    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_VLRKM' , _nFrete)
				EndIf
				_oModel:LoadValue( 'ZLXMASTER' , 'ZLX_PEDANT' , ZZU->ZZU_PEDANT)
			EndIf
		EndIf
	EndIf
EndIf

If _nOpc == 1
	_nFrete += _nValAdc
    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_VLRFRT' , _nFrete )
EndIf

Return _nFrete
              
/*
===============================================================================================================================
Programa----------: AGLT035E
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para retornar o valor de ICMS referente ao Frete
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035E(_cVeic As Character,_cFornec As Character,_cLojaF As Character,_cTransp As Character,_cLojaT As Character,_nValAdc As Numeric,_nValPed As Numeric) As Numeric

Local _oModel 		:= FWModelActive() As Object
Local _lCobFrt		:= ( _oModel:GetValue( 'ZLXMASTER' , 'ZLX_PGFRT' ) == "S" ) As Logical
Local _lIcmPed		:= .F. As Logical
Local _cCapc		:= "" As Character
Local _nFrete		:= 0 As Numeric
Local _nAlqICM		:= 0 As Numeric
Local _nAux			:= 0 As Numeric
Local _nTtFrt		:= 0 As Numeric

If _lCobFrt
	DBSelectArea("ZZV")
	ZZV->( DBSetOrder(1) )
	If ZZV->( DBSeek( xFilial("ZZV") + _cVeic + _cTransp + _cLojaT ) )
		_cCapc := ZZV->ZZV_FXCAPA
		DBSelectArea("ZZT")
		ZZT->( DBSetOrder(1) )
		If ZZT->( DBSeek( xFilial("ZZT") + _cTransp + _cLojaT + _cCapc ) )
			DBSelectArea("ZZU")
			ZZU->( DBSetOrder(1) )
			If ZZU->( DBSeek( xFilial("ZZU") + _cTransp + _cLojaT + PadR( _cCapc , TamSX3('ZZU_CAPACI')[01] ) + _cFornec + _cLojaF ) )
				If ZZU->ZZU_VLRKM <> 0
					_nFrete := Round( ( ZZU->ZZU_VLRKM * ZZU->ZZU_KMFORN ) , 2 )
				ElseIf ZZU->ZZU_VLRCOM <> 0
					_nFrete := ZZU->ZZU_VLRCOM
				EndIf
				_nAlqICM	:= ZZU->ZZU_VLICMS
				_lIcmPed	:= ZZU->ZZU_ICMPED == 'S'
			EndIf
		EndIf
	EndIf
EndIf

_nFrete += _nValAdc + IIf( _lIcmPed , _nValPed , 0 )

If _nFrete > 0 
	_nAux			:= ( 100 - _nAlqICM ) / 100
	_nTtFrt			:= _nFrete / _nAux
	_nAlqICM		:= _nTtFrt - _nFrete
	M->ZLX_TVLFRT	:= _nTtFrt
EndIf

Return( _nAlqICM )

/*
===============================================================================================================================
Programa----------: AGLT035T
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para retornar o valor total do Frete
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035T(_cVeic As Character,_cFornec As Character,_cLojaF As Character,_cTransp As Character,_cLojaT As Character,_nValAdc As Numeric,_nValPed As Numeric) As Numeric

Local _oModel 		:= FWModelActive() As Object
Local _lCobFrt		:= ( _oModel:GetValue( 'ZLXMASTER' , 'ZLX_PGFRT' ) == "S" ) As Logical
Local _cCapc		:= "" As Character
Local _nFrete		:= 0 As Numeric
Local _nAlqICM		:= 0 As Numeric
Local _nAux			:= 0 As Numeric
Local _nTtFrt		:= 0 As Numeric
Local _lIcmPed		:= .F. As Logical

Default _nValAdc	:= 0

If _lCobFrt
	DBSelectArea("ZZV")
	ZZV->( DBSetOrder(1) )
	If ZZV->( DBSeek( xFilial("ZZV") + _cVeic + _cTransp + _cLojaT ) )
		_cCapc := ZZV->ZZV_FXCAPA
		DBSelectArea("ZZT")
		ZZT->( DBSetOrder(1) )
		If ZZT->( DBSeek( xFilial("ZZT") + _cTransp + _cLojaT + _cCapc ) )
			DBSelectArea("ZZU")
			ZZU->( DBSetOrder(1) )
			If ZZU->( DBSeek( xFilial("ZZU") + _cTransp + _cLojaT + PadR( _cCapc , TamSX3('ZZU_CAPACI')[01] ) + _cFornec + _cLojaF ) )
				If ZZU->ZZU_VLRKM <> 0
					_nFrete := Round( ( ZZU->ZZU_VLRKM * ZZU->ZZU_KMFORN ) , 2 )
				ElseIf ZZU->ZZU_VLRCOM <> 0
					_nFrete := ZZU->ZZU_VLRCOM
				EndIf
				_nAlqICM := ZZU->ZZU_VLICMS
				_lIcmPed := ( ZZU->ZZU_ICMPED == 'S' )
			EndIf
		EndIf
	EndIf
EndIf

_nFrete += _nValAdc + IIf( _lIcmPed , _nValPed , 0 )

If _nFrete > 0
	_nAux	:= ( 100 - _nAlqICM ) / 100
	_nTtFrt	:= ( _nFrete / _nAux ) + IIf( _lIcmPed , 0 , _nValPed )
EndIf

Return( _nTtFrt )

/*
===============================================================================================================================
Programa----------: AGLT035G
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para retornar o código do CTE com Zeros à Esquerda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035G() As Character

Local _aArea	:= FWGetArea() As Array
Local _cCte		:= '' As Character

_cCte := StrZero( Val( M->ZLX_CTE ) , 9 )

FWRestArea( _aArea )

Return( _cCte )

/*
===============================================================================================================================
Programa----------: AGLT035H
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para validar o cadastro da Análise do Leite de Terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035H() As Logical

Local _aArea	:= FWGetArea() As Array
Local _lRet		:= .F. As Logical
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
SELECT ZZX_CODIGO
  FROM %Table:ZZX%
 WHERE D_E_L_E_T_ = ' '
   AND ZZX_FILIAL = %xFilial:ZZX%
   AND ZZX_FORNEC = %exp:M->ZLX_FORNEC%
   AND ZZX_LJFORN = %exp:M->ZLX_LJFORN%
   AND ZZX_CODIGO = %exp:M->ZLX_CODANA%
   AND NOT EXISTS (SELECT ZLX.ZLX_CODIGO
          FROM %Table:ZLX% ZLX
         WHERE ZLX.D_E_L_E_T_ = ' '
                 AND ZLX_FILIAL = ZZX_FILIAL
                 AND ZLX.ZLX_CODANA = ZZX_CODIGO)
 ORDER BY ZZX_CODIGO
EndSql

If (_cAlias)->( !Eof() ) .And. (_cAlias)->ZZX_CODIGO == M->ZLX_CODANA
   	_lRet := .T.
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea( _aArea )

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT035F
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para validar os dados de Datas e Horas de Entrada x Saída
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035F() As Logical

Local _lRet		:= .T. As Logical
Local _nHorEnt	:= 0 As Numeric
Local _nHorSai	:= 0 As Numeric

If !Empty(M->ZLX_DTSAID) .And. !Empty(M->ZLX_DATAEN)
	If M->ZLX_DTSAID == M->ZLX_DATAEN
		_nHorEnt := ( Val( SubStr( M->ZLX_HRENTR , 1 , 2 ) ) * 60 ) + Val( SubStr( M->ZLX_HRENTR , 4 , 2 ) )
		_nHorSai := ( Val( SubStr( M->ZLX_HRSAID , 1 , 2 ) ) * 60 ) + Val( SubStr( M->ZLX_HRSAID , 4 , 2 ) )
		If _nHorEnt > _nHorSai
			Help(NIL, NIL, "AGLT03503", NIL, "Hora de saída é inválida com relação à entrada!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Para entrada e saída na mesma data o horário de saída deve ser maior que o de entrada."})
			_lRet := .F.
		EndIf
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: VALIDCOMIT
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para validar os dados na confirmação da tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VALIDCOMIT(oModel As Object) As Logical

Local _nOper		:= oModel:GetOperation() As Numeric //O valor 3 quando e uma inclusao
														//O valor 4 quando e uma alteracao
														//O valor 5 quando e uma exclusao.
Local _oModel		:= oModel:GetModel() As Object
Local _lRet			:= .T. As Logical
Local _lFecha		:= ( _oModel:GetValue( 'ZLXMASTER' , 'ZLX_STATUS' ) == '3' ) As Logical
Local _cCodFor		:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_FORNEC'	) As Character
Local _cLojFor		:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_LJFORN'	) As Character
Local _cCodAna		:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_CODANA'	) As Character
Local _aArea		:= FWGetArea() As Array
Private _cCodigo	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_CODIGO'	) As Character

DBSelectArea('SA2')
SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial('SA2') + _cCodFor + _cLojFor ) )
	If SA2->A2_MSBLQL == '1'
		Help(NIL, NIL, "AGLT03504", NIL, "O Fornecedor informado encontra-se Bloqueado ou Inativo no cadastro do Sistema!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do Fornecedor no Sistema ou os dados informados."})
		_lRet := .F.
	Else
		_lRet := .T.
	EndIf
EndIf

If _lRet
	If _lFecha
		Help(NIL, NIL, "AGLT03505", NIL, "Não será possível confirmar a operação atual!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Essa Recepção de Leite encontra-se com status de Fechamento Realizado."})
		Return( .F. )
	EndIf

	If _nOper == 3 .Or. _nOper == 4
		If !Empty(_oModel:GetValue('ZLXMASTER','ZLX_LISTA')) .And. _nTotVolume # 0 .And. (_oModel:GetValue('ZLXMASTER','ZLX_VOLNF') # _nTotVolume .Or. (_cCodFor+_cLojFor) # _cSalvaForn)
			Help(NIL, NIL, "AGLT03506", NIL, "O Campo Volume NF não pode ser modifiado", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Retire os vinculos com os Tickets para modifica-lo."})
       EndIf

	   	ZZX->( DBSetOrder(1) )
		If ZZX->( DBSeek( xFilial("ZZX") + _cCodAna ) )

			If ZZX->ZZX_FORNEC == _cCodFor .And. ZZX->ZZX_LJFORN == _cLojFor
				RecLock("ZZX",.F.)
		       	ZZX->ZZX_ANAUSE := .T.
		 	    ZZX->(MSUnLock())
				ZZX->(DBCommit())
			Else
				Help(NIL, NIL, "AGLT03507", NIL, "Não será possível confirmar a operação atual!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"A análise de qualidade informada está registrada para outro Fornecedor."})
				Return( .F. )
			EndIf
	    EndIf
	    
	    If _nOper == 4
			DBSelectArea("ZLX")
	   		ZLX->( DBSetOrder(1) )
			If ZLX->( DBSeek( xFilial("ZLX") + _cCodigo ) )
				If ZZX->( DBSeek( xFilial("ZZX") + ZLX->ZLX_CODANA ) ) .And. ZLX->ZLX_CODANA <> _cCodAna
					RecLock("ZZX",.F.)
					ZZX->ZZX_ANAUSE := .F.
			 	    ZZX->( MSUnLock() )
					ZZX->( DBCommit() )
			    EndIf
			EndIf
	    EndIf
	
	ElseIf _nOper == 5
	    DBSelectArea("ZLX")
	   	ZLX->( DBSetOrder(1))
		If ZLX->( DBSeek( xFilial("ZLX") + _cCodigo ) )
			DBSelectArea("ZZX")
	   		ZZX->( DBSetOrder(1) )
			If ZZX->( DBSeek( xFilial("ZZX") + ZLX->ZLX_CODANA ) )
				RecLock("ZZX",.F.)
			    ZZX->ZZX_ANAUSE := .F.
			    ZZX->( MSUnLock() )
				ZZX->( DBCommit() )
		    EndIf
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: F3ZZXLT
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar que monta a tela de consulta dos resultados de Análises de Leite de terceiros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F3ZZXLT() As Logical

Local _oModel	:= FWModelActive() As Object
Local _oBrwAux	:= Nil As Object
Local _lRet		:= .F. As Logical

Local _cTitulo  := 'Consulta - Análises de Leite de Terceiros' As Character
Local _cFornec	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_FORNEC' ) As Character
Local _cLjForn	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_LJFORN' ) As Character
Local _cCodPrd	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_PRODLT' ) As Character
Local _cTipo	:= '' As Character
Local _bView	:= {|| FWExecView( "Análise - ["+ ZZX->ZZX_CODIGO +"]" , "AGLT029" , MODEL_OPERATION_VIEW ,, {||.T.} , {||.T.} ) } As Codeblock

Local _bInc 	:= {|| FWExecView( "Inclusão"                            , "AGLT029" , 3 ,, {||.T.} , {||.T.} ),U_F3QRYZZX(_cFornec, _cLjForn, _cTipo, _cCodPrd),U_AGLT035N() } As Codeblock // 3 - Inserção
Local _bAlt	    := {|| FWExecView( "Alteração - ["+ ZZX->ZZX_CODIGO +"]" , "AGLT029" , 4 ,, {||.T.} , {||.T.} ),U_F3QRYZZX(_cFornec, _cLjForn, _cTipo, _cCodPrd),U_AGLT035N() } As Codeblock // 4 - Atualização
Local _bExc     := {|| FWExecView( "Exclusão  - ["+ ZZX->ZZX_CODIGO +"]" , "AGLT029" , 5 ,, {||.T.} , {||.T.} ),U_F3QRYZZX(_cFornec, _cLjForn, _cTipo, _cCodPrd),U_AGLT035N() } As Codeblock // 5 - Exclusão

Private _aDados := {{"","","","","","","","","","","",""}} As Array
Private _oLbx 	:= Nil As Object

U_F3QRYZZX(_cFornec, _cLjForn, _cTipo, _cCodPrd)

DBSelectArea('ZZX')
ZZX->( DBSetOrder(1) )

//====================================================================================================
// Monta a tela para usuario visualizar consulta
//====================================================================================================
DEFINE MSDIALOG _oBrwAux TITLE _cTitulo FROM 000,000 TO 340,600 PIXEL
	
@ 002,002	LISTBOX		_oLbx		;
			FIELDS		HEADER 'Código','Data','Hora','Fornecedor','Loja','Nome Fantasia','Placa','Transportadora','Loja','Nome Fantasia','Densidade' ;
			SIZE		300,155		;
			OF 			_oBrwAux	;
			PIXEL ON 	DBLCLICK( ZZX->( DBGoTo( _aDados[_oLbx:nAt,12] ) ) , _lRet := .T. , _oBrwAux:End() )

_oLbx:SetArray( _aDados )
_oLbx:bLine := {|| {	_aDados[_oLbx:nAt][01] ,;
						_aDados[_oLbx:nAt][02] ,;
						_aDados[_oLbx:nAt][03] ,;
						_aDados[_oLbx:nAt][04] ,;
						_aDados[_oLbx:nAt][05] ,;
						_aDados[_oLbx:nAt][06] ,;
						_aDados[_oLbx:nAt][07] ,;
						_aDados[_oLbx:nAt][08] ,;
						_aDados[_oLbx:nAt][09] ,;
						_aDados[_oLbx:nAt][10] ,;
						_aDados[_oLbx:nAt][11] ,;
						_aDados[_oLbx:nAt][12] }}

@158,110 BUTTON _oButton PROMPT "Visualizar"	SIZE 029,010 PIXEL OF _oBrwAux ACTION ( ZZX->( DBGoTo( _aDados[_oLbx:nAt,12] ) ) , EVal( _bView )					)
@158,140 BUTTON _oButton PROMPT "Incluir"	    SIZE 029,010 PIXEL OF _oBrwAux ACTION ( ZZX->( DBGoTo( _aDados[_oLbx:nAt,12] ) ) , EVal( _bInc )					)
@158,170 BUTTON _oButton PROMPT "Alterar"	    SIZE 029,010 PIXEL OF _oBrwAux ACTION ( ZZX->( DBGoTo( _aDados[_oLbx:nAt,12] ) ) , EVal( _bAlt )					)
@158,200 BUTTON _oButton PROMPT "Excluir"	    SIZE 029,010 PIXEL OF _oBrwAux ACTION ( ZZX->( DBGoTo( _aDados[_oLbx:nAt,12] ) ) , EVal( _bExc )					)  
@158,230 BUTTON _oButton PROMPT "Confirmar"		SIZE 029,010 PIXEL OF _oBrwAux ACTION ( ZZX->( DBGoTo( _aDados[_oLbx:nAt,12] ) ) , _lRet := .T. , _oBrwAux:End()	)  // @158,240
@158,260 BUTTON _oButton PROMPT "Cancelar"		SIZE 029,010 PIXEL OF _oBrwAux ACTION ( _lRet := .F. , _oBrwAux:End()												)  // @158,270
	
ACTIVATE MSDIALOG _oBrwAux CENTER

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AGLT035P
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para retornar o código do CTE com Zeros à Esquerda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035P(_cCodPrd As Character,_nVlMin As Numeric) As Logical

Local _lRet		:= .T. As Logical
Local _cValMin	:= '' As Character
Local _cValMax	:= '' As Character

DBSelectArea('ZA7')
ZA7->( DBSetOrder(1) )
If ZA7->( DBSeek( xFilial('ZA7') + AllTrim(_cCodPrd) ) )
	If ZA7->ZA7_GORMIN > _nVlMin .Or. _nVlMin > ZA7->ZA7_GORMAX
		_cValMin := AllTrim( Transform( ZA7->ZA7_GORMIN , PesqPict( 'ZA7' , 'ZA7_GORMIN' ) ) )
		_cValMax := AllTrim( Transform( ZA7->ZA7_GORMAX , PesqPict( 'ZA7' , 'ZA7_GORMAX' ) ) )
		Help(NIL, NIL, "AGLT03508", NIL, "O valor cadastrado para o Campo Gordura Mini está fora do range permitido pelo  cadastro do produto na Gestão do Leite!",;
			 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados informados ou o cadastro de regras. Val.Mínimo("+ _cValMin +") Val.Máximo("+ _cValMax +") "})
		_lRet := .F.
	EndIf
Else
	If _nVlMin > 0
		Help(NIL, NIL, "AGLT03509", NIL, "Não foi encontrado o cadastro do Produto na configuração de Produtos da Recepção de Leite de Terceiros!",;
			 1, 0, NIL, NIL, NIL, NIL, NIL, {"Caso o produto não seja relacionado à Recepção de Leite o Campo Gordura Mini não deve ser preenchido."})
		_lRet := .F.
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT035D
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para desvincular uma recepção da Análise de Qualidade
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035D()

Local _aArea	:= FWGetArea() As Array

If ZLX->ZLX_STATUS == '3'
	MsgStop('Não é permitido desvincular uma Análise de uma Recepção que esteja com o Status de "Fechamento Concluído"!',"AGLT03510")
ElseIf ZLX->ZLX_TIPOLT == 'P'
	MsgStop('Não é permitido desvincular uma Análise de uma Recepção do tipo Plataforma',"AGLT03539")	
Else
	If Aviso("AGLT03511","Essa opção irá desvincular a Análise de Qualidade da recepção de Leite de Terceiros. Deseja confirmar o processamento?" , {"Sim","Não"} , 2 ) == 1
		
		Begin Transaction
		
		DBSelectArea('ZZX')
		ZZX->( DBSetOrder(1) )
		If ZZX->( DBSeek( xFilial('ZZX') + ZLX->ZLX_CODANA ) )
			RecLock( 'ZZX' , .F. )
			ZZX->ZZX_ANAUSE := .F.
			ZZX->( MSUnLock() )
			
			RecLock( 'ZLX' , .F. )
			ZLX->ZLX_CODANA := ''
			ZLX->ZLX_STATUS	:= '1'
			ZLX->ZLX_TEORAN	:= 0
			ZLX->ZLX_TEOEST	:= 0
			ZLX->ZLX_DATAEN	:= SToD('')
			ZLX->ZLX_HRENTR	:= ''
			ZLX->ZLX_PLACA	:= ''
			ZLX->ZLX_VLRFRT	:= 0
			ZLX->ZLX_TVLFRT := 0
			ZLX->ZLX_TRANSP	:= ''
			ZLX->ZLX_LJTRAN	:= ''
			ZLX->ZLX_ICMSFR	:= 0
			ZLX->( MSUnLock() )
		Else
			MsgStop("Não será possível desvincular a Análise pois a mesma não foi encontrada! Verifique os dados das Análises para tentar novamente.","AGLT03512")
		EndIf
		
		End Transaction
	EndIf
EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: AGLT035I
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina auxiliar para verificar o cálculo e a aplicação do ICMS ao valor do pedágio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035I(_nOpcao As Numeric,_nValOrg As Numeric,_nValAdc As Numeric,_nValPed As Numeric,_cCodTra As Character,_cLojTra As Character,_cCodFor As Character,_cLojFor As Character,_cPlaca As Character)

Local _nRet		:= 0 As Numeric
Local _cICMPED	:= Posicione('ZZU',2,xFilial('ZZU')+_cCodTra+_cLojTra+_cCodFor+_cLojFor,'ZZU_ICMPED') As Character// Order 2 = ZZU_FILIAL+ZZU_TRANSP+ZZU_LJTRAN+ZZU_FORNEC+ZZU_LJFORN

If _nOpcao == 1 .And. (  Empty(_cICMPED) .Or.  _cICMPED <> "S" )
	_nRet += _nValPed
EndIf

_nRet += U_AGLT035C(_nOpcao, _cPlaca , _cCodFor , _cLojFor , _cCodTra , _cLojTra , _nValAdc )

Return( _nRet )

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para montar o menu da tela principal com as funcionalidades da rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT035VLD(_oModel As Object) As Logical

Local _lRet		:= .T. As Logical
Local _nX		:= 0 As  Numeric
Local _nOper	:= _oModel:GetOperation() As Numeric//O valor 3 quando e uma inclusao;O valor 4 quando e uma alteracao; O valor 5 quando e uma exclusao.
Local _oAux     := _oModel:GetModel('ZLXMASTER') As Object
Local _oStruct  := _oAux:GetStruct() As Object
Local _aFields  := {"ZLX_FORNEC","ZLX_LJFORN","ZLX_DTENTR","ZLX_CODANA","ZLX_DTSAID","ZLX_HRSAID","ZLX_VOLNF","ZLX_PESOCA","ZLX_PESOVA",;
                    "ZLX_CTE"   ,"ZLX_CTESER","ZLX_PEDAGI","ZLX_MEDVAZ"	} As Array

If _nOper <> MODEL_OPERATION_INSERT .And. _nOper <> 1

	If !Empty(ZLX->ZLX_STATUS) .And. ZLX->ZLX_STATUS <> '1'
		Help(NIL, NIL, "AGLT03513", NIL, "O registro atual encontra-se bloqueado!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Para realizar essa operação é necessário estornar o Fechamento e/ou a Classificação."})
		_lRet := .F.
	ElseIf !Empty(ZLX->ZLX_ORIGEM) .And. _nOper = 5 .And. ZLX->ZLX_ORIGEM <> '1'//não pode exluir linhas com origem 2 3 
		Help(NIL, NIL, "AGLT03514", NIL, "A Recepção não pode ser excluida.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Só pode ser excluido pela origem que gerou 2 ou 3 : "+ZLX->ZLX_ORIGEM})
		_lRet := .F.
	ElseIf Empty(ZLX->ZLX_ORIGEM) .And. _nOper = 5  .And. !Empty(ZLX->ZLX_CODANA)//não pode exluir se tiver análise vinculada
		Help(NIL, NIL, "AGLT03540", NIL, "A Recepção não pode ser excluida.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Para excluir a recepção, retire a análise vinculada."})
		_lRet := .F.
	ElseIf !Empty(ZLX->ZLX_ORIGEM) .And. _nOper = 4 .And. ZLX->ZLX_ORIGEM $ '2,3'//Pode alterar somente OBS , Paga Frete , Acréscimos ou Desconto
       //Setores Primários
	   For _nX := 1 To Len(_aFields)
           _oStruct:SetProperty( _aFields[_nX], MODEL_FIELD_WHEN, {||.F.} )
	   Next _nX
	ElseIf !Empty(ZLX->ZLX_LISTA) .And. _nOper = 4 
       //Setores Secundários
       _nTotVolume:=ZLX->ZLX_VOLNF
       _cSalvaForn:=ZLX->ZLX_FORNEC+ZLX->ZLX_LJFORN
	EndIf
Else
	For _nX := 1 To Len(_aFields)
		If !Empty(GetSX3Cache(_aFields[_nX],"X3_WHEN"))
			_oStruct:SetProperty( _aFields[_nX], MODEL_FIELD_WHEN, &("{||"+AllTrim(GetSX3Cache(_aFields[_nX],"X3_WHEN"))+"}") )
		Else
			_oStruct:SetProperty( _aFields[_nX], MODEL_FIELD_WHEN, {|| .T. } )
		EndIf
	Next _nX
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT035X
Autor-------------: Alexandre Villar
Data da Criacao---: 08/12/2014
Descrição---------: Rotina para classificação das recepções
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035X(_nOpca As Numeric)

Local _aCampos	:= {} As Array
Local _aRecep	:= {} As Array
Local _cPerg	:= 'AGLT035X' As Character
Local _cAlias	:= '' As Character
Local _nRegOk	:= 0 As Numeric
Local _nI		:= 0 As Numeric
Local _nSel		:= 0 As Numeric
Local _cCodUsr	:= RetCodUsr() As Character

If _nOpca == 2

	If ZLX->ZLX_STATUS == '2'
	
		RecLock( 'ZLX' , .F. )
		
		ZLX->ZLX_STATUS := '1'
		ZLX->ZLX_USRCLS	:= _cCodUsr
		ZLX->ZLX_DTCLAS	:= Date()
		ZLX->ZLX_HRCLAS	:= Time()
		
		ZLX->( MSUnLock() )
		Help(NIL, NIL, "AGLT03515", NIL, "Estorno da classificação realizado com sucesso!", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	Else
		
	    If Pergunte( _cPerg )
	    
	    	_cAlias := GetNextAlias()
			BeginSql alias _cAlias
				SELECT ZLX_CODIGO, ZLX_TIPOLT, ZLX_PRODLT, ZLX_FORNEC, ZLX_LJFORN, R_E_C_N_O_ REGZLX
				FROM  %Table:ZLX% ZLX
				WHERE D_E_L_E_T_ =' '
				AND ZLX_FILIAL = %xFilial:ZLX%
				AND ZLX.ZLX_STATUS = '2'
				AND ZLX.ZLX_CODIGO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
				ORDER BY ZLX.ZLX_CODIGO
			EndSql			

			While (_cAlias)->( !Eof() )
			
				aAdd( _aRecep , {	.T.																								  		,;
								(_cAlias)->ZLX_CODIGO																				  		,;
								(_cAlias)->ZLX_TIPOLT																				  		,;
								(_cAlias)->ZLX_PRODLT																				  		,;
								AllTrim( Posicione( 'SB1' , 1 , xFilial('SB1') + (_cAlias)->ZLX_PRODLT					, 'B1_DESC' ) )		,;
								(_cAlias)->ZLX_FORNEC																						,;
								(_cAlias)->ZLX_LJFORN																						,;
								AllTrim( Posicione( 'SA2' , 1 , xFilial('SA2') + (_cAlias)->(ZLX_FORNECE + ZLX_LJFORN )	, 'A2_NREDUZ' ) )	,;
								(_cAlias)->REGZLX																							})
			
			(_cAlias)->( DBSkip() )
			EndDo
			
			(_cAlias)->( DBCloseArea() )
			
			If Empty( _aRecep )
				Help(NIL, NIL, "AGLT03516", NIL, "Não foram encontradas recepções classificadas com os parâmetros informados!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados e tente novamente."})
			Else
				If U_ITLISTBOX( 'Recepções para estornar:' , {'[  ]','Código','Tipo','Produto','Descrição','Cód. Fornecedor','Loja Fornecedor','Nome'} , @_aRecep , .T. , 2 , 'Verifique e selecione as recepções para estornar:' )
					
					_nSel := 0
					
					For _nI := 1 To Len( _aRecep )
						
						If _aRecep[_nI][01]
							_nSel++
							_lOk := .T.
							
							DBSelectArea('ZLX')
							ZLX->( DBGoTo( _aRecep[_nI][09] ) )
							RecLock( 'ZLX' , .F. )
								ZLX->ZLX_STATUS := '1'
								ZLX->ZLX_USRCLS	:= _cCodUsr
								ZLX->ZLX_DTCLAS	:= Date()
								ZLX->ZLX_HRCLAS	:= Time()
							ZLX->( MSUnLock() )
						
						EndIf
					
					Next _nI
					
					If _nSel > 0
						Help(NIL, NIL, "AGLT03517", NIL, cValToChar(_nSel) +" recepções estornadas com sucesso!", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
					Else
						Help(NIL, NIL, "AGLT03518", NIL, "As recepções não foram estornadas pois não foi selecionado nenhum registro para processamento.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	
ElseIf _nOpca == 1
	
    Pergunte( _cPerg , .F. )
    MV_PAR01 := ZLX->ZLX_CODIGO
    MV_PAR02 := ZLX->ZLX_CODIGO
    
    If Pergunte( _cPerg )
    
    	_cAlias := GetNextAlias()
		BeginSql alias _cAlias		
			SELECT ZLX_CODIGO, ZLX_TIPOLT, ZLX_PRODLT, ZLX_FORNEC, ZLX_LJFORN, R_E_C_N_O_ REGZLX
			FROM  %Table:ZLX%
			WHERE D_E_L_E_T_ = ' '
			AND ZLX_FILIAL = %xFilial:ZLX%
			AND ZLX_STATUS = '1'
			AND ZLX_CODIGO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			ORDER BY ZLX_CODIGO
		EndSql		

		While (_cAlias)->( !Eof() )
		
			aAdd( _aRecep , {	.T.																										,;
							(_cAlias)->ZLX_CODIGO																						,;
							(_cAlias)->ZLX_TIPOLT																						,;
							(_cAlias)->ZLX_PRODLT																						,;
							AllTrim( Posicione( 'SB1' , 1 , xFilial('SB1') + (_cAlias)->ZLX_PRODLT					, 'B1_DESC' ) )		,;
							(_cAlias)->ZLX_FORNEC																						,;
							(_cAlias)->ZLX_LJFORN																						,;
							AllTrim( Posicione( 'SA2' , 1 , xFilial('SA2') + (_cAlias)->(ZLX_FORNECE + ZLX_LJFORN )	, 'A2_NREDUZ' ) )	,;
							(_cAlias)->REGZLX																					  		})
		
		(_cAlias)->( DBSkip() )
		EndDo
		
		(_cAlias)->( DBCloseArea() )
		
		If Empty( _aRecep )
			Help(NIL, NIL, "AGLT03518", NIL, "Não foram encontradas recepções com os parâmetros informados!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados e tente novamente."})
		Else
			
			If U_ITLISTBOX( 'Recepções para classificar:' , {'[  ]','Código','Tipo','Produto','Descrição','Cód. Fornecedor','Loja Fornecedor','Nome'} , @_aRecep , .T. , 2 , 'Verifique e selecione as recepções para classificar:' )
				
				_nRegOk := 0
				
				For _nI := 1 To Len( _aRecep )
					
					If _aRecep[_nI][01]
						
						_nSel++
						_lOk := .T.
						
						DBSelectArea('ZLX')
						ZLX->( DBGoTo( _aRecep[_nI][09] ) )
						If Empty(ZLX->ZLX_CODANA)
							aAdd( _aCampos , { ZLX->ZLX_CODIGO , 'Cód. Análise'		, 'Não foi informado o código da Análise de Qualidade da Recepção'	} )
							_lOk := .F.
						EndIf
						
						If Empty(ZLX->ZLX_DTSAID)
							aAdd( _aCampos , { ZLX->ZLX_CODIGO , 'Data Saída'		, 'Não foi informada a data de saída do Transportador'				} )
							_lOk := .F.
						EndIf
						
						If Empty(ZLX->ZLX_HRSAID)
							aAdd( _aCampos , { ZLX->ZLX_CODIGO , 'Hora Saída'		, 'Não foi informada a hora de saída do Transportador'				} )
							_lOk := .F.
						EndIf
						
						If Empty(ZLX->ZLX_VOLREC)
							aAdd( _aCampos , { ZLX->ZLX_CODIGO , 'Volume Recebido'	, 'Não foi informado o Volume Recebido'	} )
							_lOk := .F.
						EndIf
						
						If Empty(ZLX->ZLX_VOLNF)
							aAdd( _aCampos , { ZLX->ZLX_CODIGO , 'Volume NF'		, 'Não foi informado o Volume da NF'								} )
							_lOk := .F.
						EndIf
						
						If ZLX->ZLX_PGFRT == "S" .And. ZLX->ZLX_TIPOLT <> "P" .And. ( Empty(ZLX->ZLX_CTE) .Or. Empty(ZLX->ZLX_CTESER) )
							aAdd( _aCampos , { ZLX->ZLX_CODIGO , 'Número CTE'		, 'Número + Série do CTE'						} )
							_lOk := .F.
						EndIf
						
						If _lOk
							
							RecLock( 'ZLX' , .F. )
							
							ZLX->ZLX_STATUS := '2'
							ZLX->ZLX_USRCLS	:= _cCodUsr
							ZLX->ZLX_DTCLAS	:= Date()
							ZLX->ZLX_HRCLAS	:= Time()
							
							ZLX->( MSUnLock() )
							
							_nRegOk++
						
						EndIf
					
					EndIf
				
				Next _nI
				
				If _nRegOk > 0
					If Empty(_aCampos)
						Help(NIL, NIL, "AGLT03520", NIL, "Recepções classificadas com sucesso!", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
					Else
						Help(NIL, NIL, "AGLT03521", NIL, "Existem recepções que não foram classificadas", 1, 0, NIL, NIL, NIL, NIL, NIL, {"É necessário que todos os campos obrigatórios tenham sido informados!"})
						U_ITLISTBOX( 'Campos obrigatórios não preenchidos:' , { ' Recepção ' , ' Nome do Campo ' , ' Descrição ' } , _aCampos,.F.,1,'Verifique o preenchimento dos campos abaixo:')
					EndIf
				Else
					
					If _nSel == 0
						Help(NIL, NIL, "AGLT03522", NIL, "As recepções não foram classificadas! Não foi selecionado nenhum registro para processamento.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
					Else
						If Empty(_aCampos)
							Help(NIL, NIL, "AGLT03523", NIL, "As recepções não foram classificadas!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique os dados e tente novamente!"})
						Else
							Help(NIL, NIL, "AGLT03524", NIL, "As recepções não foram classificadas!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"É necessário que todos os campos obrigatórios tenham sido informados!"})
							U_ITLISTBOX( 'Campos obrigatórios não preenchidos:' , { ' Recepção ' , ' Nome do Campo ' , ' Descrição ' } , _aCampos,.F.,1,'Verifique o preenchimento dos campos abaixo:')
						EndIf
					EndIf
					
				EndIf
			
			EndIf
			
		EndIf
	
	EndIf

Else
	Help(NIL, NIL, "AGLT03525", NIL, "Não é possível realizar essa operação no registro selecionado", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o registro atual e tente novamente."})
EndIf

Return

/*
===============================================================================================================================
Programa--------: AGLT035C
Autor-----------: Alexandre Villar
Data da Criacao-: 08/12/2014
Descrição-------: Rotina para validação da amarração CTE/NF
Parametros------: _cCTE		- Número do CTE
----------------: _cCTESer	- Série do CTE
----------------: _cTransp	- Código do Transportador
----------------: _cLjTran	- Loja do Transportador
----------------: _cNF		- Número da NF
----------------: _cNFSer		- Série da NF
----------------: _cFornec	- Fornecedor da NF
----------------: _cLjForn	- Loja do Fornecedor da NF
Retorno---------: _lRet		- Valida se a amarração está correta
===============================================================================================================================
*/
User Function ALGT035C(_cCodRec As Character,_cCTE As Character,_cCTESer As Character) As Logical

Local _lRet			:= .T. As Logical
Local _cAlias		:= GetNextAlias() As Character

Default _cCodRec	:= ''
Default _cCTE		:= ''
Default _cCTESer	:= ''

If !Empty(_cCodRec) .And. !Empty(_cCTE) .And. !Empty(_cCTESer)
	
	_cCTE := StrZero( Val(_cCTE) , TamSX3("ZLX_CTE")[01] )
	BeginSql alias _cAlias	
		SELECT ZLX_CODIGO
		FROM  %Table:ZLX%
		WHERE D_E_L_E_T_ = ' '
		AND ZLX_FILIAL = %xFilial:ZLX%
		AND ZLX_CODIGO <> %exp:_cCodRec%
		AND ZLX_CTE    =  %exp:_cCTE%
		AND ZLX_CTESER =  %exp:_cCTESer%
	EndSql
	//====================================================================================================
	// Valida apenas se o CTE já foi utilizado em outra recepção.
	//====================================================================================================
	If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->ZLX_CODIGO )
		Help(NIL, NIL, "AGLT03526", NIL, "O CTE + Série informado já foi lançado em outra recepção de leite de terceiros! Recepção: ["+ (_cAlias)->ZLX_CODIGO +"]", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o CTE informado!"})		
		_lRet := .F.
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT035V
Autor-------------: Alexandre Villar
Data da Criacao---: 19/11/2014
Descrição---------: Rotina para validação do código de Fornecedor digitado na tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035V(_nCampo As Numeric) As Logical

Local _aArea	:= FWGetArea() As Array
Local _lRet		:= .T. As Logical
Local _oModel	:= FWModelActive() As Object
Local _cCodFor	:= '' As Character
Local _cLojFor	:= '' As Character

If _nCampo = 3
	_nZLX_MEDVAZ:=_oModel:GetValue( 'ZLXMASTER' , 'ZLX_MEDVAZ' )
	_nZLX_PESOLI:=_oModel:GetValue( 'ZLXMASTER' , 'ZLX_PESOLI' )
	If _nZLX_PESOLI # 0 .And. _nZLX_MEDVAZ # 0 
		Help(NIL, NIL, "AGLT03527", NIL, "Medidor de Vazão não pode ser preenchido", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Zere o campo de Peso Liquido para poder usa-lo."})
		Return .F.
	EndIf
	Return .T.
ElseIf _nCampo = 4
	M->ZLX_VOLNF:=_oModel:GetValue('ZLXMASTER','ZLX_VOLNF')
	If !Empty(_oModel:GetValue('ZLXMASTER','ZLX_LISTA')) .And. _nTotVolume <> 0 .And. (M->ZLX_VOLNF <> _nTotVolume)
		Help(NIL, NIL, "AGLT03528", NIL, "O Campo Volume NF não pode ser modifiado.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Retire os vinculos com os Tickets para modifica-lo."})
		_oModel:LoadValue( 'ZLXMASTER' , 'ZLX_VOLNF' , _nTotVolume)
		M->ZLX_VOLNF:=_nTotVolume
		Return .F.
	EndIf
	Return .T.
ElseIf _nCampo = 1
	_cCodFor	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_FORNEC' )
	_cLojFor	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_LJFORN' )
	M->ZLX_LISTA:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_LISTA'  )
	If !Empty(M->ZLX_LISTA) .And. !Empty(_cSalvaForn) .And. _cCodFor+_cLojFor # _cSalvaForn
		Help(NIL, NIL, "AGLT03529", NIL, "O Fornecedor não pode ser modifiado.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Retire os vinculos com os Tickets para modifica-lo."})
	    Return .F.
	EndIf
ElseIf _nCampo = 2
	_cCodFor	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_TRANSP' )
	_cLojFor	:= _oModel:GetValue( 'ZLXMASTER' , 'ZLX_LJTRAN' )
EndIf

DBSelectArea('SA2')
SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial('SA2') + _cCodFor + AllTrim( _cLojFor ) ) )
	_lRet := .T.
Else
	Help(NIL, NIL, "AGLT03530", NIL, "O Fornecedor digitado não foi encontrado no cadastro de Fornecedores do Sistema!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique o cadastro do Fornecedor no Sistema ou os dados informados."})
	_lRet := .F.
EndIf

FWRestArea( _aArea )

Return _lRet

/*
===============================================================================================================================
Programa----------: F3QRYZZX
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/02/2018
Descrição---------: Roda a query de dados para a cosulta específica F3ZZXLT.
Parametros--------: _cFornec = Codigo do fornecedor
                    _cLjForn = Loja do fornecedor
                    _cTipo   = Tipo de produto
                    _cCodPrd = Código do produto.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F3QRYZZX(_cFornec As Character,_cLjForn As Character,_cTipo As Character,_cCodPrd As Character)

Local _cAlias	:= GetNextAlias() As Character
Local _cFiltro	:="" As Character

_aDados := {}

BeginSql alias _cAlias
	SELECT DISTINCT ZA7_TIPPRD
	FROM %Table:ZA7%
	WHERE D_E_L_E_T_ =' '
	AND ZA7_FILIAL = %xFilial:ZA7%
	AND ZA7_CODPRD = %exp:_cCodPrd%
EndSql

While (_cAlias)->( !Eof() )
	_cTipo += (_cAlias)->ZA7_TIPPRD +';'
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If !Empty(_cTipo)
	_cTipo := SubStr( _cTipo , 1 , Len(_cTipo) - 1 )
EndIf
_cFiltro:= "% AND ZZX.ZZX_CODPRD IN " +FormatIn(_cTipo, ';')+ " %"
_cAlias	:= GetNextAlias()
BeginSql alias _cAlias
	SELECT ZZX.ZZX_CODIGO, ZZX.ZZX_DATA, ZZX.ZZX_HORA, ZZX.ZZX_FORNEC, ZZX.ZZX_LJFORN, A2F.A2_NREDUZ FORNECE,
			ZZX.ZZX_PLACA, ZZX.ZZX_TRANSP, ZZX.ZZX_LJTRAN, A2T.A2_NREDUZ TRANSPO, ZZX.ZZX_DENSID, ZZX.R_E_C_N_O_ REGZZX
		FROM %Table:ZZX% ZZX, %Table:SA2% A2F, %Table:SA2% A2T
		WHERE ZZX.D_E_L_E_T_ = ' '
		AND A2F.D_E_L_E_T_ = ' '
		AND A2T.D_E_L_E_T_ = ' '
		AND ZZX.ZZX_FILIAL = %xFilial:ZZX%
		AND A2F.A2_COD = ZZX.ZZX_FORNEC
		AND A2F.A2_LOJA = ZZX.ZZX_LJFORN
		AND A2T.A2_COD = ZZX.ZZX_TRANSP
		AND A2T.A2_LOJA = ZZX.ZZX_LJTRAN
		AND ZZX.ZZX_FORNEC = %exp:_cFornec%
		AND ZZX.ZZX_LJFORN = %exp:_cLjForn%
		AND NOT EXISTS (SELECT ZLX.ZLX_CODIGO
				FROM %Table:ZLX% ZLX
				WHERE ZLX.D_E_L_E_T_ = ' '
				AND ZZX.ZZX_FILIAL = ZLX.ZLX_FILIAL
				AND ZLX.ZLX_CODANA = ZZX.ZZX_CODIGO)
		%exp:_cFiltro%
		ORDER BY ZZX_CODIGO
EndSql

While (_cAlias)->( !Eof() )

	aAdd( _aDados , {	(_cAlias)->ZZX_CODIGO	,;
					DToC( SToD(	(_cAlias)->ZZX_DATA ) )	,;
					(_cAlias)->ZZX_HORA		,;
					(_cAlias)->ZZX_FORNEC	,;
					(_cAlias)->ZZX_LJFORN	,;
					(_cAlias)->FORNECE		,;
					(_cAlias)->ZZX_PLACA	,;
					(_cAlias)->ZZX_TRANSP	,;
					(_cAlias)->ZZX_LJTRAN	,;
					(_cAlias)->TRANSPO		,;
					(_cAlias)->ZZX_DENSID	,;
					(_cAlias)->REGZZX		})

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Empty(_aDados)
   _aDados   := {{"","","","","","","","","","","",1}}
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT035N()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/02/2018
Descrição---------: Atualizar a tela da cosulta específica F3ZZXLT.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT035N()

_oLbx:SetArray( _aDados )
_oLbx:bLine := {|| { _aDados[_oLbx:nAt][01] ,;
					_aDados[_oLbx:nAt][02] ,;
					_aDados[_oLbx:nAt][03] ,;
					_aDados[_oLbx:nAt][04] ,;
					_aDados[_oLbx:nAt][05] ,;
					_aDados[_oLbx:nAt][06] ,;
					_aDados[_oLbx:nAt][07] ,;
					_aDados[_oLbx:nAt][08] ,;
					_aDados[_oLbx:nAt][09] ,;
					_aDados[_oLbx:nAt][10] ,;
					_aDados[_oLbx:nAt][11] ,;
					_aDados[_oLbx:nAt][12] }}
_oLbx:GoTop()			            
_oLbx:Refresh() 

Return

/*
===============================================================================================================================
Programa----------: AGLT35Tickets(oView)
Autor-------------: Alex Wallauer
Data da Criacao---: 15/02/2018
Descrição---------: Monta Tela para consulta dos Tickets
Parametros--------: oView
Retorno-----------: .T.
===============================================================================================================================
/*/  

Static Function AGLT35Tickets(oView As Object) As Logical

Local _nX			:= 0 As Numeric
Local _cAlias		:= GetNextAlias() As Character
Local _oModel		:= FWModelActive() As Object
Local _nOper		:= _oModel:GetOperation() As Numeric
Local _cPit			:= PesqPict("ZLD","ZLD_TOTBOM") As Character
Local _cFiltro		:= "%" As Character
Local _cSetor		:= "" As Character
Private nTam      	:= Len(ZLD->ZLD_TICKET+ZLD->ZLD_SETOR) As Numeric
Private nMaxSelect	:= 0 As Numeric
Private aCat      	:= {} As Array
Private MvPar     	:= "" As Character
Private cTitulo   	:= "" As Character
Private MvParDef  	:= "" As Character
Private _cViagens 	:= "" As Character

If M->ZLX_ORIGEM $ "2,3"
	Help(NIL, NIL, "AGLT03531", NIL, "Essa Recepção de Leite NÃO tem origem na Recepcao Leite Terceiros MANUAL (1)", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	Return(.F.)
EndIf

If Empty(M->ZLX_FORNEC)
	Help(NIL, NIL, "AGLT03532", NIL, "Preencha o Forncedor + Loja", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	Return(.F.)
EndIf

If !Empty(M->ZLX_LISTA) .And. !Empty(_cSalvaForn) .And. M->ZLX_FORNEC+M->ZLX_LJFORN # _cSalvaForn
	Help(NIL, NIL, "AGLT03533", NIL, "O Fornecedor não pode ser modifiado.", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Retire os vinculos com os Tickets para modifica-lo"})
EndIf

BeginSql alias _cAlias
	SELECT ZL2_COD , ZL2_CRIRT
	FROM %Table:ZL2%
	WHERE D_E_L_E_T_ =' '
	AND ZL2_FILIAL = %xFilial:ZL2%
	AND ZL2_CRIRT = '2' 
	AND ZL2_PLAFOR = %exp:M->ZLX_FORNEC%
	AND ZL2_PLALOJ = %exp:M->ZLX_LJFORN%
EndSql

While (_cAlias)->(!Eof())
   _cSetor+="'"+(_cAlias)->ZL2_COD+"',"
   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

If Empty( _cSetor ) 
	Help(NIL, NIL, "AGLT03534", NIL, "O(s) setor(es)  do Forncedor "+M->ZLX_FORNEC+" / "+M->ZLX_LJFORN+" não é secundario ou o Fornecedor não esta vinculado a nenhum setor.";
		, 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
   DBSelectArea("ZLX")
   Return .F.
EndIf

While  !_nOper  = MODEL_OPERATION_VIEW .And. !_nOper = MODEL_OPERATION_DELETE

   _lOK     := .F.
   _nLinha  := 05
   _nPula   := 15
   _nCol1   := 05
   _nCol2   := _nCol1+100

   DEFINE MSDIALOG _oDlg TITLE "Tickets / Viagens"  FROM 000,000 TO 170,330 PIXEL
   
	@ _nLinha,_nCol1 Say "    DIGITE OS TICKETS SEPERADOS POR VIRGULA:" PIXEL
	_nLinha+=_nPula

	@ _nLinha,_nCol1 GET _cViagens MEMO SIZE 150,040 PIXEL OF _oDlg 
	_nLinha+=_nPula
	_nLinha+=_nPula
	_nLinha+=_nPula

    @_nLinha,_nCol1 Button "CONTINUAR" Size 50,15 Action (_lOK:=.T.,Close(_oDlg)) OF _oDlg PIXEL
    @_nLinha,_nCol2 Button "VOLTAR"    Size 50,15 Action (_lOK:=.F.,Close(_oDlg)) OF _oDlg PIXEL
					
   Activate MSDialog _oDlg Centered

   If !_lOK
      Return .F.
   EndIf

   _cViagens:= AllTrim(_cViagens)
   If Len(_cViagens) >= Len(ZLD->ZLD_TICKET)
      _cViagens:= StrTran(_cViagens,Chr(10),"")
      _cViagens:= StrTran(_cViagens,Chr(13),"")
      _cViagens:= StrTran(_cViagens," ","")
      _cViagens:= StrTran(_cViagens,"/",",")
      _cViagens:= StrTran(_cViagens,";",",")
      _cViagens:= Upper(_cViagens)
   Else
      _cViagens:=""
   EndIf
   Exit

EndDo

_cSetor:=Left(_cSetor,Len(_cSetor)-1)
	    
_cAlias:=GetNextAlias()
            
//Tratamento para carregar variaveis da lista de opcoes
nMaxSelect:= 0
cTitulo   := "Chave - Ticket / Viagem - Dt coleta - Dt Lanc - Setor - Volume "

If Len(_cSetor) > 10
   _cFiltro += "AND ZLD_SETOR IN ("+_cSetor+") "
Else
   _cFiltro += "AND ZLD_SETOR = "+_cSetor
EndIf

If _nOper  = MODEL_OPERATION_VIEW .Or. _nOper = MODEL_OPERATION_DELETE
   _cQuery += "  AND ZLD_CODZLX = '"+M->ZLX_CODIGO+"'  "
ElseIf Empty(_cViagens)
   _cFiltro += "  AND ((ZLD_CODZLX = ' ' AND ZLD_DTCOLE > '"+DToS((DDataBase-40))+"') OR ZLD_CODZLX = '"+M->ZLX_CODIGO+"')  "
Else
   _cFiltro += "  AND ZLD_TICKET IN "+FormatIn(_cViagens,",")
EndIf

If _nOper  = MODEL_OPERATION_VIEW .Or. _nOper = MODEL_OPERATION_DELETE
   _cFiltro += "  ORDER BY  ZLD_TICKET , ZLD_SETOR "
Else
   _cFiltro += "  ORDER BY  ZLD_DTCOLE DESC, ZLD_DTLANC DESC , ZLD_SETOR , ZLD_TICKET "
EndIf
_cFiltro += " %"
BeginSql alias _cAlias
	SELECT DISTINCT ZLD_FILIAL, ZLD_TICKET, ZLD_DTCOLE, ZLD_DTLANC, ZLD_SETOR, ZLD_TOTBOM
	FROM %Table:ZLD% ZLD
	WHERE D_E_L_E_T_ = ' '
	AND ZLD_FILIAL = %xFilial:ZLD%
	AND ZLD_STATUS <> 'F'
	AND ZLD_TOTBOM <> 0
	%exp:_cFiltro%
EndSql

nTamPict := 6

While (_cAlias)->(!Eof())

	MvParDef += (_cAlias)->ZLD_TICKET+(_cAlias)->ZLD_SETOR

    If Len(AllTrim( Trans((_cAlias)->ZLD_TOTBOM,_cPit))) > nTamPict
       nTamPict:=Len(AllTrim( Trans((_cAlias)->ZLD_TOTBOM,_cPit)))
    EndIf

	aAdd(aCat, PadL(AllTrim((_cAlias)->ZLD_TICKET),Len(ZLD->ZLD_TICKET),"0")+" - "+DToC(SToD((_cAlias)->ZLD_DTCOLE))+" - "+;
	           DToC(SToD((_cAlias)->ZLD_DTLANC))+" - "+(_cAlias)->ZLD_SETOR+": "+Right( Trans((_cAlias)->ZLD_TOTBOM,_cPit),nTamPict) )
	           
    If (!Empty(M->ZLX_LISTA) .And. (_cAlias)->ZLD_TICKET $ M->ZLX_LISTA) .Or. !Empty(_cViagens) .Or. _nOper = MODEL_OPERATION_VIEW .Or. _nOper = MODEL_OPERATION_DELETE
        MvPar+= (_cAlias)->ZLD_TICKET+(_cAlias)->ZLD_SETOR
    EndIf
   
   nMaxSelect++
   (_cAlias)->(DBSkip())
   
EndDo
(_cAlias)->( DBCloseArea() )

If nMaxSelect = 0
	If _nOper = MODEL_OPERATION_VIEW .Or. _nOper = MODEL_OPERATION_DELETE
	   Help(NIL, NIL, "AGLT03535", NIL, "Não achou tickets anexo para essa recepção: "+M->ZLX_CODIGO, 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	Else
	   Help(NIL, NIL, "AGLT03536", NIL, "Não achou tickets em aberto para esse Setor(es): "+_cSetor, 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	EndIf
	DBSelectArea("ZLX")
	Return .F.
EndIf

nMaxSelect:= 10

//====================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//====================================================================
If Empty(M->ZLX_LISTA)
   MvPar := M->ZLX_LISTA
EndIf
//=============================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//=============================================================
//Executa funcao que monta tela de opcoes
If F_Opcoes(@MvPar		,; //01 -> Variavel de Retorno
			cTitulo		,; //02 -> Titulo da Coluna com as opcoes
			aCat		,; //03 -> Opcoes de Escolha (Array de Opcoes)
			MvParDef	,; //04 -> String de Opcoes para Retorno
            NIL         ,; //Nao Utilizado
            NIL         ,; //Nao Utilizado
			.F.			,; //07 -> Se a Selecao sera de apenas 1 Elemento por vez
			nTam		,; //08 -> Tamanho da Chave
			nMaxSelect	,; //09 -> Quantidade máxima de registros selecionados ao mesmo tempo
            .T.         ,; //Inclui Botoes para Selecao de Multiplos Itens
            .F.         ,; //Se as opcoes serao montadas a partir de ComboBox de Campo ( X3_CBOX )
            NIL         ,; //Qual o Campo para a Montagem do aOpcoes
            .F.         ,; //Nao Permite a Ordenacao
            .F.         ,; //Nao Permite a Pesquisa    
            .F.         ,; //Forca o Retorno Como Array
            NIL         ); //Consulta F3    
            .And. !_nOper  = MODEL_OPERATION_VIEW .And. !_nOper = MODEL_OPERATION_DELETE


	ZLJ->( DBSetOrder(3) )//ZLJ_FILIAL+ZLJ_VIAGEM+ZLJ_SETOR+ZLJ_TIPPRO+ZLJ_LINROT
	ZLD->( DBSetOrder(5) )//ZLD_FILIAL+ZLD_TICKET+ZLD_SETOR

	M->ZLX_LISTA:= ""
	_nTotVolume := 0
	_aRecnosZLD := {}
	For _nX:= 1 To Len(MvPar) Step nTam
		If !(SubStr(MvPar,_nX,1) $ " |*")
		    _cChave:=SubStr(MvPar,_nX,nTam)
		    _cData:=""
		    If ZLJ->( DBSeek( xFilial() + _cChave ) )
		       _cData:=DToC(ZLJ->ZLJ_DTCRIA)
		    EndIf
		    If ZLD->( DBSeek( xFilial("ZLD")+_cChave ) )
		       While ZLD->(!Eof()) .And. xFilial("ZLD")+_cChave == ZLD->ZLD_FILIAL+ZLD->ZLD_TICKET+ZLD->ZLD_SETOR .And. ZLD->ZLD_TOTBOM = 0
		          ZLD->(DBSkip())
		       EndDo
		       If ZLD->ZLD_TOTBOM <> 0
		          _cData:=If(Empty(_cData),DToC(ZLD->ZLD_DTCOLE),_cData)
		          _cTexto:=ZLD->ZLD_TICKET+" - "+ZLD->ZLD_SETOR+" - "+_cData+ " - Vol.: "+ Right(Trans(ZLD->ZLD_TOTBOM,_cPit),nTamPict)
		          _nTotVolume+=ZLD->ZLD_TOTBOM
		          aAdd(_aRecnosZLD, { ZLD->ZLD_TICKET , ZLD->ZLD_SETOR , ZLD->(RECNO()) } )
		       Else
		          _cTexto:="Sem Volume "+_cChave
		       EndIf
		    Else
		       _cTexto:="Não achou "+_cChave
		    EndIf
			M->ZLX_LISTA  += _cTexto + CHR(13)+CHR(10)
		EndIf
	Next _nX
	ZLJ->( DBSetOrder(1) )
	ZLD->( DBSetOrder(1) )
    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_VOLNF' , _nTotVolume)
    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_LISTA' , M->ZLX_LISTA )
    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_DIFVOL', M->ZLX_VOLREC - _nTotVolume)
    _oModel:LoadValue( 'ZLXMASTER' , 'ZLX_BALCAP', M->ZLX_VOLREC - Val(Posicione("ZZV",2,xFilial("ZZV")+M->(ZLX_TRANSP+ZLX_LJTRAN+ZLX_PLACA),"ZZV_CAPACI"))	)
    _cSalvaForn := M->ZLX_FORNEC+M->ZLX_LJFORN
    _oModel:LMODIFY:=.T.
    _oModel:Activate()
	If _nTotVolume <> 0
	    Help(NIL, NIL, "AGLT03537", NIL, "Tickets / Viagens Selecionadas: " + M->ZLX_LISTA + "Total dos Volumes : "+RIGHT(TRANS(_nTotVolume,_cPit),nTamPict), 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	Else
		_cSalvaForn := ""
	    Help(NIL, NIL, "AGLT03538", NIL, "Foram desmacardos todos os Tickets.", 1, 0, NIL, NIL, NIL, NIL, NIL, {""})
	EndIf
EndIf     

DBSelectArea("ZLX")

Return(.T.)

/*
===============================================================================================================================
Programa----------: AGLT035Z()
Autor-------------: Alex Wallauer
Data da Criacao---: 15/02/2018
Descrição---------: Monta Tela para consulta dos Tickets
Parametros--------: oView
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AGLT035Z() As Logical

Local _aParam	:= ParamIXB As Array
Local _oObj		:= '' As Object
Local _oModel	:= Nil As Object
Local _cIdPonto	:= '' As Character

If _aParam <> NIL

	_oObj	  := _aParam[01]
	_cIdPonto := _aParam[02]
	_oModel   := FWModelActive()
	_nOper	  := _oObj:GetOperation()

	If _cIdPonto == 'MODELPOS'	.And. ( _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE .Or. _nOper == MODEL_OPERATION_DELETE )

	   Private _cCodigo  := _oModel:GetValue( 'ZLXMASTER' , 'ZLX_CODIGO'	)
	   
       FWMsgRun(,{|oProc| AGLT35Grv(oProc,_nOper) },"Aguarde! Aguarde! Aguarde! Aguarde! ","Processando Tickets vinculados..." )
	
	ElseIf _cIdPonto ==  'MODELVLDACTIVE'
       _aRecnosZLD := {}
	EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AGLT035Z()
Autor-------------: Alex Wallauer
Data da Criacao---: 15/02/2018
Descrição---------: Monta Tela para consulta dos Tickets
Parametros--------: oView
Retorno-----------: .T.
===============================================================================================================================
*/  
Static Function AGLT35Grv(oProc As Object,_nOper As Numeric)

Local _nX		:= 0 As Numeric
Local _nRecno	:= 0 As Numeric
Local _aOrd		:= SaveOrd({"ZLD"}) As Array
Local _cFilZLD	:= xFilial("ZLD") As Character

Begin Transaction

If (_nOper = MODEL_OPERATION_UPDATE .And. Len(_aRecnosZLD) > 0) .Or. _nOper == MODEL_OPERATION_DELETE//Se clicou no botao e salvou vai ter recnos
	oproc:cCaption := ("Limpando Tickets vinculados...")
	ProcessMessages()
	ZLD->( DBSetOrder(8) )// ZLD_FILIAL+ZLD_CODZLX
	If ZLD->(DBSeek( _cFilZLD + _cCodigo) )
		While ZLD->(!Eof()) .And. ZLD->ZLD_FILIAL+ZLD->ZLD_CODZLX == _cFilZLD+_cCodigo
			If !Empty(ZLD->ZLD_CODZLX)
				oproc:cCaption := ("Limpando Ticket / Setor: "+ZLD->ZLD_TICKET+" / "+ZLD->ZLD_SETOR)
				ProcessMessages()
				ZLD->(DBSkip())
				_nRecno:=ZLD->(RECNO())
				ZLD->(DBSkip(-1))
				ZLD->(RecLock("ZLD",.F.))
				ZLD->ZLD_CODZLX = ""
				ZLD->(MSUnLock())
				ZLD->(DBGoTo(_nRecno))
			Else
				ZLD->(DBSkip())
			EndIf
		EndDo
	EndIf
EndIf

If _nOper <> MODEL_OPERATION_DELETE .And. Len(_aRecnosZLD) > 0//Se clicou no botao e salvou vai ter recnos
    ZLD->( DBSetOrder(5) )// ZLD_FILIAL+ZLD_TICKET+ZLD_SETOR
    _cMostraViagem:=""
	For _nX := 1 To Len(_aRecnosZLD)
		
		_cChave:=_aRecnosZLD[_nX,1]+_aRecnosZLD[_nX,2]//ZLD_TICKET + ZLD_SETOR
        oproc:cCaption := ("Vinculando Ticket / Setor: "+_aRecnosZLD[_nX,1]+" / "+_aRecnosZLD[_nX,2])
        ProcessMessages()
		
		If ZLD->( DBSeek( _cFilZLD+_cChave ) )//ZLD_TICKET + ZLD_SETOR
			_cMostraViagem+="["+ZLD->ZLD_TICKET+"-"+ZLD->ZLD_SETOR+"], "
			While ZLD->(!Eof()) .And. _cFilZLD+_cChave == ZLD->ZLD_FILIAL+ZLD->ZLD_TICKET+ZLD->ZLD_SETOR
			   If ZLD->ZLD_TOTBOM # 0
				  ZLD->(RecLock("ZLD",.F.))
				  ZLD->ZLD_CODZLX = _cCodigo
				  ZLD->(MSUnLock())
			   EndIf
				ZLD->(DBSkip())
			EndDo
		EndIf
	Next _nX

	If _nOper = MODEL_OPERATION_INSERT .Or. _cCodigo # ZLX->ZLX_CODIGO
	    Help(NIL, NIL, "AGLT03538", NIL, "Recepção Gravada ["+_cCodigo+"] nos Tickets anexados: "+_cMostraViagem+;
	    "Recepção Posicionada: "+ZLX->ZLX_CODIGO+" / Tipo Manutenção: "+AllTrim(Str(_nOper)), 1, 0, NIL, NIL, NIL, NIL, NIL, {"Caso não seja o numero da Recepção que voce entrou para Atualizar entre em contado com a area de TI"})
	EndIf
	
EndIf

End Transaction
_aRecnosZLD := {}//Zera para não levar os recnos para outra recepção
RestOrd(_aOrd,.T.)

Return .T.
