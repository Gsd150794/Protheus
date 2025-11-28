/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 14/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 23/04/2021 | Chamado 36219. Corrigidos erros apresentado durante testes pelo fiscal. 
-------------------------------------------------------------------------------------------------------------------------------
Igor Fricks   | 12/05/2022 | Chamado 36219. Corrigidos erros apresentado durante testes pelo fiscal. 
-------------------------------------------------------------------------------------------------------------------------------
Igor Fricks   | 16/05/2022 | Chamado 37448. Adcionado a função copiar. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 13/06/2022 | Chamado 40456. Tratamento para o Novo Campo de Exceto Produto (ZZQ_PRODUT). 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 02/05/2022 | Chamado 43678. Criação e tratamento do novo botão " Excluir Títulos". 
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves | 20/12/2024 | Chamado 45908. Exclusão do Título de CP que não está tratado. 
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves | 26/01/2024 | Chamado 46172. Tratativa para considerar impedimento do cadastro NCM x MVA tambem o item de exceção.
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "TopConn.ch"
/*
===============================================================================================================================
Programa----------: AOMS059
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Cadastro de Regras NCM x MVA
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS059()
 
Private cAlias 		:= "ZZQ"
Private cCadastro 	:= "Cadastro de Regra NCM x MVA"
Private aRotina 	:= {}
Private cDelFunc 	:= ".T." // Validacao para a exclusao. Pode-se utilizar ExecBlock
_aItalac_F3:={}
_bSelectSB1:={ || "SELECT B1_COD , B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE B1_POSIPI = '"+aCOLS[n,GdFieldPos("ZZQ_NCM")]+"' AND D_E_L_E_T_ = ' ' ORDER BY B1_COD " }
aAdd(_aItalac_F3,{"M->ZZQ_PRODUT",_bSelectSB1,{|Tab| (Tab)->B1_COD }                , {|Tab| (Tab)->B1_DESC   }   ,          ,"Produtos",,,010       ,.F.        ,       , } )

aAdd( aRotina , { "Pesquisar"	   , "AxPesqui"  , 0 , 1 } )
aAdd( aRotina , { "Visualizar"	   , "U_ZZQMNT"  , 0 , 2 } )
aAdd( aRotina , { "Incluir"		   , "U_ZZQINC"  , 0 , 3 } )
aAdd( aRotina , { "Manutencao"	   , "U_ZZQMNT"  , 0 , 4 } )
aAdd( aRotina , { "Excluir Títulos", "U_AOMS59E" , 0 , 5 } )
aAdd( aRotina , { "Copiar"		   , "U_ZZQCPY"  , 0 , 3 } )

DBSelectArea(cAlias)
DBSetOrder(1)

MBrowse( ,,,, cAlias )

Return

/*
===============================================================================================================================
Programa----------: ZZQINC
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para inclusão de Regras - Utilizado no cálculo e geração dos títulos de ST Antecipados
===============================================================================================================================
Parametros--------: cAlias , nReg , nOpc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQINC( cAlias , nReg , nOpc )

Local oTPanel1	:= Nil

Private oDlg	:= Nil
Private oGet	:= Nil

Private cCodigo	:= Space(6) 
Private cLoja	:= Space(4)
Private cNome	:= Space(40) 

Private aHeader	:= {} 
Private aCols	:= {} 
Private aReg	:= {} 

//Log de utilização
U_ITLOGACS()

DBSelectArea( cAlias ) 
DBSetOrder(1)

ZZQHEADER(cAlias) 
ZZQCOLS( cAlias , nReg , nOpc )

DEFINE MSDIALOG oDlg TITLE cCadastro From 8,0 To 28,80 OF oMainWnd 
	
	oTPanel1 := TPanel():New(30,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,20,.T.,.F.) 
	
	@ 5, 006 Say "Cód. Cliente:" SIZE 70,7 PIXEL OF oTPanel1 
	@ 5, 080 Say "Loja:"         SIZE 70,7 PIXEL OF oTPanel1 
	@ 5, 140 Say "Nome:"         SIZE 70,7 PIXEL OF oTPanel1 
	
	@ 4, 038 MSGET cCodigo F3 "SA1_02" PICTURE "@!" VALID U_ZZQCLI() SIZE 32,7 PIXEL OF oTPanel1
	@ 4, 095 MSGET IIf(cCodigo <> ' ',cLoja,' ') PICTURE "@!" SIZE 30,7 PIXEL OF oTPanel1
	@ 4, 160 MSGET IIf(cCodigo <> ' ',cNome,' ') WHEN .F.	PICTURE "@!" SIZE 150,7 PIXEL OF oTPanel1
		
	oGet := MSGetDados():New(0,0,0,0,nOpc,"U_ZZQTVLD('I')","AllwaysTrue()",,.T.)
	
    oDlg:lMaximized:=.T.

ACTIVATE MSDIALOG oDlg CENTER ON INIT (EnchoiceBar(oDlg,{|| IIf(U_ZZQTVLD('I'), ZZQGRVI(),.F.)},{|| oDlg:End() })  , oTPanel1:Align := CONTROL_ALIGN_TOP , oGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT  )

Return 

/*
===============================================================================================================================
Programa----------: ZZQMNT
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para manutenção das Regras - Utilizado no cálculo e geração dos títulos de ST Antecipados
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQMNT(cAlias,nReg,nOpc)

Local oTPanel1 

Private cCodigo := Space(6) 
Private cLoja   := Space(4)
Private cNome   := Space(40) 

Private oDlg 
Private oGet 

Private aHeader := {}
Private aCOLS := {} 
Private aReg := {} 

//Log de utilização
U_ITLOGACS()

DBSelectArea(cAlias) 
DBGoTo(nReg) 

cCodigo := ZZQ->ZZQ_CLIENT
cLoja   := ZZQ->ZZQ_LOJA
cNome   := Posicione("SA1",1,xFilial("SA1")+cCodigo,"A1_NOME")

ZZQHEADER(cAlias)
ZZQCOLS(cAlias, nReg, nOpc)

DEFINE MSDIALOG oDlg TITLE cCadastro From 8,0 To 28,80 OF oMainWnd 
	
	oTPanel1 := TPanel():New(30,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,20,.T.,.F.) 
	
	@ 5, 006 Say "Cód. Cliente:" SIZE 70,7 PIXEL OF oTPanel1 
	@ 5, 080 Say "Loja:"         SIZE 70,7 PIXEL OF oTPanel1 
	@ 5, 140 Say "Nome:"         SIZE 70,7 PIXEL OF oTPanel1
	
	@ 4, 038 MSGET cCodigo F3 "SA1_02"  SIZE 32,7 PIXEL OF oTPanel1 
	@ 4, 095 MSGET cLoja   SIZE 30,7 PIXEL OF oTPanel1 
	@ 4, 160 MSGET cNome   When .F. SIZE 150,7 PIXEL OF oTPanel1
	
	If nOpc == 4 
		oGet := MSGetDados():New(0,0,0,0,nOpc,"U_ZZQTVLD('M')","AllwaysTrue()",,.T.) 
	Else
		oGet := MSGetDados():New(0,0,0,0,nOpc) 
	EndIf 

    oDlg:lMaximized:=.T.
	
ACTIVATE MSDIALOG oDlg CENTER ON INIT (EnchoiceBar(oDlg,{|| IIf(U_ZZQTVLD('M'), ZZQALT(),.F.) },{|| oDlg:End() }) , oTPanel1:Align := CONTROL_ALIGN_TOP , oGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT  )

Return

/*
===============================================================================================================================
Programa----------: ZZQHEADER
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para Montagem do Cabeçalho do GRID na tela
===============================================================================================================================
Parametros--------: cAlias
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ZZQHEADER(cAlias) 

Local aArea := FWGetArea() 
Local _aZZQ := ZZQ->(Dbstruct())
Local _nnj	:= 0

For _nnj := 1 to Len(_aZZQ)

	If 	Trim(_aZZQ[_nnj][1]) <> "ZZQ_FILIAL" .And. ;
	Trim(_aZZQ[_nnj][1]) <> "ZZQ_CLIENT" .And. ;
	Trim(_aZZQ[_nnj][1]) <> "ZZQ_LOJA"
	 
	  	 
	aAdd( aHeader, { trim(getsx3cache(_aZZQ[_NNJ][1],"X3_TITULO") ),;
							getsx3cache(_aZZQ[_NNJ][1],"X3_CAMPO")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_PICTURE")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_TAMANHO")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_DECIMAL")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_VALID")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_USADO")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_TIPO")			,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_ARQUIVO")		,;
							getsx3cache(_aZZQ[_NNJ][1],"X3_CONTEXT")	})
		
	EndIf 

Next


FWRestArea(aArea) 

Return

/*
===============================================================================================================================
Programa----------: ZZQCOLS
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para incialização do GRID - Utilizado no cálculo e geração dos títulos de ST Antecipados
===============================================================================================================================
Parametros--------: cAlias, nReg, nOpc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ZZQCOLS(cAlias, nReg, nOpc) 

Local aArea  := FWGetArea() 
Local cChave := ZZQ->ZZQ_CLIENTE+ZZQ->ZZQ_LOJA 
Local nI     := 0,nColuna

If nOpc <> 3   

	DBSelectArea(cAlias) 
	DBSetOrder(1) 
	DBSeek(xFilial(cAlias)+cChave) 
	
	While !Eof() .And. ZZQ->(ZZQ_FILIAL+ZZQ_CLIENTE+ZZQ_LOJA) == xFilial(cAlias)+cChave 
	
		aAdd(aReg, ZZQ->(RecNo()))
		aAdd(aCOLS, Array(Len(aHeader)+1)) 
		
		For nI := 1 To Len( aHeader ) 
		
			If aHeader[nI,10] == "V" 
				aCOLS[Len(aCOLS),nI] := CriaVar(aHeader[nI,2],.T.) 
			Else
				aCOLS[Len(aCOLS),nI] := FieldGet(FieldPos(aHeader[nI,2])) 
			EndIf 
			
		Next nI 
		
		aCOLS[Len(aCOLS),Len(aHeader)+1] := .F. 
		
		DBSkip() 
	
	End 
	
Else 
	aCols := Array(1,Len(aHeader)+1)

	// Inicialização do aCols
	For nColuna := 1 to Len(aHeader)

		If aHeader[nColuna][8] == "C"
			aCols[1][nColuna] := Space(aHeader[nColuna][4])
		ElseIf aHeader[nColuna][8] == "N"
			aCols[1][nColuna] := 0
		ElseIf aHeader[nColuna][8] == "D"
			aCols[1][nColuna] := CTOD("")
		ElseIf aHeader[nColuna][8] == "L"
			aCols[1][nColuna] := .F.
		ElseIf aHeader[nColuna][8] == "M"
			aCols[1][nColuna] := ""
		EndIf
		
	Next nColuna

	aCols[1][Len(aHeader)+1] := .F. // Linha não deletada
	
EndIf 

FWRestArea(aArea) 


Return

/*
===============================================================================================================================
Programa----------: ZZQGRVI
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para gravação das Regras na operação de Inclusão
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ZZQGRVI() 

Local aArea := FWGetArea() 
Local nI    := 0 
Local nX    := 0 

DBSelectArea("ZZQ") 
DBSetOrder(1) 

For nI := 1 To Len( aCOLS ) 

	If ! aCOLS[nI,Len(aHeader)+1] 
	
	RecLock("ZZQ",.T.) 
		ZZQ->ZZQ_FILIAL := xFilial("ZZQ") 
		ZZQ->ZZQ_CLIENT := cCodigo 
		ZZQ->ZZQ_LOJA   := cLoja 
		
		For nX := 1 To Len( aHeader ) 
		
			FieldPut( FieldPos( aHeader[nX, 2] ), aCOLS[nI, nX] ) 
			
		Next nX 
		
	MSUnLock("ZZQ") 
	
	EndIf 
	
Next nI 

FWRestArea(aArea) 

oDlg:End()

Return

/*
===============================================================================================================================
Programa----------: ZZQALT
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para gravação nas operações de manutenção das Regras
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ZZQALT() 

Local aArea := FWGetArea() 
Local nI := 0
Local nX := 0 

DBSelectArea("ZZQ")

For nI := 1 To Len(aCols) 

	If nI <= Len(aReg) 
		
		DBGoTo(aReg[nI]) 
		
		RecLock("ZZQ",.F.) 
		
		If aCols[nI, Len(aHeader)+1] 
		
			dbDelete() 
            
		Else
			
			ZZQ->ZZQ_FILIAL  := xFilial("ZZQ") 
			ZZQ->ZZQ_CLIENTE := cCodigo 
			ZZQ->ZZQ_LOJA    := cLoja
			
			For nX := 1 To Len(aHeader) 
			
				FieldPut(FieldPos(aHeader[nX, 2]), aCOLS[nI, nX]) 
				
			Next nX
			
		EndIf 
		
		MSUnLock()
	
	Else 
 		
 		If 	!aCols[nI, Len(aHeader)+1]  
	
			RecLock("ZZQ",.T.) 
	
   			ZZQ->ZZQ_FILIAL  := xFilial("ZZQ") 
			ZZQ->ZZQ_CLIENTE := cCodigo 
			ZZQ->ZZQ_LOJA    := cLoja 
			
			For nX := 1 To Len(aHeader) 
			
				FieldPut(FieldPos(aHeader[nX, 2]), aCOLS[nI, nX]) 
				
			Next nX 
			
		EndIf
	
	EndIf 
	
	MSUnLock() 
	
Next nI

FWRestArea(aArea)

oDlg:End() 

Return

/*
===============================================================================================================================
Programa----------: ZZQLVLD
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para validação dos dados nas linhas do GRID
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQLVLD() 

Local aArea := FWGetArea()

Local lRet := .T. 
Local nI   := 0 
Local cMsg1 := "Não será permitido linhas sem o NCM!" 
Local cMsg2 := "Não será permitido linhas sem o MVA!" 
Local cMsg3 := "O NCM inserido já foi cadastrado!"

For nI := 1 To Len( aCOLS ) 

If aCOLS[nI, Len(aHeader)+1] 
	Loop 
EndIf

If ( aCols[Len(aCols)][Len(aHeader)+1] == .F. ) 

	If !aCOLS[nI, Len(aHeader)+1] 
		If Empty(aCOLS[n,GdFieldPos("ZZQ_NCM")]) 
			U_ITMsg(cMsg1,"Atenção",,1)
			lRet := .F.
			Exit
		ElseIf Empty(aCOLS[n,GdFieldPos("ZZQ_MVA")]) 
			U_ITMsg(cMsg2,"Atenção",,1)
			lRet := .F.
			Exit
		ElseIf ( (nI <> n) .And. (aCols[nI][1] == aCols[n][1]) .And. (aCols[nI][Len(aHeader)+1] == .F.) )
			U_ITMsg(cMsg3,"Atenção",,1)
			lRet := .F.
			Exit
		EndIf
	EndIf 

EndIf

Next nI 

FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: ZZQTVLD
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para validação Total das Regras antes da gravação
===============================================================================================================================
Parametros--------: _cTipo
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQTVLD( _cTipo ) 

Local _aArea	:= FWGetArea()
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .T.
Local _nI		:= 0 

For _nI := 1 To Len( aCOLS )

	If aCOLS[ _nI ][ Len(aHeader) + 1 ]
		Loop
	EndIf
	
	If !( aCols[ Len(aCols) ][ Len(aHeader) + 1 ] )
	
		If !aCOLS[ _nI ][ Len(aHeader) + 1 ]
		
			If Empty( aCOLS[ n ][ GdFieldPos("ZZQ_NCM") ] )
			
				U_ITMsg('O NCM é obrigatório para todos os itens do cadastro.',"Atenção",'Verifique os dados informados!',1 )

				_lRet := .F.
				Exit
			
			EndIf
			
			If Empty( aCOLS[ n ][ GdFieldPos("ZZQ_MVA") ] )
			
				U_ITMsg('O MVA é obrigatório para todos os itens do cadastro.',"Atenção",'Verifique os dados informados!',1 )
	
				_lRet := .F.
				Exit
				
			EndIf
			
			If ( ( _nI <> n ) .And. ( aCols[_nI][1] == aCols[n][1] ) .And. ( aCols[_nI][2] == aCols[n][2] ) .And. ( aCols[_nI][5] == aCols[n][5] ) .And. !aCols[n][Len(aHeader)+1] )
			
				U_ITMsg('O NCM + Perc. MVA + Cód. Exceção já foi incluído no cadastro anteriormente.',"Atenção",'Verifique os dados informados!',1 )

				_lRet := .F.
				Exit
				
			EndIf
			
		EndIf
		
		If _lRet .And. _cTipo == "I"
		
			_cQuery := " SELECT COUNT(1) AS REGS FROM "+ RetSqlName('ZZQ') +" ZZQ WHERE "+ RetSqlCond('ZZQ') +" AND ZZQ.ZZQ_NCM = '"+ aCols[n][1] +"' AND ZZQ.ZZQ_EXCNCM = '"+ aCols[n][5] +"' "+;
						"AND ZZQ_CLIENT = '"+cCodigo+"' AND ZZQ_LOJA = '"+cLoja+"'"
			
			If Select(_cAlias) > 0
				(_cAlias)->( DBCloseArea() )
			EndIf
			
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )
			
			DBSelectArea(_cAlias)
			(_cAlias)->( DBGoTop() )
			If (_cAlias)->( !Eof() ) .And. (_cAlias)->REGS > 0
			
				U_ITMsg('O NCM + Cód. Exceção já foi incluído no cadastro anteriormente.',"Atenção",'Verifique os dados informados!',1 )
			
				_lRet := .F.
				
			EndIf
			
			(_cAlias)->( DBCloseArea() )
		
		EndIf
	
	EndIf
	
Next _nI

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ZZQNCM
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para validação dos códigos NCM
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQNCM()
	
Local _aArea	:= FWGetArea()
Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .T.          
Local _cNcm		:= AllTrim(M->ZZQ_NCM)
Local _nQtdNcm	:= 0

//====================================================================================================
// Query que verifica se o ncm está cadastrado no cadastro de produto
//====================================================================================================
_cQuery := " SELECT COUNT(1) AS CONTNCM "
_cQuery += " FROM "+ RetSqlName("SB1")
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND B1_POSIPI  = '"+ _cNcm +"' "
_cQuery += " AND B1_TIPO    = 'PA' "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )
	_nQtdNcm := (_cAlias)->CONTNCM
EndIf

(_cAlias)->( DBCloseArea() )

If _nQtdNcm == 0

	U_ITMsg('O NCM informado não existe no cadastro de Produtos do Sistema.',"Atenção",'Verifique os dados informados!',1 )

	_lRet := .F.

EndIf
	
FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ZZQCLI
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 03/09/2012
===============================================================================================================================
Descrição---------: Função para validação dos dados de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQCLI()
	
Local _aArea    := FWGetArea()
Local _cQuery   := ""
Local lRet      := .T.
Local nQtdCli  	:= 0 

If cCodigo <> ' '

	//Query que verifica se o cliente entra na regra
	_cQuery := " SELECT SUM(INSTR('"+AllTrim(GetMv('IT_STEST'))+"',A1_EST)) AS CONTCLI "
	_cQuery += " FROM " + RetSqlName("SA1")
	_cQuery += " WHERE D_E_L_E_T_ <> '*'"
	_cQuery += " AND   A1_COD = '" + cCodigo + "' "
	_cQuery += " AND   A1_I_STESP = 'N' "
	
	If Select("QCLI") > 0
		DBSelectArea("QCLI")
		QCLI->(DBCloseArea())
	EndIf
	
	TcQuery _cQuery New Alias "QCLI"
	
	DBSelectArea("QCLI")
	DBGoTop()
	
	nQtdCli := QCLI->CONTCLI

	DBSelectArea("QCLI")
	DBCloseArea()
	
	If nQtdCli == 0
	
		U_ITMsg("CLIENTE NÃO EXISTENTE OU FORA DA REGRA DE GERAÇÃO","Atenção","Teclando F3 você pode ver os clientes que podem ser cadastrados.",1 )
	
		lRet := .F.

	EndIf

EndIf
	
FWRestArea(_aArea)

Return(lRet)


/*
===============================================================================================================================
Programa----------: ZZQCPY
Autor-------------: Igor Melgaço
Data da Criacao---: 12/05/2022
===============================================================================================================================
Descrição---------: Função para manutenção das Regras - Utilizado no cálculo e geração dos títulos de ST Antecipados
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ZZQCPY(cAlias,nReg,nOpc)

Local oTPanel1 

Private cCodigo := Space(6) 
Private cLoja   := Space(4)
Private cNome   := Space(40) 

Private oDlg 
Private oGet 

Private aHeader := {}
Private aCOLS   := {} 
Private aReg    := {} 

//Log de utilização
U_ITLOGACS()

DBSelectArea(cAlias) 
DBGoTo(nReg) 

cCodigo := Space(Len(ZZQ->ZZQ_CLIENT))
cLoja   := Space(Len(ZZQ->ZZQ_LOJA))
cNome   := Space(Len(Posicione("SA1",1,xFilial("SA1")+cCodigo,"A1_NOME")))

ZZQHEADER(cAlias)
ZZQCOLS(cAlias, nReg, nOpc)

DEFINE MSDIALOG oDlg TITLE cCadastro From 8,0 To 28,80 OF oMainWnd 
	
	oTPanel1 := TPanel():New(30,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,0,20,.T.,.F.) 
	
	@ 5, 006 Say "Cód. Cliente:" SIZE 70,7 PIXEL OF oTPanel1 
	@ 5, 080 Say "Loja:"         SIZE 70,7 PIXEL OF oTPanel1 
	@ 5, 140 Say "Nome:"         SIZE 70,7 PIXEL OF oTPanel1
	
	@ 4, 038 MSGET cCodigo F3 "SA1_02"  PICTURE "@!" VALID U_ZZQCLI() SIZE 32,7 PIXEL OF oTPanel1 
	@ 4, 095 MSGET cLoja   PICTURE "@!" SIZE 30,7 PIXEL OF oTPanel1 
	@ 4, 160 MSGET cNome   When .F. SIZE 150,7 PIXEL OF oTPanel1
	
	If nOpc == 4 
		oGet := MSGetDados():New(0,0,0,0,nOpc,"U_ZZQTVLD('I')","AllwaysTrue()",,.T.) 
	Else
		oGet := MSGetDados():New(0,0,0,0,nOpc) 
	EndIf 

    oDlg:lMaximized:=.T.

ACTIVATE MSDIALOG oDlg CENTER ON INIT (EnchoiceBar(oDlg,{|| IIf(U_ZZQTVLD('I'), ZZQGRVI(),.F.) },{|| oDlg:End() }) , oTPanel1:Align := CONTROL_ALIGN_TOP , oGet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT  )

Return

/*
===============================================================================================================================
Programa----------: AOMS59E
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 02/05/2023
===============================================================================================================================
Descrição---------: Função com intuito de permitir que o usuário tenha a possibilidade de excluir os títulos gerados pela 
------------------: rotina uma vez que se For identificado alguma parametrização indevida.
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS59E(cAlias,nReg,nOpc)
Local _aParRet :={}
Local _aParAux :={} , nI 

MV_PAR01:=dDataBase
MV_PAR02:=dDataBase

aAdd( _aParAux , { 1 , "Dt Emissão de"	      , MV_PAR01, "@D"	, ""	, ""		, "" , 060 , .T. } )
aAdd( _aParAux , { 1 , "Dt Emissão ate"       , MV_PAR02, "@D"	, ""	, ""		, "" , 060 , .T. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.
             //aParametros, cTitle            , @aRet     ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "FILTRAR TITULOS" , @_aParRet ,/*bOK*/, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
      Exit
   EndIf

   _aDados:={}
   _nTotalM:=0
   _cTimeIni:=Time()
   FWMsgRun( ,{|oproc| _aDados:=AOMS59Ler(oproc) } , "Aguarde!" , "Hora Inicial: "+_cTimeIni+" / Executando a SELECT ..." )

   If Len(_aDados) > 0
   
       aCab:={}
       aAdd(aCab," ")
       aAdd(aCab," ")
       aAdd(aCab ,"Filial")
       aAdd(aCab ,"Dt Emissao")    
       aAdd(aCab ,"No. Titulo") ; _nPosTit:=Len(aCab)
       aAdd(aCab ,"Parcela")    
       aAdd(aCab ,"Prefixo")    
       aAdd(aCab ,"Tipo")  
       aAdd(aCab ,"Natureza")    
       aAdd(aCab ,"Cliente")
       aAdd(aCab ,"Loja")  
       aAdd(aCab ,"Dt Vecto")   
       aAdd(aCab ,"Dt Vecto Real")    
       aAdd(aCab ,"Valor") 
       aAdd(aCab ,"Saldo") 
       aAdd(aCab ,"Dt Baixa") 
       aAdd(aCab ,"Situacao") 
       aAdd(aCab ,"Registro") 
   	
       _cTitulo2:='Exclusao de Titulos - Data: ' + DToC(Date()) 
       _cMsgTopFixo:=" - Dt Inicial: "+AllTrim(AllToChar(MV_PAR01))+"; Dt Final: "+AllTrim(AllToChar(MV_PAR02))+" -  H.I.: "+_cTimeIni+" H.F.: "+Time()
       _cMsgTop:="Total Selecionado : "+ AllTrim(Transform(  _nTotalM  , "9999" ))+_cMsgTopFixo

       _bDblClk := {|| U_AOMS59Marca( @oLbxAux, @oSayAux, @_cMsgTop,.F.) }
       _bHeadClk := {|oLbx, ni| IIf(ni=1,FWMsgRun( ,{|oProc|  U_AOMS59Marca( @oLbxAux, @oSayAux, @_cMsgTop, .T.,oProc) } , "Processando... " ),.F.)  }

		_aButtons:={}
		aAdd(_aButtons,{"",{|| AOMS59Vis(oLbxAux:aArray[oLbxAux:nAt][Len(oLbxAux:aArray[oLbxAux:nAt])])  },"", "Visualizar Titulo" })
        aAdd(_aButtons,{"",{|| AOMS59Pes( oLbxAux ) }, "" , "PESQUISAR TITULO"} )

	//      ITListBox(_cTitAux , _aHeader , _aCols ,_lMaxSiz,_nTipo,_cMsgTop,_lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
   	   If U_ITListBox(_cTitulo2, aCab     , _aDados, .T.    , 2    ,_cMsgTop, .F.     ,         ,         ,     ,        , _aButtons,, _bDblClk ,,,,, _bHeadClk )
          
          
          FWMsgRun( ,{|oProc|  AOMS59Exc(oProc) }  , "Processando... " )

   	   EndIf
     	
   EndIf


EndDo

Return 

/*
===============================================================================================================================
Programa----------: MOMS66Pesq
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 08/05/2022
===============================================================================================================================
Descrição---------: Pesquisa Pedidos
===============================================================================================================================
Parametros--------: _oLbxAux
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AOMS59Pes( oLbxAux ) 

Local _oGet1		:= Nil
Local _oDlg			:= Nil
Local _cGet1		:= Space(Len(SE1->E1_NUM))
Local _nOpca		:= 0
Local nPos			:= 0
Local _lAchou		:= .F.

If oLbxAux <> NIL
   N:=oLbxAux:nAt
   aCols:=oLbxAux:aArray
Else
   Return .F.
EndIf

DEFINE MSDIALOG _oDlg TITLE "Pesquisar Numero do Titulo" FROM 178,181 TO 259,697 PIXEL 

@005,003 Say "Numero do Titulo para Pesquisar :" Size 213,010 PIXEL OF _oDlg
@020,003 MsGet _oGet1 Var _cGet1				 Size 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!" F3 "SE1"

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1
   _cGet1 := RTrim( _cGet1 )
   If (nPos := aScan(aCols,{|P| P[_nPosTit] == _cGet1 }) ) <> 0 
   	  oLbxAux:nAt    := N :=nPos
   	 _lAchou:= .T.
   EndIf	  	
Else
   Return _cRet//RETORNA O CONTEUDO DELE MESMO 
EndIf

If _lAchou
   oLbxAux:Refresh()
   oLbxAux:SetFocus()
   U_ITMsg("O Titulo "+_cGet1+" esta na linha: "+AllTrim(Str(nPos)),'Atenção!',,2) 
Else
   U_ITMsg("Titulo não encontrado nesta lista.",'Atenção!',"Tente outro Titulo",3) 
EndIf

Return .T.



/*
===============================================================================================================================
Programa----------: AOMS59Ler
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 02/05/2023
===============================================================================================================================
Descrição---------: Função com intuito de permitir que o usuário tenha a possibilidade de excluir os títulos gerados pela 
------------------: rotina uma vez que se For identificado alguma parametrização indevida.
===============================================================================================================================
Parametros--------: cAlias,nReg,nOpc
===============================================================================================================================
Retorno-----------: _aDados
===============================================================================================================================
*/
Static Function AOMS59Ler(oproc)
Local _cAlias2:= GetNextAlias()
Local _cQuery := "SELECT "  
_cQuery += " R_E_C_N_O_ SE1REC "
_cQuery += "FROM " + RetSqlName("SE1") + " E1 "  
_cQuery += "WHERE E1.D_E_L_E_T_ = ' ' "
_cQuery += "  AND E1.E1_FILIAL  = '" + xFilial("SE1") + "' "   
_cQuery += "  AND E1.E1_TIPO    = 'ICM' "
_cQuery += "  AND E1.E1_ORIGEM  = 'GRVICMST' "  
_cQuery += "  AND E1.E1_EMISSAO BETWEEN '" + DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' " 
_cQuery += "ORDER BY E1_NUM, E1_EMISSAO,  E1_PARCELA"


cTimeINI:=Time()
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias2 , .T. , .F. )
   
_nTot:=nConta:=0
COUNT TO _nTot
_cTotGeral:=AllTrim(Str(_nTot))

cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

(_cAlias2)->(DBGoTop())
If (_cAlias2)->(Eof())
   U_ITMsg("Não tem titulos para listados com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
   Return {}
EndIf
      
If _nTot > 500 .And. !U_ITMsg("Serão listados "+_cTotGeral+' titulos , Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
   Return {}
EndIf
      
_aDados:={}
_nTotalM:=0
While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
            
    If oproc <> NIL
       nConta++
       oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
       ProcessMessages()
    EndIf
	
	SE1->(DBGoTo((_cAlias2)->SE1REC))
    If Empty(SE1->E1_BAIXA) .And.  SE1->E1_SALDO = SE1->E1_VALOR
       _nTotalM++
    EndIf

    _aProd := {}
    aAdd(_aProd , Empty(SE1->E1_BAIXA) .And.  SE1->E1_SALDO = SE1->E1_VALOR .And. SE1->E1_SITUACA = "0") 
    aAdd(_aProd , Empty(SE1->E1_BAIXA) .And.  SE1->E1_SALDO = SE1->E1_VALOR .And. SE1->E1_SITUACA = "0") 
    aAdd(_aProd ,SE1->E1_FILIAL )   
    aAdd(_aProd ,SE1->E1_EMISSAO)    
    aAdd(_aProd ,SE1->E1_NUM    ) 
    aAdd(_aProd ,SE1->E1_PARCELA)    
    aAdd(_aProd ,SE1->E1_PREFIXO)    
    aAdd(_aProd ,SE1->E1_TIPO   )  
    aAdd(_aProd ,SE1->E1_NATUREZ)    
    aAdd(_aProd ,SE1->E1_CLIENTE)    
    aAdd(_aProd ,SE1->E1_LOJA   )  
    aAdd(_aProd ,SE1->E1_VENCTO )   
    aAdd(_aProd ,SE1->E1_VENCREA)
    aAdd(_aProd ,"R$ "+TRANS(SE1->E1_VALOR,"@E 999,999,999,999.99")  ) 
    aAdd(_aProd ,"R$ "+TRANS(SE1->E1_SALDO,"@E 999,999,999,999.99")  ) 
    aAdd(_aProd ,SE1->E1_BAIXA)
    aAdd(_aProd ,If(SE1->E1_SITUACA<>"0","EM BORDERO","          "))	
    aAdd(_aProd ,SE1->(RECNO()))
    aAdd(_aDados , _aProd  )
          
    (_cAlias2)->(DBSkip())
      
EndDo


Return _aDados

/*
===============================================================================================================================
Programa----------: AOMS59Exc
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 08/05/2023
===============================================================================================================================
Descrição---------: Rotina de exclusao do SE1
===============================================================================================================================
Parametros--------: oProc = Status de Processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS59Exc( oProc )
Local nI
Local nModAnt  := nModulo
Local cModAnt  := cModulo
Local _lSegue  := .T.  //Para excluir a SE1 somente se OK na exclusão da SE2
Local _TitSE2  //ARRRAY PARA CARREGAR OS DADOS DO TÍTULO DA SE2 PARA EXCLUSÃO

_nConta:=0
// Altera o modulo para Financeiro, senao o SigaAuto nao executa.
nModulo := 6
cModulo := "FIN"

For nI := 1 To Len( _aDados )
     
	If _aDados[nI,1] 

//INICIO DO TRATAMENTO DA EXCLUSÃO DA SE2
		DBSelectArea("SE2")
		SE2->(DBSetOrder(1)) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA                                                                                               
		If SE2->(DBSeek(_aDados[nI][3]+_aDados[nI][7]+_aDados[nI][5]+_aDados[nI][6]+_aDados[nI][8]))
     	
		While SE2->(!Eof()) .And. SE2->E2_FILIAL == _aDados[nI][3] .And. SE2->E2_PREFIXO == _aDados[nI][7];
							   .And. SE2->E2_NUM == _aDados[nI][5] .And. SE2->E2_PARCELA == _aDados[nI][6];
							   .And. SE2->E2_TIPO == _aDados[nI][8] .And. SE2->E2_ORIGEM == "GRVICMST"
					_TitSE2 := {}
					aAdd(_TitSE2, {"E2_FILIAL",  SE2->E2_FILIAL,    Nil})
					aAdd(_TitSE2, {"E2_NUM",     SE2->E2_NUM,    Nil})
					aAdd(_TitSE2, {"E2_PREFIXO", SE2->E2_PREFIXO,Nil})
					aAdd(_TitSE2, {"E2_PARCELA", SE2->E2_PARCELA,Nil})
					aAdd(_TitSE2, {"E2_TIPO",    SE2->E2_TIPO,    Nil})
					aAdd(_TitSE2, {"E2_NATUREZ", SE2->E2_NATUREZ,    Nil})
					aAdd(_TitSE2, {"E2_FORNECE", SE2->E2_FORNECE,    Nil})
					aAdd(_TitSE2, {"E2_LOJA", SE2->E2_LOJA,    Nil})
					aAdd(_TitSE2, {"E2_NOMFOR", SE2->E2_NOMFOR,    Nil})
					aAdd(_TitSE2, {"E2_EMISSAO", SE2->E2_EMISSAO,    Nil})
					aAdd(_TitSE2, {"E2_VENCTO", SE2->E2_VENCTO,    Nil})
					aAdd(_TitSE2, {"E2_VENCREA", SE2->E2_VENCREA,    Nil})
					aAdd(_TitSE2, {"E2_VALOR", SE2->E2_VALOR,    Nil})
					aAdd(_TitSE2, {"E2_CONTAD", SE2->E2_CONTAD,    Nil})
					aAdd(_TitSE2, {"E2_HIST", SE2->E2_HIST,    Nil})
					aAdd(_TitSE2, {"E2_MOEDA", SE2->E2_MOEDA,    Nil})
					aAdd(_TitSE2, {"E2_ORIGEM",  "GRVICMST",     Nil})


        SE2->(DBSkip())
        EndDo  
		EndIf
		SE2->(DBCloseArea())


If !Empty(_TitSE2) 
//Inicia o controle de transação
Begin Transaction
    //Chama a rotina automática
    lMsErroAuto := .F.
    MsExecAuto( { |x,y,z| FINA050(x,y,z)},_TitSE2,, 5) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
    //Se houve erro, mostra o erro ao usuário e desarma a transação
    If lMsErroAuto
        MostraErro()
        DisarmTransaction()
		_lSegue := .F.
    EndIf
//Finaliza a transação
End Transaction
EndIf 
//Fim da Tratativa da Exclusão da SE2

//TRATATIVA DA SE1
If _lSegue
	   SE1->(DBGoTo( _aDados[nI,Len(_aDados[nI] )]) )
       _cChave:=SE1->(E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)
       _cChavErro:="Nota: "+SE1->E1_NUM+" / Cliente+Loja: "+SE1->E1_CLIENTE+SE1->E1_LOJA+" / Pref.: "+SE1->E1_PREFIXO+" / Parc.: "+SE1->E1_PARCELA
/*
        aArray:={{"E1_FILIAL"	,SE1->E1_FILIAL	, NIL },;
    			 {"E1_NUM"		,SE1->E1_NUM	, NIL },;
    			 {"E1_CLIENTE"	,SE1->E1_CLIENTE, NIL },;
    			 {"E1_LOJA"		,SE1->E1_LOJA   , NIL },;
        		 {"E1_PREFIXO"	,SE1->E1_PREFIXO, NIL },;
    			 {"E1_PARCELA"	,SE1->E1_PARCELA, NIL },;
              	 {"E1_TIPO"		,SE1->E1_TIPO	, NIL }}*/

	     aArray  := {	{"E1_FILIAL"  ,SE1->E1_FILIAL    		,Nil},;
         	          	{"E1_CLIENTE" ,SE1->E1_CLIENTE      	,Nil},;
	     				{"E1_LOJA"	  ,SE1->E1_LOJA 	     	,Nil},;
         	          	{"E1_PREFIXO" ,SE1->E1_PREFIXO   		,Nil},;
	     				{"E1_NUM"	  ,SE1->E1_NUM     	     	,Nil},;
	     				{"E1_TIPO"	  ,SE1->E1_TIPO           	,Nil},;
	     				{"E1_ORIGEM"  ,SE1->E1_ORIGEM         	,Nil}}      
	     

        lMsErroAuto := .F.	
	    MsExecAuto( {|x,y| FINA040( x , y ) } , aArray , 5 )  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	
        SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	    If lMsErroAuto .Or. (lAchou:=SE1->(DBSeek(_cChave)))//SE1->(DBSeek( SF1->F1_FILIAL+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC ))
		   If lMsErroAuto
	          _cErro:=(MostraErro())
		   Else
	          _cErro:="Nao exclui titulo, tente novamente!"
		   EndIf
           bBloco:={||  AVISO("MostraErro()",_cErro,{"Fechar"},3) }
           U_ITMsg("Não foi possivel excluir o titulo / "+_cChavErro,"ATENCAO!","Verifique a mensagen de erro [Mais Detalhes] e tente novamente: ",1,,,,,,bBloco)
        Else
	    	_nConta++
        EndIf

   EndIf
EndIf      	  
Next	

// Restaura o modulo em uso.
nModulo := nModAnt
cModulo := cModAnt


U_ITMsg('Processo concluído com sucesso. Titulos excluidos: '+CValToChar(_nConta),"Atenção",,2)

Return .T.

/*
===============================================================================================================================
Programa----------: MDIN019GR
Autor-------------: Igor Melgaço
Data da Criacao---: 23/02/2022
===============================================================================================================================
Descrição---------: Rotina de gravação do Array
===============================================================================================================================
Parametros--------: oLbxDados = Objeto Lisbox 
------------------: oSayAux   = Objeto Say da Mensagem
------------------: _cMsgTop  = Mesnsagem exibida em cima do Listbox 
------------------: lHeader   = Define se foi executado no Clique na primeira coluna
------------------: oProc     = Status de Processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS59Marca( oLbxDados, oMsgStop, _cMsgTop, lHeader,oProc)
Local _nPos := 0
Local _nTam := 0

Default lHeader := .F.

   If lHeader
      _nTam := Len( oLbxDados:aArray )
      oproc:cCaption := ("Atualizando os registros...   Total: "+AllTrim(Str(_nTam)))
      ProcessMessages()
      
	  _nTotalM:=0
      For _nPos := 1 To _nTam
          If oLbxDados:aArray[ _nPos , 02 ]
		     oLbxDados:aArray[ _nPos , 01 ] := !oLbxDados:aArray[ _nPos , 01 ]
             If oLbxDados:aArray[ _nPos , 01 ]
                _nTotalM ++
             EndIf
          EndIf
      Next
   Else
      _nPos := oLbxAux:nAt

      If oLbxDados:aArray[ _nPos , 02 ]
         oLbxDados:aArray[ _nPos , 01 ] := !oLbxDados:aArray[ _nPos , 01 ]
         If oLbxDados:aArray[ _nPos , 01 ]
            _nTotalM ++
         Else
            _nTotalM --
         EndIf
      EndIf

   EndIf

   _cMsgTop :="Total Selecionado : "+ AllTrim(Transform(  _nTotalM  , "9999" ))+_cMsgTopFixo
   oMsgStop:cCaption:=_cMsgTop
   oMsgStop:Refresh()
   oLbxDados:Refresh()

Return


/*
===============================================================================================================================
Programa----------: AOMS59Vis
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 08/05/2023
===============================================================================================================================
Descrição---------: Funcao para Visualizacao do SE1.
===============================================================================================================================
Parametros--------: nRecno	
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/ 
Static Function AOMS59Vis(nRecno)
Local aArea:= FWGetArea()
cCadastro:="Visualizar Titulo" 

DBSelectArea("SE1")
SE1->(DBSetOrder(1))
SE1->(DBGoTo( nRecno ))
AxVisual( "SE1", SE1->( Recno() ), 2 )

FWRestArea( aArea )        
Return .T.
