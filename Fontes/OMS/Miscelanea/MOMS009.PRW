/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data    |                              Motivo                      										 
 Lucas Borges     | 11/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
 Jonathan         | 04/03/2020 | Chamado 31910. Foi solicitado que os programas desconsiderassem as origens 'R' e 'F'.
 Julio Paz        | 27/04/2022 | Chamado 38767. Desenvolvimento de rotina para gravação de dados gerenciais de comissão.
 Alex Wallauer    | 26/07/2022 | Chamado 40771. Correcao do Error.log da variavel _cMensagem.
===============================================================================================================================
========================================================================================================================================================================
Analista    - Programador   - Inicio     - Envio      - Chamado - Motivo da Alteração
========================================================================================================================================================================
Jeryy       - Alex Wallauer - 05/06/2025 - 06/06/2025 - 50902   - Ajuste de tela para SmartClient Web.
==============================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch" 
#Include "FWMVCDEF.CH"
#Include "TOPCONN.CH"
#Include "RWMAKE.CH"    
#define	MB_OK							0
#define 	MB_ICONEXCLAMATION          48
#define   	MB_ICONASTERISK				64
/*
===============================================================================================================================
Programa----------: MOMS009
Autor-------------: Josué Danich Prestes
Data da Criacao---: 17/12/2015
===============================================================================================================================
Descrição---------: Gestão de fechamento de comissões (Chamado 11158)
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS009()

Local _oBrowse
Local _aArea 	:= ZC9->(GetArea())

Private _oFont12b                      

Define Font _oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito   

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias( 'ZC9' )
_oBrowse:SetDescription( 'Gestão de Fechamento de Comissão' )
_oBrowse:DisableDetails()

//define legendas
_oBrowse:AddLegend( "AllTrim(ZC9_STATUS)=='0'" ,   "GREEN"    , "Aberto"  )
_oBrowse:AddLegend( "AllTrim(ZC9_STATUS)=='1'" ,   "YELLOW"   , "Em fechamento"  )
_oBrowse:AddLegend( "AllTrim(ZC9_STATUS)=='2'" ,   "RED"      , "Fechado" )   
_oBrowse:AddLegend( "AllTrim(ZC9_STATUS)=='3'" ,   "ORANGE"   , "Aguardando Integração" )
_oBrowse:AddLegend( "AllTrim(ZC9_STATUS)=='4'" ,   "BLUE"     , "Integrado com Sucesso" )

_oBrowse:Activate()

FWRestArea(_aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: MENUDEF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31-07-2015
===============================================================================================================================
Descrição---------: menu de opções
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Vetor de opções
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina := {}

ADD OPTION _aRotina TITLE 'Manutenção       ' ACTION 'U_MOMS009Y()' OPERATION 2 ACCESS 0

Return _aRotina

/*
===============================================================================================================================
Programa----------: MODELDEF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Criação do modelo de dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Modelo dados
===============================================================================================================================
*/
Static Function ModelDef()

// Cria a estrutura a ser usada no Modelo de Dados
Local _oStruPAI := FWFormStruct( 1, 'ZC9', /*bAvalCampo*/, /*lViewUsado*/ )
Local _oModel

// Cria o objeto do Modelo de Dados
_oModel := MPFormModel():New( 'MMOMS009' , /*bPreValidacao*/ , /*bPosValidacao*/, /*bCommit*/  , /*bCancel*/ )

// Adiciona a descricao do Modelo de Dados
_oModel:SetDescription( 'Gestão de Fechamento de Comissão' )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
_oModel:AddFields( 'ZC9PAI', NIL, _oStruPAI,/*bPre-Validacao*/ ,/*bPos-Validacao*/,/*bCarga*/ )

//define a chave primaria
_oModel:SetPrimaryKey( {"Z0_FILIAL", "Z0_SEQ", "Z0_ROTINA"} )

// Adiciona a descricao do Componente do Modelo de Dados
_oModel:GetModel( 'ZC9PAI' ):SetDescription( 'Dados da Operacao' )

Return _oModel

/*
===============================================================================================================================
Programa----------: VIEWDEF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Criação da visão dos dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Visão dos dados
===============================================================================================================================
*/
Static Function ViewDef()
// Cria a estrutura a ser usada na View
Local _oStruPAI := FWFormStruct( 2, 'ZC9' )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local _oModel   := FWLoadModel( 'MOMS009' )
Local _oView

// Cria o objeto de View
_oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
_oView:SetModel( _oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
_oView:AddField( 'VIEW_PAI' , _oStruPAI, 'ZC9PAI'  )

// Criar "box" horizontal para receber algum elemento da view
_oView:CreateHorizontalBox( 'BOXPAI'  , 80)

// Relaciona o ID da View com o "box" para exibicao
_oView:SetOwnerView( 'VIEW_PAI' , 'BOXPAI'  )

// Liga apresentação dos titulso dos componentes
_oView:EnableTitleView( 'VIEW_PAI' )

//fechamento da view
_oView:SetCloseOnOk({|_oModel| If(_oModel:GetOperation()=MODEL_OPERATION_UPDATE,.T.,.F.)})

Return _oView

/*
===============================================================================================================================
Programa----------: MOMS009F
Autor-------------: Josué Danich Prestes
Data da Criacao---: 30-07-2015
===============================================================================================================================
Descrição---------: Fechamento financeiro da gestão de fechamento de comissão - (Chamado 11158)
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS009F()

Local _aalertas 	:= {}
Local _cAlias		:= GetNextAlias()
Local _cDataF    := ZC9->ZC9_COMP  // Data do fechamento posicionado
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nI		:= 0
//================================================================================
//verifica parametro de fechamento de comissao
//================================================================================

_aalertas := U_MOMS009VS()

//================================================================================
//Verifica se usuário pode rodar a rotina
//================================================================================

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )

If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_BLQCOM == 'S')

    aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão fechamento financeiro de comissões!") 

End If

_cDataf := StrZero(_nano,4)+StrZero(_nmes,2)+"01"

//================================================================================
//verifica se não está fazendo fechamento o mês atual ou futuro
//================================================================================

If AllTrim(Str(_nano))+AllTrim(StrZero(_nmes,2)) >= AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))

  aAdd(_aalertas,"Mês " + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + " não terminou ainda!") 
  
EndIf

//================================================================================
//verifica se já não tem fechamento de financeiro após último fechamento
//================================================================================

_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA = 'Fechamento Financeiro' "
_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and  D_E_L_E_T_ <> '*'"

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)

If .not. (_cAlias)->( Eof() )

  aAdd(_aalertas,"Já existe um fechamento financeiro para o período de comissões selecionado! (" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ") (Sequência: " + AllTrim((_cAlias)->ZC8_SEQ) +")")
  
EndIf

(_cAlias)->( DBCloseArea() )

//================================================================================
//se teve qualquer alerta na verificação monta mensagem e impede o processamento
//================================================================================

If Len(_aalertas) > 0
  
	_cMensagem := "Foram encontrados problemas com o processo!<br>"
	_cMensagem += "Fechamento não será efetuado, corrija o processo e execute novamente.<br>"
		
   For _nI = 1 to Len(_aalertas)
  
		_cMensagem += "<hr>"
		_cMensagem += _aalertas[_nI] 

		If _nI < Len(_aalertas) 
		  _cMensagem += "<hr>"
		EndIf
		
	Next
				
	U_ITMsg(_cMensagem, "Problema no processo.", ,1)

    Return
    
EndIf 
			
//================================================================================	  
//se está tudo certo inclui o resgistro de fechamento do financeiro
//================================================================================

RecLock("ZC8",.T.)
 
ZC8->ZC8_FILIAL     := xFilial("ZC8")   
ZC8->ZC8_SEQ        := U_MOMS009C()  //Gera nova sequência do ZC8
ZC8->ZC8_ROTINA     := "Fechamento Financeiro"
ZC8->ZC8_DATA       := Date()
ZC8->ZC8_HORA       := Time()
ZC8->ZC8_USER       := cUserName
ZC8->ZC8_CODUSU     := __cUserId
ZC8->ZC8_COMP       := StrZero(_nmes,2) + "/" + StrZero(_nano,4)
ZC8->ZC8_OBS        := StrZero(_nmes,2) + "/" + StrZero(_nano,4)  
 
MSUnLock()     

//===============================================================================
//Coloca competencia atual em modo de fechamento
//===============================================================================
RecLock("ZC9",.F.)
 
ZC9->ZC9_STATUS   := "1"   
  
MSUnLock()    
 
//================================================================================
//manda email de liberação do fechamento do financeiro
//================================================================================

MOMS009Z()

U_ITMsg("Fechamento Financeiro Concluído", "Processo Concluído", ,2)
  
Return

/*
===============================================================================================================================
Programa----------: MOMS009C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 30-07-2015
===============================================================================================================================
Descrição---------: Retornar próxima sequência da tabela ZC8
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function MOMS009C()

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nmax	:= 0

_cQuery := " SELECT max(ZC8_SEQ) AS MAXIMO FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE D_E_L_E_T_ <> '*'"
DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If .not. (_cAlias)->( Eof() )

	_nmax := StrZero(Val((_cAlias)->MAXIMO)+1,6)

EndIf

(_cAlias)->( DBCloseArea() )

Return _nmax

/*
===============================================================================================================================
Programa----------: MOMS009VS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Verifica se não está trabalhando em data dentro de período de comissão encerrado
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aalertas - Matriz com mensagem de erro ou vazia
===============================================================================================================================
*/
User Function MOMS009VS()

Local _cDataF    := SubStr(ZC9->ZC9_COMP,4,4)  + SubStr(ZC9->ZC9_COMP,1,2) + "01"  // Data do fechamento posicionado
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))+1
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _aalertas  := {}

//================================================================================ 
//verifica se parâmetro de fechamento está aberto
//================================================================================

If _nmes == 13

  _nmes := 1
  _nano += 1

EndIf

_dDataf := SToD(StrZero(_nano,4)+StrZero(_nmes,2)+"01")

//================================================================================
//verifica se as datas não afetam período de comissão já fechado
//================================================================================

If Date() < _dDataF 
  
    aAdd(_aalertas,"Período até " + DToC(_dDataF-1) + " já encerrado!")
  
End If 

 
Return _aalertas

/*
===============================================================================================================================
Programa----------: MOMS009Z
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Processa o envio de e-mail de fechamento financeiro de comissões
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS009Z()

Local _cConfig	:= GetMV( "IT_CMWFNF" ,, "001" )
Local _aConfig	:= U_ITCFGEML( _cConfig )
Local _cLog		:= ""
Local _cMsgAux	:= ""
Local _cMail		:= ""

DBSelectArea('ZZL')
ZZL->( Dbsetfilter({ | | ZZL->ZZL_ADMCMS="S" .Or. ZZL->ZZL_BLQCOM = "S" }, 'ZZL->ZZL_ADMCMS="S" .Or. ZZL->ZZL_BLQCOM="S"') )
ZZL->( DBGoTop() )

While .not. ZZL->( Eof() )
	
	_cmail += AllTrim( ZZL->ZZL_EMAIL ) + ";"
		
	ZZL->( DBSkip() )
	
EndDo

_cmail := SubStr(_cmail,1,Len(_cmail)-1)

_cMsgAux := '<HMTL>'
_cMsgAux += '<HEAD>'
_cMsgAux += '<META http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />'
_cMsgAux += '<TITLE>Liberação de fechamento de Comissão da competência ' + AllTrim(ZC9->ZC9_COMP) + ' -  Liberado em ' + DToC(date()) + ' </TITLE>'
_cMsgAux += '</HEAD>'
_cMsgAux += '<BODY><br>'
_cMsgAux += '<FONT FACE="Courier New" Style="font-size:12px">'
_cMsgAux	+= 'O departamento financeiro finalizou as baixas de títulos para a competência ' + AllTrim(ZC9->ZC9_COMP) + ' <br>'
_cMsgAux	+= 'O processo de recálculo e fechamento de comissões está liberado a partir de ' + DToC(date()) + '.<br>'
_cMsgAux += '<br>'
_cMsgAux += '<br>'
_cMsgAux += '=======================================================================================================<br>'
_cMsgAux += '<i><b> Atenção: essa é uma mensagem automática, favor não responder. </b></i>                          <br>'
_cMsgAux += '=======================================================================================================<br>'
_cMsgAux += '</FONT>'
_cMsgAux += '</BODY>'
_cMsgAux += '</HMTL>'

U_ITENVMAIL( _aConfig[01] , _cMail ,,, 'Liberação de fechamento de Comissão da competência ' + AllTrim(ZC9->ZC9_COMP) + ' -  Liberado em ' + DToC(date()) , _cMsgAux ,, _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog )

u_itconout( "[MOMS009] - Envio de e-mail: "+ _cLog )

Return

/*
===============================================================================================================================
Programa----------: MOMS009Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Manutenção de competência
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS009Y()

Local _oDlg := nil
Local _aSize 	:= MSADVSIZE()
Local _oBrowse	:= nil

DBSelectArea("ZC8")
ZC8->(dbsetfilter({ | | ZC8->ZC8_COMP = ZC9->ZC9_COMP }, 'ZC8->ZC8_COMP = "' + ZC9->ZC9_COMP + "'" ) )
ZC8->( DBGoTop() )	

DEFINE MSDIALOG _oDlg FROM _aSize[7]+150,150 TO _aSize[6]-150,_aSize[5]-150 PIXEL TITLE 'Fechamento Comissão - Competência ' + AllTrim(ZC9->ZC9_COMP)

	DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
    
   _oBrowse := TCBrowse():New( 01,01,500,115,,{20,20,20,20,20,50},,_oDlg,,,,,{||},,_oFont12b,,,,,.F.,"ZC8",.T.,,.F.,,.T.,.T.)      

	_oBrowse:AddColumn(TCColumn():New("Sequencia"		,{ || ZC8->ZC8_SEQ}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Rotina"		,{ || ZC8->ZC8_ROTINA}	,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Data Exec."	,{ || ZC8->ZC8_DATA}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Hora Exec."	,{ || ZC8->ZC8_HORA}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Usuário"		,{ || ZC8->ZC8_USER}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Obs"			,{ || ZC8->ZC8_OBS}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	  		
	@ 120,100 BUTTON _oButton PROMPT "Fech Financeiro"	        SIZE 045,12 ACTION IIf(MOMS009T(1),Eval({|| U_MOMS009F(),_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 120,160 BUTTON _oButton PROMPT "Rec. Comissão"	        SIZE 045,12 ACTION IIf(MOMS009T(2),Eval({|| FWMsgRun(,{ || U_MOMS009R()},"Carregando...","Aguarde..."),_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 120,220 BUTTON _oButton PROMPT "Adic. Comissao"	        SIZE 045,12 ACTION IIf(MOMS009T(3),Eval({|| U_MOMS005()	, _oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL	
	@ 120,280 BUTTON _oButton PROMPT "Integrar Dados Gerencias" SIZE 065,12 ACTION IIf(MOMS009T(5),Eval({|| U_MOMS009I(), _oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 120,355 BUTTON _oButton PROMPT "Fech. Comissao"	        SIZE 045,12 ACTION IIf(MOMS009T(4),Eval({|| U_MOMS013()	,close(_oDlg)})		,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 120,415 BUTTON _oButton PROMPT "Sair"				        SIZE 045,12 ACTION close(_oDlg) 	OF _oDlg PIXEL
	//@ 120,280 BUTTON _oButton PROMPT "Grava Dados Gerenciais" SIZE 065,12 ACTION IIf(MOMS009T(5),Eval({|| U_MOMS064()	,_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	
	_oDlg:lMaximized := .T.

ACTIVATE MSDIALOG _oDlg CENTER 

Return

/*
===============================================================================================================================
Programa----------: MOMS009T
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Validação de botões
===============================================================================================================================
Parametros--------: _nopc - botão clicado
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS009T(_nopc)

Local _lRet := .T.

If ZC9->ZC9_STATUS == '0' 

	If _nopc == 2 .Or. _nopc == 3 .Or. _nopc == 4 .Or. _nopc == 5
	
		U_ITMsg("Competência ainda não está está em fechamento!","Atenção",,1)
	
		_lRet := .F.
		
	EndIf
	
EndIf

If ZC9->ZC9_STATUS == '1' 

	If _nopc == 1
	
		U_ITMsg("Competência já está em fechamento!","Atenção",,1)
	
		_lRet := .F.
		
	EndIf
	
EndIf

If ZC9->ZC9_STATUS == '2'

	U_ITMsg("Competência já está encerrada!","Atenção",,1)
	
	_lRet := .F.
	
EndIf

If ZC9->ZC9_STATUS == '3' .And. _nopc == 4

	U_ITMsg("Integração dos dados gerenciais em andamento, não é possível concluir o fechamento antes do término da integração!" ,"Atenção",,1)
	
	_lRet := .F.
	
EndIf

If ZC9->ZC9_STATUS <> '3' .And. ZC9->ZC9_STATUS <> '4' .And. _nopc == 4

	U_ITMsg("Antes do Fechamento da Comissão é necessário concluir a integração dos dados gerenciais." ,"Atenção",,1)
	
	_lRet := .F.
	
EndIf

Return _lRet 

/*
===============================================================================================================================
Programa----------: MOMS009H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 30-07-2015
===============================================================================================================================
Descrição---------: Retornar próxima sequência da tabela ZC9
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function MOMS009H()

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nmax	:= 0

_cQuery := " SELECT max(ZC9_SEQ) AS MAXIMO FROM "+ RETSQLNAME('ZC9') +" ZC9 WHERE D_E_L_E_T_ <> '*'"
DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If .not. (_cAlias)->( Eof() )

	_nmax := StrZero(Val((_cAlias)->MAXIMO)+1,6)

EndIf

(_cAlias)->( DBCloseArea() )

Return _nmax

/*
===============================================================================================================================
Programa----------: MOMS009R
Autor-------------: Josué Danich Prestes
Data da Criacao---: 14/12/2015
===============================================================================================================================
Descrição---------: Preparara ambiente para recálculo de comissão
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function MOMS009R()

Local _cAlias 	:= ""
Local _cQuery 	:= ""
Local _afiliais 	:= {}
Local _nI 			:= 1

Local _cDataF    := ZC9->ZC9_COMP  // Data do fechamento posicionado
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))

Local _cfilial	:= cfilant

Private MvParDef	 	:= ""
Private acat 			:= {}
Private ctitulo 		:= "Recálculo de comissões em filiais"
Private MvPar			:= {}
Private nTam			:= 02
Private nMaxSelect 	:= 14

//================================================================================
//verifica se já não rodou a rotina de adicionais de comissão no período
//================================================================================

_cAlias	:= GetNextAlias()

_cQuery := " SELECT ZC8_SEQ FROM "+ RETSQLNAME('ZC8') +" ZC8 WHERE ZC8_ROTINA = 'Adicionais de Comissao' "
_cQuery += " and ZC8_COMP = '" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + "' and ZC8_OBS = '2 - Bonificações'"
_cQuery += " and D_E_L_E_T_ <> '*'"

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)

If !(_cAlias)->( Eof() )

		_cMensagem := "Foram encontrados problemas com o processo!<br>"
		_cMensagem += "Recálculo não será efetuado, corrija o processo e execute novamente.<br>"
		_cMensagem += "Já existe um cálculo de adicionais de bonificação após a liberação do financeiro para o período de comissões em aberto!(" + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + ")<br>"
				
		U_ITMsg(_cMensagem, "Problema no processo", ,1)
		
		Return
  			
EndIf
		
(_cAlias)->( DBCloseArea() )



//=====================================================================================
//Carrega dados de recálculo para montar tela de seleção
//=====================================================================================

_cAlias	:= GetNextAlias()

_cQuery := " SELECT E3_FILIAL FROM "+ RETSQLNAME('SE3') +" SE3 WHERE E3_I_ORIGE = '       ' "
_cQuery += " AND E3_EMISSAO >= '" + StrZero(_nano,4) + StrZero(_nmes,2) + "01' AND E3_EMISSAO <= '" + StrZero(_nano,4) + StrZero(_nmes,2) + "31'"
_cQuery += " AND D_E_L_E_T_ = ' ' AND E3_ORIGEM <> 'R' AND E3_ORIGEM <> 'F'"
_cQuery += " GROUP BY E3_FILIAL ORDER BY E3_FILIAL"

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)

While !((_cAlias)->( Eof() ))

	aAdd(_afiliais, {AllTrim( (_cAlias)->E3_FILIAL ), FWFilialName(cEmpAnt,AllTrim( (_cAlias)->E3_FILIAL )),  "Falta Calcular"} )
	(_cAlias)->( DBSkip() )
		
EndDo
		
(_cAlias)->( DBCloseArea() )

//=====================================================================================
//Carrega novamente sem filtro, se acahar só aqui são filiais com rec. ok
//=====================================================================================

_cAlias	:= GetNextAlias()

_cQuery := " SELECT E3_FILIAL FROM "+ RETSQLNAME('SE3') +" SE3 WHERE "
_cQuery += " E3_EMISSAO >= '" + StrZero(_nano,4) + StrZero(_nmes,2) + "01' AND E3_EMISSAO <= '" + StrZero(_nano,4) + StrZero(_nmes,2) + "31'"
_cQuery += " AND D_E_L_E_T_ <> '*'"
_cQuery += " GROUP BY E3_FILIAL ORDER BY E3_FILIAL"

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , _cAlias , .F. , .T. )
DBSelectArea(_cAlias)

While !((_cAlias)->( Eof() ))

	
	If aScan(_afiliais, { |x| x[1] = AllTrim( (_cAlias)->E3_FILIAL ) } ) == 0
		
		aAdd(_afiliais, {AllTrim( (_cAlias)->E3_FILIAL ), FWFilialName(cEmpAnt,AllTrim( (_cAlias)->E3_FILIAL )), "Calculado       "} )
		
	EndIf
	
	(_cAlias)->( DBSkip() )		
		
EndDo
		
(_cAlias)->( DBCloseArea() )

//=====================================================================================
//Monta tela de seleção
//=====================================================================================

_afiliais := aSort(_afiliais, , , { | x,y | x[1] < y[1] })

For _nI := 1 to Len(_afiliais)
	MvParDef += AllTrim(_afiliais[_nI][1])
	aAdd(aCat,AllTrim(_afiliais[_nI][3] + " - " + _afiliais[_nI][2]) )
Next

//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	//Executa recálculos selecionados
	For _nI := 1 to Len(MvPar)
		cfilant := AllTrim(mvpar[_nI])
		FINA440()
	Next
	cfilant := _cfilial
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS009I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/05/2022
===============================================================================================================================
Descrição---------: Altera status da rotina para rodar a integração no modo Scheduller.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS009I()

Begin Sequence
   
   If ! U_ITMsg(" A rotina de integração de dados gerenciais pode levar em média de 4hs a 6hs para ser executada, ao clicar em 'Sim' "+;
              " a comissão será colocada no status de aguardando integração e a integração será agendada para ser gravada " +;
              " no periodo noturno via servidor. Ao finalizar a integração o sistema liberará o encerramento do período. " ,"Atenção" , , ,2, 2)  
      Break 
   EndIf 
   
   ZC9->(RecLock("ZC9", .F.))
   ZC9->ZC9_STATUS := "3"
   ZC9->(MSUnLock())

End Sequence 

Return 


