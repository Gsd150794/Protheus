/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  | 22/06/2018 | Incluida limpeza de filtro da ZZL - Chamado 25039  
Josué Danich  | 26/06/2019 | Ajustes para loboguara - Chamado 28886
Lucas Borges  | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
Lucas Borges  | 28/04/2020 | Ajuste no Parametro Data Inicial do Relatório. Chamado 32761
Julio Paz     | 31/05/2021 | Ajustar tamanho da tela de fechamento de ocorrencia de frete para Smartclient Web. Chamado 36677.

===============================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado  - Motivo da Alteração
===============================================================================================================================
Bremmer Henrique - Igor Melgaço      - 30/09/2024 - 21/10/2024 - 48654    - Reabertura Logistica e Comercial.
Jeryy            - Alex Wallauer     - 03/06/2025 - 03/06/2025 - 50902    - Ajuste de tela para SmartClient Web.
===============================================================================================================================
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
Programa----------: MOMS034
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/12/2016
===============================================================================================================================
Descrição---------: Gestão de fechamento de ocorrências de frete  - Chamado 17933
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS034()

Local _oBrowse
Local _aArea 	:= ZFZ->(GetArea())

Private _cGetSu		:= Space(100)
Private _cGetMo		:= Space(100)
Private _cGetRe		:= Space(100)
Private _cArq		   := ""
Private _aStructZF5	:= {}

Private _oFont12b                      

Define Font _oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito   

_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias( 'ZFZ' )
_oBrowse:SetDescription( 'Gestão de Fechamento de Ocorrências de frete' )
_oBrowse:DisableDetails()

//define legendas
_oBrowse:AddLegend( "AllTrim(ZFZ_STATUS)=='0'" ,   "GREEN"    , "Aberto"  )
_oBrowse:AddLegend( "AllTrim(ZFZ_STATUS)=='1'" ,   "YELLOW"   , "Em fechamento"  )
_oBrowse:AddLegend( "AllTrim(ZFZ_STATUS)=='2'" ,   "RED"      , "Fechado" )         

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

ADD OPTION _aRotina TITLE 'Manutenção       ' ACTION 'U_MOMS034Y()' OPERATION 3 ACCESS 0
ADD OPTION _aRotina TITLE 'Exporta Excel    ' ACTION 'U_MOMS034I()' OPERATION 4 ACCESS 0

Return _aRotina

/*
===============================================================================================================================
Programa----------: MOMS034I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13-12-2015
===============================================================================================================================
Descrição---------: Chama exportação excel para período atual
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS034I()

Local _lRet := .T.
Local _cStatusEncer := U_ITGetMV( 'IT_STATUSENC' , '000001;000017;000018' )

//Define parâmetros
If SubStr(AllTrim(ZFZ->ZFZ_COMP),1,2) == '01'

	_ddini := SToD(StrZero(Val(SubStr(AllTrim(ZFZ->ZFZ_COMP),4,4))-1,4) + '1226'  )
	
Else

	_ddini := SToD(StrZero(Val(SubStr(AllTrim(ZFZ->ZFZ_COMP),4,4)),4) + StrZero(Val(SubStr(AllTrim(ZFZ->ZFZ_COMP),1,2))-1,2) + '26' )
	
EndIf

//Pergunta se traz só aprovados
_lRet := U_ITMsg("Traz somente aprovados?","Tipo exportação",,3,2,2)


If _lRet

	MV_PAR08 := 1 //Só aprovados
	
Else

	MV_PAR08 := 3 //Todos

EndIf
	
MV_PAR01 := _ddini //Data inicial
MV_PAR02 := SToD(StrZero(Val(SubStr(AllTrim(ZFZ->ZFZ_COMP),4,4)),4) + StrZero(Val(SubStr(AllTrim(ZFZ->ZFZ_COMP),1,2)),2) + '25' ) //Data final
MV_PAR03 := cfilant //Filial atual
MV_PAR04 := SToD('20010101') //Data inicial de inclusão da ocorrência
MV_PAR05 := SToD('20491231') //Data final de inclusão da ocorrência
MV_PAR06 := "   " //Vazio para trazer todos os tipos de ocorrência
MV_PAR07 := _cStatusEncer // "E"  //Só encerrados // Conteúdo informado no parâmetro IT_STATUSEN.
MV_PAR09 := 1 // Filtros de desconto de custo representante
 
FWMsgRun(, {|oSay| U_MOMS031P(osay,.T.) })

Return

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
===============================================================================================================================
*/
Static Function ModelDef()

// Cria a estrutura a ser usada no Modelo de Dados
Local _oStruPAI := FWFormStruct( 1, 'ZFZ', /*bAvalCampo*/, /*lViewUsado*/ )
Local _oModel

// Cria o objeto do Modelo de Dados
_oModel := MPFormModel():New( 'MMOMS034' , /*bPreValidacao*/ , /*bPosValidacao*/, /*bCommit*/ {|_oMdl| MDGrv(_oMdl)}, /*bCancel*/ )

// Adiciona a descricao do Modelo de Dados
_oModel:SetDescription( 'Gestão de Fechamento de Ocorrências de frete' )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
_oModel:AddFields( 'ZFZPAI', NIL, _oStruPAI,/*bPre-Validacao*/ ,/*bPos-Validacao*/,/*bCarga*/ )

//define a chave primaria
_oModel:SetPrimaryKey( {"Z0_FILIAL", "Z0_SEQ", "Z0_ROTINA"} )

// Adiciona a descricao do Componente do Modelo de Dados
_oModel:GetModel( 'ZFZPAI' ):SetDescription( 'Dados da Operacao' )

Return _oModel

/*
===============================================================================================================================
Programa----------: MDGRV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Complemento de gravação da modelo de dados
===============================================================================================================================
Parametros--------: objeto da modelo de dados
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MDGrv(_oMdl)

FwFormCommit(_oMdl)

Return .T.

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
Local _oStruPAI := FWFormStruct( 2, 'ZFZ' )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local _oModel   := FWLoadModel( 'MOMS034' )
Local _oView

// Cria o objeto de View
_oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
_oView:SetModel( _oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
_oView:AddField( 'VIEW_PAI' , _oStruPAI, 'ZFZPAI'  )

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
Programa----------: MOMS034F
Autor-------------: Josué Danich Prestes
Data da Criacao---: 30-07-2015
===============================================================================================================================
Descrição---------: Fechamento logistica de ocorrências de frete/comercial
===============================================================================================================================
Parametros--------: _ntipo - 1 Fechamento de logistica
                             2 Fechamento de comercial
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS034F(_ntipo)

Local _aalertas 	:= {}
Local _cDataF    := ZFZ->ZFZ_COMP  // Data do fechamento posicionado
Local _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _npos     := ZFZ->(Recno())
Local _nI		 := 0
Local _cRotina  := ""
Local _cStatus  := ""
Local _cMsg     := ""
Local _aAreaZFZ := {}

//Verifica se ZFZ está vazio para a filial
If .NOT. ZFZ->(DBSeek(xFilial("ZFZ")))
   If _ntipo < 3
      //Se não existe cria a primeira competência da filial para ultima competência já encerrada
      If day(date()) >= 25
         _cDataF := StrZero(month(date()),2) + "/" + StrZero(year(date()),4)
      Else
         _cDataF := StrZero(month(date()-30),2) + "/" +  StrZero(year(date()-30),4)
      EndIf

      _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
      _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))

      ZFZ->(RecLock("ZFZ",.T.))
      ZFZ->ZFZ_FILIAL := xFilial("ZFZ")
      ZFZ->ZFZ_SEQ := u_MOMS034H() //GERA NOVA SEQUENCIA PARA O ZFZ
      ZFZ->ZFZ_COMP := _cDataF
      ZFZ->ZFZ_STATUS := '1'
      ZFZ->(MSUnLock())
      U_ITLOGACS('MOMS034')
   Else
      aAdd(_aalertas,"Não há registro para reabertura!" )
   EndIf
Else
   ZFZ->(DBGoTo(_npos))
EndIf

 
//================================================================================
//verifica parametro de fechamento de comissao
//================================================================================

_aalertas := U_MOMS034VS()

//================================================================================
//Verifica se usuário pode rodar a rotina
//================================================================================

DBSelectArea('ZZL')
ZZL->( DBSetOrder(3) )

If _nTipo = 1 

  If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_BLQLOG == 'S')

      aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão fechamento de logística p/ ocorrência de fretes!") 

  End If

ElseIf _nTipo = 3

  If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_REALOG == 'S')

      aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão reabertura de logística p/ ocorrência de fretes!") 

  End If

ElseIf _nTipo = 2 

  If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_BLQCO2 == 'S')

      aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão fechamento de comercial p/ ocorrência de fretes!") 

  End If

ElseIf _nTipo = 4

  If !(ZZL->( DBSeek( xFilial('ZZL') + RetCodUsr() ) ) .And. ZZL->ZZL_REACOM == 'S')

      aAdd(_aalertas,"Usuário " + AllTrim(SubStr(cUsuario,7,15)) + " sem permissão reabertura de comercial p/ ocorrência de fretes!") 

  End If

EndIf

_cDataf := StrZero(_nano,4)+StrZero(_nmes,2)+"01"

//================================================================================
//verifica se não está fazendo fechamento o mês atual ou futuro
//================================================================================

If (AllTrim(Str(_nano))+AllTrim(StrZero(_nmes,2)) > AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))) .or.;
	((AllTrim(Str(_nano))+AllTrim(StrZero(_nmes,2)) = AllTrim(Str(year(date())))+AllTrim(StrZero(month(date()),2))) .And. day(date()) < 25)

    aAdd(_aalertas,"Mês " + StrZero(_nmes,2) + "/" + StrZero(_nano,4) + " não terminou ainda!") 
  
EndIf

//================================================================================
//se teve qualquer alerta na verificação monta mensagem e impede o processamento
//================================================================================

If Len(_aalertas) > 0
  
 	_cMensagem := "Foram encontrados problemas com o processo!<br>"
		
   For _nI = 1 to Len(_aalertas)
  
  		_cMensagem += "<p>"
		_cMensagem += _aalertas[_nI] 
		_cMensagem += "</p>
		If _nI < Len(_aalertas) 
		  _cMensagem += "<hr>"
		EndIf
		
	Next
					
	U_ITMsg(_cMensagem,"Problema no processo.",,1)

    Return
    
EndIf 

_cseq := U_MOMS034C()  //Gera nova sequência do ZFY

BEGIN TRANSACTION
			
//================================================================================	  
//se está tudo certo inclui o resgistro de fechamento da logistica
//================================================================================

If _ntipo = 1
   _cRotina := 'Fechamento Logistico'
ElseIf _ntipo = 2  
   _cRotina := 'Fechamento Comercial'
ElseIf _ntipo = 3
   _cRotina := 'Reabertura Logistica'
ElseIf _ntipo = 4
   _cRotina := 'Reabertura Comercial'
EndIf

RecLock("ZFY",.T.)
 
ZFY->ZFY_FILIAL     := xFilial("ZFY")   
ZFY->ZFY_SEQ        := _cseq
ZFY->ZFY_ROTINA     := _cRotina //IIf(_ntipo == 1,'Fechamento Logistico', 'Fechamento Comercial')
ZFY->ZFY_DATA       := Date()
ZFY->ZFY_HORA       := Time()
ZFY->ZFY_USER       := cUserName
ZFY->ZFY_CODUSU     := __cUserId
ZFY->ZFY_COMP       := StrZero(_nmes,2) + "/" + StrZero(_nano,4)
ZFY->ZFY_OBS        := StrZero(_nmes,2) + "/" + StrZero(_nano,4)  
 
MSUnLock()     

If _ntipo == 1 
   _cStatus := "1"
ElseIf _ntipo = 2 
   _cStatus := "2"
ElseIf _ntipo = 3 
   _cStatus := "0"
ElseIf _ntipo = 4 
   _cStatus := "1"
EndIf

//===============================================================================
//Coloca competencia atual em modo de fechamento
//===============================================================================
RecLock("ZFZ",.F.)
 
ZFZ->ZFZ_STATUS   :=   _cStatus
  
MSUnLock()    

_cseq := u_MOMS034H() //GERA NOVA SEQUENCIA PARA O ZFZ
_cpos := ZFZ->(Recno())

//Se For fechamento ccomercial já cria a nova competência
If _ntipo == 2
  
    
    _dinicia := SToD(SubStr(_cDataf,1,4)+SubStr(_cDataf,5,2)+'01') +32
    
    _cDataF := StrZero(month(_dinicia),2) + "/" + StrZero(year(_dinicia),4)
    
  
   _nmes      := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
   _nano      := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
   
   _aAreaZFZ := ZFZ->(GetArea())

   ZFZ->(DBSetOrder(2))
   If !ZFZ->(DBSeek(xFilial("ZFZ")+_cDataF))
      ZFZ->(RecLock("ZFZ",.T.))
      ZFZ->ZFZ_FILIAL := xFilial("ZFZ")
      ZFZ->ZFZ_SEQ := _cseq
      ZFZ->ZFZ_COMP := _cDataF
      ZFZ->ZFZ_STATUS := '0'
      ZFZ->(MSUnLock())

      U_ITLOGACS('MOMS034')

      FWRestArea(_aAreaZFZ)

   Else

      FWRestArea(_aAreaZFZ)
      U_ITLOGACS('MOMS034')

   EndIf

Else

   U_ITLOGACS('MOMS034')
   ZFZ->(DBGoTo(_cpos))
EndIf


END TRANSACTION 
//================================================================================
//manda email de liberação do fechamento da logistica
//================================================================================

MOMS034Z(_ntipo)

If _ntipo = 1
   _cMsg :=  "Fechamento Logistica Concluído"
ElseIf _ntipo = 2  
   _cMsg :=  "Fechamento Comercial Concluído" 
ElseIf _ntipo = 3  
   _cMsg :=  "Reabertura Logistica Concluído" 
ElseIf _ntipo = 4  
   _cMsg :=  "Reabertura Comercial Concluído" 
EndIf

U_ITMsg(_cMsg, "Processo Concluído",,2)
  
Return

/*
===============================================================================================================================
Programa----------: MOMS034C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 30-07-2015
===============================================================================================================================
Descrição---------: Retornar próxima sequência da tabela ZFY
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function MOMS034C()

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nmax	:= 0

_cQuery := " SELECT max(ZFY_SEQ) AS MAXIMO FROM "+ RETSQLNAME('ZFY') +" ZFY WHERE D_E_L_E_T_ <> '*'"
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
Programa----------: MOMS034VS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Verifica se não está trabalhando em data dentro de período de ocorrências encerrado
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aalertas - Matriz com mensagem de erro ou vazia
===============================================================================================================================
*/
User Function MOMS034VS()

Local _cDataF    := SubStr(ZFZ->ZFZ_COMP,4,4)  + SubStr(ZFZ->ZFZ_COMP,1,2) + "01"  // Data do fechamento posicionado
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
Programa----------: MOMS034Z
Autor-------------: Josué Danich Prestes
Data da Criacao---: 31/07/2015
===============================================================================================================================
Descrição---------: Processa o envio de e-mail de fechamento financeiro de comissões
===============================================================================================================================
Parametros--------: _ntipo - 1 Logistica
                             2 Comercial
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS034Z(_ntipo)

Local _cConfig	:= GetMV( "IT_CMWFNF" ,, "001" )
Local _aConfig	:= U_ITCFGEML( _cConfig )
Local _cLog		:= ""
Local _cMsgAux	:= ""
Local _cMail	:= ""
Local _aMail    := {}
Local _nni		:= 0

If _ntipo == 1

  DBSelectArea('ZZL')
  ZZL->( Dbsetfilter({ | | ZZL->ZZL_ADMOCO="S" .Or. ZZL->ZZL_BLQLOG = "S" }, 'ZZL->ZZL_ADMOCO="S" .Or. ZZL->ZZL_BLQLOG="S"') )
  ZZL->( DBGoTop() )

Else

  DBSelectArea('ZZL')
  ZZL->( Dbsetfilter({ | | ZZL->ZZL_ADMOCO="S" .Or. ZZL->ZZL_BLQCO2 = "S" }, 'ZZL->ZZL_ADMOCO="S" .Or. ZZL->ZZL_BLQCO2="S"') )
  ZZL->( DBGoTop() )

EndIf

While .not. ZZL->( Eof() )
	
	aAdd(_amail,AllTrim( ZZL->ZZL_EMAIL ))
		
	ZZL->( DBSkip() )
	
EndDo

ZZL->(Dbclearfilter())

For _nni := 1 to Len(_amail)

_cmail := _amail[_nni]

_cMsgAux := '<HMTL>'
_cMsgAux += '<HEAD>'
_cMsgAux += '<META http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />'
_cMsgAux += '<TITLE>Liberação ' + IIf(_ntipo==1," setor logistica ", " setor comercial ") + ' de fechamento de Ocorrências de frete ' + AllTrim(ZFZ->ZFZ_COMP) + " - Filial " + xFilial("SF2") + "  -  Liberado em ' + dtoc(date()) + ' </TITLE>'
_cMsgAux += '</HEAD>'
_cMsgAux += '<BODY><br>'
_cMsgAux += '<FONT FACE="Courier New" Style="font-size:12px">'
_cMsgAux	+= 'O departamento de ' + IIf(_ntipo==1, ' logistica ',' comercial ') + ' finalizou os encerramentos de ocorrências de frete para a competência ' + AllTrim(ZFZ->ZFZ_COMP) +  " - Filial " + xFilial("SF2") +  ' <br>'

If _ntipo == 1

  _cMsgAux	+= 'O processo de aprovação de descontos por representante está liberado a partir de ' + DToC(date()) + '.<br>'

Else

  _cMsgAux	+= 'O processo de registro de descontos por representante está liberado a partir de ' + DToC(date()) + '.<br>'

EndIf

_cMsgAux += '<br>'
_cMsgAux += '<br>'
_cMsgAux += '=======================================================================================================<br>'
_cMsgAux += '<i><b> Atenção: essa é uma mensagem automática, favor não responder. </b></i>                          <br>'
_cMsgAux += '=======================================================================================================<br>'
_cMsgAux += '</FONT>'
_cMsgAux += '</BODY>'
_cMsgAux += '</HMTL>'

U_ITENVMAIL( _aConfig[01] , _cMail ,,, 'Liberação de fechamento ' + IIf(_ntipo==1," setor logistica ", " setor comercial ") + ' de Ocorrências de frete ' + AllTrim(ZFZ->ZFZ_COMP)  + " - Filial " + xFilial("SF2") +  ' -  Liberado em ' + DToC(Date()) , _cMsgAux ,, _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog )

u_itconout( "[MOMS034] - Envio de e-mail para  " + _cmail + " - " +  _cLog )

Next

Return

/*
===============================================================================================================================
Programa----------: MOMS034Y
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
User Function MOMS034Y()

Local _oDlg := nil
Local _aSize 	:= MSADVSIZE()
Local _oBrowse	:= nil
Local _cDirSmartC := ""
Local _nLinPos := 150
Local _aAreaZFZ := ZFZ->(GetArea())

//==========================================================================
// Verifica se o usuário está utilizando SmartCliente Html/ acesso via Web.
//==========================================================================
_cDirSmartC := GetClientDir()

If Empty(_cDirSmartC) 
   _nLinPos := 0 // para reajuste da posição tela em caso de acesso via smartclient Html.
EndIf 

//==========================================================================
// Inicia a montagem da tela
//==========================================================================
DBSelectArea("ZFY")
ZFY->(dbsetfilter({ | | ZFY->ZFY_FILIAL = ZFZ->ZFZ_FILIAL .And. ZFY->ZFY_COMP = ZFZ->ZFZ_COMP .And. ZFZ->ZFZ_FILIAL = xFilial('ZFZ') },;
 								'ZFY->ZFY_FILIAL = ZFZ_FILIAL .And. ZFY->ZFY_COMP = "' + ZFZ->ZFZ_COMP + "' .And. ZFZ->ZFZ_FILIAL = '" + xFilial('ZFZ') + "'" ) )
ZFY->( DBGoTop() )	

DEFINE MSDIALOG _oDlg FROM _aSize[7]+150,150 TO _aSize[6]-_nLinPos,_aSize[5]-150 PIXEL TITLE 'Fechamento Ocorrência de fretes - Competência ' + AllTrim(ZFZ->ZFZ_COMP)

	DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD
    
   _oBrowse := TCBrowse():New( 01,01,500,115,,{20,20,20,20,20,50},,_oDlg,,,,,{||},,_oFont12b,,,,,.F.,"ZFY",.T.,,.F.,,.T.,.T.)      

	_oBrowse:AddColumn(TCColumn():New("Sequencia"	,{ || ZFY->ZFY_SEQ}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Rotina"		,{ || ZFY->ZFY_ROTINA}	,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Data Exec."	,{ || ZFY->ZFY_DATA}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Hora Exec."	,{ || ZFY->ZFY_HORA}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Usuário"		,{ || ZFY->ZFY_USER}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	_oBrowse:AddColumn(TCColumn():New("Obs"			,{ || ZFY->ZFY_OBS}		,,,,"LEFT",,.F.,.F.,,,,.F.,))
	
	
	@ 124,010 BUTTON _oButton PROMPT "Fech Logistica"	SIZE 045,12 ACTION IIf(MOMS034T(1),Eval({|| U_MOMS034F(1),_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 124,070 BUTTON _oButton PROMPT "Aprova Desconto"	SIZE 045,12 ACTION IIf(MOMS034T(2),Eval({|| U_MOMS034S(),_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 124,130 BUTTON _oButton PROMPT "Fech Comercial"	SIZE 045,12 ACTION IIf(MOMS034T(3),Eval({|| U_MOMS034F(2)	,_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 124,190 BUTTON _oButton PROMPT "Reab Logistica"	SIZE 045,12 ACTION IIf(MOMS034T(4),Eval({|| U_MOMS034F(3),_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 124,250 BUTTON _oButton PROMPT "Reab Comercial"	SIZE 045,12 ACTION IIf(MOMS034T(5),Eval({|| U_MOMS034F(4)	,_oBrowse:GoTop()})	,_oBrowse:GoTop()) 	OF _oDlg PIXEL
	@ 124,340 BUTTON _oButton PROMPT "Sair"				SIZE 045,12 ACTION Eval({|| close(_oDlg),close(_oDlg)}) 	OF _oDlg PIXEL
	
   _oDlg:lMaximized := .T.

ACTIVATE MSDIALOG _oDlg CENTERED 

FWRestArea(_aAreaZFZ)

Return

/*
===============================================================================================================================
Programa----------: MOMS034T
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
Static Function MOMS034T(_nopc)

Local _lRet := .T.

If ZFZ->ZFZ_STATUS == '0' .Or. ZFZ->(Eof()) 

	If _nopc == 2 .Or. _nopc == 3 .Or. _nopc == 4
		
      U_ITMsg("Competência ainda não tem fechamento logistica!","Atenção",,1)
		_lRet := .F.

   ElseIf  _nopc == 5 
      
      U_ITMsg("Competência ainda não tem fechamento Comercial!","Atenção",,1)
      _lRet := .F.

   EndIf
EndIf

If ZFZ->ZFZ_STATUS == '1' 

	If _nopc = 1
	
		U_ITMsg("Competência já possui fechamento logística!","Atenção",,1)
		_lRet := .F.

	ElseIf _nopc = 5 	
		
      U_ITMsg("Competência não possui fechamento Comercial!","Atenção",,1)
		_lRet := .F.   

	EndIf
	
EndIf

If ZFZ->ZFZ_STATUS == '2'
   If _nopc = 2 	.Or. _nopc = 3 

   	U_ITMsg("Competência já está encerrada!","Atenção",,1)	
   	_lRet := .F.
	
   ElseIf _nopc = 4 	

		U_ITMsg("Para esta competência é necessário a Reabertura Comercial antes!","Atenção",,1)
		_lRet := .F.   

   EndIf

EndIf

Return _lRet 

/*
===============================================================================================================================
Programa----------: MOMS034H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 30-07-2015
===============================================================================================================================
Descrição---------: Retornar próxima sequência da tabela ZFZ
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function MOMS034H()

Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _nmax	:= 0

_cQuery := " SELECT max(ZFZ_SEQ) AS MAXIMO FROM "+ RETSQLNAME('ZFZ') +" ZFZ WHERE D_E_L_E_T_ <> '*'"
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
Programa--------: MOMS034S
Autor-----------: Julio de Paula Paz
Data da Criacao-: 09/08/2016
===============================================================================================================================
Descrição-------: Rotina de exibição e seleção de dados para aprovação ou rejeição.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno   ------: Nenhum
===============================================================================================================================
*/
User Function MOMS034S()
Local _lInverte := .F. 
Local _aButtons := {}, _lRet := .F.
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _nLin1,_nCol1, _nLin2, _nCol2
Local _aStructZF5
Local _aOrd := SaveOrd({"ZF5","SX3"})
Local _cMsg
Private _aCampos := {}
Private _oMarkApr, _oDlgApr
Private _cMarcaApr  := GetMark() 
Private _lMontaTela := .T.

Begin Sequence

   _cTitulo := "Gestão de Ocorrências de Frete - Aprovação de Ocorrências"   
  
   //================================================================================
   // Cria tabela temporária.
   //================================================================================                                    
   _aStructZF5 := {}
   
   aAdd(_aStructZF5,{"ZF5_DOCOC"   	,"C"	,9	,0 })
   aAdd(_aStructZF5,{"ZF5_FILIAL"  	,"C"	,2	,0 })
   aAdd(_aStructZF5,{"ZF5_CODIGO"  	,"C"	,6	,0 })
   aAdd(_aStructZF5,{"ZF5_CARGA"   	,"C"	,10	,0 })
   aAdd(_aStructZF5,{"ZF5_TIPOO"  	,"C"	,6	,0 })
   aAdd(_aStructZF5,{"ZF5_MOTIVO"  	,"C"	,20	,0 })
   aAdd(_aStructZF5,{"ZF5_MOTCUS"  	,"C"	,100,0 })   
   aAdd(_aStructZF5,{"ZF5_NCLIEN"  	,"C"	,30	,0 })
   aAdd(_aStructZF5,{"ZF5_NREPRE" 	,"C"	,30	,0 })
   aAdd(_aStructZF5,{"ZF5_NCOOR"  	,"C"	,30	,0 })
   aAdd(_aStructZF5,{"ZF5_NTRANS"  	,"C"	,30	,0 })
   aAdd(_aStructZF5,{"ZF5_CUSTOR"  	,"C"	,10	,0 })
   aAdd(_aStructZF5,{"ZF5_PEDIDO"  	,"C"	,20	,0 })
   aAdd(_aStructZF5,{"ZF5_DTFIN"  	,"D"	,8	,0 })
   aAdd(_aStructZF5,{"ZF5_NRPCO"  	,"C"	,25	,0 })
   aAdd(_aStructZF5,{"ZF5_NRPLO"  	,"C"	,25	,0 })
   aAdd(_aStructZF5,{"ZF5_AGENDA"  	,"C"	,120,0 })   
   aAdd(_aStructZF5,{"WK_OK"   		,"C"	,2	,0 })
   aAdd(_aStructZF5,{"WKRECNO" 		,"N"	,10  ,0 })
      
   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
   //================================================================================
   If Select("TRBZF5") > 0
      TRBZF5->( DBCloseArea() )
   EndIf

   //================================================================================
   // Permite o uso do arquivo criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZF5", _aStructZF5)
   
   _otemp:AddIndex( "01", {"ZF5_DOCOC","ZF5_CODIGO"} )

   _otemp:Create()
   
   //================================================================================
   // Carrega dados na tabela temporária.
   //================================================================================  
   Processa( {||U_MOMS034D(  ) } , 'Aguarde!' , 'Filtrando dados...' )
  
   //================================================================================
   // Monta colunas do MsSelect()
   //================================================================================ 
                    //Campo         , "" , Titulo                          , Picture   
   aAdd( _aCampos , { "WK_OK"		,    , "Marca"                         ,"@!"})
   aAdd( _aCampos , { "ZF5_FILIAL"  , "" , "Filial"                        ,"@!"})
   aAdd( _aCampos , { "ZF5_DOCOC"   , "" , "Nota Fiscal"                   ,"@!"})
   aAdd( _aCampos , { "ZF5_CODIGO"  , "" , "Codigo Ocorr"                  ,"@!"}) 
   aAdd( _aCampos , { "ZF5_MOTIVO"  , "" , "Motivo ocorrência"             ,"@!"})  
   aAdd( _aCampos , { "ZF5_MOTCUS"  , "" , "Motivo de Custo"               ,"@!"})
   aAdd( _aCampos , { "ZF5_NCLIEN"  , "" , "Cliente"                       ,"@!"}) 
   aAdd( _aCampos , { "ZF5_NREPRE"  , "" , "Representante"                 ,"@!"}) 
   aAdd( _aCampos , { "ZF5_CUSTOR"  , "" , "Custo"                         ,"@!"}) 
   aAdd( _aCampos , { "ZF5_NCOOR"  	, "" , "Coordenador"                   ,"@!"}) 
   aAdd( _aCampos , { "ZF5_NRPCO"  	, "" , "Assist Comercial"              ,"@!"}) 
   aAdd( _aCampos , { "ZF5_NRPLO"  	, "" , "Assist Logistica"              ,"@!"}) 
   aAdd( _aCampos , { "ZF5_NTRANS"  , "" , "Transportador"                 ,"@!"}) 
   aAdd( _aCampos , { "ZF5_PEDIDO"  , "" , "Pedido"                        ,"@!"}) 
   aAdd( _aCampos , { "ZF5_DTFIN"  	, "" , "Data Encerramento"             ,"@!"}) 
   aAdd( _aCampos , { "ZF5_TIPOO"  	, "" , "Tipo  Ocorr"                   ,"@!"}) 
   aAdd( _aCampos , { "ZF5_CARGA"  	, "" , "Carga"                         ,"@!"})
   aAdd( _aCampos , { "ZF5_AGENDA"  , "" , "Agenda"			               ,"@!"}) 
  
   aAdd(_aButtons,{"RESPONSA",{|| U_MOMS034J("T") },"Marc/Des","Marca/Desmarca Todos"}) 
   aAdd( _aButtons , { "Filtro"	, {|| dbClearFilter(), U_MOMS034P(), _oDlgApr:Refresh(), _oMarkApr:oBrowse:ResetLen(), _oMarkApr:oBrowse:Refresh() } , "Filtro"		, "Filtro"	} )

                              
   _bOk := {|| If(U_MOMS034L(),(_lRet := .T., _oDlgApr:End()),)}
   _bCancel := {|| _lRet := .F., _oDlgApr:End()}

   TRBZF5->(DBGoTop())

   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   _nLin1 := 9
   _nCol1 := 0
   _nLin2 := _aSizeAut[6] * 0.079023  // 55
   _nCol2 := _aSizeAut[5] * 0.126138  // 194
   
   Define MsDialog _oDlgApr Title _cTitulo From _nLin1,_nCol1 To _nLin2,_nCol2 Of oMainWnd 
              
      _oMarkApr := MsSelect():New("TRBZF5","WK_OK","",_aCampos,@_lInverte, @_cMarcaApr,{_aSizeAut[7]+20, 5, _aSizeAut[4]-30, _aSizeAut[3]})
      _oMarkApr:bAval := {|| U_MOMS034J("P")}
      _lMontaTela := .F.
 
   Activate MsDialog _oDlgApr On Init (EnchoiceBar(_oDlgApr,_bOk,_bCancel,,_aButtons), _oMarkApr:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT, _oMarkApr:oBrowse:Refresh())
   
   If _lRet
 
       _cMsg := "Confirma a aprovação da(s) ocorrência(s) de frete selecionada(s) e a alteração de seu Status?"
 
       If !U_ITMsg(_cMsg,"Atenção",,2,2,2)
         Break
      EndIf
            
      _lAtualizou := .F.
      
      TRBZF5->(DBGoTop())
      While ! TRBZF5->(Eof())  
      
         ZF5->(DBGoTo(TRBZF5->WKRECNO)) 
         
         If Empty(TRBZF5->WK_OK)
                                                
 
               ZF5->(RecLock("ZF5",.F.))
               ZF5->ZF5_APRREJ := "R" // Rejeitado
               ZF5->ZF5_USRAPR := SubStr(cUsuario, 7,15)
               ZF5->ZF5_DTAPRR := Date()
               ZF5->ZF5_HRAPRR := SubStr(Time(),1,5)
               ZF5->(MSUnLock())
               _lAtualizou := .T.

          Else  // "APROVAR"
  
               _lAtualizou := .T.
               ZF5->(RecLock("ZF5",.F.))
               ZF5->ZF5_APRREJ := "A" // Aprovado
               ZF5->ZF5_USRAPR := SubStr(cUsuario, 7,15)
               ZF5->ZF5_DTAPRR := Date()
               ZF5->ZF5_HRAPRR := SubStr(Time(),1,5)
               ZF5->(MSUnLock())
  
          EndIf
            
         TRBZF5->(DBSkip())
 
      EndDo                      
      
      If _lAtualizou
 
        //================================================================================	  
        //se está tudo certo inclui o resgistro da aprovação de descontos
        //================================================================================

        RecLock("ZFY",.T.)
 
        ZFY->ZFY_FILIAL     := xFilial("ZFY")   
        ZFY->ZFY_SEQ        := U_MOMS034C()  //Gera nova sequência do ZFY
        ZFY->ZFY_ROTINA     := "Aprovação de descontos por representante"
        ZFY->ZFY_DATA       := Date()
        ZFY->ZFY_HORA       := Time()
        ZFY->ZFY_USER       := cUserName
        ZFY->ZFY_CODUSU     := __cUserId
        ZFY->ZFY_COMP       := ZFZ->ZFZ_COMP
        ZFY->ZFY_OBS        := ZFZ->ZFZ_COMP
 
        MSUnLock()     
 
          	U_ITMsg("Aprovação realizada com sucesso.","Atenção",,2)
      
      Else
 
           U_ITMsg("Não foi possível realizar a aprovação.","Atenção",,1)

      EndIf

  EndIf
   
End Sequence

If Select("TRBZF5") > 0
   DBCloseArea()
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa--------: MOMS034D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/08/2016
===============================================================================================================================
Descrição-------: Carrega os dados das ocorrências de frete filtrados do Comercial, para seleção e aprovação ou rejeição.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno   ------: Nenhum
===============================================================================================================================
*/
User Function MOMS034D()
Local _cQry, _nTotreg
Local _nRegAtu := ZF5->(Recno())
Local _nI
Local _aStatusC := {}

Begin Sequence 

  //Prepara data inicial e data final da competência escolhida
  _cdtfim := SubStr(AllTrim(ZFZ->ZFZ_COMP),4,4) + SubStr(AllTrim(ZFZ->ZFZ_COMP),1,2) + "25"
  _cdtini := SubStr(DToS(SToD(_cdtfim)-30),1,4) + SubStr(DToS(SToD(_cdtfim)-30),5,2) + "26"

   _aStatusC := {{"P","PENDENTE"},{"T","TRATAMENTO"},{"E","ENCERRADO"},{"S","SEM CUSTO"} }

   _cQry := " SELECT ZF5.R_E_C_N_O_ AS NRRECNO FROM "+RetSqlName("ZF5")+" ZF5 "
   _cQry += " WHERE ZF5.D_E_L_E_T_ = ' ' AND ZF5_FILIAL = '"+xFilial("ZF5")+"' "  
   _cQry += " AND ZF5_STATUS = '000001' AND ZF5_DTFIN >= '" + _cdtini + "' AND ZF5_DTFIN <= '" + _cdtfim + "'" 
   _cQry += " AND ZF5_CUSTOR > 0 AND (SELECT SA3.A3_TIPO FROM  "+RetSqlName("SA3")+" SA3 WHERE SA3.D_E_L_E_T_ = ' ' "
   _cQry += " AND SA3.A3_FILIAL = '"+xFilial("SA3")+"'  AND SA3.A3_COD = ZF5.ZF5_REPRES AND ROWNUM = 1) = 'E'" 
   _cQry += " AND (SELECT SA3.A3_I_DESOF FROM  "+RetSqlName("SA3")+" SA3 WHERE SA3.D_E_L_E_T_ = ' ' "
   _cQry += " AND SA3.A3_FILIAL = '"+xFilial("SA3")+"'  AND SA3.A3_COD = ZF5.ZF5_REPRES AND ROWNUM = 1) <> 'N'" 
  If !Empty(_cGetSu)
	   _cQry += " AND ZF5_COORD IN " + FormatIn(_cGetSu,";") + " "
   EndIf
   If !Empty(_cGetRe)
	   _cQry += " AND ZF5_REPRES IN " + FormatIn(_cGetRe,";") + " "
   EndIf
   If !Empty(_cGetMo)
	   _cQry += " AND ZF5_TIPOO IN " + FormatIn(_cGetMo,";") + " "
   EndIf

   _cQry += " ORDER BY ZF5_COORD, ZF5_REPRES, ZF5_TIPOO "
 
 
   
   If Select("QRYZF5") > 0
      DBCloseArea()
   EndIf
           
   _cQry := ChangeQuery(_cQry) 
   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYZF5", .F., .T.)
   
   COUNT TO _nTotreg
   If _nTotreg = 0               
      U_ITMsg("Não existem ocorrências de frete a serem exibidas.","Atenção",,3)
      Break
   EndIf 
                    
   ProcRegua(_nTotreg)

   QRYZF5->(DBGoTop())
   While ! QRYZF5->(Eof())
      IncProc("Filtrando dados de Ocorrências de Frete...")
      
      ZF5->(DBGoTo(QRYZF5->NRRECNO))
      
      TRBZF5->(RecLock("TRBZF5",.T.))
      
      For _nI := 1 To TRBZF5->(FCount())
          If AllTrim(TRBZF5->(FieldName(_nI))) $ "WK_OK/WKRECNO/ZF5_CUSTOR"
             Loop
          EndIf
          &("TRBZF5->"+TRBZF5->(FieldName(_nI))) :=  &("ZF5->"+TRBZF5->(FieldName(_nI)))
      Next    
 
      TRBZF5->ZF5_CUSTOR := PadL(AllTrim(transform(ZF5->ZF5_CUSTOR,"@E 999,999.99")),10)
      TRBZF5->WK_OK := IIf(ZF5->ZF5_APRREJ == 'R', ' ', _cMarcaApr)
      TRBZF5->WKRECNO := QRYZF5->NRRECNO
      TRBZF5->(MSUnLock())
      
      QRYZF5->(DBSkip())
   EndDo
   TRBZF5->(DBGoTop())

End Sequence

If Select("QRYZF5") > 0
   DBCloseArea()
EndIf

ZF5->(DBGoTo(_nRegAtu))

Return

/*
===============================================================================================================================
Programa--------: MOMS034L
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/08/2016
===============================================================================================================================
Descrição-------: Verifica se existe registros marcados na tela de ocorrências de frete filtrados do Comercial, 
                  para seleção e aprovação ou rejeição.
===============================================================================================================================
Parametros------: _cOpcao = Opção selecionada pelo usuário = "REJEITAR" ou "APROVAR"
===============================================================================================================================
Retorno   ------: Nenhum
===============================================================================================================================
*/
User Function MOMS034L(_cOpcao)
Local _lRet := .F.
Local _cMsg, _lTemMarca
Local _nRegAtu := TRBZF5->(Recno())

Begin Sequence
   _cMsg := "Não existem dados marcados para aprovação."
    
   _lTemMarca := .F.
                          
   TRBZF5->(DBGoTop())
   While ! TRBZF5->(Eof())
      If ! Empty(TRBZF5->WK_OK)
         _lTemMarca := .T.     
         _lRet := .T.
         Exit                 
      EndIf
       
      TRBZF5->(DBSkip())
   EndDo
   
   If ! _lTemMarca
      U_ITMsg(_cMsg,"Atenção",,3)
   EndIf
   
End Sequence

TRBZF5->(DBGoTo(_nRegAtu))

Return _lRet              


/*
===============================================================================================================================
Programa--------: MOMS034J
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/08/2016
===============================================================================================================================
Descrição-------: Função para marcar e desmarcar todas as notas fiscais da carga.
===============================================================================================================================
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
                  */
User Function MOMS034J(_cTipoMarca)
Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZF5->(Recno()) 

Begin Sequence          
   If Empty(TRBZF5->WK_OK )
      _cSimboloMarca := _cMarcaApr
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZF5->(RecLock("TRBZF5",.F.))
      TRBZF5->WK_OK := _cSimboloMarca 
      TRBZF5->(MSUnLock())              
   Else
      TRBZF5->(DBGoTop())
      While ! TRBZF5->(Eof())
         TRBZF5->(RecLock("TRBZF5",.F.))
         TRBZF5->WK_OK := _cSimboloMarca 
         TRBZF5->(MSUnLock()) 
          
         TRBZF5->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZF5->(DBGoTo(_nRegAtu)) 
_oMarkApr:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: MOMS034P
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 07/12/2016                                    .
===============================================================================================================================
Descrição---------: Criação do novo grupo de perguntas, para filtrar o browse
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS034P(_lTela)
Local _oGetSu
Local _oGetMo
Local _oGetRe
Local _oSaySu
Local _oSayMo
Local _oSayRe
Local _oSbtCan
Local _oSbtOk
Local _nOpca	:= 0

Private _oDlgFil

DEFINE MSDIALOG _oDlgFil TITLE "Filtro - Ocorrência de Frete" FROM 000, 000  TO 130, 480 COLORS 0, 16777215 PIXEL

	@ 005, 006 Say _oSaySu PROMPT "Coordenador:" SIZE 035, 007 OF _oDlgFil COLORS 0, 16777215 PIXEL
	@ 005, 046 MSGET _oGetSu VAR _cGetSu SIZE 184, 010 OF _oDlgFil COLORS 0, 16777215 F3 "LSTSUP" PIXEL
	@ 021, 006 Say _oSayRe PROMPT "Representante:" SIZE 038, 007 OF _oDlgFil COLORS 0, 16777215 PIXEL
	@ 021, 046 MSGET _oGetRe VAR _cGetRe SIZE 184, 010 OF _oDlgFil COLORS 0, 16777215 F3 "LSTVEN" PIXEL
	If !IsInCallStack("U_MOMS034I")
		@ 037, 006 Say _oSayMo PROMPT "Mot. Ocor.:" SIZE 033, 007 OF _oDlgFil COLORS 0, 16777215 PIXEL
		@ 037, 046 MSGET _oGetMo VAR _cGetMo SIZE 184, 010 OF _oDlgFil COLORS 0, 16777215 F3 "LSTZFC" PIXEL
	EndIf
	DEFINE SBUTTON _oSbtOk FROM 049, 168 Type 01 OF _oDlgFil ENABLE ACTION (_nOpca := 1, _oDlgFil:End())
	DEFINE SBUTTON _oSbtCan FROM 049, 200 Type 02 OF _oDlgFil ENABLE ACTION (_nOpca := 0, _oDlgFil:End())

ACTIVATE MSDIALOG _oDlgFil CENTERED

If IsInCallStack("U_MOMS034I")
	If _nOpca == 1
		_lTela := .T.
	Else
		_lTela := .F.
	EndIf
Else
	If Select("TRBZF5") > 0
		If _nOpca == 1
			//=======================
			// Apago seleção anterior
			//=======================
			TRBZF5->(DBGoTop())
			While !TRBZF5->(Eof())
				RecLock("TRBZF5", .F.)
					TRBZF5->(dbDelete())
				TRBZF5->(MSUnLock())
				TRBZF5->(DBSkip())
			End
			//================================================================================
			// Carrega dados na tabela temporária.
			//================================================================================  
			Processa( {||U_MOMS034D() } , 'Aguarde!' , 'Filtrando dados...' )
		ElseIf _nOpca == 0
			_lTela := .F.
		EndIf
	EndIf
EndIf

Return
