/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/07/2017| Chamado 20599. Ajuste para filtrar fornecedor quando as NFs forem de de devolução
Josué Danich  |13/07/2017| Chamado 20753. Revisão completa para versão 12
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"
#Include "TopConn.ch"
#Include "Fileio.ch"

#Define CLRF Chr(13)+Chr(10)

/*
===============================================================================================================================
Programa----------: MOMS002
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 24/06/2009
===============================================================================================================================
Descrição---------: Geracao de arquivo de informacoes de notas fiscais de Pallet para envio ao controle de Pallet CHEP.  
===============================================================================================================================
Parâmetros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS002()

Local cQry			:= ""
Local cCodProd		:= AllTrim(GetMV("IT_CCHEP"))
	
Private cCodOrig	:= AllTrim(GetMV("IT_CODCHEP"))
Private cCodEmp		:= AllTrim(GetMV("IT_EMPCHEP"))
	
Private cPerg		:= "MOMS002"
Private aNotas		:= {}
Private cChave		:= ""
Private nTotReg		:= 0
Private aNotMark	:= {}
	
Private nQtPalet	:= 0
Private nQtMov		:= 0

U_ITLOGACS() //Grava log de utilização

	While Pergunte(cPerg,.T.)

        If  (!Empty(MV_PAR01+MV_PAR02) .Or. !Empty(MV_PAR03+MV_PAR04)) .And. (!Empty(MV_PAR09+MV_PAR10) .Or. !Empty(MV_PAR11+MV_PAR12))
            MSGSTOP("Informe somente o filtro inicial e final do Cliente / Loja ou somente do Fornecedor / Loja, ou deixe todos os campos em branco do Fornecedor / Loja e do Cliente / Loja para trazer todos.","MOMS002")
            Loop
        EndIf

 		cQry := "SELECT D2_SERIE, D2_DOC, D2_EMISSAO, D2_CLIENTE, D2_LOJA, B1_I_CPCHE, D2_TIPO"//, A1_NREDUZ A1_I_CCHEP, 
		
		//Abate devolucao
		If MV_PAR08 == 1    
		   cQry += ", D2_QUANT-(SELECT COALESCE(SUM(D1.D1_QUANT),0) FROM " + RETSQLNAME("SD1") + " D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1.D1_FILIAL = D2.D2_FILIAL AND D1.D1_NFORI = D2.D2_DOC AND D1.D1_SERIORI = D2.D2_SERIE) D2_QUANT"
        Else
		   cQry += ", D2_QUANT"
		EndIf            

		
		cQry += " FROM " + RETSQLNAME("SD2") + " D2, " + RETSQLNAME("SB1") + " B1 " //, " + RetSQLName("SA1") + " a1"
		cQry += " WHERE ( D2.D_E_L_E_T_ = ' ' AND B1.D_E_L_E_T_ = ' ' ) "// and a1.d_e_l_e_t_ = ' ')"
//		cQry += " and (d2_cliente = a1_cod and d2_loja = a1_loja)"
		cQry += " AND (D2_COD = B1_COD)"
//		cQry += " and (a1_filial = '" + xFilial("SA1") + "')"
		cQry += " AND (D2_FILIAL = '" + xFilial("SD2") + "')"

        If !Empty(MV_PAR01+MV_PAR02) .Or. !Empty(MV_PAR03+MV_PAR04)
		   cQry += " AND (D2_CLIENTE BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR03 + "')"
		   cQry += " AND (D2_LOJA BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR04 + "')"

        ElseIf !Empty(MV_PAR09+MV_PAR10) .Or. !Empty(MV_PAR11+MV_PAR12)
		   cQry += " AND (D2_CLIENTE BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR11 + "')"
		   cQry += " AND (D2_LOJA BETWEEN '" + MV_PAR10 + "' AND '" + MV_PAR12 + "')"

        EndIf



		cQry += " AND (D2_EMISSAO BETWEEN '" + DToS(MV_PAR06) + "' AND '" + DToS(MV_PAR07) + "')"
		cQry += " AND (D2_COD = '" + AllTrim(cCodProd) + "' AND B1_I_CPCHE <> ' ')"




	
		If MV_PAR08 == 1

		   cQry += " AND D2_QUANT - (SELECT COALESCE(SUM(D1.D1_QUANT),0) FROM " + RETSQLNAME("SD1") + " D1 WHERE D1.D_E_L_E_T_ = ' ' AND D1.D1_FILIAL = D2.D2_FILIAL AND D1.D1_NFORI = D2.D2_DOC AND D1.D1_SERIORI = D2.D2_SERIE) > 0"

		EndIf

		If Select("TRAB") > 0
			TRAB->(DBCloseArea())

	
	EndIf

	TCQUERY cQry NEW ALIAS "TRAB"
		
	While  !TRAB->(Eof())
            If TRAB->D2_TIPO # "D"
               _cAliasBusca:="SA1"
               _cCampoBusca:="A1_NREDUZ"
               _CCHEP:=AllTrim(Posicione(_cAliasBusca,1,xFilial(_cAliasBusca)+TRAB->D2_CLIENTE+TRAB->D2_LOJA,"A1_I_CCHEP"))
               _cNome:=""
            Else
               _cAliasBusca:="SA2"
               _cCampoBusca:="A2_NREDUZ"
               _CCHEP:=Space(10)
               _cNome:=" [D]"
            EndIf
            _cNome:=AllTrim(Posicione(_cAliasBusca,1,xFilial(_cAliasBusca)+TRAB->D2_CLIENTE+TRAB->D2_LOJA,_cCampoBusca))+_cNome
			aAdd(aNotas,{	.F.,;
							TRAB->D2_DOC,;
							TRAB->D2_SERIE,;
							TRAB->D2_EMISSAO,;
							TRAB->D2_CLIENTE,;
							TRAB->D2_LOJA,;
							_cNome,;
							_CCHEP,;
							TRAB->B1_I_CPCHE,;
							TRAB->D2_QUANT })

							
			cChave		+= TRAB->d2_doc
			nTotReg++
			
			aAdd(aNotMark, TRAB->d2_serie + " - " + DToC(SToD(TRAB->d2_emissao)) + " - " +;
								TRAB->D2_CLIENTE + " - " + TRAB->D2_LOJA + " - " + _cNome + " - " +;
								AllTrim(Transform(TRAB->d2_quant,"@E 9,999")) )

		TRAB->(DBSkip())
	
	EndDo

	TRAB->(DBCloseArea())


	If 	MOMS002S() .And. MOMS002T() 
	
			Processa({|| MOMS002P() },"Processando...")
        Else
           Loop
		EndIf
	
		Exit
		
	EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS002t
Autor-------------: Rafael Ramos Lavinas
Data da Criacao---: 24/07/2008
===============================================================================================================================
Descrição---------: Tela para apresentacao das notas fiscais baseadas nas perguntas "MOMS002"
===============================================================================================================================
Parâmetros--------: Nenhum
===============================================================================================================================
Retorno-----------: lret - Lógico indicando se tela foi confirmada ou cancelada
===============================================================================================================================
*/

Static Function MOMS002T()

Local lRet		:= .F.,I
Local aNFImp	:= {}
	
Private _oDlg
Private olbNotas

DEFINE MSDIALOG _oDlg TITLE "Geração - EDI CHEP" FROM 178,181 TO 435,700 PIXEL

	// Cria as Groups do Sistema
	@ 001,003 TO 114,259 LABEL " Notas selecionadas: " PIXEL OF _oDlg

	// Cria Componentes Padroes do Sistema
	@ 115,183 Button "OK" Size 037,012 PIXEL OF _oDlg ACTION (lRet := .T.,_oDlg:End())
	@ 115,221 Button "Cancelar" Size 037,012 PIXEL OF _oDlg ACTION (_oDlg:End())

	@ 010,007 ListBox olbNotas Fields ;
		HEADER "Num. NF","Serie","Emissão","Cod./Loja Cliente","Nome Fantasia","Cod. Origem","Cod. Destino","Quantidade";
		Size 246,098 Of _oDlg Pixel ColSizes 35,25,30,50,100,40,40,40

	olbNotas:SetArray(aNFImp)

// Carregue aqui sua array da Listbox
For i := 1 to Len(aNotas)
	If (aNotas[i][1])
			aAdd(aNFImp, {	aNotas[i][2],;
							aNotas[i][3],;
							DToC(SToD(aNotas[i][4])),;
							aNotas[i][5]+ "/" + aNotas[i][6],;
							AllTrim(aNotas[i][7]),;
							cCodOrig,;
							aNotas[i][5]+ aNotas[i][6],;//aNotas[i][8],;
							TransForm(aNotas[i][10],"@E 9,999") })

			nQtPalet	+= aNotas[i][10]
			nQtMov++

	EndIf
Next
	
If (Len(aNFImp) == 0)
	aAdd(aNFImp, {"","","","","","","",""})
EndIf

olbNotas:bLine := {|| {;
		aNFImp[olbNotas:nAT,01],;
		aNFImp[olbNotas:nAT,02],;
		aNFImp[olbNotas:nAT,03],;
		aNFImp[olbNotas:nAT,04],;
		aNFImp[olbNotas:nAT,05],;
		aNFImp[olbNotas:nAT,06],;
		aNFImp[olbNotas:nAT,07],;
		aNFImp[olbNotas:nAT,08]}}

ACTIVATE MSDIALOG _oDlg CENTERED 

Return (lRet)

/*
===============================================================================================================================
Programa----------: MOMS002P
Autor-------------: Frederico O. C. Jr 
Data da Criacao---: 25/06/2009 
===============================================================================================================================
Descrição---------: Funcao para geracao do arquivo texto. 
===============================================================================================================================
Parâmetros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS002P()

Local cArqTxt 	:= 	""
Local cEOL    	:= 	CHR(13)+CHR(10)
Local nHdl
Local i
	
Local nTamLin, cLin, cCpo

// Criacao do aquivo a ser gerado o EDI CHEP
cArqTxt := AllTrim(MV_PAR05) + cCodEmp + ".txt"
nHdl	:= FCreate(cArqTxt, FC_NORMAL,,.T.)
			
If nHdl < 1

	U_ITMsg("O arquivo de nome [" + cCodEmp + ".txt] nao pode ser gerado! Verifique os parametros.","Atencao!",,1)

Else
	
	ProcRegua( Len(aNotas) + 2)
	
	// Impressao do Cabecalho
	nTamLin :=	72
	cLin    := 	Space(nTamLin) // Variavel para criacao da linha do registros para gravacao
	
	// Constante que indica que eh "Cabecalho"
	cCpo 	:= 	PadR("H1",02)
	cLin 	:= 	Stuff(cLin,01,02,cCpo)
		
	// Codigo Poolnet da empresa que envia a informacao
	cCpo	:= 	PadR("00" + cCodEmp,10)
	cLin 	:=	Stuff(cLin,03,12,cCpo)

	// Somatoria total das quantidades
	cCpo 	:=	PadR(StrZero(nQtPalet,5),5)
	cLin 	:=	Stuff(cLin,13,17,cCpo)
		
	// Numero total de movimentos
	cCpo	:= 	PadR(StrZero(nQtMov,5),5)
	cLin 	:= 	Stuff(cLin,18,22,cCpo)
		
	// Uso Interno (CHEP)
	cCpo	:= 	PadR(Replicate("0",30),30)
	cLin 	:= 	Stuff(cLin,23,52,cCpo)

	// Data inicial e final do periodo informado
	cCpo	:= 	PadR(SubStr(DToS(MV_PAR06),7,2) + "/" + SubStr(DToS(MV_PAR06),5,2) + "/" + SubStr(DToS(MV_PAR06),1,4) +;
					SubStr(DToS(MV_PAR07),7,2) + "/" + SubStr(DToS(MV_PAR07),5,2) + "/" + SubStr(DToS(MV_PAR07),1,4),20)
	cLin 	:= 	Stuff(cLin,53,72,cCpo)

	cLin	+= cEOL
		
	FWrite(nHdl,cLin,Len(cLin))
	IncProc()
		
	// Impressao dos Itens
	For i := 1 to Len(aNotas)
		If aNotas[i][1]

			nTamLin :=	95
			cLin    := 	Space(nTamLin) // Variavel para criacao da linha do registros para gravacao
			
			// Constante que indica que eh "Detalhe"
			cCpo 	:= 	PadR("D1",02)
			cLin 	:= 	Stuff(cLin,01,02,cCpo)
				
			// Constante que indica que o movimento foi emitido ou cancelado
			cCpo	:= 	PadR("E",1)
			cLin 	:=	Stuff(cLin,03,03,cCpo)
		
			// Numero de nota
			cCpo 	:=	PadR(StrZero(Val(aNotas[i][2]),20),20)
			cLin 	:=	Stuff(cLin,04,23,cCpo)
				
			// Data do Movimento
			cCpo	:= 	PadR(SubStr(aNotas[i][4],7,2) + "/" + SubStr(aNotas[i][4],5,2) + "/" + SubStr(aNotas[i][4],1,4),10)
			cLin 	:= 	Stuff(cLin,24,33,cCpo)
				
			// Codigo CHEP do recinto origem
			cCpo	:= 	PadL(cCodOrig,10)
			cLin 	:= 	Stuff(cLin,34,43,cCpo)

			// Codigo CHEP do recinto destino
			cCpo	:= 	PadL(AllTrim(aNotas[i][5]+aNotas[i][6]),10)//PadL(AllTrim(aNotas[i][8]),10)// 24/01/14 - Talita Teixeira -  Alterado geração do arquivo CHEP para em vez de trazer o codigo chep trazer a juncao do Codigo do Cliente+Loja. Chamado: 5293
			cLin 	:= 	Stuff(cLin,44,53,cCpo)

			// Codigo CHEP do produto
			cCpo	:= 	PadR(aNotas[i][9],7)
			cLin 	:= 	Stuff(cLin,54,60,cCpo)

			// Quantidade de produto
			cCpo	:= 	PadR(StrZero(aNotas[i][10],5),5)
			cLin 	:= 	Stuff(cLin,61,65,cCpo)
			
			// Comentarios (Opcional)
			cCpo	:= 	PadR(Replicate(" ",30),30)
			cLin 	:= 	Stuff(cLin,66,95,cCpo)

			cLin	+= cEOL
		
			FWrite(nHdl,cLin,Len(cLin))

		EndIf
			
		IncProc()
	Next
		
	// Impressao do Rodape
	nTamLin :=	24
	cLin    := 	Space(nTamLin) // Variavel para criacao da linha do registros para gravacao
	
	// Constante que indica que eh "Rodape"
	cCpo 	:= 	PadR("F1",02)
	cLin 	:= 	Stuff(cLin,01,02,cCpo)
		
	// Somatoria total das quantidades
	cCpo 	:=	PadR(StrZero(nQtPalet,5),5)
	cLin 	:=	Stuff(cLin,03,07,cCpo)
		
	// Uso Interno (CHEP)
	cCpo	:= 	PadR(Replicate("0",7),7)
	cLin 	:= 	Stuff(cLin,08,14,cCpo)

	// Numero total de movimentos
	cCpo	:= 	PadR(StrZero(nQtMov,5),5)
	cLin 	:= 	Stuff(cLin,15,19,cCpo)

	// Total de registros (inclui cabeceira e rodape)
	cCpo	:= 	PadR(StrZero(nQtMov+2,5),5)
	cLin 	:= 	Stuff(cLin,20,24,cCpo)

	cLin	+= cEOL
		
	FWrite(nHdl,cLin,Len(cLin))
	IncProc()
		
	FClose(nHdl)
	
	U_ITMsg("Arquivo " + cArqTxt + " gerado com sucesso","Processo completado",,2)
		
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS002S
Autor-------------: Frederico O. C. Jr 
Data da Criacao---: 12/06/2009 
===============================================================================================================================
Descrição---------: Programa para selecao das notas a serem geradas no EDI do Carrefour 
===============================================================================================================================
Parâmetros--------: Nenhum
===============================================================================================================================
Retorno-----------: Sempre .T.  Prepara Array em Private com as notas a serem geradas no EDI do Carrefour    
===============================================================================================================================
*/

Static Function MOMS002S()

Local i				:= 0
Local nPos			:= 0

Private nTam		:= 9
Private nMaxSelect	:= nTotReg
Private cRet		:= ""
Private cTitulo		:= "Seleção de Notas - EDI CHEP"
	
#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Executa funcao que monta tela de opcoes
f_Opcoes(@cRet,cTitulo,aNotMark,cChave,12,49,.F.,nTam,nMaxSelect)
	
//Retorno
cRet	:= AllTrim(StrTran(cRet,"*",""))
	
For i := 1 to (Len(cRet)/9)
	                           
	nPos := aScan(aNotas,{|x| AllTrim(x[2]) == SubStr(cRet, 1+(9*(i-1)), 9)})
		
	If (nPos <> 0)
		aNotas[nPos][1] := .T.
	EndIf
	
Next
	
Return !Empty(cRet)
