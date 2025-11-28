/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Walluer  |31/03/2022| Chamado 39596. Gravação do campo novo ZLD_VFILHA. 
Alex Walluer  |05/08/2022| Chamado 40901. Nova validacao para não efetivar sem data de estoque. 
Igor Melgaço  |19/04/2024| Chamado 46580. Inclusão de campo de Observações na tela de Dados da Recepção Tipo Plataforma.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RWMAKE.CH"
#Include "FwMVCDef.ch"
#Include "ap5mail.ch"
/*
===============================================================================================================================
Programa--------: AGLT021
Autor-----------: Josué Danich Prestes
Data da Criacao-: 29/04/2016
Descrição-------: Tela para efetivação das recepções do leite recebidas via Smartquestion - Chamado 14887
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT021

DBSelectArea("ZLJ")
ZLJ->(DBSetOrder(2))
//====================================================================================================
// Configura e inicializa a Classe do Browse
//====================================================================================================
_oBrowse := FWMBrowse():New()
_oBrowse:SetAlias( "ZLJ" )   

_aFields:={}
aAdd( _aFields ,{"Tipo Produtor",{|| U_MGLTTipoProd("ZLJ") },"C","@!",1,15, 0 } )//Rdmake MGLT002.PRW
_oBrowse:SetFields(_aFields)

_oBrowse:SetMenuDef( 'AGLT021' )
_oBrowse:SetDescription( "Efetivação das recepções do leite recebidas via Smartquestion" )

 //Legendas
_oBrowse:AddLegend( "ZLJ->ZLJ_STATUS = 'P'", "GREEN", "Pendente" )
_oBrowse:AddLegend( "ZLJ->ZLJ_STATUS = 'E'", "RED",   "Efetivado" )
_oBrowse:AddLegend( "ZLJ->ZLJ_STATUS = 'R'", "GRAY",  "Recusado" )

DBSelectArea("ZLJ")
ZLJ->(DBSetOrder(2))
_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa--------: MenuDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Rotina de definição automática do menu via MVC
Parametros------: Nenhum
Retorno---------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRot := {}

                                                             // TODOS TEM QUE SER MODEL_OPERATION_UPDATE PARA PEGAR DA VARIAVEL DE MEMORIA
ADD OPTION _aRot TITLE 'Sincronizar'   	ACTION 'U_AGLT021R'     		OPERATION MODEL_OPERATION_INSERT ACCESS 0 // 1-Processamento
ADD OPTION _aRot TITLE 'Efetivar'    	ACTION 'U_AGLT021E'     		OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // 2-Tela nova Enchoice //AGLT021Tela()
ADD OPTION _aRot TITLE 'Visualizar' 	ACTION 'U_AGLT021Z'		    	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // 3-Tela nova Enchoice //AGLT021Tela()
ADD OPTION _aRot TITLE 'Recusar'    	ACTION 'U_AGLT021U'     		OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // 4-Tela nova Enchoice //AGLT021Tela()
ADD OPTION _aRot TITLE 'Estornar'    	ACTION 'U_AGLT021A'     		OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // 5-Tela nova Enchoice //AGLT021Tela()
ADD OPTION _aRot TITLE 'Apagar'    	    ACTION 'U_AGLT021F'     		OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // 6-Tela nova Enchoice //AGLT021Tela()
ADD OPTION _aRot TITLE 'Refaz Estoque'  ACTION 'U_AGLT21RE'     		OPERATION MODEL_OPERATION_UPDATE ACCESS 0 // 8-Tela nova Enchoice //AGLT021Tela()
//ATENÇÃO: se For colocar um novo botão coloque abaixo do botão 'Refaz Estoque' pq tem tratamento para _nOpc dentro da função AGLT021Tela(Tela nova Enchoice )
ADD OPTION _aRot TITLE 'Legenda'    	ACTION 'U_AGLT021H'     		OPERATION 6                      ACCESS 0 // 7-Legenda
ADD OPTION _aRot TITLE 'Envia Produtores' ACTION 'U_MGLT001'            OPERATION MODEL_OPERATION_VIEW   ACCESS 0 // 9-Envia produtores para o SQ

Return _aRot

/*
===============================================================================================================================
Programa--------: ModelDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Rotina de definição do Modelo de Dados do MVC
Parametros------: Nenhum
Retorno---------: oModel - Objeto do modelo de dados do MVC
===============================================================================================================================
*/
Static Function ModelDef()

//====================================================================================================
// Inicializa a estrutura do modelo de dados
//====================================================================================================
Local _oStrCAB	:= FWFormStruct( 1 , "ZLJ" , {|_cCampo| AGLT021CPO( _cCampo , 1 ) } )
Local _oStrITN	:= FWFormStruct( 1 , "ZLJ" , {|_cCampo| AGLT021CPO( _cCampo , 2 ) } )
Local _oModel	:= Nil
Local _bValid	:= {|_oModel| .T. }//Grava log de utilização da rotina

//====================================================================================================
// Inicializa e configura o modelo de dados
//====================================================================================================
_oModel :=MPFormModell():New( "AGLT021M" ,, _bValid )

_oModel:SetDescription( 'Viagem - Recepção Leite' )

_oModel:AddFields( 'ZLJMASTER' ,				, _oStrCAB )
_oModel:AddGrid(   'ZLJDETAIL' , "ZLJMASTER"	, _oStrITN )

_oModel:GetModel( 'ZLJMASTER' ):SetDescription( 'Configuração da Tabela'	)
_oModel:GetModel( 'ZLJDETAIL' ):SetDescription( 'Configuração dos Produtos'	)

_oModel:SetRelation( "ZLJDETAIL" , {	{ "ZLJ_FILIAL"	, 'xFilial("ZLJ")'	} ,;
										{ "ZLJ_VIAGEM"	, "ZLJ_VIAGEM"		}  } , ZLJ->( IndexKey( 3 ) ) )

_oModel:GetModel( 'ZLJDETAIL' ):SetUniqueLine( { 'ZLJ_NUMERO' } )

_oModel:SetPrimaryKey( { 'ZLJ_FILIAL' , 'ZLJ_VIAGEM' , 'ZLJ_NUMERO' } )

Return( _oModel )

/*
===============================================================================================================================
Programa--------: ViewDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Rotina de definição da View do MVC
Parametros------: Nenhum
Retorno---------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function ViewDef()

Local _oStrCAB	:= FWFormStruct( 2 , "ZLJ" , {|_cCampo| AGLT021CPO( _cCampo , 1 ) } )
Local _oStrITN	:= FWFormStruct( 2 , "ZLJ" , {|_cCampo| AGLT021CPO( _cCampo , 2 ) } )
Local _oModel	:= FWLoadModel( "AGLT021" )
Local _oView	:= Nil

//====================================================================================================
// Inicializa o Objeto da View
//====================================================================================================
_oView := FWFormView():New()

_oView:SetModel( _oModel )

_oView:AddField( "VIEW_CAB" , _oStrCAB , "ZLJMASTER" )
_oView:AddGrid(  "VIEW_ITN" , _oStrITN , "ZLJDETAIL" )

_oView:CreateHorizontalBox( 'BOX0101' , 065 )
_oView:CreateHorizontalBox( 'BOX0102' , 035 )

_oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )
_oView:SetOwnerView( "VIEW_ITN" , "BOX0102" )

Return( _oView )

/*
===============================================================================================================================
Programa--------: AGLT021CPO
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Configuração da inicialização de campos na tela
Parametros------: _cCampo: Campo , _nOpc : opcao
Retorno---------: oView - Objeto de exibição do MVC
===============================================================================================================================
*/
Static Function AGLT021CPO( _cCampo , _nOpc )
Local _ccampos := ""
Local _lRet := .F. 

//Pasta 1
_ccampos += 'ZLJ_VIAGEM;'
_ccampos += 'ZLJ_STATUS;'
_ccampos += 'ZLJ_DTRAN;'
_ccampos += 'ZLJ_DMOTOR;'
_ccampos += 'ZLJ_DIFER;'
_ccampos += 'ZLJ_DIFER2;'
_ccampos += 'ZLJ_VOLREA;'
_ccampos += 'ZLJ_VOLCOL;'
_ccampos += 'ZLJ_VOLPRO;'
_ccampos += 'ZLJ_VOLCOO;'
_ccampos += 'ZLJ_VFILHS;'
//_ccampos += 'ZLJ_LIN HSQ;'//Para aparecer nos itens
//Pasta 2
_ccampos += 'ZLJ_MOTIVO;'
_ccampos += 'ZLJ_UEFET;'
_ccampos += 'ZLJ_DEFET;'
_ccampos += 'ZLJ_HREFET;'
_ccampos += 'ZLJ_USRSMQ;'
_ccampos += 'ZLJ_LOGINS;'

If _nOpc == 1//Os campos abaixo aparecem na CAPA E NOS ITENS, mas eles não podem esta na lista de acima
	_ccampos += 'ZLJ_DTCRIA;'
	_ccampos += 'ZLJ_DTIVIA;'
	_ccampos += 'ZLJ_CODTRN;'
	_ccampos += 'ZLJ_MOTORI;'
	_ccampos += 'ZLJ_VEICUL;'
	_ccampos += 'ZLJ_LITRAG;'
	_ccampos += 'ZLJ_PLACA;'
	_ccampos += 'ZLJ_LOJTRN;'
	_ccampos += 'ZLJ_HRIVIA;'
	_ccampos += 'ZLJ_DTFVIA;'
	_ccampos += 'ZLJ_HRFVIA;'
	_ccampos += 'ZLJ_PSIVIA;'
	_ccampos += 'ZLJ_PSFVIA;'
	_ccampos += 'ZLJ_DESCAR;'
    _ccampos += 'ZLJ_UINTSQ;'
    _ccampos += 'ZLJ_DINTSQ;'
    _ccampos += 'ZLJ_HINTSQ;'
EndIf
_lRet := AllTrim(_cCampo) $ _ccampos

If _nOpc == 2
	_lRet := !_lRet
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa--------: AGLT021Y
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Retorna o nome do motorista para a viagem posicionada
Parametros------: Nenhum
Retorno---------: _cret - Nome do motorista
===============================================================================================================================
*/
User Function AGLT021Y()

Local _cmot := ZLJ->ZLJ_MOTORI
      
If Empty(_cmot)
   _cmot := Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_MOTORI")     
EndIf

Return (Posicione("ZL0",1,xFilial("ZL0")+_cmot,"ZL0_NOME"))

/*
===============================================================================================================================
Programa--------: AGLT021L
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2015
Descrição-------: Retorna o volumes  do veiculo para a viagem posicionada
Parametros------: _ntipo - 1 (Default) - Retorna volume real do veiculo
							   2 - Retorna volume declarado nas recepções
							   3 - Retorna diferença de volume
Retorno---------: _nret - volume retornado
===============================================================================================================================
*/
User Function AGLT021V(_nTipo,_cAlias)

Local _nvol := 0
Local _nret := 0
Local _nVolrec := 0
Local _cFilial := ZLJ->ZLJ_FILIAL
Local _cViagem := ZLJ->ZLJ_VIAGEM
Local _nPosi   := ZLJ->( Recno() )
Local _aAreaAnt:= ZLJ->( FWGetArea() )
Local _nVolLeiteProprio:= 0
Local _nVolCooperativa := 0

Default _ntipo := 1
Default _cAlias:="ZLJ"//Tratamento para o alias TRB_ZLJ só para o tipo = 1

If ZLJ->(FIELDPOS("ZLJ_VFILHA")) # 0
   ZLJ->( DBSetOrder(5) )//ZLJ_FILIAL+ZLJ_VIAGEM+ZLJ_TIPPRO
   If !ZLJ->( DBSeek( _cFilial + _cViagem + "F" ) ) //Se não achar a linha da julieta fica onde tava
      ZLJ->( DBGoTo(_nPosi) )
   EndIf
EndIf

If (_cAlias)->ZLJ_LITRAG > 0
	_nvol := (_cAlias)->ZLJ_LITRAG
Else
	_nvol :=((_cAlias)->ZLJ_PSIVIA - (_cAlias)->ZLJ_PSFVIA) / Posicione("ZA7",1,(_cAlias)->ZLJ_FILIAL+"001","ZA7_DENPAD")
EndIf

//Se o retorno vai ser o volume da viagem já deixa a variável carregada
If _ntipo == 1
   If (_cAlias)->ZLJ_DESCAR//Se descarte deve ser zerado
  	  _nret := 0
   Else
  	  _nret := _nvol
   EndIf
	
//Se o retorno vai ser o volume declarado das recepções ou diferença de volumes roda o ZLJ para chegar ao total
ElseIf  _ntipo == 2 .Or. _ntipo == 3 .Or. _ntipo == 4 .Or. _ntipo == 5

	ZLJ->( DBSetOrder(2) )
	ZLJ->( DBSeek( _cfilial + _cviagem ) )
	
	While ZLJ->(!Eof()) .And. ZLJ->ZLJ_VIAGEM  == _cviagem .And. ZLJ->ZLJ_FILIAL == _cfilial
	
		_nVolrec += ZLJ->ZLJ_VOLUME
        
        If ZLJ->ZLJ_TIPPRO == 'C' //Cooperativa
           _nVolCooperativa += ZLJ->ZLJ_VOLUME
        ElseIf ZLJ->ZLJ_TIPPRO == 'P'//Leite Proprio
           _nVolLeiteProprio+= ZLJ->ZLJ_VOLUME
		EndIf

		ZLJ->( DBSkip() )
		
	EndDo
	
	If _ntipo == 2
		_nret := _nvolrec
	ElseIf _ntipo == 3
		_nret :=  _nvol - _nvolrec
	ElseIf _ntipo == 4
		_nret := _nVolLeiteProprio 
	ElseIf _ntipo == 5
		_nret := _nVolCooperativa
	EndIf
	
EndIf

//Retorna ZLJ à posição original para não matar o processo do fwbrowse
ZLJ->( FWRestArea(_aAreaAnt) )
ZLJ->( DBGoTo(_nposi) )

Return Round(_nret,0)

/*
===============================================================================================================================
Programa--------: AGLT021H
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Legenda para o fwbrowse principal
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT021H()
    
Local aLegenda := {}
     
//Monta as cores
aAdd(aLegenda,{"BR_VERDE",      	"Pendente"})
aAdd(aLegenda,{"BR_VERMELHO",   	"Efetivado"})
aAdd(aLegenda,{"BR_CINZA",   		"Recusado"})
     
BrwLegenda("Integração Smartquestion", "Recepções", aLegenda)

Return

/*
===============================================================================================================================
Programa--------: AGLT021R
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Atualiza dados a partir do Smartquestion
Parametros------: Nenhum
Retorno---------: .T.  OU .F.
===============================================================================================================================
*/
User Function AGLT021R()

Local oProcess
Local _cPerg  	:= "AGLT021"
Local _nX		:= 0
Local _aFils	:= {}
Local _lOK		:= .F.
Private _cFiltroFilial:= ""
Private _dDtini  := SToD( Posicione("SX6",1,cFilant+"MV_ULMES","X6_CONTEUD") )//ddatabase
Private _dDtfim  := ddatabase
Private _cTransI := Space(Len(ZLJ->ZLJ_CODPAT))
Private _cTraLoI := Space(Len(ZLJ->ZLJ_LOJPAT))
Private _cTransF := Space(Len(ZLJ->ZLJ_CODPAT))
Private _cTraLoF := Space(Len(ZLJ->ZLJ_LOJPAT))
Private _cSetorI := Space(Len(ZLJ->ZLJ_SETOR))
Private _cSetorF := Space(Len(ZLJ->ZLJ_SETOR))
Private _cLinhaI := Space(Len(ZLJ->ZLJ_LINROT))
Private _cLinhaF := Space(Len(ZLJ->ZLJ_LINROT))
Private _cHoraI  := Space(2)
Private _cHoraF  := Space(2)

If !Pergunte(_cPerg)
    Return .F.
EndIf

_cFiltroFilial:= MV_PAR01
_dDtini  := MV_PAR02
_dDtfim  := MV_PAR03
_cSetorI := MV_PAR04
_cSetorF := MV_PAR05
_cLinhaI := MV_PAR06
_cLinhaF := MV_PAR07
_cTransI := MV_PAR08
_cTraLoI := MV_PAR09
_cTransF := MV_PAR10
_cTraLoF := MV_PAR11
_cHoraI  := MV_PAR12
_cHoraF  := MV_PAR13
   
If AGLT21Valid(,"OK")
	_lOK:=.T.
	//Já trava as filiais selecionadas
	If !Empty(_cFiltroFilial)
		_aFils       := StrTokArr(AllTrim(_cFiltroFilial),';')
		_cZLJ_UINTSQ := AllTrim(UsrFullName(__cUserId))
		_lConcorr    := .F.
		_cTread      := ""
		_cFilial     := ""
		_cMens       := ""
		_nFil        := 0
		ZLK->(DBSetOrder(1))//Vamos controlar por filial agora
		
		For _nX := 1 To Len(_aFils)
			_cFilial :=LEFT(_aFils[_nX],2)
		    _lConcorr := .F.
			If ZLK->(DBSeek(_cFilial ))
				If !ZLK->(MsRLock(ZLK->(RECNO())))
					_lConcorr:= .T.
					_cTread  := ZLK->ZLK_THREAD
					_cUser   := Lower(AllTrim(ZLK->ZLK_USUSAR))
					_cViagem := AllTrim(ZLK->ZLK_VIAGEM)
				Else
					ZLK->(RecLock("ZLK",.F.))
					ZLK->ZLK_VIAGEM := _cFilial+"-"+DToC(DATE())+"-"+Time()
					ZLK->ZLK_THREAD := StrZero(ThreadID(),6)
					ZLK->ZLK_USUSAR := _cZLJ_UINTSQ
					ZLK->(MSUnLock())
					ZLK->(RecLock("ZLK",.F.))
				EndIf
			Else
				ZLK->(RecLock("ZLK",.T.))
				ZLK->ZLK_FILIAL := _cFilial  
				ZLK->ZLK_VIAGEM := _cFilial+"-"+DToC(DATE())+"-"+Time()
				ZLK->ZLK_THREAD := StrZero(ThreadID(),6)
				ZLK->ZLK_USUSAR := _cZLJ_UINTSQ
				ZLK->(MSUnLock())
				ZLK->(RecLock("ZLK",.F.))
			EndIf
			If _lConcorr  
               ZLK->(MSUnLockALL())
			   _cMens+=CHR(13)+CHR(10)+_cUser+", filial: "+_cViagem
			   _nFil++
			   _lOK:=.F.
			EndIf
		Next _nX
	EndIf
	If _lOK
	   _cTimeInicial:=Time()
	   oProcess:=MsNewProcess():New({|lEnd| _lOK:=U_MGLT002( _dDtini, _dDtfim, .F., @oProcess, @lEnd) },'Hora Inicial: '+_cTimeInicial,"Atualizando dados...",.T.)
	   oProcess:Activate()
	Else
	   If _nFil > 2
          bBloco:={||  MsgAlert(_cMens,"AGLT02152") }
          _cMens1:="Filiais sendo integradas por usuários: "+CHR(13)+CHR(10)+"Clique em Mais Detalhes"
       Else
          bBloco:=NIL
          _cMens1:="Filiais sendo integradas por usuários: "+_cMens
       EndIf
	   MsgAlert(_cMens1+" Tente novamente daqui a pouco","AGLT02153")
	EndIf
EndIf

If !Empty(_cFiltroFilial)
   ZLK->(DBSetOrder(1))
   For _nX := 1 To Len(_aFils)
	   _cFilial:=LEFT(_aFils[_nX],2)
	   If ZLK->(DBSeek(_cFilial))
          ZLK->(MSUnLock())
       EndIf
   Next _nX
   ZLK->(MSUnLockALL())
EndIf

ZLJ->(DBGoTop())
_oBrowse:Refresh()

Return _lOK

/*
===============================================================================================================================
Programa--------: AGLT21Valid()
Autor-----------: Alex Walaluer
Data da Criacao-: 05/07/2016
Descrição-------: Validacoes da Tela
Parametros------: uDado   : Codigo para validar
                  cChamada: Da onde chamou
Retorno---------: Verdadeiro se os valores informados estiverem consistentes
===============================================================================================================================
*/
Static Function AGLT21Valid(uDado,cChamada)

If cChamada = "OK" 

   If Empty(_cFiltroFilial)
	  MsgStop("A digitação da filial é obrigatoria. Selecione uma ou mais filiais","AGLT02154")
	  Return .F.
   EndIf
   If Empty(_dDtini) .Or. Empty(_dDtfim)
	  MsgStop("As duas datas devem ser preenchidas","AGLT02101")
	  Return .F.
   EndIf
   _dDtMV_ULMES:= SuperGetMV("MV_ULMES",.F.,Date())
   If _dDtini <= _dDtMV_ULMES
	  MsgStop("Data inicial menor ou igual que a data do fechamento do estoque: "+DToC(_dDtMV_ULMES)+"] ","AGLT02102")
	  Return .F.
   EndIf
   If _dDtini > _dDtfim
	  MsgStop("Data inicial deve ser menor que a data final","AGLT02103")
	  Return .F.
   EndIf

   If !Empty(_cSetorF) .And. !AGLT21Valid(_cSetorI,"SE")
	  Return .F.
   EndIf
   If !Empty(_cSetorF) .And. !AGLT21Valid(_cSetorF,"SE")
	  Return .F.
   EndIf
   If !Empty(_cSetorF) .And. _cSetorI > _cSetorF
	  MsgStop("Setor inicial deve ser menor que o setor final","AGLT02104")
	  Return .F.
   EndIf

   If !Empty(_cLinhaI) .And. !AGLT21Valid(_cLinhaI,"LI")
	  Return .F.
   EndIf
   If !Empty(_cLinhaF) .And. !AGLT21Valid(_cLinhaF,"LI")
	  Return .F.
   EndIf
   If !Empty(_cLinhaF) .And. _cLinhaI > _cLinhaF
	  MsgStop("Linha inicial deve ser menor que a linha final","AGLT02105")
	  Return .F.
   EndIf

   If !Empty(_cTransI+_cTraLoI) .And. !AGLT21Valid(_cTransI+_cTraLoI,"TRI")
	  Return .F.
   EndIf
   If !Empty(_cTransF+_cTraLoF) .And. !AGLT21Valid(_cTransF+_cTraLoF,"TRF")
	  Return .F.
   EndIf
   If !Empty(_cTransF+_cTraLoF) .And. _cTransI+_cTraLoI > _cTransF+_cTraLoF
	  MsgStop("Transportador inicial deve ser menor que o transportador final","AGLT02106")
	  Return .F.
   EndIf
   If !Empty(_cHoraI) .And. Val(_cHoraI) < 0 .Or. Val(_cHoraI) > 23
	  MsgStop("A hora Inicial só pode ser de Meia Noite (0) as 23 horas ","AGLT02107")
	  Return .F.
   EndIf    
   If !Empty(_cHoraF) .And. Val(_cHoraF) < 0 .Or. Val(_cHoraF) > 23
	  MsgStop("A hora Final só pode ser de Meia Noite (0) as 23 horas ","AGLT02108")
	  Return .F.
   EndIf    
   If !Empty(_cHoraI) .And. !Empty(_cHoraF) .And. Val(_cHoraI) >  Val(_cHoraF) 
	  MsgStop("A hora Inical é menor que a hora Final ","AGLT02109")
	  Return .F.
   EndIf    

ElseIf Empty(uDado)// SE EM BRANCO NAO VALIDA OS CAMPOS ABAIXO, ELES NãO SãO OBRIGATORIOS
   Return .T.

ElseIf cChamada = "TR" 
	SA2->(DBSetOrder(1))
	If SA2->(DBSeek(xFilial()+uDado))
		If !SA2->A2_I_CLASS $ "A,T,G,C"  .Or. SA2->A2_MSBLQL # "2" .Or. SA2->A2_L_ATIVO == 'N'
			MsgStop("Código: "+uDado+" não é do tipo Transportador (T,A,G,C) ou esta bloqueado ou inativo","AGLT02110")
			Return .F.
		EndIf
	Else
		MsgStop("Codigo: "+uDado+" do Transportador nao cadastrado","AGLT02111")
		Return .F.
	EndIf

ElseIf cChamada = "SE" 
	ZL2->(DBSetOrder(1))
	If !ZL2->(DBSeek(xFilial()+uDado))
		MsgStop("Codigo: "+uDado+" do Setor nao cadastrado","AGLT02112")
		Return .F.
	EndIf

ElseIf cChamada = "LI" 
	ZL3->(DBSetOrder(1))
	If !ZL3->(DBSeek(xFilial()+uDado))
		MsgStop("Codigo: "+uDado+" da Linha nao cadastrado","AGLT02113")
		Return .F.
	EndIf

ElseIf cChamada = "PLACA"
	ZZV->(DBSetOrder(3))
	If uDado <> ZZV->ZZV_PLACA
		ZZV->(DBSeek(xFilial("ZZV")+uDado))
	EndIf
	_cZLX_TRANSP := ZZV->ZZV_TRANSP
	_cZLX_LJTRAN := ZZV->ZZV_LJTRAN
	_cNomeTRAN   := Posicione('SA2',1,xFilial('SA2')+_cZLX_TRANSP+_cZLX_LJTRAN,'A2_NREDUZ')

EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021U
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Recusa recepção posicionada
Parametros------: _cAlias: Tabela , nRecZLJ: Recno , _nOpc: Opcao
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT021U(_cAlias , nRecZLJ , _nOpc )

Local _bok     :=  { || AGLT021VL()  }

//Verifica status
If ZLJ->ZLJ_STATUS == "R"
	MsgStop("Viagem já está recusada","AGLT02114")
	Return
EndIf	

If ZLJ->ZLJ_STATUS == "E"
	MsgStop("Viagem já está efetivada, realize estorno primeiro.","AGLT02115")
	Return
EndIf	

//Locka registros
If !( AGLT021LO( SubStr( ZLJ->ZLJ_FILIAL , 1 , 2 ), ZLJ->ZLJ_VIAGEM ) )
	Return .F.
EndIf

AGLT021Tela("Recusa de Recepcao",_bok,_nOpc,nRecZLJ)

AGLT021UN(ZLJ->ZLJ_FILIAL, ZLJ->ZLJ_VIAGEM )

Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021GRC
Autor-----------: Josué Danich Prestes
Data da Criacao-: 13/04/2016
Descrição-------: Grava as informações da recusa da recepção
Parametros------: _cmotivo - Motivo da recusa
				  _lEstoque - movimenta estoque
				  _lrefaz - veio do refaz estoque automático
Retorno---------: .T.
===============================================================================================================================
*/
Static Function AGLT021GRC(_cmotivo,_lEstoque,_lRefaz)

Local _nI  := 0
Local _lOK := .T.
Local _lRet:= .T.   
Local _asetores:= {}
Local _cFilOr  := ZLJ->ZLJ_FILIAL
Local _cviajori:= ZLJ->ZLJ_VIAGEM  
Local _dSalvaDT:= ZLJ->ZLJ_DTCRIA
Local _cAlias  := GetNextAlias()
Local _lAltDtEstoque:= .T.
Default _lEstoque   := .F.
Default _lRefaz     := .F.

BeginSql alias _cAlias
	SELECT D3_EMISSAO
	  FROM %Table:SD3%
	 WHERE D_E_L_E_T_ = ' '
	   AND D3_ESTORNO != 'S'
	   AND D3_L_ORIG = %exp:_cViajori%
	   AND D3_FILIAL = %exp:_cFilOr%
EndSql	
	
If !Empty((_cAlias)->D3_EMISSAO)
   _dSalvaDT:= SToD((_cAlias)->D3_EMISSAO)
EndIf

(_cAlias)->(DBCloseArea())

If _lEstoque .And. _dSalvaDT = M->ZLJ_DTCRIA
	If !_lRefaz .And. !MsgYesNo("A data de Estoque "+DToC(M->ZLJ_DTCRIA)+" não foi alterada, mas essa data pode ser REPLICADA para todos os atendimentos dessa viagem, CONFIRMA ?","AGLT02116")
	   Return .F.
    EndIf
    _lAltDtEstoque:=.F.
EndIf

If Empty(_cmotivo)
	MsgStop("Motivo obrigatório! Preencha o campo motivo","AGLT02116")
	Return .F.
EndIf

Begin TRANSACTION
Begin Sequence

ProcRegua(0)
IncProc("Lendo Viagem...")
IncProc("Lendo Viagem...")

_cusrname := UsrFullName(__cUserId)

ZLJ->( DBSetOrder(2) )
ZLD->( DBSetOrder(7) )
If ZLJ->( DBSeek( SubStr( _cFilOr , 1 , 2 ) + _cviajori ) )

   While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL + ZLJ->ZLJ_VIAGEM == SubStr(_cFilOr,1,2) + _cviajori
	
        IncProc("Lendo Atendimento: "+ZLJ->ZLJ_NUMERO) 

		If _lEstoque .And. _lAltDtEstoque .And. !Empty(ZLJ->ZLJ_NUMERO) .And. ZLD->( DBSeek( xFilial("ZLD") + ZLJ->ZLJ_NUMERO) )

		    If ZLD->ZLD_STATUS = "F"  .Or. AGLT021D( ZLD->ZLD_DTCOLE , ZLD->ZLD_RETIRO , ZLD->ZLD_RETILJ , .T.,ZLJ->ZLJ_TIPPRO )
		       Disarmtransaction()  
		       If ZLD->ZLD_STATUS = "F"
  		          MsgStop("Registro de recepção já teve fechamento ou eventos: "+xFilial("ZLD") + ZLJ->ZLJ_NUMERO ,"AGLT02117")
  		       EndIf   
	          _lOK:=.F.
	          Break
            EndIf

	    EndIf

		ZLJ->( RecLock( "ZLJ" , .F. ) )
		
		If _lEstoque
		   If _lAltDtEstoque
              ZLJ->ZLJ_MOTIVO := "Alt Dt Estoq:Usu.:"+AllTrim(_cusrname)+",Dt:"+DToC(ddatabase)+",Hr:"+Time()
           ElseIf ZLJ->ZLJ_DTCRIA # M->ZLJ_DTCRIA
              _dSalvaDT:= ZLJ->ZLJ_DTCRIA
              ZLJ->ZLJ_MOTIVO := "Confirmada Dt Estoq:Usu.:"+AllTrim(_cusrname)+",Dt:"+DToC(ddatabase)+",Hr:"+Time()
           EndIf
		Else
           ZLJ->ZLJ_STATUS := "R"
		   ZLJ->ZLJ_UEFET  := _cusrname//cUserName
		   ZLJ->ZLJ_DEFET  := ddatabase
		   ZLJ->ZLJ_HREFET := Time()
		   ZLJ->ZLJ_MOTIVO := _cmotivo
		EndIf	
		ZLJ->( MSUnLock() )
		
		//Tem que ser dentro While pq pode ser tudo cooperativa 
		If _lAltDtEstoque .And. aScan(_asetores, ZLJ->ZLJ_VIAGEM ) == 0 .And. ZLJ->ZLJ_TIPPRO $ 'P,A' .And. !ZLJ->ZLJ_DESCAR .And. U_AGLT021V(1) # 0 //Nao é descarte  Vol. veiulo zerado
			aAdd(_asetores, ZLJ->ZLJ_VIAGEM )
		EndIf
		
	    ZLJ->( DBSkip() )
	    
	EndDo
	
EndIf

ProcRegua(0)

ZLJ->( DBSeek( SubStr( _cFilOr , 1 , 2 ) + _cviajori ) )

For _nI := 1 To Len(_aSetores)

	cSetor := ""//_asetores[_nI]//Variavel usada dentro da funcao U_AGLT003G()
    IncProc("Estornando Estoque da Data: "+DToC(_dSalvaDT))
					
	If ! U_AGLT003G(ZLJ->ZLJ_VIAGEM,5) //Estorna movimento de estoque igual a rotina da recepção manual
		Disarmtransaction()
		MsgStop("Não foi possível estornar a entrada de estoque da data "+DToC(_dSalvaDT)+" da Viagem: "+ZLJ->ZLJ_VIAGEM +". Entre em contato com a area de PCP / Estoque","AGLT02118")
        _lOK:=.F.
        _lRet := .F.
        Break
	EndIf
		
Next

If _lOK .And. _lEstoque .And. _lAltDtEstoque .And. !AGLT021PES(2,_lEstoque)
   _lOK:=.F.
   _lRet := .F.
   Disarmtransaction()
EndIf

End Sequence
End Transaction

If _lOK .And. _lEstoque .And. !_lRefaz
   MsgInfo("Data de Estoque ALTERADA DE: "+DToC(_dSalvaDT)+" PARA: "+DToC(M->ZLJ_DTCRIA)+" com sucesso!","AGLT02119")
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: AGLT021LO
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Locka registros da viagem
Parametros------: _cfilAux - Filial do pedido
				  _cnumped - Numero da viagem
Retorno---------: _lRet - se conseguiu ou não lockar os registros do pedido
===============================================================================================================================
*/
Static Function AGLT021LO(_cFilAux,_cNumvia)

Local _lRet := .T.
Local _aArea := ZLJ->(GetArea())

//=======================================================================================================================
//Bloqueia a viagem na pesquisa, para que não seja possivel enquanto esta rotina estiver sendo utilizada a sua alteracao	
//=======================================================================================================================	
DBSelectArea("ZLJ")
ZLJ->( DBSetOrder(2) )

If ZLJ->( DBSeek( _cFilAux + _cNumvia ) )
	While ZLJ->(!Eof()) .And. ZLJ->( ZLJ_FILIAL + ZLJ_VIAGEM ) == _cFilAux + _cNumvia .And. _lRet
		If ZLJ->( DBRLock() )
			ZLJ->( MSUnLock())	
			RecLock("ZLJ",.F.)
			ZLJ->( DBSkip() )
		Else
			MsgStop( "Falha ao reservar a viagem, está em uso por outra estação","AGLT02120")
			_lRet := .F.
		EndIf
	EndDo
Else
	MsgStop("Falha ao identificar a viagem. Informar a área de TI/ERP.","AGLT02121")
	_lRet := .F.
EndIf

FWRestArea( _aArea)

Return _lRet

/*
===============================================================================================================================
Programa--------: AGLT021UN
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: UnLocka registros da recepção do leite
Parametros------: _cfilAux - Filial do pedido
					_cnumped - Numero do pedido
Retorno---------: _lRet - se conseguiu ou não lockar os registros do pedido
===============================================================================================================================
*/
Static Function AGLT021UN(_cFilAux,_cNumPed)

Local _aArea := FWGetArea()

DBSelectArea("ZLJ")
ZLJ->( DBSetOrder(2) )

If ZLJ->( DBSeek( _cFilAux + _cNumPed ) )
	While ZLJ->(!Eof()) .And. ZLJ->( ZLJ_FILIAL + ZLJ_VIAGEM ) == _cFilAux + _cNumPed 
		ZLJ->( MSUnLock())	
		ZLJ->( DBSkip() )
	EndDo
EndIf

FWRestArea( _aArea)

Return

/*
===============================================================================================================================
Programa--------: AGLT021VL
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Le motivo de recusa e encaminha para função de processamento da recusa
Parametros------: Nenhum
Retorno---------: _lRet - se confirmou a janela de motivo e se preencheu o motivo
===============================================================================================================================
*/
Static Function AGLT021VL()

Local _lRet := .F.
Local _cMens1 := Space(100)

While .T.
	_lRet := .F.
	DEFINE FONT oFont NAME "Tahoma" BOLD
			
	@0,0 To 320,500 DIALOG oDlg TITLE "Dados da recusa"
			
	oTPanel1:= TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,300,160,.T.,.F.)
				
	@005,010 Say "Motivo de Recusa"						Of oTPanel1 Pixel FONT oFont
	@020,010 Say "Viagem........: "+ ZLJ->ZLJ_VIAGEM	Of oTPanel1 Pixel
	@035,010 Say "Transportador.: "+ ZLJ->ZLJ_CODTRN 	Of oTPanel1 Pixel
					
	oTFolder1 := TFolder():New( 050,005,{"Motivo"},,oTPanel1,,,,.T.,,240,090 )
				
	@ 005,005 Get _cMens1 MEMO Size 230,60 when .T. of oTFolder1:aDialogs[1] Pixel
	
	TButton():New( 145 , 010 , ' Confirma '	, oTPanel1 , {|| Processa( {|| _lRet := AGLT021GRC(_cMens1) } ) ,  oDlg:END()	} , 70 , 10 ,,,, .T. )
	TButton():New( 145 , 080 , ' Cancela '	, oTPanel1 , {||  oDlg:END()	} , 70 , 10 ,,,, .T. )
				
	Activate MSDialog oDlg Centered
	
	If Empty(_cMens1)
	   Loop
	EndIf
	
	Exit
EndDo

Return _lRet

/*
===============================================================================================================================
Programa--------: AGLT021Z
Autor-----------: Alex Wallauer 
Data da Criacao-: 18/07/2016
Descrição-------: Visualizar Recepcao
Parametros------:  _cAlias: Tabela , nRecZLJ: Recno , _nOpc: Opcao
Retorno---------: .T.
===============================================================================================================================
*/
User Function AGLT021Z(_cAlias , nRecZLJ , _nOpc)

AGLT021Tela("Visualizar Recepcao",{ || .T. },_nOpc,nRecZLJ)

Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021F
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Apaga recepção posicionada
Parametros------:  _cAlias: Tabela , nRecZLJ: Recno , _nOpc: Opcao
Retorno---------: .T. OU .F.
===============================================================================================================================
*/
User Function AGLT021F(_cAlias , nRecZLJ , _nOpc)

Local _bok     :=  { || AGLT021ER(.T.) }

//Verifica status
If ZLJ->ZLJ_STATUS == "E"
	MsgAlert("Estorne a viagem antes de apagar!","AGLT02122")
	Return .F.
EndIf	

If ZLJ->ZLJ_STATUS == "P"
	MsgAlert("Recuse a viagem antes de apagar","AGLT02123")
	Return .F.
EndIf	

//Locka registros
If !( AGLT021LO( SubStr( ZLJ->ZLJ_FILIAL , 1 , 2 ), ZLJ->ZLJ_VIAGEM ) )
	Return .F.
EndIf
	      
AGLT021Tela("Apagar Recepcao",_bok,_nOpc,nRecZLJ)

//DesLocka registros
AGLT021UN(ZLJ->ZLJ_FILIAL,ZLJ->ZLJ_VIAGEM)

Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021E
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Efetiva recepção posicionada
Parametros------: _cAlias: Tabela , nRecZLJ: Recno , _nOpc: Opcao
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT021E(_cAlias , nRecZLJ , _nOpc)

Local _bok     :={|| lOk:=.F., Processa( {|| lOk:=AGLT021EL()} ), lOk }
Local _bMarca  :={|oMark| GLT21Marca(oMark) }	
Local _aButtons:={}

//Verifica status
If ZLJ->ZLJ_STATUS == "R"
	MsgStop("Viagem, está recusada. Realize estorno da recusa primeiro.","AGLT02124")
	Return
EndIf	

If ZLJ->ZLJ_STATUS == "E"
	MsgAlert("Viagem já está efetivada!","AGLT02125")
	Return
EndIf	

//Locka registros
If !( AGLT021LO( SubStr( ZLJ->ZLJ_FILIAL , 1 , 2 ), ZLJ->ZLJ_VIAGEM ) )
	Return
EndIf

aAdd( _aButtons , { "RESPONSA" , {|| _Ret:=.T., Processa(  {|| _Ret:=AGLT021K()  } ) , If(!_Ret,(nOpca:=0,oDlg:End()),) } , "Reprocessar dados", "Reprocessar"} )

AGLT021Tela("Efetivação de Recepcao",_bok,_nOpc,nRecZLJ,_aButtons,_bMarca)

//DesLocka registros
AGLT021UN(ZLJ->ZLJ_FILIAL, ZLJ->ZLJ_VIAGEM )

Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021EL
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Processa Efetivação da recepção posicionada
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AGLT021EL()

Local _nRecZLJ 	:= ZLJ->( Recno() )
Local _cviagem	:= ZLJ->ZLJ_VIAGEM
Local _nPosLinha:= 0
Local _nI		:= 0
Local _nTotBom	:= 0
Local _aLinhas  := {}
Local _nTotger	:= 0
Local _lGera_ZLX:=.F.
Local _oDlg		:= Nil
Local _oMemoKM	:= Nil
Local _oBtnCon	:= Nil
Local _cJustKM	:= ""
Local _cDivKM	:= " "
Local _nTolerKM	:= SuperGetMv("LT_KMTOLER",.F.,5)
Local _lcont	:= .T.
Local lTemCpoTPKM:=ZL3->(FIELDPOS("ZL3_TPKM")) <> 0
Private nTotBom		:= 0
Private dDtColeta 	:= ddatabase
Private cSetor		:= ""

ProcRegua(0)	
DBSelectArea("ZLD")
DBSelectArea("ZLW")
DBSelectArea("ZLJ")

SA2->( DBSetOrder(1))
ZLW->( DBSetOrder(7))
ZLD->( DBSetOrder(7))
ZL2->( DBSetOrder(1))

ZLJ->( DBSetOrder(5))//ZLJ_FILIAL+ZLJ_VIAGEM+ZLJ_TIPPRO+ZLJ_VFILHA+ZLJ_SETOR+ZLJ_LINROT   //ZLJ_FILIAL+ZLJ_VIAGEM+ZLJ_SETOR+ZLJ_TIPPRO+ZLJ_LINROT
ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem))
	
lTemSoAtravessador:= .T.
lTemLeiteproprio  := .F.
nTotLProprio      := 0
nTotCooperativa   := 0
_cLinhaRota       := ""//Preenche o km na linha/Rota para O MENOR atendimento da viagem SÓ do Leite proprio
_aSetores	      := {}
_nSetor			  := 0
_aAtraSetores     := {}
_aDuplicados      := {}
_nAtraSetor		  := 0
lMaeTemAtendimento:= .F.
_cFilhasIntegradas:= ""
_cFilhasMae:=""

ProcRegua(TRB->(LASTREC()))	

//Pre - Processamentos
While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL == xFilial("ZLJ") .And. ZLJ->ZLJ_VIAGEM == _cviagem

   IncProc("Validando Atendimento: "+ZLJ->ZLJ_NUMERO) 
   If AGLT021D( ZLJ->ZLJ_DTIVIA , ZLJ->ZLJ_CODPAT , ZLJ->ZLJ_LOJPAT , .F. ,ZLJ->ZLJ_TIPPRO)
      Return .F.
   EndIf

   If aScan(_aDuplicados, ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_NUMERO ) = 0
	  aAdd(_aDuplicados, ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_NUMERO )
   Else
	  MsgStop("Essa viagem possui atendimentos duplicados. Recuse e apague essa viagem e integre novamente, e verifique se estoque foi estornado corretamente","AGLT02155")
      Return .F.
   EndIf

   If Empty(ZLJ->ZLJ_VFILHA)
      lMaeTemAtendimento:=.T.
   Else
      _cFilhasIntegradas+=ZLJ->ZLJ_VFILHA+"-"//Filhas já integradas
   EndIf

   If !Empty(ZLJ->ZLJ_VFILHS)
      _cFilhasMae:=AllTrim(ZLJ->ZLJ_VFILHS)//Filhas que esta na lista da Mae
   EndIf
   
	If (nPos:=aScan(_aSetores, {|S| S[1] == ZLJ->ZLJ_SETOR+ZLJ->ZLJ_TIPPRO} )) = 0 //+ZLJ->ZLJ_VFILHA
	   aAdd(_aSetores, {ZLJ->ZLJ_SETOR+ZLJ->ZLJ_TIPPRO, ZLJ->ZLJ_VOLUME,"Posicao desativada",0})//Acumula os totais de leite por setor de todos os tipos //+ZLJ->ZLJ_VFILHA
	Else
	   _aSetores[nPos][2] += ZLJ->ZLJ_VOLUME
	EndIf

    //Atravessadores
	If SA2->(DBSeek(xFilial("SA2")+ZLJ->ZLJ_CODPAT+ZLJ->ZLJ_LOJPAT)) .And. SA2->A2_L_TIPPR = "A" .And. !Empty(SA2->A2_L_ATRCO)
       _cSalvaCod:=SA2->A2_L_ATRCO+" "+SA2->A2_L_ATRLO
       If !SA2->(DBSeek(xFilial("SA2")+SA2->A2_L_ATRCO+SA2->A2_L_ATRLO)) .Or. (SA2->A2_L_TIPPR # "P" .Or. SA2->A2_I_CLASS # "P")
		  MsgStop(	 'Os campos de "Cod. Atravessador" e "Loja Atravessador" devem ser da Classificacao: PRODUTOR e do Tipo: PRODUTOR.'+;
					 "Cadastratamento atual: Cod. Atravessador+Loja: "+_cSalvaCod+" - Classificacao: "+SA2->A2_I_CLASS+" - Tipo: "+SA2->A2_L_TIPPR,;
                     'Problema nos dados do cadastro de fornecedores',;
		             "Ajuste o cadastro do Produtor: "+ZLJ->ZLJ_CODPAT+" "+ZLJ->ZLJ_LOJPAT+" com um Cod. Atravessador correto","AGLT02126")
	      Return .F.
	   
	   EndIf

	   If (nPosA:=aScan(_aAtraSetores, {|S| S[1] == ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_SETOR} )) = 0//Acumula os totais de leite por setor do tipo atravessador
	      aAdd(_aAtraSetores, {ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_SETOR, ZLJ->ZLJ_VOLUME})
	   Else
	      _aAtraSetores[nPosA][2] += ZLJ->ZLJ_VOLUME
	   EndIf

    ElseIf SA2->A2_L_TIPPR # "A"
		lTemSoAtravessador:= .F.
	EndIf

	If (nPosL:=aScan(_aLinhas, {|S| S[1] == ZLJ->ZLJ_TIPPRO+ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_SETOR+ZLJ->ZLJ_LINROT } )) = 0
	   aAdd(_aLinhas, {ZLJ->ZLJ_TIPPRO+ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_SETOR+ZLJ->ZLJ_LINROT, ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_NUMERO})
	Else
	   If ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_NUMERO < _aLinhas[nPosL][2]//Acumula as quebras da geracao do numero da recepcao para ordenar por atendimento do menor para o maior
	      _aLinhas[nPosL][2] :=ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_NUMERO
	   EndIf   
	EndIf

	If ZLJ->ZLJ_TIPPRO == "P" .Or. ZLJ->ZLJ_TIPPRO == "A"//Leite proprio //Testa o tipo A para previnir
       nTotLProprio+=ZLJ->ZLJ_VOLUME
	   lTemLeiteproprio:=.T.
	ElseIf ZLJ->ZLJ_TIPPRO == "C"
       nTotCooperativa+=ZLJ->ZLJ_VOLUME
	EndIf   

	_nTotger += ZLJ->ZLJ_VOLUME//Para DEBUG	

    If ZL2->( DBSeek(xFilial()+ZLJ->ZLJ_SETOR)) .And. ZL2->ZL2_CRIRT = "1" .And. lTemLeiteproprio
       _lGera_ZLX:=.T.
    EndIf
    If ZLJ->ZLJ_DTIVIA < M->ZLJ_DTIVIA 
       M->ZLJ_DTIVIA := ZLJ->ZLJ_DTIVIA//Gravar a menor data de todos
    EndIf

	ZLJ->( DBSkip() )
		
EndDo

If Empty(M->ZLJ_DTCRIA) .And. lTemLeiteproprio
   U_ITMsg("Data de estoque em branco, o estoque não foi gerado corretamente.","ATENCAO !",;
            "Recuse, apague essa viagem e integre novamente. Apos a integracao analise o KARDEX para validar o Estoque.",3)//,2,3,,"CONTINUAR","VOLTAR")
   Return .F.
EndIf


If !Empty(_cFilhasIntegradas) .And. Empty(_cFilhasMae)
    MsgStop("Problema nos dados da Viagem Julieta a viagem Mae não foi integrada"+;
            "Tente integrar novamente e verifique se a Vaigem Mãe não foi recusada ou esta em outro dia.","AGLT02127")
    Return .F.
EndIf

_aFilhasMae := StrTokArr(_cFilhasMae,"-")
_cFilhasNaoIntegradas:=""
For _nI := 1 To Len(_aFilhasMae)
    If !_aFilhasMae[_nI] $ _cFilhasIntegradas
       _cFilhasNaoIntegradas+=_aFilhasMae[_nI]+", "
    EndIf
Next _nI

_cFilhasNaoIntegradas:=LEFT(_cFilhasNaoIntegradas,Len(_cFilhasNaoIntegradas)-2)

If !Empty(_cFilhasNaoIntegradas)
    MsgStop("Problema nos dados da Viagem Julieta a(s) viagem(ns) Filha(s) abaixo não foram integrada(s). "+;
            "Tente integrar novamente e verifique se as Viagens não foram recusadas ou estão em outro dia: "+_cFilhasNaoIntegradas,"AGLT02128")
    Return .F.
EndIf

//================================================================================
// Projeto Automação das Recepções Tipo Plataforma
//================================================================================
aDados:={}
If _lGera_ZLX .And. Empty( (aDados:=U_AGLTTela_ZLX("ORI_ZLJ")) )
   Return .F.
EndIf
Private _lGerou_ZLX:=.F. //Alterada na Funcao U_AGLTGrv_ZLX()
ProcRegua(TRB->(LastRec()))	
TRB->(DBGoTop())

_aMenorAtenViagem:={}
_aTemLinhaSQIgual:={}
_aTemSetorSQIgual:={}
ZL3->( DBSetOrder(1) )

While TRB->(!Eof()) 

   IncProc("Lando Atendimento: "+ZLJ->ZLJ_NUMERO) 

   If lMaeTemAtendimento .And. TRB->ZLJ_TIPPRO = 'F'//Recebimento
      TRB->( DBSkip() )
      Loop
   EndIf

   If !lTemSoAtravessador                                                                             //P=Leite Proprio;C=Cooperativa;A=Atravessador
      If TRB->ZLJ_TIPPRO = "P" .And. Posicione("SA2",1,xFilial("SA2")+TRB->ZLJ_CODPAT+TRB->ZLJ_LOJPAT,"A2_L_TIPPR") # "P"//Para ignorar os atravessadores
         TRB->( DBSkip() )
         Loop
      EndIf
   EndIf

   If TRB->ZLJ_TIPPRO $ "P,R,F" //(P)Leite proprio/Atravessador ou (R)Reboque ou (F)Recebimento

	  If (nPosL:=aScan(_aMenorAtenViagem, {|S| S[1] == TRB->ZLJ_VFILHA } )) = 0//             4           5    6    7
	     aAdd(_aMenorAtenViagem, {TRB->ZLJ_VFILHA , TRB->ZLJ_LINROT , TRB->ZLJ_NUMERO , TRB->ZLJ_KMDVIA , "" , "" , ""})
		 nPosL:=Len(_aMenorAtenViagem)
	  Else
	     If TRB->ZLJ_NUMERO < _aMenorAtenViagem[nPosL][3]
	        _aMenorAtenViagem[nPosL][2] :=TRB->ZLJ_LINROT//Guarda a linha/rota do menor atendimento de cada sub-viagem para colocar o KM
	        _aMenorAtenViagem[nPosL][3] :=TRB->ZLJ_NUMERO
	     EndIf   
      EndIf
   
      If TRB->ZLJ_LINHSQ == TRB->ZLJ_LINROT//Se tive uma linha = a linha do SQ colocar o KM nela senão fica a menor
         _aMenorAtenViagem[nPosL][5]:=TRB->ZLJ_LINROT
		 aAdd(_aTemLinhaSQIgual,TRB->ZLJ_VFILHA)//Guarda as viagens que tem linha igual a do SQ
      EndIf

      If ZL3->( DBSeek( xFilial("ZL3") + TRB->ZLJ_LINHSQ ) )
         If ZL3->ZL3_SETOR == TRB->ZLJ_SETOR//Se tive uma setor = a setor do SQ colocar o KM nela senão fica a menor
	        If Empty(_aMenorAtenViagem[nPosL][6]) .Or. TRB->ZLJ_NUMERO < _aMenorAtenViagem[nPosL][6] 
               _aMenorAtenViagem[nPosL][6]:=TRB->ZLJ_NUMERO
               _aMenorAtenViagem[nPosL][7]:=TRB->ZLJ_LINROT
			EndIf   
	   	    aAdd(_aTemSetorSQIgual,TRB->ZLJ_VFILHA)//Guarda as viagens que tem setor igual a do SQ
         EndIf
      EndIf

   EndIf

   TRB->( DBSkip() )
		
EndDo

ZLJ->( DBSetOrder(5))//ZLJ_FILIAL+ZLJ_VIAGEM+ZLJ_TIPPRO+ZLJ_VFILHA+ZLJ_SETOR+ZLJ_LINROT   //ZLJ_FILIAL+ZLJ_VIAGEM+ZLJ_SETOR+ZLJ_TIPPRO+ZLJ_LINROT
If !ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem + "F" ))
    ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem ))
EndIf

If ZLJ->ZLJ_LITRAG == 0
   _nTotCaminhao:= (ZLJ->ZLJ_PSIVIA - ZLJ->ZLJ_PSFVIA) / Posicione("ZA7",1,xFilial("ZA7")+"001","ZA7_DENPAD")
Else
   _nTotCaminhao:= ZLJ->ZLJ_LITRAG
EndIf

_nDiferenca:=(_nTotCaminhao - nTotCooperativa)

_aLinhas := aSort(_aLinhas,,,{|x,y| x[2] < y[2] })//Ordena por Atendimento

ProcRegua(Len(_aLinhas))	
		
Begin Transaction

	_lgravou := .F. //Flag se teve gravação de ZLD
	_lDtEstDif:=.F. //Flag se tem datas diferentes de estoque
	
	DBSelectArea("ZL3")
	ZL3->( DBSetOrder(1) )
	
	For _nPosLinha := 1 To Len(_aLinhas)
		//Zero as variáveis a cada nova gravação da ZLD 
		_cDivKM := " "
		_cJustKM := " "
	   //order(5)     ZLJ_FILIAL     + ZLJ_VIAGEM+ZLJ_TIPPRO+ZLJ_VFILHA+ZLJ_SETOR+ZLJ_LINROT
	   ZLJ->( DBSeek( xFilial("ZLJ") + _cViagem  +_aLinhas[_nPosLinha][1] ))	
	
	   IncProc("Gravando Atendimento: "+ZLJ->ZLJ_NUMERO) 
	   
	   If (_nSetor:=aScan(_aSetores, {|S| S[1] == ZLJ->ZLJ_SETOR+ZLJ->ZLJ_TIPPRO} )) = 0//+ZLJ->ZLJ_VFILHA
		  ZLJ->( DBSkip() )
		  Loop
	   EndIf
	   
	   _cNumRecP := u_GetNumRec()  //busca ultimo numero de recepção leite proprio ZLD
	   _cNumRecW := u_GetNumRww()  //busca ultimo numero de recepção cooperativa ZLW	
		
		While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL == xFilial("ZLJ")        .AND.;
		                             ZLJ->ZLJ_VIAGEM == _cviagem              .AND.; 
	                                 ZLJ->ZLJ_TIPPRO+ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_SETOR+ZLJ->ZLJ_LINROT == _aLinhas[_nPosLinha][1] .And. _lcont
			//Posiciona na linha para ler o KM e o Tipo
			ZL3->( DBSeek( xFilial("ZL3") + ZLJ->ZLJ_LINROT ) )
			
			If (nPosL:=aScan(_aMenorAtenViagem, {|S| S[1]+S[2] == ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_LINROT } )) # 0
				If Empty(_cDivKM) //Evito de apresentar a tela a cada produtor
					//Valida divergência entre o KM informado na recepção e o definido na Linha/Rota
					If _aMenorAtenViagem[nPosL][4] - ZL3->ZL3_KM > _nTolerKM
						If MsgYesNo("O KM informado: " + AllTrim(Str(_aMenorAtenViagem[nPosL][4]))+" está fora da faixa de tolerância ("+AllTrim(Str(_nTolerKM))+") baseado no valor informado na Linha: " +AllTrim(Str(ZL3->ZL3_KM))+;
									" Deseja confirmar mesmo assim?","AGLT02129")
							DEFINE MSDialog _oDlg TITLE "Justificativa" STYLE DS_MODALFRAME FROM 000,000 To 180,500 Pixel
								@005,005 Get _oMemoKM var _cJustKM MEMO Size 230,060 WHEN .T. OF _oDlg Pixel
								@070,090 BUTTON _oBtnCon PROMPT "&Confirma" Size 38,11 Pixel ACTION (IIf(!Empty(_cJustKM),_oDlg:End(),.F.), )
							Activate MSDialog _oDlg CENTERED
							_cDivKM := "S"
						Else
							DisarmTransaction()
					 		_lcont := .F.
							ZLJ->( DBSkip() )
							Loop
						EndIf
					Else
						_cDivKM := "N"
						_cJustKM := " "
					EndIf
				EndIf
	        EndIf
			If lMaeTemAtendimento .And. ZLJ->ZLJ_TIPPRO = 'F'//(F)Recebimento
				ZLJ->( DBSkip() )
				Loop
			EndIf
	
			If ZLJ->ZLJ_TIPPRO $ "P,R,F,A" //(P)Leite proprio ou (R)Reboque ou (F)Recebimento ou (A)Atravessador //Testa o tipo A para previnir
		
				If !Empty(ZLJ->ZLJ_NUMERO) .And. ZLD->( DBSeek(  xFilial("ZLD") + ZLJ->ZLJ_NUMERO))
	               ZLJ->( DBSkip() )
	               Loop
				EndIf
	
	            If ZLJ->ZLJ_DTCRIA <> M->ZLJ_DTCRIA
	               _lDtEstDif:=.T. //Flag se tem datas diferentes de estoque
	            EndIf
				// Total do setor dividido pelo total dos setores multiplicado pela diferenca = Total do setor da diferenca
				_nTotBom := _aSetores[_nSetor][2]/nTotLProprio * _nDiferenca
					
				//Se For tipo de produtor leite próprio grava ZLD
				_lgravou := .T.
				RecLock("ZLD",.T.)
				ZLD->ZLD_FILIAL 	:= xFilial("ZLD")
				ZLD->ZLD_TICKET 	:= ZLJ->ZLJ_VIAGEM
				If ZLD->(FIELDPOS("ZLD_VFILHA")) # 0
				   ZLD->ZLD_VFILHA:=ZLJ->ZLJ_VFILHA
				EndIf
	
				If !Empty(ZLJ->ZLJ_NUMERO) 
				   ZLD->ZLD_ATENDI  := ZLJ->ZLJ_NUMERO
				Else
				   _cAtendi := StrZero( Val(_cNumRecP), Len(ZLJ->ZLJ_NUMERO) )
				   ZLD->ZLD_ATENDI:= "R"+SubStr(_cAtendi,2)
		           ZLJ->(RecLock("ZLJ",.F.))
		           ZLJ->ZLJ_NUMERO:=ZLD->ZLD_ATENDI
		           //ZLJ->( MSUnLock())//Embaixo ele destrava todos
	            EndIf
				ZLD->ZLD_DTCOLE 	:= M->ZLJ_DTIVIA //Gravar a menor data de todos
				ZLD->ZLD_DTLANC 	:= Date()
				ZLD->ZLD_CODREC 	:= _cNumRecP
				ZLD->ZLD_SETOR  	:= ZLJ->ZLJ_SETOR
				ZLD->ZLD_LINROT 	:= ZLJ->ZLJ_LINROT
				lAtravessador:=.F.
				If SA2->(DBSeek(xFilial("SA2")+ZLJ->ZLJ_CODPAT+ZLJ->ZLJ_LOJPAT)) .And. SA2->A2_L_TIPPR = "A" .And. !Empty(SA2->A2_L_ATRCO)
				   ZLD->ZLD_RETIRO 	:= SA2->A2_L_ATRCO
				   ZLD->ZLD_RETILJ 	:= SA2->A2_L_ATRLO
				   lAtravessador:=.T.
	            Else
				   ZLD->ZLD_RETIRO 	:= ZLJ->ZLJ_CODPAT
				   ZLD->ZLD_RETILJ 	:= ZLJ->ZLJ_LOJPAT
				EndIf
				ZLD->ZLD_FRETIS  	:= ZLJ->ZLJ_CODTRN
				ZLD->ZLD_LJFRET  	:= ZLJ->ZLJ_LOJTRN
				ZLD->ZLD_VEICUL  	:= ZLJ->ZLJ_VEICUL
				ZLD->ZLD_MOTOR  	:= ZLJ->ZLJ_MOTORI
				ZLD->ZLD_USER		:= CriaVar("ZLD_USER") //Retorna o Codigo do Usuario 
	            //If _cLinhaRota == ZLJ->ZLJ_LINROT
				// Se a viagem ou viagem filha tem linha = a linha SQ poe nela
				If aScan(_aTemLinhaSQIgual, ZLJ->ZLJ_VFILHA ) # 0
				   If (nPosL:=aScan(_aMenorAtenViagem, {|S| S[1]+S[5] == ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_LINROT } )) # 0//Procura Linha = Linha do SQ
			          ZLD->ZLD_KM  := If(lTemCpoTPKM .And. ZL3->ZL3_TPKM="P" ,ZL3->ZL3_KM,_aMenorAtenViagem[nPosL][4])
				   EndIf
				ElseIf aScan(_aTemSetorSQIgual, ZLJ->ZLJ_VFILHA  ) # 0
				   If (nPosL:=aScan(_aMenorAtenViagem, {|S| S[1]+S[7] == ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_LINROT } )) # 0//Procura Setor = Setor do SQ
			          ZLD->ZLD_KM  := If(lTemCpoTPKM .And. ZL3->ZL3_TPKM="P" ,ZL3->ZL3_KM,_aMenorAtenViagem[nPosL][4])
				   EndIf
				ElseIf (nPosL:=aScan(_aMenorAtenViagem, {|S| S[1]+S[2] == ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_LINROT } )) # 0
				   ZLD->ZLD_KM 	:= If(lTemCpoTPKM .And. ZL3->ZL3_TPKM="P" ,ZL3->ZL3_KM,_aMenorAtenViagem[nPosL][4])// //M->ZLJ_KMDVIA//ZLJ->ZLJ_KMDVIA//A alteracao do usuario só vai para o o ZLD e ZLW o ZLJ fica = ao do SQ para manter a o sincronismo
				   _cAviso:="A KM For gravada na Viagem: "+ZLJ->ZLJ_VFILHA+", Setor: "+ZLJ->ZLJ_SETOR+" na linha "+ZLJ->ZLJ_LINROT+" por ser o menor atendimento geral da Julieta."
				EndIf
			    ZLD->ZLD_QTDBOM 	:= ZLJ->ZLJ_VOLUME
				If !ZLJ->ZLJ_DESCAR
				   ZLD->ZLD_TOTBOM 	:= _nTotBom
				EndIf
	            If Empty(ZLD->ZLD_MOTOR)
			       ZLD->ZLD_MOTOR :=Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_MOTORI")
	    		EndIf
	            If Empty(ZLD->ZLD_VEICUL)
			       ZLD->ZLD_VEICUL:= Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_COD")
	    		EndIf
	            _aSetores[_nSetor][4]:=ZLD->ZLD_TOTBOM//Não é somatoria pq é o total do rateio de cada setor sem decimal
				//Para fazer o acerto tem que somar todas as posicoes 4 do _aSetores e compara comtra a o_nDiferenca. 
				//As posicoes 4  do _aSetores da cooperativas estao zeradas exeto se só tiver cooperativa
				ZLD->ZLD_KMDIVE := IIf(_cDivKM=="N"," ",_cDivKM)
				ZLD->ZLD_KMJUST	:= _cJustKM
				ZLD->( MSUnLock())
	            FreeUsedCode()
	            If lAtravessador
	               If (_nAtraSetor:=aScan(_aAtraSetores, {|S| S[1] == ZLJ->ZLJ_VFILHA+ZLJ->ZLJ_SETOR} )) # 0
	                  AGLT021_ZLW(.T.)
	               EndIf
	            EndIf
	
	            U_AGLTGrv_ZLX("ORI_ZLJ",aDados)// Projeto Automação das Recepções Tipo Plataforma
	
			ElseIf ZLJ->ZLJ_TIPPRO == "C"//cooperativa
				AGLT021_ZLW(.F.)			
			EndIf
	
			ZLJ->( DBSkip() )
	
		EndDo
	
	Next _nPosLinha
	
	//Refaz estoque se teve mudança de data de estoque
	ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem))
	
	If _lDtEstDif .And. _lgravou
	    
		 	IncProc("Atualizando estoque...")
		 	_lrete := AGLT021GRC("Efetivação com mudança de data",.T.,.T.)
	   
	 		If !_lrete //Falhou ajuste de estoque
	 			MsgStop("Não foi possível refazer a entrada de estoque com nova data." +;
		 			    "Efetive com data de estoque original ou verifique motivo de falha de estorno do estoque original","AGLT02130")
	 			DisarmTransaction()
	 			_lcont := .F.
	 		EndIf
	   	  
	 EndIf
	
	//Atualiza status da viagem
	//Para fazer o acerto tem que somar todas as posicoes 4 do _aSetores e compara comtra a o_nDiferenca. 
	//As posicoes 4 do _aSetores da cooperativas estao zeradas exeto se só tiver cooperativa
	ProcRegua(Len(_aLinhas))	
	
	ZLJ->( DBSetOrder(2))
	ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem))
	_cusrname := UsrFullName(__cUserId)
			
	While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL == xFilial("ZLJ") .And. ZLJ->ZLJ_VIAGEM == _cviagem .And. _lcont
			
	   IncProc("Atualizando Status Atendimento: "+ZLJ->ZLJ_NUMERO) 
			
		ZLJ->(RecLock("ZLJ",.F.))
			
		ZLJ->ZLJ_STATUS := "E"
		ZLJ->ZLJ_UEFET 	:= _cusrname
		ZLJ->ZLJ_HREFET := Time()
		ZLJ->ZLJ_DEFET 	:= ddatabase
	
	    If Empty(ZLJ->ZLJ_MOTORI)
		   ZLJ->ZLJ_MOTORI:=Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_MOTORI")
		EndIf
	    If Empty(ZLJ->ZLJ_VEICUL)
		   ZLJ->ZLJ_VEICUL:= Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_COD")
		EndIf   
		ZLJ->( MSUnLock())
		ZLJ->( DBSkip() )
	EndDo

End Transaction

//Se falhou gravação já termina a rotina
If !_lcont
	Return .F.
EndIf

ZLJ->( DBGoTo(_nRecZLJ) )

If _lGerou_ZLX//Variavel alterada dentro da função U_AGLTGrv_ZLX()
   MsgInfo("Viagem E Geraçao da Recepção Tipo Plataforma automatica efetivada com SUCESSO!","AGLT02131")
Else
   MsgInfo("Viagem efetivada com SUCESSO!","AGLT02132")
EndIf		

Return .T.

/*
===============================================================================================================================
Programa--------: U_AGLT021_
Autor-----------: Alex Wallauer 
Data da Criacao-: 02/08/2016
Descrição-------: Estorno da  recepção posicionada
Parametros------: lAtravessador: Se Atravessador .T.
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AGLT021_ZLW(lAtravessador)//U_AGLT021_

If ZLW->( DBSeek(  xFilial("ZLW") + ZLJ->ZLJ_NUMERO))
   Return .F.	
EndIf

RecLock("ZLW",.T.)
ZLW->ZLW_FILIAL 	:= xFilial("ZLW")
ZLW->ZLW_TICKET 	:= ZLJ->ZLJ_VIAGEM//"S"+SubStr(ZLJ->ZLJ_VIAGEM,2)//cticket
ZLW->ZLW_ATENDI	    := ZLJ->ZLJ_NUMERO
ZLW->ZLW_DTCOLE 	:= ZLJ->ZLJ_DTIVIA
ZLW->ZLW_DTLANC 	:= ZLJ->ZLJ_DTCRIA
ZLW->ZLW_CODREC 	:= _cNumRecW
ZLW->ZLW_SETOR  	:= ZLJ->ZLJ_SETOR
ZLW->ZLW_LINROT 	:= ZLJ->ZLJ_LINROT
ZLW->ZLW_RETIRO  	:= ZLJ->ZLJ_CODPAT
ZLW->ZLW_RETILJ  	:= ZLJ->ZLJ_LOJPAT
ZLW->ZLW_FRETIS  	:= ZLJ->ZLJ_CODTRN
ZLW->ZLW_LJFRET  	:= ZLJ->ZLJ_LOJTRN
ZLW->ZLW_VEICUL  	:= ZLJ->ZLJ_VEICUL
ZLW->ZLW_MOTOR  	:= ZLJ->ZLJ_MOTORI
ZLW->ZLW_KM 	    := 0 //cooperativa nao grava KM
ZLW->ZLW_USER		:= CriaVar("ZLD_USER") //Retorna o Codigo do Usuario
ZLW->ZLW_QTDBOM 	:= ZLJ->ZLJ_VOLUME
If !ZLJ->ZLJ_DESCAR
	If lTemLeiteproprio
       If lAtravessador
	      ZLW->ZLW_TOTBOM  := _aAtraSetores[_nAtraSetor][2]
	   Else
	      ZLW->ZLW_TOTBOM  := _aSetores[_nSetor][2]
	   EndIf
	Else
		// Total do setor dividido pelo total dos setores multiplicado pela diferenca = Total do setor com a diferenca
		_nTotBom := _asetores[_nSetor][2]/nTotCooperativa * _nDiferenca
		ZLW->ZLW_TOTBOM      :=_nTotBom
		_aSetores[_nSetor][4]:=ZLD->ZLD_TOTBOM//Não é somatoria pq é o total do rateio de cada setor sem decimal
	EndIf
EndIf
If Empty(ZLW->ZLW_MOTOR)
	ZLW->ZLW_MOTOR:=Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_MOTORI")
EndIf
If Empty(ZLW->ZLW_VEICUL)
	ZLW->ZLW_VEICUL:= Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_COD")
EndIf
ZLW->( MSUnLock())
FreeUsedCode()

Return .T.	

/*
===============================================================================================================================
Programa--------: AGLT021A
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Estorno da  recepção posicionada
Parametros------:  _cAlias: Tabela , nRecZLJ: Recno , _nOpc: Opcao
Retorno---------: .T. OU .F.
===============================================================================================================================
*/
User Function AGLT021A(_cAlias , nRecZLJ , _nOpc)

Local _bok     :=  { || AGLT021ER(.F.) }

//Verifica status
If ZLJ->ZLJ_STATUS == "P"
	MsgInfo("Viagem está pendente. Não há movimento para estornar.","AGLT02133")
	Return .F.
EndIf	

//Locka registros
If !( AGLT021LO( SubStr( ZLJ->ZLJ_FILIAL , 1 , 2 ), ZLJ->ZLJ_VIAGEM ) )
	Return .F.
EndIf

AGLT021Tela("Estorno de Recepcao",_bok,_nOpc,nRecZLJ)

AGLT021UN(ZLJ->ZLJ_FILIAL,ZLJ->ZLJ_VIAGEM)

Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021ER
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Processa estorno da  recepção posicionada
Parametros------: lApaga: .T. apaga
Retorno---------: _lRet - confirmação de fechamento da tela de estorno
===============================================================================================================================
*/
Static Function AGLT021ER(lApaga)

_lRet := .T.

If lApaga
   Processa( {|| _lRet:=AGLT021PES(3) })
   Return _lRet
EndIf

If ZLJ->ZLJ_STATUS == "R"
   Processa( {|| _lRet:=AGLT021PES(2) })
   Return _lRet//Faltava um retorno aqui nao pode entrar no proximo
EndIf

If ZLJ->ZLJ_STATUS == "E"
   Processa( {|| _lRet:=AGLT021PES(1) })
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: AGLT021PES
Autor-----------: Josué Danich
Data da Criacao-: 13/04/2016
Descrição-------: Processa estorno de efetivação 
Parametros------: _ntip - Tipo de estorno - 1 Estorno de efetivação
											2 Estorno de recusa
											3 Apaga
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AGLT021PES(_ntip,_lEstoque)

Local _lok 			:= .T.
Local _cviagem		:= ZLJ->ZLJ_VIAGEM
Local _aViagens		:= {}
Local _aOrd			:= SaveOrd({"ZLJ","ZLX"})
Local _nI			:= 0
Local _nS			:= 0
Local _lMove		:= SuperGetMV("LT_LMOVE",.F.,.T.)
Default _lEstoque	:= .F.

Private cSetor		:= ""
Private nTotBom		:= 0
Private _lGerou_ZLX	:=.F.

Default _ntip := 1

ProcRegua(0)

If _ntip == 1  //Estorno de efetivação

	Begin Transaction
	
	//Localiza viagem no ZLJ
	DBSelectArea("ZLJ")
	ZLJ->( DBSetOrder(2) )
	If ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem ) )
	
		While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL == xFilial("ZLJ") .And. ZLJ->ZLJ_VIAGEM == _cviagem .And. _lok
		
           IncProc("Atualizando Atendimento: "+ZLJ->ZLJ_NUMERO) 
           //Estorna movimento de cooperativa		
           DBSelectArea("ZLW")
           ZLW->( DBSetOrder(7) )
           If !Empty(ZLJ->ZLJ_NUMERO) .And. ZLW->( DBSeek( xFilial("ZLW") + ZLJ->ZLJ_NUMERO) )
				
					If ZLW->ZLW_STATUS != "F" 
					   RecLock("ZLW", .F.)
					   ZLW->( Dbdelete() )
					   ZLW->( MSUnLock() )
					Else
						MsgAlert("Registro de recepção já teve fechamento: "+xFilial("ZLD") + ZLJ->ZLJ_NUMERO,"AGLT02134")
						_lOk := .F.
						Exit
					EndIf
				
			EndIf
			
			//Estorna movimento de leite próprio
			//Estorna recepção
				
			ZLD->( DBSetOrder(7) )
			If !Empty(ZLJ->ZLJ_NUMERO) .And. ZLD->( DBSeek( xFilial("ZLD") + ZLJ->ZLJ_NUMERO) )
				
					If ZLD->ZLD_STATUS != "F"  .And. !AGLT021D( ZLD->ZLD_DTCOLE , ZLD->ZLD_RETIRO , ZLD->ZLD_RETILJ,.T.,ZLJ->ZLJ_TIPPRO )
				
                       U_AGLTGrv_ZLX("EXCLUI")// Projeto Automação das Recepções Tipo Plataforma
                        
						RecLock("ZLD", .F.)
						ZLD->( Dbdelete() )
						ZLD->( MSUnLock() )
						
					Else
					    If ZLD->ZLD_STATUS = "F"
					  	   MsgStop("Registro de recepção já teve fechamento ou eventos: "+xFilial("ZLD") + ZLJ->ZLJ_NUMERO,"AGLT02135")
					  	EndIf 
						_lOk := .F.
						Exit
					EndIf
					
			EndIf
			
			If _lOk
			
				RecLock("ZLJ",.F.)
				
				ZLJ->ZLJ_STATUS := "P"
				ZLJ->ZLJ_UEFET 	:= " "
				ZLJ->ZLJ_DEFET 	:= ctod(" / / ")
				ZLJ->ZLJ_HREFET := " "
				
				ZLJ->( MSUnLock() )
				
			EndIf
			
			ZLJ->( DBSkip() )
			
		EndDo
		
	EndIf
	
	If .not. _lok
		Disarmtransaction()
	Else
        If _lGerou_ZLX//Variavel alterada dentro da função U_AGLTGrv_ZLX("ORI_ZLJ",aDados)
           MsgInfo("Estorno da Efetivação e da Geraçao da Recepção Tipo Plataforma automatica realizado com sucesso!","AGLT02136")
	    Else
           MsgInfo("Estorno realizado com sucesso!","AGLT02137")
	    EndIf
	EndIf
	
	End Transaction		

ElseIf _ntip == 2 //Estorno de recusa e Refaz Estoque

	Begin Transaction
	
	//Localiza viagem no ZLJ
    ZLX->(dbOrderNickname("IT_I_TISET"))//ZLX_FILIAL+ZLX_TICKET+ZLX_SETOR //ZLX->(DBSetOrder(10))
	DBSelectArea("ZLJ")
	ZLJ->( DBSetOrder(2) )
	If ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem ) )
		lTemLeiteProprio:=.F.
		_aSetores:={}
		While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL == xFilial("ZLJ") .And. ZLJ->ZLJ_VIAGEM == _cviagem
		
           IncProc("Atualizando Atendimento: "+ZLJ->ZLJ_NUMERO) 
			ZLJ->(RecLock("ZLJ", .F.))
            If _lEstoque
		   	   ZLJ->ZLJ_DTCRIA := M->ZLJ_DTCRIA // Alteração da data 

               If ZLX->( DBSeek(xFilial()+ZLD->ZLD_TICKET+ZLD->ZLD_SETOR)) .And. ZLX->ZLX_DTESTO # M->ZLJ_DTCRIA
			      ZLX->(RecLock("ZLX", .F.))
	   	          ZLX->ZLX_DTESTO := M->ZLJ_DTCRIA//Data Estoque
			      ZLX->(MSUnLock())
	   	       EndIf   

		    Else
			   ZLJ->ZLJ_STATUS := "P"
			   ZLJ->ZLJ_MOTIVO := " "
		   	   ZLJ->ZLJ_UEFET	:= " "
			   ZLJ->ZLJ_DEFET 	:= SToD(" ")
			   ZLJ->ZLJ_HREFET 	:= " "
		    EndIf	
			ZLJ->( MSUnLock() )
					
			//Atualiza array com volumes por viagem e por setor
			If 	!ZLJ->ZLJ_DESCAR 
				
				If (_nPos:=aScan(_aViagens,{|aVal| aVal[1] == ZLJ->ZLJ_VIAGEM })) == 0//.and. aVal[2] == ZLJ->ZLJ_SETOR
					aAdd(_aViagens, {ZLJ->ZLJ_VIAGEM,;//01
					                 ZLJ->ZLJ_SETOR ,;//02
					                 0              ,;//03 //Total Cooperativa
					                 ZLJ->ZLJ_DTCRIA,;//04//Data já esta alterada quando hega aqui
					                 U_AGLT021V(1)  ,;//05
					                 0              })//06 //Total Leite Proprio					                 
					_nPos:=Len(_aViagens)
				EndIf
						
                If ZLJ->ZLJ_TIPPRO = 'F'//Recebimento
                
                   _aViagens[_nPos][05]:=U_AGLT021V(1)//Atualiza o total do veiculo com a linha de atendimento do recebimento

                ElseIf ZLJ->ZLJ_TIPPRO = 'C'
			   
			       _aViagens[_nPos][3] += ZLJ->ZLJ_VOLUME//Total Cooperativa
			   
			    ElseIf ZLJ->ZLJ_TIPPRO == "P"//Leite Proprio

			       lTemLeiteProprio    := .T.            //Tem Leite Proprio
			       _aViagens[_nPos][6] += ZLJ->ZLJ_VOLUME//Total Leite Proprio
			       
		           If (_nPoSet:=aScan(_aSetores,{|aVal| aVal[1] == ZLJ->ZLJ_SETOR})) == 0
			          aAdd(_aSetores, {ZLJ->ZLJ_SETOR,0,ZLJ->ZLJ_VOLUME})
			       Else
			          _aSetores[_nPoSet][3] += ZLJ->ZLJ_VOLUME//Total do leite proprio por setor
			       EndIf
			    
			    EndIf
					
			EndIf
				
			ZLJ->( DBSkip() )
				
		EndDo
		
		//Refaz movimentos de estoque
		If !lTemLeiteProprio  .Or. !_lMove
		   _aViagens:={}
		EndIf

		ProcRegua(0)
		_lcont := .T.

		For _nI := 1 To Len(_aViagens)
                
            // Volume do veiculo - o total da cooperativa  = Volume do leite proprio com a diferença
			nTotBom  := _aViagens[_nI][5]-_aViagens[_nI][3]

			If nTotBom > 0
			
                _nCustoEst:=0
                If Len(_aSetores) > 1
                   For _nS := 1 To Len(_aSetores)                       
			          // Total do setor dividido pelo total dos setores multiplicado pela diferenca = Total do setor com a diferenca
                      _aSetores[_nS,2]:= _aSetores[_nS][3] / _aViagens[_nI][6] * nTotBom
                      _nVlrMix      := Posicione("ZL2",1,xFilial("ZL2")+_aSetores[_nS,1],"ZL2_ULTMIX")
                      _nCustoEst    += (_nVlrMix * _aSetores[_nS,2])
	               Next _nS
                EndIf			
			
			    _cErroSche:= ""               //Variavel preenchida na funcao U_AGLT003G com o mensagem de erro
				cSetor    := _aViagens[_nI][2]//Variavel usada dentro da funcao U_AGLT003G()
				dDtColeta := _aViagens[_nI][4]//Variavel usada dentro da funcao U_AGLT003G()

                IncProc("Gerando Estoque da Data: "+DToC(dDtColeta))
                IncProc("Gerando Estoque da Data: "+DToC(dDtColeta))
					
				If .not. U_AGLT003G(_aViagens[_nI][1],3,.F.,_nCustoEst) //Grava movimento de estoque igual a rotina da recepção manual
			
					disarmtransaction()
				
					MsgStop("Não foi possível gravar a entrada de estoque da Viagem, Erro: "+_cErroSche ,"AGLT02138")
				
					_lcont := .F.
					_nI := Len(_aViagens) + 1
			
				EndIf		
		
			EndIf
		
	    Next _nI
			
	EndIf
		
	End Transaction
	
	//Se falhou a gravação já sai da rotina
	If !_lcont
		Return .F.
	EndIf
	
    If !_lEstoque
	   MsgInfo("Estorno realizado com sucesso!","AGLT02139")
	EndIf

ElseIf _ntip == 3 //Apaga

	Begin Transaction

	//Localiza viagem no ZLJ
	DBSelectArea("ZLJ")
	ZLJ->( DBSetOrder(2) )
	If ZLJ->( DBSeek( xFilial("ZLJ") + _cviagem ) )
		
		While ZLJ->(!Eof()) .And. ZLJ->ZLJ_FILIAL == xFilial("ZLJ") .And. ZLJ->ZLJ_VIAGEM == _cviagem
		
            IncProc("Apagando Atendimento: "+ZLJ->ZLJ_NUMERO) 
			RecLock("ZLJ", .F.)
			ZLJ->( DBDELETE() )
			ZLJ->( MSUnLock() )

			ZLJ->( DBSkip() )
			
		EndDo

	EndIf
		
	End Transaction
	
	MsgInfo("Viagem apagada com sucesso!","AGLT02140")

EndIf

RestOrd(_aOrd,.T.)
				
Return .T.

/*
===============================================================================================================================
Programa--------: AGLT021Tela()
Autor-----------: Alex Walaluer
Data da Criacao-: 01/07/2016
Descrição-------: Tela de capa e detalhe
Parametros------: _cTitulo: Titulo da Janela
				  _bok    : Funcao para executar no OK
 				  _nOpc   : Tipo da manutencao
				  nReg    : Recno do ZLJ
				  _aButtons: Botoes
				  _bMarca : Codeblock da marcação
Retorno---------: .T.
===============================================================================================================================
*/
Static Function AGLT021Tela(_cTitulo,_bOk,_nOpc,nReg,_aButtons,_bMarca)

Local cAlias		:= "ZLJ"
Local cAliasWK		:= "TRB"
Local aCamposMostra	:= {}
Local aDarGets		:= NIL
Local aTB_Campos	:= {}
Local aHeaderItens	:= {}
Local aSemSX3		:= { {"REC_ZLJ","N",10,0} , {"TRB_GRAVA","L",01,0} }
Local bSeek			:= {|| (cAlias)->(DBSetOrder(2)) , (cAlias)->(DBSeek(xFilial(cAlias)+M->ZLJ_VIAGEM)) }
Local bWhile		:= {||  ZLJ->ZLJ_FILIAL+ZLJ->ZLJ_VIAGEM ==  xFilial(cAlias)+M->ZLJ_VIAGEM  }
Local bGrvCpo		:= {|| AGLT021Miscel() }
Local oEnCh1,oMark,cCampo,I
Local _cAlias		:= GetNextAlias()

Private aRotina		:= MenuDef()
Private oDlg,aHeader:= {}
Private _nRecMae	:= nReg
Private _nBotEstoque:= aScan(aRotina,{|X| X[2] == 'U_AGLT21RE' })
Private _nBotEfetiva:= aScan(aRotina,{|X| X[2] == 'U_AGLT021E' })

If Select(cAliasWK) # 0
   (cAliasWK)->(DBCloseArea())
EndIf

aAdd(aSemSX3,{"ZLJ_TIPPRO","C",1,0})
aAdd(aSemSX3,{"ZLJ_SETOR","C",6,0})
aAdd(aSemSX3,{"ZLJ_LINROT","C",6,0})
aAdd(aSemSX3,{"ZLJ_VIAGEM","C",10,0})
aAdd(aSemSX3,{"ZLJ_NUMERO","C",10,0})
aAdd(aSemSX3,{"ZLJ_NSETOR","C",10,0})
aAdd(aSemSX3,{"ZLJ_NLINRO","C",10,0})
aAdd(aSemSX3,{"ZLJ_CODPAT","C",6,0})
aAdd(aSemSX3,{"ZLJ_LOJPAT","C",4,0})
aAdd(aSemSX3,{"ZLJ_NOMPAT","C",15,0})
aAdd(aSemSX3,{"ZLJ_TIPVIS","C",1,0})
aAdd(aSemSX3,{"ZLJ_DTIVIA","D",8,0})
aAdd(aSemSX3,{"ZLJ_DTFVIA","D",8,0})
aAdd(aSemSX3,{"ZLJ_DTCRIA","D",8,0})
aAdd(aSemSX3,{"ZLJ_STATUS","C",1,0})
aAdd(aSemSX3,{"ZLJ_DESCAR","L",1,0})
aAdd(aSemSX3,{"ZLJ_VOLUME","N",9,2})
aAdd(aSemSX3,{"ZLJ_CODTRN","C",6,0})
aAdd(aSemSX3,{"ZLJ_LOJTRN","C",4,0})
aAdd(aSemSX3,{"ZLJ_DTRAN","C",100,0})
aAdd(aSemSX3,{"ZLJ_KMDVIA","N",18,0})
aAdd(aSemSX3,{"ZLJ_TEMPER","N",18,8})
aAdd(aSemSX3,{"ZLJ_PLACA","C",8,0})
aAdd(aSemSX3,{"ZLJ_VOLREA","N",18,0})
aAdd(aSemSX3,{"ZLJ_VOLCOL","N",18,0})
aAdd(aSemSX3,{"ZLJ_HRIVIA","C",8,0})
aAdd(aSemSX3,{"ZLJ_HRFVIA","C",8,0})
aAdd(aSemSX3,{"ZLJ_MOTIVO","C",250,0})
aAdd(aSemSX3,{"ZLJ_LITRAG","N",18,0})
aAdd(aSemSX3,{"ZLJ_DMOTOR","C",100,0})
aAdd(aSemSX3,{"ZLJ_PSIVIA","N",18,0})
aAdd(aSemSX3,{"ZLJ_PSFVIA","N",18,0})
aAdd(aSemSX3,{"ZLJ_VEICUL","C",6,0})
aAdd(aSemSX3,{"ZLJ_MOTORI","C",6,0})
aAdd(aSemSX3,{"ZLJ_AMOSTR","C",9,0})
aAdd(aSemSX3,{"ZLJ_ALIZAR","C",1,0})
aAdd(aSemSX3,{"ZLJ_BOCA","C",3,0})
aAdd(aSemSX3,{"ZLJ_REGZLX","N",9,0})
aAdd(aSemSX3,{"ZLJ_HRCRIA","C",8,0})
aAdd(aSemSX3,{"ZLJ_DTINI","D",8,0})
aAdd(aSemSX3,{"ZLJ_HRINI","C",8,0})
aAdd(aSemSX3,{"ZLJ_REGUA","N",9,2})
aAdd(aSemSX3,{"ZLJ_DTFIM","D",8,0})
aAdd(aSemSX3,{"ZLJ_HRFIM","C",8,0})
aAdd(aSemSX3,{"ZLJ_UEFET","C",50,0})
aAdd(aSemSX3,{"ZLJ_DIFER","N",18,0})
aAdd(aSemSX3,{"ZLJ_DEFET","D",8,0})
aAdd(aSemSX3,{"ZLJ_HREFET","C",20,0})
aAdd(aSemSX3,{"ZLJ_USRSMQ","C",6,0})
aAdd(aSemSX3,{"ZLJ_LOGINS","C",40,0})
aAdd(aSemSX3,{"ZLJ_DIFER2","N",9,0})
aAdd(aSemSX3,{"ZLJ_VOLCOO","N",18,0})
aAdd(aSemSX3,{"ZLJ_UINTSQ","C",50,0})
aAdd(aSemSX3,{"ZLJ_DINTSQ","D",8,0})
aAdd(aSemSX3,{"ZLJ_HINTSQ","C",8,0})
aAdd(aSemSX3,{"ZLJ_VFILHA","C",10,0})
aAdd(aSemSX3,{"ZLJ_VFILHS","C",250,0})
aAdd(aSemSX3,{"ZLJ_LINHSQ","C",6,0})

aAdd(aheader,{"Tp Produtor","ZLJ_TIPPRO"," ",1,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Setor","ZLJ_SETOR"," ",6,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Linha/Rota","ZLJ_LINROT"," ",6,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Cod. Viagem","ZLJ_VIAGEM","@!                                           ",10,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Km Viagem","ZLJ_KMDVIA","@E 999,999,999                               ",18,0,"Positivo()                                                                                                                      ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Lista Filhas","ZLJ_VFILHS","@!                                           ",250,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Num. Atendim","ZLJ_NUMERO","@!                                           ",10,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Viagem Filha","ZLJ_VFILHA","@!                                           ",10,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Nome Setor","ZLJ_NSETOR"," ",10,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","V"})
aAdd(aheader,{"Nome Rota","ZLJ_NLINRO"," ",10,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","V"})
aAdd(aheader,{"Cod do Ponto","ZLJ_CODPAT","@!                                           ",6,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Loj do Ponto","ZLJ_LOJPAT","@!                                           ",4,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Nome Ponto","ZLJ_NOMPAT","@!                                           ",15,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","V"})
aAdd(aheader,{"Tipo Visita","ZLJ_TIPVIS","@!                                           ",1,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Dt In Viagem","ZLJ_DTIVIA"," ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Hr In Viagem","ZLJ_HRIVIA","99:99:99                                     ",8,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Dt Fi Viagem","ZLJ_DTFVIA"," ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Hr Fi Viagem","ZLJ_HRFVIA","99:99:99                                     ",8,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Dt Estoque","ZLJ_DTCRIA"," ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Status","ZLJ_STATUS"," ",1,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Descarte","ZLJ_DESCAR"," ",1,0," ","€€€€€€€€€€€€€€ ","L","ZLJ","R"})
aAdd(aheader,{"Volume Col.","ZLJ_VOLUME","@E 999,999                                   ",9,2," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Temperatura","ZLJ_TEMPER","@E 99.99                                     ",18,8," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Placa Veic.","ZLJ_PLACA","@!                                  ",7,0,"(M->ZLJ_PLACA:=ZLJ->ZLJ_PLACA,.T.)                                                                                              ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Vol veiculo","ZLJ_VOLREA","@E 999,999,999                               ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","V"})
aAdd(aheader,{"Vol Coletado","ZLJ_VOLCOL","@E 999,999,999                               ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","V"})
aAdd(aheader,{"Diferenca","ZLJ_DIFER","@E 999,999,999                               ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","V"})
aAdd(aheader,{"Motivo Recus","ZLJ_MOTIVO"," ",250,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Vol Med Vaza","ZLJ_LITRAG","@E 999,999,999,999,999,999                   ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Cod. Transp.","ZLJ_CODTRN","@!                                           ",6,0,"(M->ZLJ_CODTRN:=ZLJ->ZLJ_CODTRN,.T.)                                                                                            ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Loja Transp.","ZLJ_LOJTRN","@!                                           ",4,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Nome Transp","ZLJ_DTRAN"," ",100,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","V"})
aAdd(aheader,{"Motorista","ZLJ_MOTORI"," ",6,0,"(M->ZLJ_MOTORI:=ZLJ->ZLJ_MOTORI,.T.)                                                                                            ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Nome Motoris","ZLJ_DMOTOR"," ",100,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","V"})
aAdd(aheader,{"Veiculo","ZLJ_VEICUL"," ",6,0,"(M->ZLJ_VEICUL:=ZLJ->ZLJ_VEICUL,.T.)                                                                                            ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Id. Amostra","ZLJ_AMOSTR","@!                                           ",9,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Alizarol","ZLJ_ALIZAR","@!                                           ",1,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Boca","ZLJ_BOCA","@!                                           ",3,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Reg. Tabela","ZLJ_REGZLX","@E 999999999                                 ",9,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Hora Criacao","ZLJ_HRCRIA"," ",8,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Data Inicio","ZLJ_DTINI"," ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Hora Inicial","ZLJ_HRINI"," ",8,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Regua","ZLJ_REGUA","@E 999,999.99                                ",9,2," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Data fim","ZLJ_DTFIM"," ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Hora fim","ZLJ_HRFIM"," ",8,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Usr Efetivou","ZLJ_UEFET"," ",50,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Data Efetiva","ZLJ_DEFET"," ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Hr Efetivaca","ZLJ_HREFET"," ",20,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Usr. SmartQs","ZLJ_USRSMQ","@!                                           ",6,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Login SMQ","ZLJ_LOGINS","@x                                           ",40,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Peso Cheio","ZLJ_PSIVIA","@E 999,999,999                               ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Vol L.Propri","ZLJ_VOLPRO","@E 999,999,999,999                           ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","V"})
aAdd(aheader,{"Peso Vazio","ZLJ_PSFVIA","@E 999,999,999                               ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","R"})
aAdd(aheader,{"Vol Cooperat","ZLJ_VOLCOO","@E 999,999,999,999                           ",18,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","V"})
aAdd(aheader,{"Peso Liq","ZLJ_DIFER2","@E 999,999,999                               ",9,0," ","€€€€€€€€€€€€€€ ","N","ZLJ","V"})
aAdd(aheader,{"User Int SQ","ZLJ_UINTSQ","@!                                           ",50,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Data Int SQ","ZLJ_DINTSQ","@D                                           ",8,0," ","€€€€€€€€€€€€€€ ","D","ZLJ","R"})
aAdd(aheader,{"Hora Int SQ","ZLJ_HINTSQ","@!                                           ",8,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})
aAdd(aheader,{"Linha SQ","ZLJ_LINHSQ","@!                                           ",6,0," ","€€€€€€€€€€€€€€ ","C","ZLJ","R"})

_otemp := FWTemporaryTable():New( cAliasWK, aSemSX3 )
_otemp:AddIndex( "01", {"ZLJ_VFILHA","ZLJ_TIPPRO","ZLJ_NUMERO"} )

_otemp:Create()

DBSelectArea(cAlias)
DBGoTo(_nRecMae)
For i := 1 To FCount()
    M->&(FieldName(i)) := FieldGet(i)
Next i

BeginSql alias _cAlias
	SELECT D3_EMISSAO
	  FROM %Table:SD3%
	 WHERE D_E_L_E_T_ = ' '
	   AND D3_ESTORNO != 'S'
	   AND D3_L_ORIG = %exp:ZLJ->ZLJ_VIAGEM%
	   AND D3_FILIAL = %exp:ZLJ->ZLJ_FILIAL%
EndSql
	
_cSalvoZLJ_DTCRIA:=SToD((_cAlias)->D3_EMISSAO)//Se não achar vai branco mesmo

(_cAlias)->( DBCloseArea() )
DBSelectArea("ZLJ")

If Empty(M->ZLJ_MOTORI)//Esse campo foi alterado para real
   M->ZLJ_MOTORI:=Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_MOTORI")
EndIf

If Empty(M->ZLJ_VEICUL)//Esse campo foi alterado para real
   M->ZLJ_VEICUL:=Posicione("ZL1",2,xFilial("ZL1")+ZLJ->ZLJ_PLACA,"ZL1_COD")
EndIf

aAdd(aCamposMostra,"NOUSER")
For i := 1 To Len(aHeader)
    cCampo:=AllTrim(aHeader[I,2])
    If AGLT021CPO( cCampo , 1 ) //Campos da Capa
       aAdd(aCamposMostra,cCampo)
    EndIf
    If AGLT021CPO( cCampo , 2 ) //Campos dos atendimentos
       xCol1:=cCampo
       If cCampo = "ZLJ_TIPPRO"
          xCol1:={|| U_MGLTTipoProd("TRB") }//Rdmake MGLT002.PRW
       ElseIf cCampo = "ZLJ_DESCAR"
          xCol1:={|| If(TRB->ZLJ_DESCAR,"Sim","Nao") }
       EndIf
       aAdd(aTB_Campos,{xCol1,,AVSX3(cCampo,5),AVSX3(cCampo,6)})
       aAdd(aHeaderItens,aHeader[I])
    EndIf
Next
aAdd(aTB_Campos,{"ZLJ_MOTIVO",,AVSX3("ZLJ_MOTIVO",5),AVSX3("ZLJ_MOTIVO",6)})

Private _lBotEst:=.F.
If _nOpc = _nBotEstoque//'Refaz Estoque'
   aDarGets:={"ZLJ_DTCRIA"}
   _lBotEst:=.T.
ElseIf _nOpc # _nBotEfetiva//'Visualizar''Recusar''Estornar''Apagar'
   aDarGets:={}
EndIf

lMaeTemAtendimento:=.F.
_nRecReboque:=0
(cAlias)->(DBGoTo(_nRecMae))

E_GravaTRB(cAlias,bSeek,NIL ,bWhile,aSemSX3,bGrvCpo,cAliasWK)

If lMaeTemAtendimento .And. _nRecReboque # 0
   (cAliasWK)->(DBGoTo(_nRecReboque))
   (cAliasWK)->(DBDELETE())
EndIf

M->ZLJ_DTCRIA:=_cSalvoZLJ_DTCRIA

While .T.
	nOpca:=0

	aCoors:= FWGetDialogSize(oMainWnd)
	oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo
	Define MSDialog oDlg Title _cTitulo From aCoors[1],aCoors[2] To aCoors[3],aCoors[4] OF oMainWnd Pixel
		nLinha :=Int(((oMainWnd:nBottom-60)-(oMainWnd:nTop+125))/2.5)

		(cAlias)->(DBGoTo(_nRecMae))
		//MsmGet(): New (         [ cAlias],[ uPar2], < nOpc>, [ uPar4], [ uPar5], [ uPar6], [ aAcho]    , [ aPos], [ aCpos], [ nModelo], [ uPar11], [ uPar12], [ uPar13], [ oWnd], [ lF3], [ lMemoria], [ lColumn], [ caTela], [ lNoFolder], [ lProperty], [ aField], [ aFolder], [ lCreate], [ lNoMDIStretch], [ uPar25] )																												,,,,,,,   ,,.T.)
		oEnCh1:=MsMget():New( cAlias,_nRecMae,_nOpc,,,,aCamposMostra,{15,1,nLinha,(oDlg:nClientWidth-4)/2},aDarGets ,1)  

		(cAliasWK)->(DBGoTop())
		oMark:=MSSELECT():New(cAliasWK,,,aTB_Campos,.F.,,{nLinha+1,1,(oDlg:nClientHeight-6)/2,(oDlg:nClientWidth-4)/2})
		If _bMarca # NIL
			oMark:bAval:= {|| EVAL(_bMarca,oMark) }
		EndIf
       
	Activate MSDialog oDlg ON INIT ( EnchoiceBar(oDlg, {|| (nOpca:=1,oDlg:End()) } , {|| (nOpca:=0,oDlg:End()) },,_aButtons) ,;
                                    oEnCh1:oBox:Align:=CONTROL_ALIGN_TOP ,;
                                    oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT ,;
                                    oMark:oBrowse:Refresh() )
	If nOpca = 1 .And. !Eval(_bOk)
		If Select(cAliasWK) # 0
			Loop
		Else//Se o TRB For fechado erroniamente
			Exit
		EndIf         
	EndIf

	Exit

EndDo

If Select(cAliasWK) # 0
   _otemp:delete()
EndIf

Return .T.               

/*
===============================================================================================================================
Programa--------: AGLT021Miscel()
Autor-----------: Alex Walaluer
Data da Criacao-: 01/07/2016
Descrição-------: Grava campos virtuais do TRB e devolve o tipo do produtor
Retorno---------: TIPO DO PRODUTOR
===============================================================================================================================
*/
Static Function AGLT021Miscel()

Local I
//Executa o X3_RELACAO
TRB->ZLJ_NSETOR:=CriaVar("ZLJ_NSETOR")
TRB->ZLJ_NLINRO:=CriaVar("ZLJ_NLINRO")
TRB->ZLJ_NOMPAT:=CriaVar("ZLJ_NOMPAT")
//Executa o X3_RELACAO
TRB->REC_ZLJ:=ZLJ->(RECNO())

If TRB->ZLJ_TIPPRO = "F"//Atendimento de Recebimento
	_nRecReboque:=TRB->(RECNO())
	_nRecMae:=ZLJ->(RECNO())
	For I := 1 To FCount()
		M->&(FieldName(i)) := ZLJ->(FieldGet(i))
	Next
EndIf

If Empty(ZLJ->ZLJ_VFILHA)
   lMaeTemAtendimento:=.T.
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AGLT021K()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/12/2015
Descrição---------: Reler o dados lidos no prothues da integracao do SQ
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AGLT021K()

Local _cLinhaRota	:="",_cMsgTop
Local _cSetor		:=""
Local _atlog		:={}
Local _cMem			:=""
Local _lDeuErro		:=.F.
Local _lTudoIgual	:=.F.
Local _lTemErro		:=.F.
Local _lTodosIguais	:=.T.
                               
If !MsgYesNo("Confirma LEITURA do Reprocessamento dessa Viagem?","AGLT02141")
   Return .T.
EndIf

ProcRegua( TRB->(LastRec()) )

TRB->(DBGoTop())
SA2->( DBSetOrder(1))
ZL0->( DBSetOrder(1))
ZL1->( DBSetOrder(2))

While TRB->(!Eof())

	_cCposDif:=_cMem:=""
	_lTudoIgual:=.T.
	_cLinhaRota:=_cSetor:=""
	ZLJ->(DBGoTo(TRB->REC_ZLJ))

	aAdd(_atlog, {.F.,;//Bolinha verde ou vermelha
					TRB->ZLJ_NUMERO,;//'Atendimento'
					ZLJ->ZLJ_CODPAT+' '+ZLJ->ZLJ_LOJPAT+' '+TRB->ZLJ_NOMPAT,;//Produtor
					TRB->ZLJ_TIPPRO,;//Tp Produtor
					TRB->ZLJ_SETOR ,;//'Setor'
					TRB->ZLJ_LINROT,;//'Linha'
					TRB->ZLJ_VEICUL,;//'Veiculo'
					TRB->ZLJ_CODTRN+' '+TRB->ZLJ_LOJTRN+' '+Posicione("SA2",1,xFilial("SA2")+TRB->ZLJ_CODTRN+TRB->ZLJ_LOJTRN,"A2_NOME"),;//'Transportador'
					"Dados Atual, veja linha abaixo"})//'Observação'

	If !Empty(ZLJ->ZLJ_CODPAT)

		If !SA2->(DBSeek(xFilial("SA2")+ZLJ->ZLJ_CODPAT+ZLJ->ZLJ_LOJPAT)) .Or. (SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N')
			_cMem+="[Produtor: "+ZLJ->ZLJ_CODPAT+' '+ZLJ->ZLJ_LOJPAT+" nao encontrado, bloqueado ("+SA2->A2_MSBLQL+") ou inativo ("+SA2->A2_L_ATIVO+")] "
			_lDeuErro:=.T.
			_cLinhaRota:=SA2->A2_L_LI_RO
		Else
			TRB->ZLJ_NOMPAT:=SA2->A2_NOME
			If TRB->ZLJ_TIPPRO # SA2->A2_L_TIPPR
				_cMem+="[Tipo do Produtor diferente do cadastro: "+SA2->A2_L_TIPPR+", integre a viagem novamente] "
				_lDeuErro:=.T.
			EndIf
			_cLinhaRota:=SA2->A2_L_LI_RO
		EndIf
   
	Else
		_cLinhaRota:=TRB->ZLJ_LINROT
	EndIf
	
    If Empty(_cLinhaRota)
		_cMem+="[Linha/Rota nao preenchida Chave: "+ZLJ->ZLJ_CODPAT+" "+ZLJ->ZLJ_LOJPAT+"] "
		_lDeuErro:=.T.
	Else
        If !(TRB->ZLJ_LINROT == _cLinhaRota)
           _cCposDif+="[Linha] "
           _lTudoIgual:=.F.
        EndIf
		TRB->ZLJ_LINROT:=_cLinhaRota
        TRB->ZLJ_NLINRO:=CriaVar("ZLJ_NLINRO")
		_cSetor:=Posicione("ZL3",1,ZLJ->ZLJ_FILIAL+_cLinhaRota,"ZL3_SETOR")
	EndIf
	
	If !Empty(_cLinhaRota) .And. Empty(_cSetor)
		_cMem+="[Setor nao encontrada da Linha: "+_cLinhaRota+"] "
		_atlog[Len(_atlog),6]:=_cLinhaRota//Atyualizo a linha pq pode ser a linha nova que esteja com erro
		_lDeuErro:=.T.
	ElseIf !Empty(_cLinhaRota)
        If !(TRB->ZLJ_SETOR == _cSetor)
           _cCposDif+="[Setor] "
           _lTudoIgual:=.F.
        EndIf
		TRB->ZLJ_SETOR :=_cSetor
        TRB->ZLJ_NSETOR:=CriaVar("ZLJ_NSETOR")
	EndIf
	
	_cCodtransp:= ""
	_cLojtransp:= ""
	_lAchouMoto:= .T.
	
	If !ZL0->( DBSeek( ZLJ->ZLJ_FILIAL + ZLJ->ZLJ_MOTORI ) )
		_lAchouMoto:= .F.
		_cMem += '[Motorista: '+ ZLJ->ZLJ_MOTORI+' não encontrado] '
		_lDeuErro:=.T.
	Else
		_cCodtransp:= ZL0->ZL0_FRETIS
		_cLojtransp:= ZL0->ZL0_FRETLJ
        If !(TRB->ZLJ_CODTRN == _cCodtransp) .Or. !(TRB->ZLJ_LOJTRN == _cLojtransp)
           _cCposDif+="[Fretista] "
           _lTudoIgual:=.F.
        EndIf
		TRB->ZLJ_CODTRN:= _cCodtransp
		TRB->ZLJ_LOJTRN:= _cLojtransp
		TRB->ZLJ_DTRAN := Posicione("SA2",1,xFilial("SA2")+_cCodtransp+_cLojtransp,"A2_NOME")
	EndIf
	
	_cVeiculo:=""
	_lAchouPlaca:=.F.
	
	If _lAchouMoto .And. ZL1->(DBSeek(ZLJ->(ZLJ_FILIAL+ZLJ_PLACA)))
		While ZL1->(!Eof()) .And.  ZL1->ZL1_FILIAL + ZL1->ZL1_PLACA == ZLJ->ZLJ_FILIAL + ZLJ->ZLJ_PLACA
			If ZL1->ZL1_MOTORI == ZLJ->ZLJ_MOTORI
				_cVeiculo   :=ZL1->ZL1_COD
				_lAchouPlaca:=.T.
				Exit
			EndIf
			ZL1->(DBSkip())
		EndDo
	EndIf
	
	If !_lAchouPlaca
		_cMem += '[Placa: '+ZLJ->ZLJ_PLACA + ' + Motorista: '+ZLJ->ZLJ_MOTORI+' não encontrado] '
		_lDeuErro:=.T.
    Else
        If !(TRB->ZLJ_VEICUL == _cVeiculo)
           _cCposDif+="[Veiculo] "
           _lTudoIgual:=.F.
        EndIf
		TRB->ZLJ_VEICUL:= _cVeiculo
	EndIf

    TRB->TRB_GRAVA:=.F.
    _lTemErro:=!Empty(_cMem)

    If !_lTemErro 
       If _lTudoIgual
          _cMem:="SEM diferenças"
          _lTemErro:=.T.//Se ta tudo OK não precisa atualizar
       Else
          _cMem:="COM diferenças: "+_cCposDif
          TRB->TRB_GRAVA:=.T.
          _lTodosIguais:=.F.
       EndIf   
    EndIf

    _atlog[Len(_atlog),1]:=!_lTemErro//Atualiza a primeira linha tb com o status da segunda linha
    
    If TRB->TRB_GRAVA//Só cria uma linha duplicada de tiver diferenças
	   aAdd(_atlog,{.T.,;//Bolinha ver ou vermelha
                 TRB->ZLJ_NUMERO,;//'Atendimento'
                 ZLJ->ZLJ_CODPAT+' '+ZLJ->ZLJ_LOJPAT+' '+TRB->ZLJ_NOMPAT,;//Produtor
                 TRB->ZLJ_TIPPRO,;//Tp Produtor
			     TRB->ZLJ_SETOR ,;//'Setor'
			     TRB->ZLJ_LINROT,;//'Linha'
			     TRB->ZLJ_VEICUL,;//'Veiculo'
			     TRB->ZLJ_CODTRN+' '+TRB->ZLJ_LOJTRN+' '+TRB->ZLJ_DTRAN,;//'Transportador'
			     _cMem})//'Observação'
     Else
       _atlog[Len(_atlog),Len(_atlog[1])]:=_cMem//Atualiza a mensagem
     EndIf
     
     TRB->(DBSkip())
	
EndDo

_bCancel:=_bOK:=NIL

If _lDeuErro
   _cProblema:="Ocorreram problemas no Reprocessamento, para maiores detalhes veja a Coluna Observações."
   _cSolucao :="Para fechar a tela de Log clique no Botão FECHAR. Todo o processamento gerado não será salvo."
   _bOK:={|| Help(NIL, NIL, "AGLT02142", NIL, _cProblema, 1, 0, NIL, NIL, NIL, NIL, NIL, {_cSolucao}) , .F. }
   _bCancel := {|oDlg| (_lRet:=.F. , oDlg:End()) }
ElseIf _lTodosIguais
   _cProblema:="Não há diferenças em nenhum atendimento."
   _cSolucao :="Para fechar a tela de Log clique no Botão FECHAR."
   _bOK:={|| Help(NIL, NIL, "AGLT02143", NIL, _cProblema, 1, 0, NIL, NIL, NIL, NIL, NIL, {_cSolucao}) , .F. }
   _bCancel := {|oDlg| (_lRet:=.F. , oDlg:End()) }
Else
   _bCancel := {|oDlg| If(MsgYesNo("Confirma o Cancelamento? Todo o processamento gerado não será salvo!","AGLT02144"),(_lRet:=.F. , oDlg:End()),.F.) }
EndIf

While .T.

//ITListBox(         _cTitAux        , _aHeader
   _cMsgTop:="Viagem: "+AllTrim(M->ZLJ_VIAGEM)
   _lRet:=U_ITListBox( "Log de Reprocessamento dos Atendimentos. (AGLT021)" ,;                               //        , _aCols , _lMaxSiz,_nTipo,_cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel )
            {"",'Atendimento','Produtor','Tp Produtor','Setor','Linha','Veiculo','Transportador','Observações / Erros'}, _atlog , .T.     , 4    ,_cMsgTop ,          ,;
            {10,           55,       110,           40,     40,     40,       40,            130,        400},, _bOK,_bCancel  )

   If _lRet .And. !MsgYesNo("Confirma a GRAVAÇÃO do Reprocessamento dessa Viagem?","AGLT02145")
      Loop
   EndIf
   
   Exit
   
EndDo 

If _lRet 

   ProcRegua( TRB->(LASTREC()) )

   TRB->(DBGoTop())

   lTemRecebimento:=.F.

   While TRB->(!Eof())

      IncProc("Gravando Atendimento: "+ZLJ->ZLJ_NUMERO)

      If !TRB->TRB_GRAVA
         TRB->(DBSkip())
         Loop
      EndIf

      ZLJ->(DBGoTo(TRB->REC_ZLJ))
      ZLJ->(RecLock("ZLJ",.F.))
	  ZLJ->ZLJ_VEICUL:=TRB->ZLJ_VEICUL
	  ZLJ->ZLJ_CODTRN:=TRB->ZLJ_CODTRN
	  ZLJ->ZLJ_LOJTRN:=TRB->ZLJ_LOJTRN
	  ZLJ->ZLJ_TIPPRO:=TRB->ZLJ_TIPPRO
	  ZLJ->ZLJ_LINROT:=TRB->ZLJ_LINROT
	  ZLJ->ZLJ_SETOR :=TRB->ZLJ_SETOR
      ZLJ->(MSUnLock())

      If TRB->ZLJ_TIPPRO = "F"
         lTemRecebimento:=.T.
	     M->ZLJ_CODTRN:= TRB->ZLJ_CODTRN
	     M->ZLJ_LOJTRN:= TRB->ZLJ_LOJTRN
	     M->ZLJ_DTRAN := TRB->ZLJ_DTRAN
	     M->ZLJ_VEICUL:= TRB->ZLJ_VEICUL
      EndIf

      TRB->(DBSkip())
	
   EndDo

   TRB->(DBGoTop())

   If !lTemRecebimento
      M->ZLJ_CODTRN:= TRB->ZLJ_CODTRN
      M->ZLJ_LOJTRN:= TRB->ZLJ_LOJTRN
      M->ZLJ_DTRAN := TRB->ZLJ_DTRAN
      M->ZLJ_VEICUL:= TRB->ZLJ_VEICUL
   EndIf

EndIf

TRB->(DBGoTop())

Return (_lTodosIguais .Or. _lRet)//Se os 2 forem falsos não retorna para a tela pq alterou o TRB 

/*
===============================================================================================================================
Programa----------: GLT21Marca
Autor-------------: Alex Wallauer
Data da Criacao---: 15/06/2016
Descrição---------: Funcao para troca sim e na dos campos de Transportadora de redespacho e Operador Logistico
Parametros--------: objBrowse: objeto
Retorno-----------: Verdadeiro
===============================================================================================================================
*/
Static Function GLT21Marca(objBrowse)

Local _lOK    := .F.
Local _nKmVia := 0
Local _bValid
Local _nCol1  :=5
Local _nCol2  :=15
Local _nTam   :=50
Local _nRecTRB:=TRB->(RECNO())
Local _cVaigem:=If(Empty(TRB->ZLJ_VFILHA) .Or. Upper(TRB->ZLJ_VFILHA) = "JULIETA" ,TRB->ZLJ_VIAGEM,TRB->ZLJ_VFILHA)
Local _cTit   :="Km da Viagem: "+_cVaigem

_nKmVia:= TRB->ZLJ_KMDVIA
_lOK   := .F.
_bValid:= {|| If(Positivo(_nKmVia),(_lOK:=.T.,Close(_oDlg)),.F.) }

Define MSDialog _oDlg Title _cTit From 000,000 To 080,200 Pixel
   
	@ 005, _nCol1 Say _cTit Pixel
	@ 016, _nCol2 MSGet _nKmVia Picture "@E 999,999,999" Size _nTam,11 Of _oDlg Valid ( EVAL(_bValid) ) Pixel

	@ 100,0110	BMPButton Type 01 Action EVAL(_bValid)
					
Activate MSDialog _oDlg Centered

If _lOK

	If Empty(TRB->ZLJ_VFILHA) .Or. Upper(TRB->ZLJ_VFILHA) = "JULIETA" 
		M->ZLJ_KMDVIA := _nKmVia
	EndIf

	TRB->(DBGoTop())
	While TRB->(!Eof())

		If (_cVaigem == If(Empty(TRB->ZLJ_VFILHA) .Or. Upper(TRB->ZLJ_VFILHA) = "JULIETA" ,TRB->ZLJ_VIAGEM,TRB->ZLJ_VFILHA))
			TRB->ZLJ_KMDVIA := _nKmVia
		EndIf
		TRB->(DBSkip())

	EndDo

	TRB->(DBGoTo(_nRecTRB))
	objBrowse:oBrowse:Refresh()

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AGLT021D
Autor-------------: Abrahao Copia by Alex Wallauer
Data da Criacao---: 09/01/2009 - 10/03/2017
Descrição---------: Verifica se Ticket nao pode ser modificado por ja possuir lançamento de algum evento.
Parametros--------: dDataCol: Data da Coleta , cCodProd: Codigo do Produtor , cLjProd: Loja do Produtor
Retorno-----------: .T. : Se tem eventos , .F. : Se não tem eventos
===============================================================================================================================
*/
Static Function AGLT021D( dDataCol , cCodProd , cLjProd , lValZLX , cTipoLeite )

Local cAliasZLF	:= GetNextAlias()
Local nCountRec	:= 0
Local lRet		:= .F.
Local aArea		:= FWGetArea()
Local _cCod		:= ""
Local _cLoja	:= ""
Local _nI		:= 0
Default lValZLX := .T.

ZLX->(DBSetOrder(1))
If lValZLX .And. !Empty(ZLD->ZLD_CODZLX) .And. ZLX->( DBSeek(xFilial()+ZLD->ZLD_CODZLX)) .And. ZLD->ZLD_TICKET $ ZLX->ZLX_LISTA//VALIDACAO DO SETOR SEGUNDARIO = "2"
	MsgAlert("Viagem / Ticket ["+ZLD->ZLD_TICKET+"] nao pode ser alterado ou excluido por estar vinculado a Recepção de Leite de Terceiros. " +;
	            "Desvincule a Viagem / Ticket da Recepção de Leite de terceiros Código: "+ZLD->ZLD_CODZLX , "AGLT02146")
	Return .T.//Verdadeiro é que não deixa continuar
EndIf

ZLX->(dbOrderNickname("IT_I_TISET"))//ZLX_FILIAL+ZLX_TICKET+ZLX_SETOR// INDICE 10
If lValZLX .And. ZLX->( DBSeek(xFilial()+ZLD->ZLD_TICKET+ZLD->ZLD_SETOR)) .And. ZLX->ZLX_STATUS $ '2,3' //VALIDACAO DO SETOR PRIMARIO  = "1"
	MsgAlert("Viagem / Ticket ["+ZLD->ZLD_TICKET+"] nao pode ser alterado ou excluido por estar vinculado a Recepção de Leite de Terceiros NÃO PENDENTE. "+;
	            "Altere o status para pendente da Recepção de Leite de terceiros Código: "+ZLX->ZLX_CODIGO,"AGLT02147")
    ZLX->(DBSetOrder(1))
	Return .T.//Verdadeiro é que não deixa continuar
EndIf
ZLX->(DBSetOrder(1))

SA2->( DBSetOrder(1) )
For _nI	:= 1 To 2// Primeiro valido produtor e depois transportador
	If _nI == 1
		_cCod := cCodProd
		_cLoja := cLjProd
	Else 
		_cCod := ZLD->ZLD_FRETIS
		_cLoja := ZLD->ZLD_LJFRET
	EndIf
	If !Empty(_cCod)
		If SA2->( DBSeek( xFilial('SA2') + _cCod + _cLoja ) )
			If SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N'
				lRet := .T.
				MsgAlert("Cadastro do Produtor/Fretista ["+ SA2->A2_COD +"-"+ SA2->A2_LOJA +"] está Bloqueado ou Inativo no cadastro de fornecedores.","AGLT02148")
			ElseIf cTipoLeite <> "C"//Cooperativa
				cAliasZLF := GetNextAlias()
				BeginSql alias cAliasZLF
					SELECT ZLF_CODZLE
					FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
					WHERE ZLF.D_E_L_E_T_ = ' '
					AND ZL8.D_E_L_E_T_ = ' '
					AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
					AND ZLF.ZLF_FILIAL = ZL8.ZL8_FILIAL
					AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
					AND ZL8.ZL8_COMPGT <> 'S'
					AND ZL8.ZL8_ADICOM <> 'S'
					AND ZLF_A2COD = %exp:_cCod%
					AND ZLF_A2LOJA = %exp:_cLoja%
					AND %exp:dDataCol% >= ZLF_DTINI
					AND %exp:dDataCol% <= ZLF_DTFIM
					AND ZLF_DTCALC >= ZLF_DTFIM
				EndSql
				
				COUNT To nCountRec //Contabiliza o numero de registros encontrados pela query
				(cAliasZLF)->( DBGoTop() )
						
				If nCountRec > 0    
					lRet := .T.			
					MsgAlert("Viagem nao pode ser modificada por ja possuir lançamento de algum evento. "+;
								"Favor contactar o responsável pelo lançamento dos eventos e pedir para excluir os eventos gerados no mix: "+;
									(cAliasZLF)->ZLF_CODZLE +" para o Produtor / Fretista - Data: "+ _cCod +"-"+ _cLoja+" - "+DToC(dDataCol),"AGLT02149")
					Exit
				EndIf
				(cAliasZLF)->( DBCloseArea() )
			EndIf
		Else
			lRet := .T.
			MsgAlert("Código do Produtor/Fretista não foi encontrado no cadastro de fornecedores.","AGLT02150")
			Exit
		EndIf
	EndIf
Next _nI

FWRestArea(aArea)

Return( lRet )

/*
===============================================================================================================================
Programa--------: AGLT21RE
Autor-----------: Alex Wallauer
Data da Criacao-: 24/10/2017
Descrição-------: Refaz a entrada do Estoque
Parametros------: _cAlias: Tabela , nRecZLJ: Recno , _nOpc: Opcao
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT21RE(_cAlias , nRecZLJ , _nOpc )

Local _bok:={ || lOK := .T. , Processa( {|| lOK := AGLT021GRC(".",.T.,.F.) } ) , lOK}

//Verifica status
If ZLJ->ZLJ_STATUS == "R"
   MsgAlert("Viagem já está recusada","Atenção","Estorne a recusa","AGLT02151")
   Return
EndIf	

//Locka registros
If !( AGLT021LO( SubStr( ZLJ->ZLJ_FILIAL , 1 , 2 ), ZLJ->ZLJ_VIAGEM ) )
	Return .F.
EndIf

AGLT021Tela("Refaz a entrada do Estoque",_bok,_nOpc,nRecZLJ)

AGLT021UN(ZLJ->ZLJ_FILIAL, ZLJ->ZLJ_VIAGEM )

Return .T.

/*
===============================================================================================================================
Programa--------: AGLTTela_ZLX
Autor-----------: Alex Wallauer 
Data da Criacao-: 07/02/2018
Descrição-------: Tela Dados complemetares para Geraçao da Recepção Tipo Plataforma automatica
Parametros------: cManut: Origem da manutenção
Retorno---------: aDados
===============================================================================================================================
*/
User Function AGLTTela_ZLX(cManut)//U_AGLTTela_ZLX("ORI_ZLJ")

Local _lOK				:= .F.
Local _bValid
Local _nLinha			:=05
Local _nPula			:=23
Local _nCol1			:=50
Local _nCol2			:=_nCol1+65
Local _nCol3			:=_nCol1+150
Local _nTam				:=55
Local nLarg				:=_nTam
Local nAltu				:=105
Local _cTit				:="Dados complemetares para Geraçao da Recepção Tipo Plataforma automatica (AGLT021)"
Local aDados			:={}
Local M->ZLX_DTENTR		:= CTOD('')
Local _cZLX_PLACA		:= ''
Private _nZLX_TEORAN	:= _nMedia := 0
Private _cNomeTRAN		:= Space(100)
Private M->ZLX_HRENTR	:= Space(GetSx3Cache("ZLX_HRENTR","X3_TAMANHO"))//Usado na função U_AGLT035F()
Private M->ZLX_DATAEN	:= CTOD('')//Usado na função U_AGLT035F()
Private M->ZLX_HRSAID	:= Space(GetSx3Cache("ZLX_HRSAID","X3_TAMANHO"))//Usado na função U_AGLT035F()
Private M->ZLX_DTSAID	:= CTOD('')//Usado na função U_AGLT035F()
Private M->ZLX_OBS      := Space(30)

If cManut = "ORI_ZLJ"
   M->ZLX_DTENTR := M->ZLJ_DTCRIA//Data Estoque
   _cZLX_PLACA   := ZLJ->ZLJ_PLACA//Placa Veicul
   _cZLX_TRANSP  := ZLJ->ZLJ_CODTRN//Cod Transpor
   _cZLX_LJTRAN  := ZLJ->ZLJ_LOJTRN//Loja Transp
ElseIf cManut = "ORI_ZLD"
   M->ZLX_DTENTR := dDtColeta//ZLJ->ZLJ_DTCRIA//Data Estoque
   _cZLX_PLACA   := Posicione("ZL1",1,xFilial("ZL1")+cVeicul,"ZL1_PLACA")//Placa Veicul - variável Private no AGLT003
   _cZLX_TRANSP  := cFretist//Cod Transpor - variável Private no AGLT003
   _cZLX_LJTRAN  := cLjFret //Loja Transp - variável Private no AGLT003
EndIf   

_bValid := {|| NaoVazio(_nMedia) }
_bOK    := {|| (If(EVAL(_bValid).AND.U_AGLT035F().AND.U_AGLT035P("001",_nMedia),(_lOK:=.T.,Close(_oDlg)),))  }
aLista  := {{0}}
While .T.

   _lOK   := .F.
   _nLinha :=05
	_nCol1 -= 10
	_nCol2 -= 10
	_nCol3 -= 10

   Define MSDialog _oDlg Title _cTit From 000,000 To 470,575 Pixel
   
	@ _nLinha+2, _nCol1    Say "Veiculo:" Pixel       //Tem que ser com essa pict para grava com o traçõ na ZLX e validar ZZV
	@ _nLinha  , _nCol2    MSGet _cZLX_PLACA  Picture GetSx3Cache("ZLX_PLACA","X3_PICTURE") Size _nTam,11 OF _oDlg VALID ExistCpo("ZZV",_cZLX_PLACA) .And. AGLT21Valid(_cZLX_PLACA,"PLACA") Pixel F3 "ZZV"
	@ _nLinha  , _nCol3-25 MSGet _cZLX_TRANSP Picture AVSX3('ZLX_DTENTR',6) Size 40,11 OF _oDlg Pixel WHEN .F.
	@ _nLinha  , _nCol3+20 MSGet _cZLX_LJTRAN Picture AVSX3('ZLX_LJTRAN',6) Size 25,11 OF _oDlg Pixel WHEN .F.
	
	_nLinha    += _nPula
	_nLinSalva := _nLinha
	
	@ _nLinha+2, _nCol1    Say "Transportadora:" Pixel
	@ _nLinha  , _nCol2    MSGet _cNomeTRAN   Picture "@!" Size (_nTam+40+30),11 OF _oDlg Pixel WHEN .F.
	
	_nLinha += _nPula
	
	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_DTENTR","X3_TITULO")+":") Pixel
	@ _nLinha, _nCol2 MSGet M->ZLX_DTENTR  Picture GetSx3Cache("ZLX_DTENTR","X3_PICTURE") Size _nTam,11 OF _oDlg VALID CheckSX3("ZLX_DTENTR") Pixel
	
	_nLinha += _nPula
	
	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_DATAEN","X3_TITULO")+":") Pixel
	@ _nLinha, _nCol2 MSGet M->ZLX_DATAEN Picture GetSx3Cache("ZLX_DATAEN","X3_PICTURE") Size _nTam,11 OF _oDlg VALID CheckSX3("ZLX_DATAEN") Pixel
	
	_nLinha += _nPula
	
	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_HRENTR","X3_TITULO")+":") Pixel
	@ _nLinha, _nCol2 MSGet M->ZLX_HRENTR Picture GetSx3Cache("ZLX_HRENTR","X3_PICTURE") Size _nTam,11 OF _oDlg VALID CheckSX3("ZLX_HRENTR") Pixel
	
	_nLinha += _nPula
	
	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_DTSAID","X3_TITULO")+":") Pixel
	@ _nLinha, _nCol2 MSGet M->ZLX_DTSAID Picture GetSx3Cache("ZLX_DTSAID","X3_PICTURE") Size _nTam,11 OF _oDlg VALID CheckSX3("ZLX_DTSAID") Pixel
	
	_nLinha += _nPula

	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_HRSAID","X3_TITULO")+":") Pixel
	@ _nLinha, _nCol2 MSGet M->ZLX_HRSAID Picture GetSx3Cache("ZLX_HRSAID","X3_PICTURE") Size _nTam,11 OF _oDlg VALID CheckSX3("ZLX_HRSAID") Pixel
	
	_nLinha += _nPula

	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_TEORAN","X3_TITULO")+"  +  Media") Pixel
	@ _nLinha, _nCol2 MSGet _oTeor VAR _nZLX_TEORAN  Picture GetSx3Cache("ZLX_TEORAN","X3_PICTURE") Size _nTam,11 OF _oDlg VALID CheckSX3("ZLX_TEORAN") Pixel
   @ _nLinha, _nCol3-20 Button " + " Size 11,12 Action (AGLTLista("ADD")) OF _oDlg Pixel
	@ _nLinha, _nCol3 MSGet _nMedia       Picture GetSx3Cache("ZLX_TEORAN","X3_PICTURE") Size _nTam,11 OF _oDlg  Pixel
   @ _nLinha, _nCol3+60 Button " - " Size 11,12 Action (AGLTLista("DEL")) OF _oDlg Pixel
	
	_nLinha += _nPula

	@ _nLinha+2, _nCol1 Say (GetSx3Cache("ZLX_OBS","X3_TITULO")+":") Pixel
	@ _nLinha, _nCol2 MSGet M->ZLX_OBS Size (_nTam+70),11 OF _oDlg VALID CheckSX3("ZLX_OBS") Pixel //Picture GetSx3Cache("ZLX_OBS","X3_PICTURE") 

   oList:=TWBrowse():New(_nLinSalva+_nPula,_nCol3,nLarg,nAltu,,{GetSx3Cache("ZLX_TEORAN","X3_TITULO")},{40},oDlg,,,,,,,,,,,,,"ARRAY",.T.)
  	oList:SetArray(aLista)					
   oList:bLine:={|| {TRANS(aLista[oList:nAt,1],"@E 999.99") } }

	_nLinha += _nPula

   @_nLinha,_nCol1-5 Button "Continuar" Size 50,15 Action (EVAL(_bOK)) OF _oDlg Pixel
   @_nLinha,_nCol3   Button "Voltar"    Size 50,15 Action (_lOK:=.F.,Close(_oDlg)) OF _oDlg Pixel
					
   Activate MSDialog _oDlg Centered

   If _lOK

      aDados:={,,,,,,,,,}
      aDados[1]:= M->ZLX_DTENTR //Data de Movimento: (Sugerir a data do estoque, mas deixar o campo editável)
      aDados[2]:= M->ZLX_DATAEN //Data Entrada
      aDados[3]:= M->ZLX_HRENTR //Hora Entrada
      aDados[4]:= M->ZLX_DTSAID //Data Saida
      aDados[5]:= M->ZLX_HRSAID //Hora Saida
      aDados[6]:= _nMedia //Teor Analise-Teor de Gordura (Gride igual da análise de qualidade)
      aDados[7]:= _cZLX_PLACA
      aDados[8]:= _cZLX_TRANSP
      aDados[9]:= _cZLX_LJTRAN
		aDados[10]:= M->ZLX_OBS

   EndIf

   Exit

EndDo

Return aDados


/*
===============================================================================================================================
Programa--------: AGLTLista()
Autor-----------: Alex Wallauer 
Data da Criacao-: 14/02/2018
Descrição-------: add aLista
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AGLTLista(cManut)

Local _nX := 0
If cManut=="DEL"
   If Len(aLista) > 1
	  aDel(aLista,oList:nAt)
	  aSize(aLista,Len(aLista)-1)      
   Else
      aLista[1,1]:=0
   EndIf
Else
   If Empty(aLista[1,1])
      aLista [1,1]:=_nZLX_TEORAN
   ElseIf !Empty(_nZLX_TEORAN)
      aAdd(aLista,{_nZLX_TEORAN})
   EndIf
   _oTeor:SetFocus()
EndIf

_nMedia:=0
For _nX := 1 To Len(aLista)
    _nMedia+=aLista[_nX,1]
Next _nX

_nMedia:=_nMedia/Len(aLista)

oList:Refresh()

Return .T.

/*
===============================================================================================================================
Programa--------: U_AGLTGrv_ZLX
Autor-----------: Alex Wallauer 
Data da Criacao-: 07/02/2018
Descrição-------: Gravar Recepções Tipo Plataforma O ZLD tem que esta posicionado
Parametros------: cManut: Origem da manutenção ; aDados: dados dos campos que deram GET
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLTGrv_ZLX(cManut,aDados)//U_AGLTGrv_ZLX

Local _cNumRecZLX	:= ""
Default aDados		:={DATE(),DATE(),TIME(),DATE(),TIME(),0,""}

ZLX->(dbOrderNickname("IT_I_TISET"))//ZLX_FILIAL+ZLX_TICKET+ZLX_SETOR //ZLX->(DBSetOrder(10))
If ZLX->( DBSeek(xFilial()+ZLD->ZLD_TICKET+ZLD->ZLD_SETOR))

	_lGerou_ZLX:=.T.
	ZLX->( RecLock("ZLX",.F.) )

	//Exclusão
	If cManut = "EXCLUI"

		ZZX->(DBSetOrder(1))
		If ZZX->( DBSeek(xFilial()+ZLX->ZLX_CODANA))
			ZZX->( RecLock("ZZX",.F.) )
			ZZX->(DBDELETE())
			ZZX->( MSUnLock())
		EndIf
		ZAP->(DBSetOrder(1))
		If ZAP->( DBSeek(xFilial()+ZLX->ZLX_CODANA))
			ZAP->( RecLock("ZAP",.F.) )
			ZAP->(DBDELETE())
			ZAP->( MSUnLock())
		EndIf
		ZLX->(DBDELETE())

	//Alteração
	ElseIf cManut = "LIMPA"
		ZLX->ZLX_VOLNF:=0//zera para somar de novo

	ElseIf cManut == "ORI_ZLJ"//SQ         //ACUMLA depois que inclui o primeiro produtor
		ZLX->ZLX_VOLNF +=ZLD->ZLD_QTDBOM//ZLJ->ZLJ_VOLUME//"Volume na Nota fiscal" //somatória do que foi coletado dos produtores
		ZLX->ZLX_VOLREC:=ZLD->ZLD_TOTBOM//_nTotBom//Volume Recebido//TOTAL DO SETOR 
		ZLX->ZLX_DIFVOL:=ZLX->ZLX_VOLREC - ZLX->ZLX_VOLNF

	ElseIf cManut == "ORI_ZLD"//MANUAL   //ACUMLA depois que inclui o primeiro produtor
		ZLX->ZLX_VOLNF :=nLeiteBom//Essa variavel é do RDM AGLT003.prw ZLJ->ZLJ_VOLUME//"Volume na Nota fiscal" //somatória do que foi coletado dos produtores
		ZLX->ZLX_VOLREC:=nTotBom  //Essa variavel é do RDM AGLT003.prw Volume Recebido//TOTAL DO SETOR 
		ZLX->ZLX_DIFVOL:=ZLX->ZLX_VOLREC - ZLX->ZLX_VOLNF

   EndIf

   ZLX->( MSUnLock())
   ZLX->(DBSetOrder(1))

   Return .T.

ElseIf cManut = "EXCLUI" .Or. cManut = "LIMPA"//Se não achar no ZLX NÃO faz nada
   Return .F.
EndIf

If Empty(ZLD->ZLD_TICKET) .Or. Empty(ZLD->ZLD_SETOR) .OR.;
   ZLD->ZLD_TOTBOM = 0 //Reboque
   Return .F.
EndIf

ZL2->(DBSetOrder(1))
If !ZL2->( DBSeek(xFilial()+ZLD->ZLD_SETOR)) .Or. !(ZL2->ZL2_CRIRT = "1")//SETOR PRIMARIO = "1"
   Return .F.
EndIf

//Inclusão ZLX - Início
_cNumRecZLX := GETSXENUM("ZLX","ZLX_CODIGO")

ZLX->(RecLock("ZLX",.T.))
ZLX->ZLX_FILIAL := xFilial("ZLX")
ZLX->ZLX_CODIGO := _cNumRecZLX
ZLX->ZLX_TICKET := ZLD->ZLD_TICKET
ZLX->ZLX_SETOR  := ZLD->ZLD_SETOR
ZLX->ZLX_FORNEC := ZL2->ZL2_PLAFOR
ZLX->ZLX_LJFORN := ZL2->ZL2_PLALOJ
ZLX->ZLX_TRANSP := ZLD->ZLD_FRETIS//Cod Transpor
ZLX->ZLX_LJTRAN := ZLD->ZLD_LJFRET//Loja Transp
ZLX->ZLX_PGFRT  := "N"            //Paga Frete
ZLX->ZLX_TIPOLT := "P"            //P=PLATAFORMA
ZLX->ZLX_STATUS := "1"            //1=Pendente
ZLX->ZLX_PRODLT := "08000000004"
ZLX->ZLX_DTENTR := aDados[1]//Data de Movimento: (Sugerir a data do estoque, mas deixar o campo editável)
ZLX->ZLX_DATAEN := aDados[2]//Data Entrada
ZLX->ZLX_HRENTR := aDados[3]//Hora Entrada
ZLX->ZLX_DTSAID := aDados[4]//Data Saida
ZLX->ZLX_HRSAID := aDados[5]//Hora Saida
ZLX->ZLX_TEORAN := aDados[6]//Teor Analise-Teor de Gordura (Gride igual da análise de qualidade)
  
If cManut == "ORI_ZLJ"//SQ
   ZLX->ZLX_DTESTO := ZLJ->ZLJ_DTCRIA//Data Estoque
   ZLX->ZLX_ORIGEM := "3"            //Origem Gerada //"1=Recepcao Leite Terceiros (Manual), 2=Recepcao Leite Próprio (Manual), 3=Integracao SmartQuestion"
   ZLX->ZLX_PLACA  := ZLJ->ZLJ_PLACA //Placa Veicul
   ZLX->ZLX_VOLNF  += ZLD->ZLD_QTDBOM//ZLJ->ZLJ_VOLUME//"Volume na Nota fiscal" //somatória do que foi coletado dos produtores
   ZLX->ZLX_VOLREC := ZLD->ZLD_TOTBOM//_nTotBom//Volume Recebido//TOTAL DO SETOR 

ElseIf cManut == "ORI_ZLD"//Manual
   ZLX->ZLX_DTESTO := ZLD->ZLD_DTCOLE//ZLJ->ZLJ_DTCRIA//Data Estoque
   ZLX->ZLX_ORIGEM := "2"            //Origem Gerada //"1=Recepcao Leite Terceiros (Manual), 2=Recepcao Leite Próprio (Manual), 3=Integracao SmartQuestion"
   ZLX->ZLX_PLACA  := Posicione("ZL1",1,xFilial("ZL1")+ZLD->ZLD_VEICUL,"ZL1_PLACA")//ZLD->ZLD_VEICUL//ZLJ->ZLJ_PLACA//Placa Veicul
   ZLX->ZLX_VOLNF  := nLeiteBom//Essa variavel é do RDM AGLT003.prw ZLJ->ZLJ_VOLUME//"Volume na Nota fiscal" //somatória do que foi coletado dos produtores
   ZLX->ZLX_VOLREC := nTotBom  //Essa variavel é do RDM AGLT003.prw Volume Recebido//TOTAL DO SETOR 

EndIf   

ZLX->ZLX_DIFVOL := ZLX->ZLX_VOLREC - ZLX->ZLX_VOLNF
If !Empty(aDados[7])
   ZLX->ZLX_PLACA  := aDados[7]//Placa Veicul
   ZLX->ZLX_TRANSP := aDados[8]//Cod Transpor
   ZLX->ZLX_LJTRAN := aDados[9]//Loja Transp
EndIf

ZLX->ZLX_OBS := aDados[10] //Observações

ConfirmSX8()

//Inclusão ZZX
_cNumRecZZX := GETSXENUM("ZZX","ZZX_CODIGO")
ZZX->(RecLock("ZZX",.T.))
ZZX->ZZX_FILIAL:=xFilial("ZZX") //Filial
ZZX->ZZX_CODIGO:=_cNumRecZZX    //Codigo
ZZX->ZZX_CODPRD:="001"          //Produto
ZZX->ZZX_DATA  :=ZLX->ZLX_DATAEN//Data
ZZX->ZZX_HORA  :=ZLX->ZLX_HRENTR//Hora
ZZX->ZZX_FORNEC:=ZLX->ZLX_FORNEC//Fornecedor
ZZX->ZZX_LJFORN:=ZLX->ZLX_LJFORN//Loja Fornece
ZZX->ZZX_PLACA :=ZLX->ZLX_PLACA //Placa
ZZX->ZZX_TRANSP:=ZLX->ZLX_TRANSP//Transportado
ZZX->ZZX_LJTRAN:=ZLX->ZLX_LJTRAN//Loja
ZZX->ZZX_ANAUSE:=.T.//Analise Vinc
ZZX->(MSUnLock())

ConfirmSX8()

//Inclusão ZAP
ZAP->(RecLock("ZAP",.T.))
ZAP->ZAP_FILIAL:=xFilial("ZZX") //Filial
ZAP->ZAP_CODIGO:=_cNumRecZZX    //Analise
ZAP->ZAP_GORD  :=ZLX->ZLX_TEORAN//Gordura
ZAP->ZAP_ITEM  :="01"           //Item
ZAP->(MSUnLock())

ZLX->ZLX_CODANA:=_cNumRecZZX
ZLX->( MSUnLock())
ZLX->(DBSetOrder(1))
_lGerou_ZLX:=.T.
//Inclusão ZLX - Fim

Return .T.
