/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |13/02/2020| Chamado 31083. Correção no processo de baixa por natureza
Alex Wallauer |29/10/2020| Chamado 34262. Remoção de bugs apontados pelo Totvs CodeAnalysis.
Antonio Neves |24/01/2024| Verifica se a tabela TRB existe antes de fechar (336)
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TopConn.ch"

/*
================================================================================================================================
Programa----------: AFIN013
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Funcao para criacao de MarkBrowse e SigaAuto de Baixa de Contas a Receber.
                    Usado para fazer as baixas dos descontos nos titulos, cada desconto eh baixado normalmente, porem utilizando
                    um Motivo de Baixa que nao movimenta banco, alem disso, cada desconto eh identificado pela natureza.
		            Se o titulo estiver em bordero, a rotina o retirara do bordero, fara a baixa do desconto e em seguida o
                    retornara para o bordero novamente.   
Parametros--------: Nenhum
Retorno-----------: Nenhum
================================================================================================================================
*/
User Function AFIN013()

Local aLegMbrw    := {}

Private cMarkado  := GetMark()
Private lInverte  := .F.
Private cPerg     := "AFIN013"
Private cCadastro := "Baixa de desconto nos Titulos"
Private bProcessa := {|| AFIN013H()}
Private bLegenda  := {|| AFIN013L()}
Private aCampos   := {}
Private aRotina   := {}
Private cCodBco   := ""
Private cCodAge   := ""
Private cCodCta   := ""

//===============================================================
// Atribuicao de Valores no aRotina.    
//===============================================================
aAdd(aRotina,{"Pesquisar"  ,"AxPesqui"       ,0,1})
aAdd(aRotina,{"Visualizar" ,"AxVisual"       ,0,2})
aAdd(aRotina,{"Bx. Descto" ,'Eval(bProcessa)',0,4})
aAdd(aRotina,{"Lengenda"   ,'Eval(bLegenda)' ,0,2})

aAdd(aLegMbrw,{"E1_SALDO==E1_VALOR .And. E1_SALDO>0" ,"BR_VERDE"   })//Titulo em Aberto
aAdd(aLegMbrw,{"E1_SALDO<>E1_VALOR .And. E1_SALDO<=0","BR_VERMELHO"})//Titulo Totalmente baixado
aAdd(aLegMbrw,{"E1_SALDO<>E1_VALOR .And. E1_SALDO>0" ,"BR_AZUL"    })//Titulo parcialmente baixado

DBSelectArea("SE1")
DBSetOrder(1)
mBrowse( 6,1,22,75,"SE1",,"E1_SALDO<=0",,,,aLegMbrw)

Return

/*
===============================================================================================================================
Programa----------: AFIN013H
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Funcao para processamento dos titulos marcados.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013H()

Local lOk := .F.   //Controle de falhas

Local oPanel
Local oDlg1
Local oQtda
Local oValor
Local nHeight    := 0
Local nWidth     := 0
Local nOpca      := 0
Local aSize      := {}
Local aBotoes    := {}
Local aCoors     := {}
Local aColors    := {}

Private oMark
Private oBrowse
Private nValor  := 0
Private nQtdTit := 0

//===================================================================================================
// Declara as variaveis padroes do sistema, para compatibilizacao na chamada da funcao FA070Tit() 
//===================================================================================================

Private oFontLbl ; DEFINE FONT oFontLbl NAME "Arial" SIZE 6, 15 BOLD
Private nTotAGer   := 0
Private nTotADesc  := 0
Private nTotAMul   := 0
Private nTotAJur   := 0
Private nTotADesp  := 0
Private cLoteFin   := Space (4 )
Private cMarca     := GetMark()
Private cOld       := cCadastro
Private aCampos    := {}
Private cLote      := ""
Private aCaixaFin  := xCxFina()
Private lF070Auto  := .F.
Private lValidou   := .F.
Private aautocab	  := {}

//===================================================================================================
// Variaveis de restauracao do ambiente. 
//===================================================================================================
Private nRecTRB := 0
Private nRecSE1 := 0

Private lFini055 := IsInCallStack("FINI055") //Guilherme - 19/12/2012 - Chamado Totvs TGIJRJ 

Private aCols:= {} //Talita Teixeira - 22/08/14 - Declarada a variavel aCols devido a um erro na chamada da função padrão. Chamado Totvs: TQHUOI. Chamado: 6964

//===================================================================================================
// Botoes da tela.                       
//===================================================================================================
aAdd( aBotoes, {"PESQUISA",{||AFIN013P(oMark,"TRB")},"Pesquisar..(CTRL-P)","Pesquisar" })
aAdd( aBotoes, {"S4WB005N",{||AFIN013V()           },"Visualizar..."      ,"Visualizar"})

//===================================================================================================
// Cores da MsSelect.                    
//===================================================================================================
aAdd( aColors, {"TRB_SALDO==TRB_VALOR .And. TRB_SALDO>0" ,"BR_VERDE"   })//Titulo em Aberto
aAdd( aColors, {"TRB_SALDO<>TRB_VALOR .And. TRB_SALDO>0" ,"BR_AZUL"   })//Titulo parcialmente baixado

//===================================================================================================
// Faz o calculo automatico de dimensoes de objetos     
//===================================================================================================
aSize := MSADVSIZE()

//===============================================================
// Chama a tela de parametros.                                           
//===============================================================
If !Pergunte(cPerg,.T.)
	Return
EndIf

//===============================================================
// Armazena banco, agencia e conta para que o mesmo seja sugerido na tela de baixas. 
//===============================================================
cCodBco := MV_PAR01
cCodAge := MV_PAR02
cCodCta := MV_PAR03

//===============================================================
// Cria o arquivo Temporario para insercao dos dados selecionados. 
//===============================================================
MsgRun("Aguarde.... Criando arquivo temporario...",,{|| AFIN013C(), CursorArrow()})

//===============================================================
// Cria a tela para selecao dos titulos.                             
//===============================================================
DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Desconto por Natureza") From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL

oPanel       := TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )

@ 0.8 ,00.8 Say OemToAnsi("Valor Total:") OF oPanel
@ 0.8 ,0007 Say oValor VAR nValor Picture "@E 999,999,999.99" SIZE 60,8 OF oPanel
@ 0.8 ,0021 Say OemToAnsi("Quantidade:") OF oPanel
@ 0.8 ,0032 Say oQtda VAR nQtdTit Picture "@E 99999" SIZE 50,8 OF oPanel

If FlatMode()

	aCoors := GetScreenRes()
	nHeight	:= aCoors[2]
	nWidth	:= aCoors[1]

Else

	nHeight	:= 143
	nWidth	:= 315

EndIf

DBSelectArea("TRB")
TRB->(DBGoTop())

oMark := MsSelect():New("TRB","TRB_OK","TRB_SALDO<=0",aCampos,@lInverte,@cMarkado,{35,1,nHeight,nWidth},,,,,aColors)
oMark:bMark := {|| AFIN013I(cMarkado,lInverte,oValor,oQtda)}
oMark:oBrowse:bAllMark := { || AFIN013A(cMarkado,oValor,oQtda) }

ACTIVATE MSDIALOG oDlg1 ON INIT (EnchoiceBar(oDlg1,{|| nOpca := 1,oDlg1:End()},{|| nOpca := 2,oDlg1:End()},,aBotoes),oPanel:Align := CONTROL_ALIGN_TOP,oMark:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT,oMark:oBrowse:Refresh())

If nOpca == 1

	DBSelectArea("TRB")
	TRB->(DBGoTop())
    _bPergunte := {|| Pergunte("FIN070",.F.) }	

	While TRB->(!Eof())
		
		If IsMark("TRB_OK",cMarkado)
			
			DBSelectArea("SE1")
			DBSetOrder(1)

			If DBSeek(xFilial("SE1")+TRB->TRB_PREFIX+TRB->TRB_NUM+TRB->TRB_PARCEL+TRB->TRB_TIPO)
				
				//===============================================================
				// Inicia o controle de transacao.
				//===============================================================
				Begin Transaction
				
				//===============================================================
				// Salva a area dos arquivos.    
				//===============================================================
				nRecSE1 := SE1->(Recno())
				nRecTRB := TRB->(Recno())
				
				//===============================================================
				// Restaura a area dos arquivos. 
				//===============================================================
				DBSelectArea("SE1")
				DBGoTo(nRecSE1)
				
				DBSelectArea("TRB")
				DBGoTo(nRecTRB)
				
				//===============================================================
				// Verifica se o titulo esta em bordero.             
				//===============================================================
				If !Empty(AllTrim(SE1->E1_NUMBOR))

					MsgRun("Aguarde.... Cancelando bordero...",,{|| AFIN013B()})

				EndIf

				//===============================================================
				// Chama tela para digitacao dos descontos por natureza.   
				//===============================================================			
				lOk := AFIN013N()

				//===============================================================
				// Restaura a area dos arquivos. 
				//===============================================================
				DBSelectArea("SE1")
				DBGoTo(nRecSE1)
				
				DBSelectArea("TRB")
				DBGoTo(nRecTRB)
				
				//=======================================================================================
				// Busca parametros da rotina do financeiro, para funcionamento correto da FA070Tit(). 
				//=======================================================================================
				EVAL(_bPergunte)//Pergunte("FIN070",.F.)

				//=======================================================================================
				// Chama a tela de baixas padrao do sistema, ja com os dados do banco preenchido. 
				//=======================================================================================
				cBanco 	 := cCodBco
				cAgencia := cCodAge
				cConta	 := cCodCta
                nIss	 := 0

				If lOk .And. SE1->E1_SALDO > 0

				   MsgRun("Aguarde.... Baixando titulo principal...",,{|| FA070Tit("SE1",0,SE1->(Recno())) })

				EndIf
				
				If !lOk
					DisarmTransaction()
				EndIf
				End Transaction
			EndIf
		EndIf

		TRB->(DBSkip())

	EndDo
	DBSelectArea("TRB")
	DBCloseArea()
Else
	If Select("TRB") > 0
		TRB->(DBCloseArea())
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: AFIN013P
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Funcao para processamento dos titulos marcados.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013P(oMark,cAlias)

Local oGet1
Local oDlg
Local cGet1	     := Space(17)
Local cComboBx1  := ""
Local aComboBx1	 := {"Prefixo+Numero+Parcela+Tipo","Cliente+Loja+Prefixo+Titulo","Nome Cliente","Valor do Titulo"}
Local nOpca      := 0
Local nI         := 0

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL

@ 004,003 ComboBox cComboBx1 Items aComboBx1 Size 213,010 PIXEL OF oDlg
@ 020,003 MsGet oGet1 Var cGet1 Size 212,009 COLOR CLR_BLACK Picture "@!" PIXEL OF oDlg

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION (nOpca:=1,oDlg:End()) OF oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION (nOpca:=0,oDlg:End()) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1

	For nI := 1 To Len(aComboBx1)

		If cComboBx1 == aComboBx1[nI]

			If nI == 4

				DBSelectArea("TRB")
				TRB->(DBSetOrder(nI))
				MsSeek(Val(cGet1),.T.)
				oMark:oBrowse:Refresh(.T.)

			Else

				DBSelectArea("TRB")
				TRB->(DBSetOrder(nI))
				MsSeek(cGet1,.T.)
				oMark:oBrowse:Refresh(.T.)

			EndIf

		EndIf

	Next nI

EndIf

Return

/*
===============================================================================================================================
Programa----------: AFIN013V
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Funcao para Visualizacao no arquivo temporario.   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013V()

Local 	aArea 		:= FWGetArea()
Private cCadastro 	:= OemToAnsi( "Visualizar" )

DBSelectArea("SE1")
DBSetOrder(1)

If DBSeek(  xFilial("SE1") + TRB->TRB_PREFIX + TRB->TRB_NUM + TRB->TRB_PARCEL + TRB->TRB_TIPO )

	AxVisual( "SE1", SE1->( Recno() ), 2 )

EndIf

FWRestArea( aArea )
Return

/*
===============================================================================================================================
Programa----------: AFIN013I 
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Rotina para inverter a marcacao do registro posicionado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013I(cMarca,lInverte,oValor,oQtda)

Local lMarcado := IsMark("TRB_OK",cMarca,lInverte)

If lMarcado

	nValor += TRB->TRB_SALDO
	nQtdTit++

Else

	nValor -= TRB->TRB_SALDO
	nQtdTit--

EndIf

oValor:Refresh()
oQtda:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AFIN013A
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013A(cMarca,oValor,oQtda)

Local nReg     := TRB->(Recno())
Local lMarcado := .F.

DBSelectArea("TRB")
DBGoTop()

While TRB->(!Eof())
	
	lMarcado := IsMark("TRB_OK", cMarca, lInverte)

	If lMarcado .Or. lInverte

		RecLock("TRB", .F.)
		TRB->TRB_OK := Space(2)
		MSUnLock()
		nQtdTit--
		nValor -= TRB->TRB_SALDO

	Else

		RecLock("TRB", .F.)
		TRB->TRB_OK := cMarca
		MSUnLock()
		nQtdTit++
		nValor += TRB->TRB_SALDO

	EndIf
	
	nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)
	nValor := IIf(nValor<0 ,0,nValor)
	
	TRB->(DBSkip())

EndDo

TRB->(DBGoTo(nReg))

oValor:Refresh()
oQtda:Refresh()
oMark:oBrowse:Refresh(.T.)

Return
/*
===============================================================================================================================
Programa----------: AFIN013C
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Funcao para criacao do arquivo temporario. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013C()

Local aEstru := {}
Local cQuery := ""

//=======================================================================================
// Armazena no array aEstru a estrutura dos campos da tabela.      
//=======================================================================================
aAdd(aEstru,{"TRB_OK"      ,'C',02,0})
aAdd(aEstru,{"TRB_PREFIX"  ,'C',03,0})
aAdd(aEstru,{"TRB_NUM"     ,'C',09,0})
aAdd(aEstru,{"TRB_PARCEL"  ,'C',02,0})
aAdd(aEstru,{"TRB_TIPO"    ,'C',03,0})
aAdd(aEstru,{"TRB_NATURE"  ,'C',10,0})
aAdd(aEstru,{"TRB_CLIENT"  ,'C',06,0})
aAdd(aEstru,{"TRB_LOJA"    ,'C',04,0})
aAdd(aEstru,{"TRB_NOMCLI"  ,'C',20,0})
aAdd(aEstru,{"TRB_EMISSA"  ,'D',08,0})
aAdd(aEstru,{"TRB_VENCTO"  ,'D',08,0})
aAdd(aEstru,{"TRB_VENCRE"  ,'D',08,0})
aAdd(aEstru,{"TRB_VALOR"   ,'N',14,2})
aAdd(aEstru,{"TRB_SALDO"   ,'N',14,2})

//=======================================================================================
// Armazena no array aCampos o nome, picture e descricao dos campos. 
//=======================================================================================
aAdd( aCampos ,{"TRB_OK"      ,""," "          ," "})
aAdd( aCampos ,{"TRB_PREFIX"  ,"","Prefixo"    ,PesqPict("SE1","E1_PREFIXO")})
aAdd( aCampos ,{"TRB_NUM"     ,"","Numero"     ,PesqPict("SE1","E1_NUM")})
aAdd( aCampos ,{"TRB_PARCEL"  ,"","Parcela"    ,PesqPict("SE1","E1_PARCELA")})
aAdd( aCampos ,{"TRB_TIPO"    ,"","Tipo"       ,PesqPict("SE1","E1_TIPO")})
aAdd( aCampos ,{"TRB_NATURE"  ,"","Natureza"   ,PesqPict("SE1","E1_NATUREZ")})
aAdd( aCampos ,{"TRB_CLIENT"  ,"","Cliente"    ,PesqPict("SE1","E1_CLIENTE")})
aAdd( aCampos ,{"TRB_LOJA"    ,"","Loja"       ,PesqPict("SE1","E1_LOJA")})
aAdd( aCampos ,{"TRB_NOMCLI"  ,"","Nome"       ,PesqPict("SE1","E1_NOMCLI")})
aAdd( aCampos ,{"TRB_EMISSA"  ,"","Emissao"    ,PesqPict("SE1","E1_EMISSAO")})
aAdd( aCampos ,{"TRB_VENCTO"  ,"","Vencto"     ,PesqPict("SE1","E1_VENCTO")})
aAdd( aCampos ,{"TRB_VENCRE"  ,"","Vencto Real",PesqPict("SE1","E1_VENCREA")})
aAdd( aCampos ,{"TRB_VALOR"   ,"","Valor"      ,PesqPict("SE1","E1_VALOR",14,2)})
aAdd( aCampos ,{"TRB_SALDO"   ,"","Saldo"      ,PesqPict("SE1","E1_SALDO",14,2)})

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRB") > 0
	TRB->( DBCloseArea() )
EndIf

//================================================================================
// Permite o uso do arquivo criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( "TRB", aEstru )

_otemp:AddIndex( "01",{"TRB_PREFIX","TRB_NUM","TRB_PARCEL","TRB_TIPO"} )
_otemp:AddIndex( "02",{"TRB_NOMCLI"} )
_otemp:AddIndex( "03",{"TRB_VALOR"} )

_otemp:Create()


//=======================================================================================
// Query para selecao dos dados.                                   
//=======================================================================================
cQuery := "SELECT E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_NATUREZ,E1_CLIENTE,E1_LOJA,E1_NOMCLI,E1_EMISSAO,E1_VENCTO,E1_VENCREA,E1_VALOR,E1_SALDO"
cQuery += " FROM "+RetSqlName("SE1")
cQuery += " WHERE D_E_L_E_T_ = ' ' "
cQuery += " AND E1_FILIAL  = '"+xFilial("SE1")+"' "
cQuery += " AND E1_CLIENTE BETWEEN '"+MV_PAR04+"' AND '"+MV_PAR05+"'"
cQuery += " AND E1_LOJA    BETWEEN '"+MV_PAR06+"' AND '"+MV_PAR07+"'"
cQuery += " AND E1_PREFIXO BETWEEN '"+MV_PAR08+"' AND '"+MV_PAR09+"'"
cQuery += " AND E1_TIPO    BETWEEN '"+MV_PAR10+"' AND '"+MV_PAR11+"'"
cQuery += " AND E1_EMISSAO BETWEEN '"+DToS(MV_PAR12)+"' AND '"+DToS(MV_PAR13)+"'"
cQuery += " AND E1_VENCTO  BETWEEN '"+DToS(MV_PAR14)+"' AND '"+DToS(MV_PAR15)+"'"
cQuery += " AND E1_NUMBOR  BETWEEN '"+MV_PAR16+"' AND '"+MV_PAR17+"'"
cQuery += " AND E1_SALDO <> 0"

TCQUERY cQuery NEW ALIAS "FIN"

DBSelectArea("FIN")
FIN->(DBGoTop())

While FIN->(!Eof())
	
	TRB->(DbAppend())
	
	TRB->TRB_PREFIX  := FIN->E1_PREFIXO
	TRB->TRB_NUM     := FIN->E1_NUM
	TRB->TRB_PARCEL  := FIN->E1_PARCELA
	TRB->TRB_TIPO    := FIN->E1_TIPO
	TRB->TRB_NATURE  := FIN->E1_NATUREZ
	TRB->TRB_CLIENT  := FIN->E1_CLIENTE
	TRB->TRB_LOJA    := FIN->E1_LOJA
	TRB->TRB_NOMCLI  := FIN->E1_NOMCLI
	TRB->TRB_EMISSA  := SToD(FIN->E1_EMISSAO)
	TRB->TRB_VENCTO  := SToD(FIN->E1_VENCTO)
	TRB->TRB_VENCRE  := SToD(FIN->E1_VENCREA)
	TRB->TRB_VALOR   := FIN->E1_VALOR
	TRB->TRB_SALDO   := FIN->E1_SALDO
	
	FIN->(DBSkip())

EndDo

DBSelectArea("FIN")
DBCloseArea()

Return

/*
===============================================================================================================================
Programa----------: AFIN013B
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Rotina para permitir cancelar o Bordero de Contas a receber
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013B()

DBSelectArea("SE1")
DBGoTo(nRecSE1)

DBSelectArea("SEA")
DBSetOrder(2)//EA_FILIAL+EA_NUMBOR+EA_CART+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA
DBSeek(xFilial("SEA")+SE1->E1_NUMBOR+"R"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)

If xFilial("SEA")+SE1->E1_NUMBOR+"R"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO ==;
	SEA->(EA_FILIAL+EA_NUMBOR+EA_CART+EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO)
	
	If SE1->E1_SALDO > 0 .And. !Empty(SE1->E1_NUMBOR)
		
		RecLock("SE1",.F.)
		SE1->E1_NUMBOR  := Space(6)
		SE1->E1_DATABOR := CTOD("//")
		SE1->E1_PORTADO := ""
		SE1->E1_AGEDEP  := ""
		SE1->E1_CONTA   := ""
		SE1->E1_SITUACA := "0"
		MSUnLock()
		
		RecLock("SEA",.F.)
		dbDelete()
		MSUnLock()

	EndIf

EndIf


Return

/*
===============================================================================================================================
Programa----------: AFIN013L
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Rotina para mostrar as cores da legenda.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013L()

Local aLegenda := {{"ENABLE","Titulo em Aberto"},;
{"DISABLE","Titulo Totalmente Baixado"},;
{"BR_AZUL","Titulo Parcialmente Baixado"}}

BrwLegenda("Lengenda","Itens",aLegenda)

Return

/*
===============================================================================================================================
Programa----------: AFIN013N
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Tela para informar o valor de desconto para cada natureza. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013N()

//=======================================================================================
// Declaracao das variaveis Locais. 
//=======================================================================================
Local oMainWnd
Local oGetDados
Local oFontLbl
Local oGrp1
Local oGrp2
Local oPanel1
Local oPanel2
Local oTipo
Local oCodCli
Local oNaturez
Local oValorLiq
Local oDescont
Local oMulta
Local oJuros

Local nTotAbat  := 0
Local nTotAbLiq := 0
Local nTotAbImp := 0
Local nValorLiq := 0
Local nParciais := 0
Local nDescont  := 0
Local nMulta    := 0
Local nJuros    := 0
Local nOpc1     := 0
Local nI        := 0
Local lRet      := .T.

//=======================================================================================
// Declaracao das variaveis Privadas de compatibilizacao com a rotina MsGetDados. 
//=======================================================================================
Private oValRec
Private oDlg
Private bVldCmp   := {|| AFIN013D()} //Bloco de execucao de validacao do campo
Private bVldLin   := {|| AFIN013E()} //Bloco de execucao de validacao da linha
//Private bVldDel   := {|| AFIN013F()} //Bloco de execucao de validacao da delecao da linha
Private nValRec   := 0
Private nOldValRec:=0
Private lRefresh  := .T.
Private aHeader   := {}
Private aCols     := {}
Private aRotina   := {{"Pesquisar" , "AxPesqui", 0, 1},;
{"Visualizar", "AxVisual", 0, 2},;
{"Incluir"   , "AxInclui", 0, 3},;
{"Alterar"   , "AxAltera", 0, 4}}

//=======================================================================================
// Criacao do aHeader( Colunas da tela ).
//=======================================================================================
aAdd(aHeader,{"Natureza" ,"ED_CODIGO ","@!"               ,10,0,"","","C","",""})
aAdd(aHeader,{"Historico","ED_DESCRIC","@S45"             ,40,0,"","","C","",""})
aAdd(aHeader,{"Valor"    ,"ED_PERCIRF","@E 999,999,999.99",14,2,"","","N","",""})

//=======================================================================================
// Inicializa o aCols com as Naturezas de Desconto. 
//=======================================================================================
DBSelectArea("SED")
DBSetOrder(1)
DBGoTop()

_cIT_NATCONT:=GetMv("IT_NATCONT")

While SED->(!Eof())
	
	If SED->ED_I_BAIXA == "S"

		//Cria uma linha em branco no aCols
		aAdd(aCols,Array(Len(aHeader)+1))
		
		//Preenche o aCols
		For nI := 1 To Len(aHeader)
			
			//Preenche a coluna para controle dos deletados
			aCols[Len(aCols),Len(aHeader)+1] := .F.
			
			If (aHeader[nI,2]) == "ED_PERCIRF"           

				aCols[Len(aCols),nI] := IIf(AllTrim(SED->ED_CODIGO) == _cIT_NATCONT,AFIN013K(SE1->E1_I_DESCO,AllTrim(_cIT_NATCONT),SE1->E1_NUM,SE1->E1_PREFIXO,SE1->E1_PARCELA,SE1->E1_CLIENTE,SE1->E1_LOJA),0)

			ElseIf (aHeader[nI,2]) == "ED_DESCRIC"

				aCols[Len(aCols),nI] := PadR(SED->&(aHeader[nI,2]),40)

			Else

				aCols[Len(aCols),nI] := SED->&(aHeader[nI,2])

			EndIf

		Next nI

	EndIf
	
	SED->(DBSkip())

EndDo

//=======================================================================================
// Restaura a area dos arquivos. 
//=======================================================================================
DBSelectArea("SE1")
DBGoTo(nRecSE1)

//=======================================================================================
// Calcula os abatimentos,juros,saldo, etc. 
//=======================================================================================
nTotAbat  := SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"S",dDataBase,@nTotAbImp) 
nTotAbLiq := nTotAbat - nTotAbImp
nValorLiq := (SE1->E1_VALOR - nTotAbLiq - nTotAbImp)
nParciais := (SE1->E1_VALOR - SE1->E1_SALDO)
nJuros    := 0  //processo de baixa nunca usar juros aqui
nValRec   := (nValorLiq + nJuros) - nParciais
nOldValRec:= nValRec

DBSelectArea("SA1")
DBSetOrder(1)
DBSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)

DEFINE FONT oFontLbl NAME "Arial" SIZE 6, 15 BOLD
DEFINE MSDIALOG oDlg FROM  69,33 TO 552,581 TITLE "Baixas por Natureza" PIXEL OF oMainWnd

oPanel1:= TPanel():New(0,0,'',oDlg,, .T., .T.,, ,45,45,.F.,.F. )

oPanel2:= TPanel():New(0,0,'',oDlg,, .T., .T.,, ,30,30,.F.,.F. )

@ 001,002 GROUP oGrp1 TO 043, 272 LABEL "Titulo"       OF oPanel1 PIXEL
@ 001,002 GROUP oGrp2 TO 085, 272 LABEL "Dados Gerais" OF oPanel2 PIXEL
oGrp1:oFont := oFontLbl
oGrp2:oFont := oFontLbl

//////////////////////////
//Dados do titulo
@ 008,004 Say "Prefixo"			            SIZE 31,07 OF oPanel1 PIXEL
@ 008,027 MSGET SE1->E1_PREFIXO	            SIZE 25,08 OF oPanel1 PIXEL When .F.
@ 008,060 Say "Numero" 			            SIZE 31,07 OF oPanel1 PIXEL
@ 008,085 MSGET SE1->E1_NUM		            SIZE 70,08 OF oPanel1 PIXEL When .F.
@ 008,165 Say "Parcela"			            SIZE 31,07 OF oPanel1 PIXEL
@ 008,188 MSGET SE1->E1_PARCELA	            SIZE 25,08 OF oPanel1 PIXEL When .F.
@ 008,220 Say "Tipo"			            SIZE 31,07 OF oPanel1 PIXEL
@ 008,238 MSGET oTipo VAR SE1->E1_TIPO	F3 "SE1RDO" SIZE 30,08 OF oPanel1 PIXEL HASBUTTON
oTipo:lReadOnly := .T.

@ 019,004 Say "Cliente"                              SIZE 022,07 OF oPanel1 PIXEL
@ 019,027 MSGET oCodCli VAR SE1->E1_CLIENTE F3 "SA1" SIZE 045,08 OF oPanel1 PIXEL HASBUTTON
@ 019,075 MSGET SA1->A1_LOJA                         SIZE 025,08 OF oPanel1 PIXEL When .F.
@ 019,105 MSGET SA1->A1_NOME                         SIZE 165,08 OF oPanel1 PIXEL When .F.
oCodCli:lReadOnly := .T.

@ 030,004 Say "Natureza" 				              SIZE 31,07 OF oPanel1 PIXEL
@ 030,027 MSGET oNaturez VAR SE1->E1_NATUREZ F3 "SED" SIZE 70,08 OF oPanel1 PIXEL HASBUTTON
oNaturez:lReadOnly := .T.

@ 030,105 Say "Emissao" 		 SIZE 31,07 OF oPanel1 PIXEL
@ 030,133 MSGET SE1->E1_EMISSAO	 SIZE 48,08 OF oPanel1 PIXEL When .F.
@ 030,189 Say "Vencto.Atual" 	 SIZE 49,07 OF oPanel1 PIXEL
@ 030,222 MSGET SE1->E1_VENCREA	 SIZE 48,08 OF oPanel1 PIXEL When .F.


//////////////////////////
//Dados da Baixa
nLinha := 10
@ nLinha,005 Say "Valor Original " SIZE 53,08 OF oPanel2 PIXEL COLOR CLR_HBLUE
@ nLinha,065 MSGET SE1->E1_VALOR   SIZE 66,08 OF oPanel2 PIXEL COLOR CLR_HBLUE When .F. Picture PesqPict("SE1","E1_VALOR")

@ nLinha,144 Say "- Decrescimo"    SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,204 MSGET SE1->E1_SDDECRE SIZE 66,08 OF oPanel2 PIXEL HASBUTTON Picture PesqPict( "SE1","E1_DECRESC" ) When .F.

nLinha +=12
@ nLinha,005 Say "- Abatimentos" SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,065 MSGET nTotAbLiq     SIZE 66,08 OF oPanel2 PIXEL When .F. Picture PesqPict( "SE1","E1_VALOR" )

@ nLinha,144 Say "+ Acrescimo"     SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,204 MSGET SE1->E1_SDACRES SIZE 66,08 OF oPanel2 PIXEL HASBUTTON Picture PesqPict( "SE1","E1_ACRESC" ) When .F.

nLinha +=12
@ nLinha,005 Say "- Impostos" SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,065 MSGET nTotAbImp  SIZE 66,08 OF oPanel2 PIXEL When .F. Picture PesqPict( "SE1","E1_VALOR" )

@ nLinha,144 Say "- Descontos"           SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,204 MSGET oDescont VAR nDescont SIZE 66,08 OF oPanel2 PIXEL HASBUTTON When .F. Picture PesqPict( "SE1","E1_DESCONT" )

nLinha +=12
@ nLinha,005 Say "Valor Liquido"           SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,065 MSGET oValorLiq VAR nValorLiq SIZE 66,08 OF oPanel2 PIXEL When .F. Picture PesqPict("SE1","E1_VLCRUZ")

@ nLinha,144 Say "+ Multa"           SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,204 MSGET oMulta VAR nMulta SIZE 66,08 OF oPanel2 PIXEL HASBUTTON When .F. Picture PesqPict( "SE1","E1_MULTA" )

nLinha +=12
@ nLinha,005 Say "- Pagtos Parciais" SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,065 MSGET nParciais         SIZE 66,08 OF oPanel2 PIXEL HASBUTTON When .F. Picture PesqPict( "SE1","E1_VALOR" )

@ nLinha,144 Say "+ Tx.Permanenc."   SIZE 53,07 OF oPanel2 PIXEL
@ nLinha,204 MSGET oJuros VAR nJuros SIZE 66,08 OF oPanel2 PIXEL HASBUTTON When .F. Picture PesqPict( "SE1","E1_JUROS" )

nLinha +=12
@ nLinha,144 Say "= Valor Recebido"    SIZE 53,07 OF oPanel2 PIXEL COLOR CLR_HBLUE
@ nLinha,204 MSGET oValRec VAR nValRec SIZE 66,08 OF oPanel2 PIXEL HASBUTTON COLOR CLR_HBLUE Picture PesqPict( "SE1","E1_VALOR" ) When .F.


oGetDados := MsGetDados():New(145,003,236,273,4,"Eval(bVldLin)", "AllWaysTrue",;
"", .T., {"ED_DESCRIC","ED_PERCIRF"}, , .F., 200, "Eval(bVldCmp)", "AllWaysTrue",,"U_AFIN013F()",oDlg)

ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{||(nOpc1 := 1,oDlg:End())},{||(nOpc1 := 0,oDlg:End())},,),oPanel1:Align := CONTROL_ALIGN_TOP,oPanel2:Align := CONTROL_ALIGN_ALLCLIENT) CENTERED

                                                                                                            
If nOpc1 == 1

	If Len(aCols) > 0

		For nI := 1 To Len(aCols)

			If !aCols[nI,Len(aHeader)+1] .And. aCols[nI][3] > 0 .And. lRet

			    MsgRun("Aguarde.... Baixando desconto...",,{|| lRet := AFIN013G(aCols[nI][1],aCols[nI][2],aCols[nI][3]) })

			EndIf

		Next nI

	EndIf

EndIf
U_ITLOGACS('AFIN013')

Return(lRet)

/*
===============================================================================================================================
Programa----------: AFIN013D 
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Validacao dos campos do aCols.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013D

Local nX      := 0
Local nTotNat := 0

If Type("M->ED_PERCIRF") <> "U"

	nValRec := nOldValRec
	
	For nX := 1 To Len(aCols)

		If nX == n .And. !Empty(AllTrim(aCols[nX][1])) .And. !aCols[nX,Len(aHeader)+1]

			nTotNat += M->ED_PERCIRF

		ElseIf !Empty(AllTrim(aCols[nX][1])) .And. !aCols[nX,Len(aHeader)+1]

			nTotNat += aCols[nX][3]

		EndIf

	Next nX
	
	If nTotNat > nValRec

		xMagHelpFis("Desconto Excedido",;
		"O valor total dos descontos("+AllTrim(Str(nTotNat))+") é maior que o saldo do titulo("+AllTrim(Str(nValRec))+").",;
		"Informe um valor de desconto menor.")
		Return(.F.)

	Else

	    nValRec -= nTotNat

	EndIf
	
	oValRec:Refresh()
	oDlg:Refresh()
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: AFIN013E
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Validacao da linha, verifica se nao tem campos em branco.Nao deixa criar uma nova linha.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AFIN013E

If Empty(AllTrim(aCols[n][1])) .And. !aCols[n,Len(aHeader)+1]

	U_ITMsg("Nao eh permitido criar linhas","Atenção",,1)
	Return(.F.)

EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: AFIN013F
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Validacao do aCols ao deletar a linha do mesmo. Recalcula o valor recebido.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN013F

Local nX := 0

nValRec := nOldValRec

For nX := 1 To Len(aCols)

	If !Empty(AllTrim(aCols[nX][1])) .And. !aCols[nX,Len(aHeader)+1]

		nValRec -= aCols[nX][3]

	EndIf

Next nX

oValRec:Refresh()
oDlg:Refresh()

Return(.T.)

/*
===============================================================================================================================
Programa----------: AFIN013G
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Rotina p/ executar o SigaAuto de baixa de Titulo a receber.
Parametros--------: ExpC01 - Codigo da Natureza.    
						ExpC02 - Historico do titulo. 
						ExpN03 - Valor da baixa. 
Retorno-----------: .T. se o SigaAuto executou de forma correta e .F. se executou de forma incorreta. 
===============================================================================================================================
*/
Static Function AFIN013G(cNatureza,cHistorico,nVlrTit)

Local aBaixa   := {}
Local cBanco   := Space(3)
Local cAgencia := Space(5)
Local cConta   := Space(10)
Local lRet     := .T.
Local cMotBx   := AllTrim(GETMV("IT_MOTBX"))//Desconto - nao utiliza banco
Local _ne5vljuros := 0
Local _ne5vlacres := 0
Local _ne1juros   := 0
Local _ne1vlacres := 0

Private lMsErroAuto:= .F.
Private lMsHelpAuto:= .T.

DBSelectArea("SE1")
DBGoTo(nRecSE1)

//Guarda campos que o execauto do fina070 atualiza indevidamente nesse momento
_ne5vljuros := SE5->E5_VLJUROS
_ne5vlacres := SE5->E5_VLACRES
_ne1juros   := SE1->E1_JUROS
_ne1vlacres := SE1->E1_SDACRES

nSldTot := SE1->E1_SALDO //Correção do Saldo para titulos que contem Juros

aBaixa := {{"E1_FILIAL",xFilial("SE1")  ,Nil},;
{"E1_PREFIXO"	 ,SE1->E1_PREFIXO       ,Nil},;
{"E1_NUM"		 ,SE1->E1_NUM         	,Nil},;
{"E1_PARCELA"	 ,SE1->E1_PARCELA       ,Nil},;
{"E1_TIPO"	     ,SE1->E1_TIPO          ,Nil},;
{"AUTBANCO"      ,cBanco          		,Nil},;
{"AUTAGENCIA"    ,cAgencia   			,Nil},;
{"AUTCONTA"      ,cConta         		,Nil},;
{"AUTMOTBX"	     ,cMotBx          		,Nil},;
{"AUTDTBAIXA"	 ,dDataBase        		,Nil},;
{"AUTDTCREDITO"  ,dDataBase        		,Nil},;
{"AUTDESCONT"    ,0     	      	    ,Nil},;
{"AUTMULTA"      ,0          		    ,Nil},;
{"AUTJUROS"      ,0                     ,Nil ,.T.},;//Foi passado o 4 parametro para considerar zero no juros
{"AUTHIST"	     ,cHistorico            ,Nil},;
{"AUTVALREC"	 ,nVlrTit               ,Nil}}

MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3)

If lMsErroAuto

	lRet := .F.
	Mostraerro()

Else

	nSldTot := nSldTot - nVlrTit //Saldo para titulos que contem Juros
	DBSelectArea("SE1")
	DBGoTo(nRecSE1)

	If nSldTot >= 0

		RecLock("SE1",.F.)
		SE1->E1_SALDO := nSldTot
		SE1->E1_SDACRES := _ne1vlacres
		SE1->(MSUnLock())	

	EndIf

	DBSelectArea("SE5")
	
	//===============================================================
	// Grava a Natureza de desconto no SE5. 
	//===============================================================
	If SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA) ==;
		SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA)
		
		RecLock("SE5",.F.)
		SE5->E5_NATUREZ := cNatureza
		SE5->E5_VLACRES := _ne5vlacres
		MSUnLock()

	EndIf

	DBSelectArea("SE5")
	DBSetOrder(2)
	
	If DBSeek(SE1->E1_FILIAL+"JR"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+DToS(dDataBase)+SE1->E1_CLIENTE+SE1->E1_LOJA)

		RecLock("SE5",.F.)
		DbDelete()
		SE5->(MSUnLock())

	EndIf

EndIf

//=======================================================================================
// Restaura a area dos arquivos e variaveis. 
//=======================================================================================
DBSelectArea("SE1")
DBGoTo(nRecSE1)

DBSelectArea("TRB")
DBGoTo(nRecTRB)

U_ITLOGACS('AFIN013')

Return(lRet)

/*
===============================================================================================================================
Programa----------: AFIN013K
Autor-------------: Fabiano Dias  
Data da Criacao---: 08/12/09
Descrição---------: Funcao para que quando For a natureza cadastrada no parametro (IT_NATCONT) para desconto contratual seja 
                    pego o valor de desconto contratual gerado na SE1 no campo SE1->E1_I_DESCO na baixa por natureza menos o 
                    valor gerado na funcao AFIN013K que traz todo o valor ja baixado do desconto contratual para o titulo 
                    em questao.
                    Usado para fazer as baixas dos descontos nos titulos	
Parametros--------: _nValorDesc - Valor desconto
					_cNatureza - Natureza
					_cNumTitulo - Numero do titulo
					_cPrefTit - prefixo do titulo
					_cParcTit - parcela do titulo
					_cCliente - cliente od titulo
					_cLojaCli - loja do cliente do titulo
Retorno-----------: Valor total ja baixado do titulo selecionado para baixa 
===============================================================================================================================
*/    
Static Function AFIN013K(_nValorDesc,_cNatureza,_cNumTitulo,_cPrefTit,_cParcTit,_cCliente,_cLojaCli)
                                        
Local _aAreaGeral:= FWGetArea()
Local _aArea	 := {}
Local _aAlias    := {}
Local _nVlrDesCon:= 0//Armazena o valor total que ja foi baixado do desconto contratual	

//===============================
//  Salva a area. 
//===============================
AFIN013J(1,@_aArea,@_aAlias,{"SED","SE1"})          

//Se tiver gerado desconto na SE1
If _nValorDesc > 0 

		_cQuery := "SELECT" 
		_cQuery += " COALESCE(SUM(E5_VALOR),0) VLRTOTBAIXA "
		_cQuery += "FROM " + RetSqlName("SE5")
		_cQuery += " WHERE"
		_cQuery += " D_E_L_E_T_  <> '*'  AND E5_FILIAL = '" + xFilial("SE5") + "'"
		_cQuery += " AND e5_naturez = '" + _cNatureza + "'"
		_cQuery += " AND e5_motbx = 'DCT'"
		_cQuery += " AND e5_numero = '" + _cNumTitulo + "'"
		_cQuery += " AND e5_prefixo = '" + _cPrefTit + "'"
		_cQuery += " AND e5_parcela = '" + _cParcTit + "'"
		_cQuery += " AND e5_cliente = '" + _cCliente+ "'"
		_cQuery += " AND e5_loja = '" + _cLojaCli + "'"  
		_cQuery += " AND e5_situaca <> 'C'" //Baixa nao cancelada
			
		If Select("TMP01CONT") > 0
	
			DBSelectArea("TMP01CONT")
			TMP01CONT->(DBCloseArea())
	
		EndIf
			
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"TMP01CONT",.T.,.T.)
			
		DBSelectArea("TMP01CONT")
		TMP01CONT->(DBGoTop())

		_nVlrDesCon:= TMP01CONT->VLRTOTBAIXA
		
		DBSelectArea("TMP01CONT")
		TMP01CONT->(DBCloseArea())
        
		
		//Pode haver um desconto maior que o desconto efetuado no titulo na SE1, para este caso sera retornado 0
		If _nValorDesc < _nVlrDesCon
		
			_nVlrDesCon:= 0     
		        
		Else
		        
		   _nVlrDesCon:= _nValorDesc - _nVlrDesCon      
				
		EndIf


EndIf		
		
//=======================================================================================
// Restaura a area. 
//=======================================================================================
AFIN013J(2,_aArea,_aAlias)                    

FWRestArea(_aAreaGeral)

Return _nVlrDesCon

/*
===============================================================================================================================
Programa----------: AFIN013J
Autor-------------: Wodson Reis
Data da Criacao---: 16/03/09
Descrição---------: Funcao para criacao das perguntas caso elas nao existam.
                    auxiliar no GetArea e ResArea retornando o ponteiro nos Aliases descritos na chamada da Funcao.   
Parametros--------: nTipo   = 1=GetArea / 2=FWRestArea
					_aArea  = Array passado por referencia que contera GetArea
					_aAlias = Array passado por referencia que contera  {Alias(), IndexOrd(), Recno()}  
					_aArqs  = Array com Aliases que se deseja Salvar o GetArea
Retorno-----------: 
===============================================================================================================================
*/
Static Function AFIN013J(_nTipo,_aArea,_aAlias,_aArqs)

Local _nN := 0

// Tipo 1 = FWGetArea()
If _nTipo == 1

	_aArea := FWGetArea()

	For _nN := 1 To Len(_aArqs)

		DBSelectArea(_aArqs[_nN])
		aAdd(_aAlias,{ _aArqs[_nN], IndexOrd(), Recno() })

	Next
// Tipo 2 = FWRestArea()
Else

	For _nN := 1 To Len(_aAlias)

		DBSelectArea(_aAlias[_nN,1])
		DBSetOrder(_aAlias[_nN,2])
		DBGoTo(_aAlias[_nN,3])

	Next

	FWRestArea(_aArea)

EndIf

Return
