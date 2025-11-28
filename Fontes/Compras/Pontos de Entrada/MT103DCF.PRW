/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/07/2018| Chamado 25362. Alterado nome da função TABSPED para ICompFis.
Lucas Borges  |23/01/2019| Chamado 27807. Padronização dos campos de placa.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RWMake.ch"

/*
===============================================================================================================================
Programa----------: MT103DCF
Autor-------------: Erich Buttner
Data da Criacao---: 20/02/2013
===============================================================================================================================
Descrição---------: Habilita botão Mais Inf. e acrescenta campos na aba DANFE do Documento de Entrada
					Ponto de entrada utilizado para habilitar o botão Mais Informações e incluir campos na aba Informações 
					DANFE da rotina documento de entrada.
					Localização: Função A103CompDanfe.
					Em que Ponto: Ao clicar no botão Mais Inf.
Parametros--------: ParamIXB[1] -> L -> informando se a operação é de Inclusão
					ParamIXB[2] -> L -> informando se a operação é de Alteração
					ParamIXB[3] -> L -> informando se a operação é de Visualização
					ParamIXB[4] -> A -> array contendo os campos e seus conteúdos que já tenham sido informados na mesma rotina 
					(ao clicar no botão Mais Inf., informar os conteúdos dos campos, sair, e clicar novamente, devem ser 
					apresentados os mesmos conteúdos)
Retorno-----------: aCamposRet -> A -> 	Elemento 1: Código do campo
										Elemento 2: Conteúdo do campo
===============================================================================================================================
*/
User Function MT103DCF

//====================================================================================================
// Variaveis cMens1 e cMens2 declaradas como públicas no ponto de entrada MT103MEM - foi necessário
// fazer esta declaração das variáveis para trazer carregados os conteúdos para tratamento
//====================================================================================================
Local _lVisual		:= ParamIXB[3]
Local _oMemo01		:= Nil
Local _oMemo02		:= Nil

Private _oDlg			:= Nil
Private _oDescMotor		:= Nil
Private _oDescVeic		:= Nil
Private _oMotorista		:= Nil
Private _oPlaca			:= Nil
Private _oVeiculo		:= Nil

Private cDoc			:= cNFiscal
Private cSerNf			:= cSerie
Private cCliFor			:= cA100For
Private cLoj			:= cLoja
Private cNome			:= ''
Private cEmissao		:= dDEmissao

If cTipo $ 'D/B'
	cNome := SA1->A1_NOME
Else
	cNome := SA2->A2_NOME
EndIf

If _lVisual
	
	If cFormul = 'S'
		_cPlaca		:= SF1->F1_I_PLACA
		_cDescMotor	:= SF1->F1_I_NTRAN
		_cVeiculo	:= SF1->F1_I_VEICU
		_cMotorista	:= SF1->F1_I_MOTOR
	EndIf
	
	cMens1		:= SF1->F1_I_MENSA
	cMens2		:= SF1->F1_I_MENFI
	cMensAlt1	:= SF1->F1_I_MENSA
	cMensAlt2	:= SF1->F1_I_MENFI
	
EndIf

//====================================================================================================
// Validações do usuário
//====================================================================================================
DEFINE FONT oFont NAME "Tahoma" BOLD

@ 0,0 TO 310,500 DIALOG _oDlg TITLE "Mensagem Para Nota Fiscal"

	oTPanel1 := TPanel():New( 0 , 0 , "" , _oDlg , NIL , .T. , .F. , NIL , NIL , 310 , 160 , .T. , .F. )
	
	@005,010 Say "Mensagem NF"				  			Of oTPanel1 Pixel FONT oFont
	@020,010 Say "NF/Serie....: "+ cDoc +"/"+ cSerNf	Of oTPanel1 Pixel
	@020,100 Say "Emissao.....: "+ DToC(cEmissao)		Of oTPanel1 Pixel
	@020,160 Say "Tipo........: Entrada"		 		Of oTPanel1 Pixel
	@030,010 Say cCliFor +"-"+ cLoj +"-"+ cNome	 		Of oTPanel1 Pixel
	
	oTFolder1 := TFolder():New( 050 , 005 , U_TRANSPVLD() ,, oTPanel1 ,,,, .T. ,, 240 , 090 )
	
	@005,005 GET _oMemo01 VAR cMens1 MEMO SIZE 230,060 WHEN .T. OF oTFolder1:aDialogs[1] PIXEL
	@005,005 GET _oMemo02 VAR cMens2 MEMO SIZE 230,060 WHEN .T. OF oTFolder1:aDialogs[2] PIXEL

	If cFormul = 'S'
	
		@010,005 Say	'Veiculo:'							OF oTFolder1:aDialogs[3] PIXEL 
		@005,035 MSGET	_oVeiculo		VAR _cVeiculo		OF oTFolder1:aDialogs[3] PIXEL SIZE 046,010 COLORS 0,12632256 F3 "DA3" VALID(IIf(!Empty(_cVeiculo),IIf(EXISTCPO("DA3",_cVeiculo,1),buscaDA3(),_oVeiculo:SETFOCUS()),Eval({|| _cDescVeic:="",_cPlaca:="",.T.})))
		@005,086 MSGET	_oDescVeic		VAR _cDescVeic		OF oTFolder1:aDialogs[3] PIXEL SIZE 150,010 COLORS 0,12632256
		@035,005 Say	'Placa...:'							OF oTFolder1:aDialogs[3] PIXEL
		@030,035 GET	_oPlaca			VAR _cPlaca			OF oTFolder1:aDialogs[3] PIXEL SIZE 046,010 WHEN .T. PICTURE GetSx3Cache("F1_PLACA","X3_PICTURE")
		@060,005 Say	'Motorista:'						OF oTFolder1:aDialogs[3] PIXEL
		@055,035 MSGET	_oMotorista		VAR _cMotorista		OF oTFolder1:aDialogs[3] PIXEL SIZE 046,010 COLORS 0,12632256 F3 "DA4" VALID(IIf(!Empty(_cMotorista),IIf(EXISTCPO("DA4",_cMotorista,1),_cDescMotor:=Posicione("DA4",1,xFilial("DA4") + _cMotorista,"DA4_NOME"),_oMotorista:SETFOCUS()),Eval({|| _cDescMotor:="",.T.})))
		@055,086 MSGET	_oDescMotor		VAR _cDescMotor		OF oTFolder1:aDialogs[3] PIXEL SIZE 150,010 COLORS 0,12632256
		
		_oDescVeic:Disable()
		_oPlaca:Disable()
		_oDescMotor:Disable()
		
	EndIf
	
	TButton():New( 145 , 010 , 'Confirma' , oTPanel1 , {|| _oDlg:END() } , 70 , 10 ,,,, .T. )
	TButton():New( 145 , 080 , 'Cancela'  , oTPanel1 , {|| _oDlg:END() } , 70 , 10 ,,,, .T. )

ACTIVATE MSDIALOG _oDlg Centered

aCamposRet := {}

If !_lVisual
	
	cMensAlt1 := ''
	cMensAlt2 := ''
	
	LRET	:= .F.
	LRET2	:= .F.
	I		:= 1
	I2		:= 1
	
	While !( LRET ) .Or. !( LRET2 )
		
		If !Empty( AllTrim( SubStr( cMens1 , I , 254 ) ) )
			cMensAlt1 := cMensAlt1 + AllTrim( SubStr( cMens1 , I , 254 ) ) +CRLF
			cMensAlt1 := NOACENTO( cMensAlt1 )
			I += 254
		Else
			LRET := .T.
		EndIf
		
		If !Empty( AllTrim( SubStr( cMens2 , I2 , 254 ) ) )
			cMensAlt2 := cMensAlt2 + AllTrim( SubStr( cMens2 , I2 , 254 ) ) +CRLF
			cMensAlt2 := NOACENTO( cMensAlt2 )
			I2 += 254
		Else
			LRET2 := .T.
		EndIf
		
	EndDo
	
	aCamposRet := {}
	aCamposRet := {	{ "F1_I_MENSA" , Upper(cMensAlt1) } ,;
					{ "F1_I_MENFI" , Upper(cMensAlt2) } ,;
					{ "F1_I_PLACA" , _cPlaca          } ,;
					{ "F1_I_NTRAN" , _cDescMotor      } ,;
					{ "F1_I_VEICU" , _cVeiculo        } ,;
					{ "F1_I_MOTOR" , _cMotorista      }  }
	
EndIf

Return( aCamposRet )

/*
===============================================================================================================================
Programa----------: TRANSPVLD
Autor-------------: Erich Buttner
Data da Criacao---: 21/02/2013
Descrição---------: Criação de Aba de Transpote quando o Formulario Proprio igual a "SIM"
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function TRANSPVLD()

Private aAbas := {}

If cFormul = 'S'
	aAbas := { 'Mensg. Cliente' , 'Mensg. Fisco' , 'Transportes' }
Else
	aAbas := { 'Mensg. Cliente' , 'Mensg. Fisco' }
EndIf

Return( aAbas )

/*
===============================================================================================================================
Programa----------: BuscaDA3
Autor-------------: Erich Buttner
Data da Criacao---: 21/02/2013
Descrição---------: Realiza a busca dos dados para a tela de Transporte via F3
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function BuscaDA3()

DBSelectArea("DA3")
DA3->( DBSetOrder(1) )
If DA3->( DBSeek( xFilial("DA3") + _cVeiculo ) )
	
	_cDescVeic	:= AllTrim( DA3->DA3_DESC )
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
