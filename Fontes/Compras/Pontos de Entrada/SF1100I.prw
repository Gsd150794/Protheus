/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/02/2021| Chamado 35644. Ajuste para não gravar movimento do Leite de Terceiros e Contra Nota no Fechamento.
Lucas Borges  |23/04/2021| Chamado 36219. Refeito mensagens da nota.
Alex Wallauer |23/09/2025| Chamado 49221. Ajustes do Layout para o tema Dark.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RWMake.ch"

/*
===============================================================================================================================
Programa----------: SF1100I
Autor-------------: Tiago Correa Castro
Data da Criacao---: 16/12/2008
Descrição---------: Ponto de entrada após a gravação da Nota Fiscal de Entrada já classificada
					Localização: Function A100Grava() - Responsável por verificar se a linha digitada esta Ok.
					Em que Ponto: Executado apos gravacao do SF1
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function SF1100I

Local _aArea	:= FWGetArea()
Local _cTpEsp	:= ''
Local _cEsp		:= ''

Private lMsErroAuto	:= .F.

// Se nao For sigaauto, Processa e mostra a tela.
_cTpEsp	:= SuperGetMV("IT_ESP",.F.,"55")
_cEsp	:= AModNot( SF1->F1_ESPECIE )

If _cEsp $ _cTpEsp .And. SF1->F1_FORMUL == "S"
	MSGENTR()
	MSGTELA()
EndIf

//Cadastra os complementos de notas fiscais de entrada e de saida com as informacoes necessarias ao Sped.
Processa( {|| U_ICompFis("E",SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,SF1->F1_TPFRETE,SF1->F1_I_MENFI) }, "Aguarde...", "Incluindo Complementos Fiscais...",.F.)

// Função para gravar o movimento do Leite de Terceiros e Contra Nota no Leite Próprio
If !FWIsInCallStack("U_MGLT009")
	U_GrvLT3()
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MSGENTR
Autor-------------: Erich Buttner
Data da Criacao---: 21/02/2013
Descrição---------: Rotina para Inserir a Mensagem Fisco e Cliente para nota fiscal de Entrada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MSGENTR

Local _cAlias	:= ""
Local _aMsg		:= {}
Local _aMsg2	:= {}
Local _lNovaMsg	:= .F.
Local _cMn1		:= cMens1
Local _cMn2		:= cMens2
Local _nI		:= 0
Local _lRLeite	:= AllTrim(Upper(FunName())) $"MGLT009/MGLT010"

cMens1 := ''
cMens2 := ''

If cFormul = 'S'
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT M4_CODIGO, M4_I_COND1, M4_I_TPMSG, M4_I_MSG 
		FROM %Table:SM4%
		WHERE D_E_L_E_T_ = ' '
		AND M4_FILIAL  = %xFilial:SM4%
		AND M4_MSBLQL  <> '1'
		AND M4_I_TPNOT = 'E'
		AND M4_I_CLIFO IN(%Exp:SF1->F1_FORNECE% , ' ')
		AND %exp:dDataBase% BETWEEN M4_I_DTINI AND M4_I_DTFIM
	EndSql	

	SD1->(DBSetOrder(1))
	SD1->(DBSeek(SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)))
	
	While SD1->(!Eof()) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)
		(_cAlias)->(DBGoTop())
		While (_cAlias)->( !Eof() )
			If &((_cAlias)->M4_I_COND1)
				If (_cAlias)->M4_I_TPMSG == 'F'
					cMens2 := IIf(Empty(cMens2),&(AllTrim((_cAlias)->M4_I_MSG)),IIf(AllTrim((_cAlias)->M4_I_MSG) $ AllTrim(cMens2),cMens2,&(AllTrim((_cAlias)->M4_I_MSG))))
				Else
					cMens1 := IIf(Empty(cMens1),&(AllTrim((_cAlias)->M4_I_MSG)),IIf(AllTrim((_cAlias)->M4_I_MSG) $ AllTrim(cMens1),cMens1,&(AllTrim((_cAlias)->M4_I_MSG))))
				EndIf
				
				If Len(_aMsg) > 0
					_lNovaMsg := .T.
					For _nI := 1 To Len(_aMsg)
						If ( AllTrim( _aMsg[_nI][01] ) $ AllTrim(cMens1) )
							_lNovaMsg := .F.
							Exit
						EndIf
					Next _nI
					
					If _lNovaMsg
						aAdd( _aMsg , { cMens1 , (_cAlias)->M4_I_TPMSG , (_cAlias)->M4_CODIGO } )
					EndIf
				Else
					aAdd( _aMsg , { cMens1 , (_cAlias)->M4_I_TPMSG , (_cAlias)->M4_CODIGO } )
				EndIf
				
				If Len(_aMsg2) > 0
					_lNovaMsg2 := .T.
					For _nI := 1 To Len(_aMsg2)
						If ( AllTrim(_aMsg2[_nI][01]) $ AllTrim(cMens2) )
							_lNovaMsg2 := .F.
							Exit
						EndIf
					Next _nI
					
					If _lNovaMsg2
						aAdd( _aMsg2 , { cMens2 , (_cAlias)->M4_I_TPMSG , (_cAlias)->M4_CODIGO } )

					EndIf
				Else
					aAdd( _aMsg2 , { cMens2 , (_cAlias)->M4_I_TPMSG , (_cAlias)->M4_CODIGO } )
				EndIf
			EndIf
			
			(_cAlias)->( DBSkip() )
		EndDo
		//Para não prejudicar a performance do fechamento do leite, nessa situação será verificado apenas
		//o primeiro item do documento, visto que todos sempre tem a mesma regra de mensagem
		If _lRLeite
			Exit
		EndIf
		SD1->( DBSkip() )
	EndDo
	(_cAlias)->( DBCloseArea() )	
	
	// Ordena as mensagem pelo tipo Fiscal e pelo codigo da noticia cadastrada
	_aMsg	:= aSort( _aMsg  ,,, {|x, y| x[2] + x[3] < y[2] + y[3] } )
	_aMsg2	:= aSort( _aMsg2 ,,, {|x, y| x[2] + x[3] < y[2] + y[3] } )
	
	cMens1	:= ""
	cMens2	:= ""
	
	For _nI := 1 To Len(_aMsg)
		cMens1 += _aMsg[_nI][01]
	Next _nI
	
	For _nI := 1 To Len(_aMsg2)
		cMens2 += _aMsg2[_nI][01]
	Next _nI
EndIf

cMens1 += IIf( Empty(cMens1) , _cMn1 , CHR(10)+CHR(13) + _cMn1 )
cMens2 += IIf( Empty(cMens2) , _cMn2 , CHR(10)+CHR(13) + _cMn2 )

Return

/*
===============================================================================================================================
Programa----------: MsgTela
Autor-------------: Tiago Correa Castro
Data da Criacao---: 21/02/2013
Descrição---------: Tela para inserir mensagem do Fisco e Cliente na nota fiscal de entrada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MSGTELA

Local _oMemo01		:= Nil
Local _oMemo02		:= Nil
Local _oTPanel1		:= Nil
Local _oTFolder1	:= Nil

Private _lRet		:= .T.
Private _oDlg  		:= Nil
Private _oFont		:= Nil
Private _oDescMotor	:= Nil
Private _cDescMotor	:= ''
Private _oDescVeic	:= Nil
Private _cDescVeic	:= ''
Private _oMotorista	:= Nil
Private _cMotorista	:= SF1->F1_I_MOTOR
Private _oPlaca		:= Nil
Private _cPlaca		:= SF1->F1_I_PLACA
Private _oVeiculo	:= Nil
Private _cVeiculo	:= SF1->F1_I_VEICU
Private _cDoc		:= SF1->F1_DOC
Private _cSerNf		:= SF1->F1_SERIE
Private _cCliFor	:= SF1->F1_FORNECE
Private _cLoj		:= SF1->F1_LOJA
Private _cEmissao	:= SF1->F1_EMISSAO
Private _cNome		:= ''

If cTipo $ 'DB'
	_cNome := SA1->A1_NOME
Else
	_cNome := SA2->A2_NOME
EndIf

If !l103Auto

	// Validações do usuário
	DEFINE FONT _oFont NAME "Tahoma" BOLD
	
	@000,000 TO 345,500 DIALOG _oDlg TITLE "Mensagem Para Nota Fiscal"
                            //   nRow,nCol                           nWidth,nHeight
		_oTPanel1 := TPanel():New( 0 , 0 , "" , _oDlg ,, .T. , .F. ,,, 310 , 170 , .T. , .F. )
		
		@005,010 Say "Mensagem NF"				  			OF _oTPanel1 PIXEL FONT _oFont
		@020,010 Say "NF/Serie....: "+ _cDoc +"/"+ _cSerNf	OF _oTPanel1 PIXEL
		@020,100 Say "Emissao.....: "+ DToC( _cEmissao )	OF _oTPanel1 PIXEL
		@020,160 Say "Tipo........: Entrada"				OF _oTPanel1 PIXEL
		@030,010 Say _cCliFor +"-"+ _cLoj +"-"+ _cNome		OF _oTPanel1 PIXEL
		
		_oTFolder1 := TFolder():New( 050 , 005 , U_TRANSPVLD() ,, _oTPanel1 ,,,, .T. ,, 240 , 090 )
		
		@005,005 Get _oMemo01 var cMens1 MEMO Size 230,60 of _oTFolder1:aDialogs[1] Pixel
		@005,005 Get _oMemo02 var cMens2 MEMO Size 230,60 of _oTFolder1:aDialogs[2] Pixel
		
		If cFormul = 'S'
			
			@010,005 Say	"Veiculo:"										   		OF _oTFolder1:aDialogs[3] PIXEL
			@005,035 MSGET	_oVeiculo	VAR _cVeiculo	F3 "DA3"	SIZE 046,010	OF _oTFolder1:aDialogs[3] PIXEL VALID(IIf(!EMPTY(_cVeiculo),IIf(EXISTCPO("DA3",_cVeiculo,1),buscaDA3(),_oVeiculo:SETFOCUS()),Eval({|| _cDescVeic:="",_cPlaca:="",.T.})))
			@005,086 MSGET	_oDescVeic	VAR _cDescVeic 				SIZE 150,010	OF _oTFolder1:aDialogs[3] PIXEL 
			@035,005 Say	"Placa...:"												OF _oTFolder1:aDialogs[3] PIXEL
			@030,035 Get	_oPlaca		VAR _cPlaca					SIZE 046,010	OF _oTFolder1:aDialogs[3] PIXEL WHEN .T. PICTURE GetSx3Cache("F1_PLACA","X3_PICTURE")
			@060,005 SAY	"Motorista:"											OF _oTFolder1:aDialogs[3] PIXEL
			@055,035 MSGET	_oMotorista	VAR _cMotorista	F3 "DA4"	SIZE 046,010	OF _oTFolder1:aDialogs[3] PIXEL VALID(IIf(!EMPTY(_cMotorista),IIf(EXISTCPO("DA4",_cMotorista,1),_cDescMotor:=POSICIONE("DA4",1,XFILIAL("DA4") + _cMotorista,"DA4_NOME"),_oMotorista:SETFOCUS()),Eval({|| _cDescMotor:="",.T.})))
			@055,086 MSGET	_oDescMotor	VAR _cDescMotor				SIZE 150,010	OF _oTFolder1:aDialogs[3] PIXEL  
			
			_oDescVeic:Disable()
			_oPlaca:Disable()
			_oDescMotor:Disable()
			
		EndIf
		
		TButton():New( 145 , 010 , ' Confirma '	, _oTPanel1 , {|| PrepSair("1") } , 70 , 15 ,,,, .T. )
		TButton():New( 145 , 095 , ' Cancela '	, _oTPanel1 , {|| PrepSair("2") } , 70 , 15 ,,,, .T. )
	
	ACTIVATE MSDIALOG _oDlg Centered

EndIf

If _lRet
	
	cMensAlt1 := ""
	cMensAlt2 := ""
	
	LRT		:= .F.
	LRT2	:= .F.
	I		:= 1
	I2		:= 1
	
	While !(LRT) .Or. !(LRT2)
		If !Empty(AllTrim(SubStr(cMens1,I,254)))
			cMensAlt1 := cMensAlt1 + AllTrim(SubStr(cMens1,I,254)) +CRLF
			NOACENTO(cMensAlt1)
			I += 254
		Else
			LRT := .T.
		EndIf
		
		If !Empty(AllTrim(SubStr(cMens2,I2,254)))
			cMensAlt2 := cMensAlt2 + AllTrim(SubStr(cMens2,I2,254)) +CRLF
			NOACENTO(cMensAlt2)
			I2 += 254
		Else
			LRT2 := .T.
		EndIf
	EndDo

	SF1->( RecLock( "SF1" , .F. ) )
		SF1->F1_I_MENSA	:= Upper( cMensAlt1 )
		SF1->F1_I_MENFI	:= Upper( cMensAlt2 )
		SF1->F1_I_PLACA	:= _cPlaca
		SF1->F1_I_NTRAN	:= _cDescMotor
		SF1->F1_I_VEICU	:= _cVeiculo
		SF1->F1_I_MOTOR	:= _cMotorista
	SF1->( MSUnLock() )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: buscaDA3
Autor-------------: Fabiano Dias
Data da Criacao---: 01/11/2010
Descrição---------: Busca dados para a tela de Transporte mediante seleção via F3
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function buscaDA3

DBSelectArea("DA3")
DA3->( DBSetOrder(1) )
If DA3->( DBSeek( xFilial("DA3") + _cVeiculo ) )
	_cDescVeic	:= AllTrim(DA3->DA3_DESC)
	_cPlaca		:= DA3->DA3_PLACA
	
	If !Empty( DA3->DA3_MOTORI )
		DBSelectArea("DA4")
		DA4->( DBSetOrder(1) )
		If DA4->( DBSeek( xFilial("DA4") + DA3->DA3_MOTORI ) )
			_cMotorista	:= DA4->DA4_COD
			_cDescMotor	:= AllTrim( DA4->DA4_NOME )
		EndIf
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: PrepSair
Autor-------------: Tiago Correa Castro
Data da Criacao---: 21/02/2013
Descrição---------: Tratativas para os botões da tela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrepSair( cSair )

If cSair == "1"
	Close( _oDlg )
	_lRet := .T.
Else
	_oDlg:END()
	_lRet := .F.
EndIf

Return( _lRet )
