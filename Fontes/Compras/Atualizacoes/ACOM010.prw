/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Jerry         |18/11/2020| Chamado 34696. Adicionar Filtro para não lista Comprador Bloqueado
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM010
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 25/09/2015                                   
Descrição---------: Fonte criado para geração da rotina que apresenta a Qtd SC x Compradores x Filiais.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM010()
Local cPerg		:= "ACOM010"

If Pergunte(cPerg,.T.)
	FWMsgRun( ,{|| ACOM010RU() }, , "Aguarde, processando informações...")
Else
	U_ITMsg(  'Operação cancelada pelo usuário!' ,'Atenção!' ,,1 )
EndIf

Return

/*
===============================================================================================================================
Programa----------: ACOM010RU
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 25/09/2015                                   .
Descrição---------: Função utilizada para geração das informações de Quantidade SC x Compradores x Filiais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM010RU()
Local cQrySY1	:= ""
Local cQrySC1	:= ""
Local cQryFil	:= ""
Local cRetorno  := ""  
Local cMapaPor   := ""
Local nX		:= 0
Local nQuant	:= 0
Local nQtdTot	:= 0
Local nItem		:= 0
Local nTotal	:= 0
Local _nI		:= 0
Local aDados	:= {}
Local aDadTot	:= {}
Local aCampos	:= {}
Local aFiliais  := {}
Local _nX		:= 0

aAdd(aCampos, "ÍNDICE")
aAdd(aCampos, "COMPRADOR")

//============================================================
// Query para montar Lista de Compradores com movimento de SC 
//============================================================

cQrySY1 := "SELECT DISTINCT Y1_COD, Y1_NOME, Y1_GRUPCOM, Y1_USER "
cQrySY1 += "FROM "+ RetSqlName("SC1") +" SC1, "+ RetSqlName("SY1") +" SY1 "
cQrySY1 += "WHERE SC1.D_E_L_E_T_ = ' ' "
cQrySY1 += "  AND C1_CODCOMP <> ' ' "
cQrySY1 += "  AND C1_RESIDUO <> 'S' "
cQrySY1 += "  AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' " 
cQrySY1 += "  AND Y1_FILIAL = '"+ xFilial("SY1") +"' "
cQrySY1 += "  AND Y1_COD = C1_CODCOMP "
cQrySY1 += "  AND Y1_MSBLQL <> '1' "
cQrySY1 += "  AND Y1_GRUPCOM BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
cQrySY1 += "  AND SY1.D_E_L_E_T_ = ' ' "
cQrySY1 += "ORDER BY Y1_GRUPCOM, Y1_COD "
cQrySY1 := ChangeQuery(cQrySY1)
MPSysOpenQuery(cQrySY1,"TRBSY1")

//============================================================
// Query para montar Lista de Filiais com movimento de SC 
//============================================================

cQryFil := "SELECT DISTINCT C1_FILIAL "
cQryFil += "FROM "+ RetSqlName("SC1") +" SC1, "+ RetSqlName("SY1") +" SY1 "
cQryFil += "WHERE SC1.D_E_L_E_T_ = ' ' "
cQryFil += "  AND C1_CODCOMP <> ' ' "
cQryFil += "  AND C1_RESIDUO <> 'S' "
cQryFil += "  AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
cQryFil += "  AND Y1_FILIAL = '"+ xFilial("SY1") +"' "
cQryFil += "  AND Y1_COD = C1_CODCOMP "
cQryFil += "  AND Y1_GRUPCOM BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
cQryFil += "  AND Y1_MSBLQL = '2' "
cQryFil += "  AND SY1.D_E_L_E_T_ = ' ' "
cQryFil += "ORDER BY C1_FILIAL "
cQryFil := ChangeQuery(cQryFil)
MPSysOpenQuery(cQryFil,"TRBFIL")

//==========================================================================================
// Montagem do Array com os Campos do Cabeçalho da Planilha e Array Filiais com movto de SC
//==========================================================================================
TRBFIL->(DBGoTop())      
While !TRBFIL->(Eof())
	
 	aAdd(aCampos, AllTrim(TRBFIL->C1_FILIAL) + " - " + AllTrim(Posicione('SM0',1,cEmpAnt+TRBFIL->C1_FILIAL,'M0_FILIAL') ))	
	aAdd(aFiliais, AllTrim(TRBFIL->C1_FILIAL))
		
    TRBFIL->(DBSkip())
End          

aAdd(aCampos, "TOTAL")
                               			
TRBSY1->(DBGoTop())
	
While !TRBSY1->(Eof())
	nItem++
	aAdd(aDados, StrZero(nItem,4))
	aAdd(aDados, AllTrim(TRBSY1->Y1_COD) + " - " + AllTrim(TRBSY1->Y1_NOME))

	For nX := 1 To Len(aFiliais)
                                                                   
		If MV_PAR08 == 1 //Por Qtd de SC
			cQrySC1 := "SELECT COUNT(*) TOTAL "
			cQrySc1 += " FROM (SELECT DISTINCT C1_CODCOMP,C1_NUM FROM " + RetSqlName("SC1") + " "
        Else //Por qtd Itens de SC
			cQrySC1 := "SELECT COUNT(*) TOTAL "
			cQrySC1 += "FROM " + RetSqlName("SC1") + " "
        EndIf
        
		cQrySC1 += "WHERE C1_FILIAL = '" + aFiliais[nX] + "' "
		cQrySC1 += "  AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		cQrySC1 += "  AND C1_CODCOMP = '" + TRBSY1->Y1_COD + "' "    
		
		If MV_PAR05 == 1 //Com Cotacao
			cQrySC1 += "  AND C1_COTACAO <> '" + Space(TamSX3("C1_COTACAO")[1]) + "' "
		ElseIf MV_PAR05 == 2
			cQrySC1 += "  AND C1_COTACAO = '" + Space(TamSX3("C1_COTACAO")[1]) + "' "
		EndIf
		If MV_PAR06 == 1 //Com PC
			cQrySC1 += "  AND C1_QUJE > 0 "
		ElseIf MV_PAR06 == 2
			cQrySC1 += "  AND C1_QUJE = 0 "
		EndIf
		If MV_PAR07 == 1 //Dt de Retorno Atrasada
			cQrySC1 += "  AND C1_I_DTRET < '" + DToS(Date()) + "'"
		ElseIf MV_PAR07 == 2
			cQrySC1 += "  AND C1_I_DTRET >= '" + DToS(Date()) + "'"
		EndIf
		
		cQrySC1 += "  AND C1_RESIDUO <>  'S' "
		cQrySC1 += "  AND D_E_L_E_T_ =  ' ' "

		If MV_PAR08 == 1 //Por Qtd de SC
			cQrySC1 += "ORDER BY C1_CODCOMP, C1_NUM) "   
		Else 
		    cQrySC1 += "ORDER BY C1_CODCOMP, C1_NUM "
	    EndIf           
		cQrySC1 := ChangeQuery(cQrySC1)
		MPSysOpenQuery(cQrySC1,"TRBSC1")

		TRBSC1->(DBGoTop())
			
		While !TRBSC1->(Eof())
			nQuant += TRBSC1->TOTAL
			TRBSC1->(DBSkip())
		End
		
		aAdd( aDados , nQuant )

		nQtdTot += nQuant
		nQuant	:= 0

		TRBSC1->(DBCloseArea())

	Next nX

	nTotal := nQtdTot
	aAdd( aDados , nQtdTot )
	nQtdTot := 0
	
	aAdd( aDadTot , aDados )
	aDados := {}
	
TRBSY1->(DBSkip())
End

TRBSY1->(DBCloseArea())
TRBFIL->(DBCloseArea())


If !Empty( aDadTot )
	
	aDados := Array( Len( aDadTot[01] ) )
	
	nItem++
	aDados[01] := StrZero(nItem,4)
	aDados[02] := 'TOTAL GERAL'
	
	For _nI := 3 To Len( aDados )
		aDados[_nI] := 0
	Next _nI
	
	For _nI := 1 To Len( aDadTot )
		
		For _nX := 3 To Len( aDados )
			
			aDados[_nX] += aDadTot[_nI][_nX]
			
		Next _nX
		
	Next _nI
	
	aAdd( aDadTot , aDados )
	
	For _nI := 1 To Len(aDadTot)
		
		For _nX := 3 To Len( aDadTot[_nI] )
			
			aDadTot[_nI][_nX] := AllTrim( Transform( aDadTot[_nI][_nX] , PesqPict('SC1','C1_QUANT') ) )
			
		Next _nX
		
	Next _nI
	
EndIf

//===============================================================
// Montagem do Cabeçalho da Lista conforme parâmetro selecionados
//===============================================================

If MV_PAR07 == 1 //Dt de Retorno Atrasada
	cRetorno := " - Retorno Atrasado "
ElseIf MV_PAR07 == 2
	cRetorno := " - Retorno em Dia"
EndIf

If MV_PAR08 == 1 //Por Qtd de SC
	cMapaPor := " - Por Qtd de SC" 
Else 
	cMapaPor := " - Por Qtd de Itens de SC" 
EndIf

If Len(aDadTot) > 0
	U_ITListBox( "Quantidade de SC's por Comprador x Filiais "+cRetorno + cMapaPor , aCampos , aDadTot , .T. , 1 )
Else
	U_ITMsg("Não foram localizados dados com os filtros selecionados!","Atenção",,1)
EndIf

Return
