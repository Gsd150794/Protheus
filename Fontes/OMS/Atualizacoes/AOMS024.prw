/*
================================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
================================================================================================================================
    Autor     |    Data    |                                             Motivo                                          
--------------------------------------------------------------------------------------------------------------------------------
 Josué Danich | 09/08/2018 | Chamado 25823. Padronização de código e inclusão de filtro de PA. 
 Julio Paz    | 29/10/2018 | Chamado 26647. Correções consulta especifica/seleção de produtos. Ajustes p/novo servidor Totvs. 
 Julio Paz    | 19/12/2018 | Chamado 27178 / 27237. Corrigir Numeração dos Descontos e Validações para evitar Duplicidade. 
 Julio Paz    | 11/09/2019 | Chamado 30331. Alterar rotina, incluir opção para informar cliente/loja na inclusão de produtos.
 Julio Paz    | 08/04/2022 | Chamado 39590. Correção na Inclusão novos itens via tecla F3 e correção Error log na filtragem. 
 Julio Paz    | 14/04/2022 | Chamado 39177. Inclusão de filtro p/grupo de produto e botão para atualizar percentual em lotes.
 Julio Paz    | 30/05/2022 | Chamado 40234. Realização de correções na rotina de descontos contratuais. 
 Julio Paz    | 01/09/2023 | Chamado 44635. Criar uma nova opção de filtro por Mix BI. 
 Alex Wallauer| 13/10/2023 | Chamado 45217. Correção da validação do abatimento não preenchido na tela de aprovação.
 Igor Melgaço | 23/09/2024 | Chamado 47892. Ajustes de Filtro qdo rotina chamada do AOMS023.
================================================================================================================================


=========================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Antonio Ramos    -  Igor Melgaço     - 21/10/2024 - 24/10/2024 - 47892   - Inclusão de check para filtro de produto.
=========================================================================================================================================================

*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"
#Include "RwMake.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: AOMS024
Autor-------------: Wodson Reis Silva
Data da Criacao---: 02/04/2009
===============================================================================================================================
Descrição---------: Pesquisa em lista de produtos PA Ativos com seleção por grupo
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS024()
Local _lRet := .T.
Local oGrupo
Local oDescr
Local oDescto
Local oDlgPro
Local oContr
Local cContr  := Space(12)
Local cGrupo  := Space(04)
Local cDescr  := Space(60)
Local nDescto := 0
Local aAreaSB1:= SB1->(GetArea())
Local aAreaZAZ:= ZAZ->(GetArea())
Local aAreaZB0:= ZB0->(GetArea())
Local _lNMostSel := .T.

Private oBoxLib
Private nOpc      := 0
Private bNbMarked := LoadBitmap( GetResources(), "LBNO" )
Private bMarked   := LoadBitmap( GetResources(), "LBOK" )
Private aGrd      := {{LoadBitmap(GetResources(), "BR_CINZA"   ),bNbMarked,"",""}}
Private _cNomeCli := Space(50)
Private _cCodCli  := Space(6), _oCodCli
Private _cLojaCli := Space(4), _oLojaCli

Begin Sequence
   //=================================
   // Tela para escolha do produto. 
   //=================================
   DEFINE MSDIALOG oDlgPro TITLE "Pesquisa de Produtos" FROM 178,181 TO 665,1100 PIXEL  // 665,967
      SetKey(VK_F5, {|| MsgRun("Processando registros...","",{|| CursorWait(), AOMS024B(cGrupo,cDescr),CursorArrow()})})
      SetKey(VK_F6, {|| AOMS024I(nDescto,cContr),Close(oDlgPro) })

      @ 004,004 TO 045,455 LABEL "Pesquisa:"   PIXEL OF oDlgPro // 391
      @ 048,004 TO 220,455 LABEL "Resultados:" PIXEL OF oDlgPro // 391

      @ 016,008 Say "Grupo:" Size 018,006 COLOR CLR_BLACK PIXEL OF oDlgPro
      @ 023,008 MSGet oGrupo Var cGrupo F3 "SBM" Size 058,009 PIXEL  OF oDlgPro
      oGrupo:SetFocus()

      @ 016,078 Say "Descrição:" Size 026,006 COLOR CLR_BLACK PIXEL OF oDlgPro
      @ 023,078 MsGet oDescr Var cDescr Picture "@!" Size 230,009 COLOR CLR_BLACK PIXEL OF oDlgPro

      @ 016,312 Say "Contrato:" Size 026,006 COLOR CLR_BLACK PIXEL OF oDlgPro
      @ 023,312 MSGet oContr Var cContr Picture "@!" Size 037,009 COLOR CLR_BLACK PIXEL OF oDlgPro

      @ 016,353 Say "% Desconto:" Size 026,006 COLOR CLR_BLACK PIXEL OF oDlgPro
      @ 023,353 MSGet oDescto Var nDescto Picture "@E 999.99" Size 017,009 COLOR CLR_BLACK PIXEL OF oDlgPro

      @ 016,391 Say "Cliente:" Size 026,006 COLOR CLR_BLACK PIXEL OF oDlgPro
      @ 023,391 MSGet _oCodCli Var _cCodCli Picture "@!" F3 "SA1" Valid (U_AOMS024V("COD_CLIENTE",_cCodCli,_cLojaCli)) Size 017,009 COLOR CLR_BLACK PIXEL OF oDlgPro

      @ 016,428 Say "Loja:" Size 026,006 COLOR CLR_BLACK PIXEL OF oDlgPro
      @ 023,428 MSGet _oLojaCli Var _cLojaCli Picture "@!" Valid(U_AOMS024V("LOJA_CLIENTE",_cCodCli,_cLojaCli)) Size 017,009 COLOR CLR_BLACK PIXEL OF oDlgPro

      @ 036,008 CHECKBOX _oChkSel  VAR _lNMostSel PROMPT "Não mostra itens já selecionados" SIZE 100,010 ON CLICK( _oChkSel:Refresh() ) OF oDlgPro PIXEL
      

      @ 055,007 ListBox oBoxLib  Fields Headers 	" "," ","Codigo","Descricao" Size 442,163; // 381,163
      ON DBLCLICK ( AOMS024M() ) Pixel Of oDlgPro

      oBoxLib:SetArray(aGrd)
      oBoxLib:bLine := {|| {aGrd[oBoxLib:nAt,1],;
      aGrd[oBoxLib:nAt,2],;
      aGrd[oBoxLib:nAt,3],;
      aGrd[oBoxLib:nAt,4]}}

      oBoxLib:bHeaderClick := {|| AOMS024A(), oBoxLib:Refresh()}

      @ 226,313 Button "Pesquisar [F5]" Size 037,012 PIXEL OF oDlgPro;
        Action (MsgRun("Processando registros...","",{|| CursorWait(), AOMS024B(cGrupo,cDescr,_lNMostSel),CursorArrow()})) 
      @ 226,353 Button "Ok [F6]"        Size 037,012 PIXEL OF oDlgPro;  
        Action(AOMS024I(nDescto,cContr),Close(oDlgPro))

   ACTIVATE MSDIALOG oDlgPro CENTERED

   SetKey(VK_F5,Nil)
   SetKey(VK_F6,Nil)

   FWRestArea(aAreaSB1)
   FWRestArea(aAreaZAZ)
   FWRestArea(aAreaZB0)

   If nOpc <> 1
	  //======================================================================================
	  //Deve ser retornado .F. para que o sistema NAO atualize o campo de destino.          
	  //======================================================================================
	  _lRet := .F. 
	  Break 
   EndIf

End Sequence

//======================================================================================
//Deve ser retornado .T. para que o sistema atualize o campo de destino               
//Não precisa forçar o campo no retorno pois o mesmo é atualizado pela montagem do SXB
//======================================================================================
Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS024I
Autor-------------: Wodson Reis Silva
Data da Criacao---: 02/04/2009
===============================================================================================================================
Descrição---------: Insere no aCols os produtos marcados. 
===============================================================================================================================
Parametros--------: nDescto - Valor Desconto
					cContr - Contrato
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS024I(nDescto,cContr)

Local cNroItem:= "000000" 
Local nI      := 0
Local lMark   := .F.
Local _nPosContr := aScan(aHeader,{|x| AllTrim(x[2])=="ZB0_COD"})   
Local _nPosItem  := aScan(aHeader,{|x| AllTrim(x[2])=="ZB0_ITEM"})  
Local _lInicAdd := .T.
Local nProc

//===========================================================
// Ler numero do ultimo item 
//===========================================================
For nI := 1 To Len(aCols)
    //If Val(aCols[nI,_nPosItem]) > Val(cNroItem)  
	If aCols[nI,_nPosItem] > cNroItem  
       cNroItem := aCols[nI,_nPosItem] 
    EndIf
Next


For nI := 1 To Len(aGrd)
	
	//===============================================
	// Se esta marcado.                            
	//===============================================
	If (aGrd[nI,2] == bMarked)
		
		//========================================================
		// Identifica se pelo menos um produto foi selecionado. 
		//========================================================
		If !Empty(AllTrim(aGrd[nI,3]))
		    lMark := .T.
		EndIf
		
		If ! _lInicAdd 
		   If !Empty(AllTrim(aCols[Len(aCols)][2]))
			
			  //===============================================
			  // Inicializa o Acols com uma linha em Branco. 
			  //===============================================
			  aAdd(aCols,Array(Len(aHeader)+1))
			
			  //=========================
			  // Incrementa os Itens.  
			  //=========================
			  cNroItem := Soma1(cNroItem)
		   EndIf
		Else
		   _lInicAdd := .F.   
		EndIf
		
		If Len(aCols) == 1
		   aCols[1][_nPosContr] := M->ZAZ_COD  
		Else
		   //aCols[Len(aCols)-1][_nPosContr] := M->ZAZ_COD  
		   aCols[Len(aCols)][_nPosContr] := M->ZAZ_COD  
		EndIf
		
		//================================================
		// Preenche o aCols com os campos da Estrutura. 
		//================================================
		For nProc := 1 To Len(aHeader)
		    If AllTrim(aHeader[nProc][2]) == "ZB0_COD"
		       aCols[Len(aCols)][nProc] := M->ZAZ_COD
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_ITEM"
				aCols[Len(aCols)][nProc] := cNroItem
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_SB1COD"
				aCols[Len(aCols)][nProc] := aGrd[nI,3]
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_DCRSB1"
				aCols[Len(aCols)][nProc] := aGrd[nI,4]
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_DESCTO"
				aCols[Len(aCols)][nProc] := nDescto
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_CONTR"
				aCols[Len(aCols)][nProc] := cContr
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_CLIENT"
				aCols[Len(aCols)][nProc] := _cCodCli // Space(TamSX3("ZB0_CLIENT")[1])
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_LOJA"
				aCols[Len(aCols)][nProc] := _cLojaCli // Space(TamSX3("ZB0_LOJA  ")[1])
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_NOME"
				aCols[Len(aCols)][nProc] := _cNomeCli // Space(TamSX3("ZB0_NOME  ")[1])
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_ABATIM"
				aCols[Len(aCols)][nProc] := "I"//Space(TamSX3("ZB0_ABATIM")[1])
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_DESCPA"
				aCols[Len(aCols)][nProc] := 0
			ElseIf AllTrim(aHeader[nProc][2]) == "ZB0_EST"
				aCols[Len(aCols)][nProc] := Space(TamSX3("ZB0_EST")[1])
            ElseIf AllTrim(aHeader[nProc][2]) == "BM_GRUPO" 
				aCols[Len(aCols)][nProc] := Posicione("SB1",1,xFilial("SB1")+aGrd[nI,3],"B1_GRUPO")
            ElseIf AllTrim(aHeader[nProc][2]) == "B1_I_BIMIX" 
			    _cGrpMix := Posicione("SB1",1,xFilial('SB1')+ aGrd[nI,3],"B1_I_BIMIX")
			    aCols[Len(aCols)][nProc] := _cGrpMix
			EndIf
			
			//===================================================
			// Informa que a linha do Acols nao esta deletada. 
			//===================================================
			aCols[Len(aCols)][Len(aHeader)+1] := .F.

		Next nProc
	EndIf
Next nI

//=======================================================
// Verifica se pelo menos um produto foi marcado,     
// se sim nOpc recebe 1 para que a funcao retorne .T. 
//=======================================================
If lMark
	nOpc := 1
EndIf

//If IsInCallStack("AOMS023Q")
   //U_AOMS023D() 
//EndIf

//=========================================================
// Insere no backup do aCols os novos produtos inseridos.
//=========================================================
_aBkpACols := AClone(aCols) 

Return

/*
===============================================================================================================================
Programa----------: AOMS024M
Autor-------------: Wodson Reis Silva
Data da Criacao---: 02/04/2009
===============================================================================================================================
Descrição---------: Marca e desmarca o item. 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS024M()

//Se nao esta marcado
If (aGrd[oBoxLib:nAt,2] == bNbMarked)
	aGrd[oBoxLib:nAt,2] := bMarked
Else
	aGrd[oBoxLib:nAt,2] := bNbMarked
EndIf

oBoxLib:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS024B
Autor-------------: Wodson Reis Silva
Data da Criacao---: 02/04/2009
===============================================================================================================================
Descrição---------: Filtra os produtos na base e os apresenta na tela. 
===============================================================================================================================
Parametros--------: ExpC01 - Codigo do grupo selecionado.
					ExpC02 - Descricao do produto.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS024B(cGrupo,cDescr,_lNMostSel)
Local cQuery  := ""
Local _cProduto := ""
Local _nI := 0
Local _nColExc := 0

Default _lNMostSel := .F.

If _lNMostSel
   If Type("aCols") == "A"
      If Len(aCols) > 0
         _nColExc := Len(aCols[1])
      
         For _nI := 1 To Len(aCols)
            If !aCols[_nI,_nColExc] .And. !(aCols[_nI,4] $ _cProduto)
               _cProduto += IIf(Empty(_cProduto),"",";") + aCols[_nI,4]
            EndIf
         Next
      EndIf
   EndIf
EndIf
//===================================
// Query para filtrar os produtos. 
//===================================
cQuery := "SELECT B1_COD, B1_I_DESCD"
cQuery += " FROM " + RetSqlName("SB1")
cQuery += " WHERE D_E_L_E_T_ <> '*'"
cQuery += " AND B1_FILIAL  = '" + xFilial("SB1") + "'"
cQuery += " AND B1_MSBLQL <> '1'"
cQuery += " AND B1_TIPO = 'PA'"
If _lNMostSel .And. !Empty(_cProduto)
   cQuery += "  AND B1_COD NOT IN " + FormatIn(_cProduto,";") 
EndIf
If !Empty(cGrupo) //Se o grupo nao esta vazio
	cQuery += " AND B1_GRUPO = '" + AllTrim(cGrupo) + "'"
EndIf
If !Empty(cDescr) //Se a descricao nao esta vazia, verifica se a expressao contem na descricao do produto
	cQuery += " AND B1_I_DESCD LIKE '%"+ AllTrim(cDescr) +"%'   "
EndIf
cQuery += " ORDER BY B1_I_DESCD"
cQuery := ChangeQuery(cQuery)
TCQUERY cQuery NEW ALIAS "TRB1"

//=====================================================
// Limpa o array que apresenta os produtos na tela. 
//=====================================================
aGrd := {}

//=============================================================
// Processa o arquivo do select preenchendo o array do Grid. 
//=============================================================
DBSelectArea("TRB1")
DBGoTop()
While TRB1->(!Eof())
	
	aAdd(aGrd, {LoadBitmap(GetResources(),"BR_VERDE"),;
	bNbMarked 		,;
	TRB1->B1_COD	,;
	TRB1->B1_I_DESCD})
	
	TRB1->(DBSkip())
EndDo

If Len(aGrd) <= 0
	aGrd := {	{LoadBitmap(GetResources(),"BR_CINZA"),;
	bNbMarked,;
	"",;
	""}}
EndIf

DBSelectArea("TRB1")
DBCloseArea()

oBoxLib:SetArray(aGrd)
oBoxLib:bLine := {|| {aGrd[oBoxLib:nAt,1],;
aGrd[oBoxLib:nAt,2],;
aGrd[oBoxLib:nAt,3],;
aGrd[oBoxLib:nAt,4]}}
oBoxLib:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS024A
Autor-------------: Wodson Reis Silva
Data da Criacao---: 02/04/2009
===============================================================================================================================
Descrição---------: Funcao para marcar e desmarcar todos os titulos 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS024A()

Local nI    := 0
Local lMark := If(aGrd[1,2]==bMarked,.T.,.F.)

For nI := 1 To Len(aGrd)
	If (aGrd[nI,2] == bMarked)
		aGrd[nI,2] := If(lMark,bNbMarked,bMarked)
	Else
		aGrd[nI,2] := If(lMark,bNbMarked,bMarked)
	EndIf
Next

oBoxLib:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS024V()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/09/2019
===============================================================================================================================
Descrição---------: Validar a digitação do cliente e loja na tela de inclusão de produtos.
===============================================================================================================================
Parametros--------: _cCampo = Campo que chamou a validação.
                    _cCli   = Codigo de cliente.
					_cLoja  = Loja do cliente.
===============================================================================================================================
Retorno-----------: _lRet   = .T. / .F. 
===============================================================================================================================
*/
User Function AOMS024V(_cCampo,_cCli,_cLoja)
Local _lRet := .T.
Local _aOrd := SaveOrd({"SA1"})
Local _nRegAtu := SA1->(Recno())

Begin Sequence
   //=============================================
   // Valida a digitação do codigo do cliente.
   //=============================================
   If _cCampo == "COD_CLIENTE"
      If Empty(_cCli)
         Break
	  EndIf 

      SA1->(DBSetOrder(1))
      If ! Empty(_cLoja)
         If ! SA1->(DBSeek(xFilial("SA1")+_cCli+_cLoja)) 
            _lRet := .F.
            U_ITMsg("Código de Cliente e Loja não cadastrado no cadastro de clientes.","Atenção","",1) 
		 Else
            _cNomeCli := SA1->A1_NOME
		 EndIf
	  Else
         If ! SA1->(DBSeek(xFilial("SA1")+_cCli)) 
            _lRet := .F.
            U_ITMsg("Código de Cliente não cadastrado no cadastro de clientes.","Atenção","",1) 
		 Else
            _cNomeCli := SA1->A1_NOME
		 EndIf
	  EndIf
   Else
      //=============================================
	  // Valida a digitação da loja do cliente.
	  //=============================================
      If Empty(_cLoja)
         Break
	  EndIf 

      SA1->(DBSetOrder(1))
      If ! SA1->(DBSeek(xFilial("SA1")+_cCli+_cLoja)) 
         _lRet := .F.
         U_ITMsg("Código de Cliente e Loja não cadastrado no cadastro de clientes.","Atenção","",1) 
      Else
         _cNomeCli := SA1->A1_NOME
	  EndIf
   EndIf

End Sequence

RestOrd(_aOrd)
SA1->(DBGoTo(_nRegAtu))

Return _lRet

