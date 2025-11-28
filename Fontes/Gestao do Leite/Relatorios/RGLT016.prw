/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Heder José    |08/12/2009| Acerto posicionamento das colunas.
Lucas Borges  |03/07/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |05/07/2019| Chamado 29880. Corrigido valores duplicados.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT016
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Folha a pagar do Fretista - Lista os Fretistas com seus eventos e respectivos valores totalizando o valor 
					liquido a pagar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT016

Local cDesc1			:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2			:= "de acordo com os parametros informados pelo usuario."
Local cDesc3			:= "Folha a Pagar do Fretista   "
Local titulo			:= "Folha a Pagar do Fretista   "
Local nLin				:= 80
Local Cabec1			:= " "
Local Cabec2			:= ""
Local aOrd				:= {}
Private Tamanho			:= "G"
Private NomeProg		:= "RGLT016" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo			:= 18
Private aReturn			:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey		:= 0
Private m_pag			:= 01
Private wnrel			:= "RGLT016" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cPerg			:= "RGLT016"
Private cString			:= "ZLF"

Pergunte("RGLT016",.F.)

wnrel := SetPrint(cString,NomeProg,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,Tamanho,,.T.)

If nLastKey == 27
	Return
EndIf

SetDefault(aReturn,cString)

If nLastKey == 27
	Return
EndIf

nTipo := If(aReturn[4]==1,15,18)
RptStatus({|| RunReport(Cabec1,Cabec2,Titulo,nLin) },Titulo)

Return

/*
===============================================================================================================================
Programa----------: RUNREPORT
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Funcão auxiliar chamada pela RPTSTATUS. A função RPTSTATUS monta a janela com a régua de processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

Local _cAlias	:= GetNextAlias()
Local _nX		:= 0
Local nTotDeb	:= 0
Local nTotCre	:= 0
Local nAux		:= 0
Local cUltFret	:= ""
Local nqtdregs	:= 0 
Local nTotVolGer:= 0
Local  nLiq		:= 0
Local dt1,dt2

Private nTamCmp	:= 11
Private aSubTots	:= {}
Private nSubVol	:= 0
Private nSubKm	:= 0
Private nSubDia	:= 0
Private nSubLiq	:= 0
Private nPos1	:= 0
Private nMaxCol	:= 12 // maximo de colunas
Private nMaxLin	:= 60 // maximo de linhas
Private nOutros	:= 0
Private aStruct	:= {}

Private nQtdLin:=0

// posiciona no Mix pra pegar datas
DBSelectArea("ZLE")
ZLE->(DBSetOrder(1))
ZLE->(DBSeek(xFilial("ZLE")+MV_PAR02))
dt1:=ZLE->ZLE_DTINI
dt2:=ZLE->ZLE_DTFIM
ZLE->(DBCloseArea())

Cabec1 := "Setor: "+MV_PAR01+" Mix: "+MV_PAR02

nLin := nMaxLin

// obtem campos dinamicos (eventos)
BeginSql alias _cAlias
	SELECT ZL8.ZL8_COD, ZL8.ZL8_NREDUZ
	  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND ZL8.D_E_L_E_T_ = ' '
	   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
	   AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
	   AND ZLF.ZLF_SETOR = %exp:MV_PAR01%
	   AND ZLF.ZLF_CODZLE = %exp:MV_PAR02%
	   AND ZLF.ZLF_TP_MIX = 'F'
	 GROUP BY ZL8.ZL8_COD, ZL8.ZL8_NREDUZ
	 ORDER BY ZL8.ZL8_COD
EndSql

While !(_cAlias)->(Eof())
	aAdd(aStruct,{(_cAlias)->ZL8_COD,(_cAlias)->ZL8_NREDUZ,0})
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

// zera subtotal
For _nX:=1 To Len(aStruct)
	aAdd(aSubTots,0)
Next _nX

// cabecalho
Cabec2:=PadR("CODIGO LINHA",29)
Cabec2+=PadR("VOLUME",10)
Cabec2+=PadR("KM RODADO",10)
Cabec2+=PadR("VIAGENS",9)
For _nX:=1 To Len(aStruct)		
	If _nX<=nMaxCol
		Cabec2 += PadR(aStruct[_nX,2],nTamCmp)
	EndIf
	If _nX == Len(aStruct)
		Cabec2 += PadR("OUTROS",nTamCmp)
	EndIf
Next _nX

Cabec2:=PadR(Cabec2,206)
Cabec2+="VLR LIQUIDO"

_cAlias := GetNextAlias()
// obtem fretistas que movimentaram
BeginSql alias _cAlias
SELECT ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLD.ZLD_LINROT, ZL3.ZL3_DESCRI, SA2.A2_NOME
  FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL3% ZL3
 WHERE ZLD.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
   AND SA2.A2_FILIAL = %xFilial:SA2%
   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
   AND ZLD.ZLD_FRETIS = SA2.A2_COD
   AND ZLD.ZLD_LJFRET = SA2.A2_LOJA
   AND ZLD.ZLD_LINROT = ZL3.ZL3_COD
   AND ZLD.ZLD_SETOR = %exp:MV_PAR01%
   AND ZLD.ZLD_DTCOLE BETWEEN %exp:dt1% AND %exp:dt2%
   AND ZLD.ZLD_FRETIS BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
   AND ZLD.ZLD_LJFRET BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
   AND ZLD.ZLD_LINROT BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
 GROUP BY ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLD.ZLD_LINROT, ZL3.ZL3_DESCRI, SA2.A2_NOME
 ORDER BY ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLD.ZLD_LINROT
EndSql

COUNT To nqtdregs
SetRegua(nqtdregs)

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())

	IncRegua()

    If nLin >= nMaxLin 
   		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
   		nLin := 9
	EndIf

	//Mostra Cabeçalho(Linha e Fretista)
	If cUltFret != (_cAlias)->(ZLD_FRETIS+ZLD_LJFRET)

		nLin := showSubTotal(nLin)
		
		@ nLin,000 PSay __PrtThinLine()
		nLin++

		If MV_PAR09 == 1 // Quebra Pagina? 1=sim 2=nao
			Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			nLin := 9
		EndIf

		@nLin,000 PSay "Fretista: "+(_cAlias)->ZLD_FRETIS+"-"+(_cAlias)->ZLD_LJFRET+" "+(_cAlias)->A2_NOME
		nLin++
	EndIf
	cUltFret:= (_cAlias)->(ZLD_FRETIS+ZLD_LJFRET)

	//Mostra produtor e seus respectivos valores
	@nLin,000 PSay (_cAlias)->ZLD_LINROT+" "+Left((_cAlias)->ZL3_DESCRI,15)
	
	//Volume de leite coletado
	nAux := U_VolFret(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,dt1,dt2,1)
	nSubVol   += nAux
	nTotVolGer+= nAux //Totalizador Geral do volume de leite
	
	@nLin,025 PSay nAux Picture "@E 99,999,999"

	//Km rodado
	nAux:= U_GetKm(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,dt1,dt2)
	nSubKm += nAux
	@nLin,038 PSay nAux Picture "@E 99,999,999"
	
	// Viagens realizadas (dias)
	nAux:= U_getDiaFrt(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,dt1,dt2)
	nSubDia += nAux
	@nLin,046 PSay nAux Picture "@E 99,999,999"

	// conta qtd de linhas por fretista
	nQtdLin++
	
	nPos1:=58
	For _nX:=1 To Len(aStruct)
		nVlrEvt := u_getEvtFrt(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,aStruct[_nX,1],MV_PAR02)
		aStruct[_nX,3] += nVlrEvt // total geral
		If _nX <= nMaxCol
			@nLin,nPos1 PSay nVlrEvt Picture "@E 999,999.99"
			nPos1 += nTamCmp
			aSubTots[_nX] += nVlrEvt // subtotal
		Else
			nOutros += nVlrEvt
		EndIf
		If _nX == Len(aStruct) .And. nOutros <> 0
			@nLin,nPos1 PSay nOutros Picture "@E 999,999.99"
			nPos1 += nTamCmp
			aSubTots[_nX] += nOutros // subtotal
		EndIf
		nLiq += nVlrEvt
		nSubLiq += nVlrEvt
	Next _nX

	// MOSTRA VLR LIQUIDO
	@nLin,205 PSay nLiq Picture "@E 99,999,999.99"
	nLiq := 0
	nOutros := 0

 	nLin++

	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

nLin := showSubTotal(nLin)

@ nLin,000 PSay __PrtThinLine()
nLin++

If MV_PAR09 == 1 // Quebra Pagina? 1=sim 2=nao
	Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin := 9
EndIf

@nLin,000 PSay "Resumo Geral"
nLin += 2

@nLin,000 PSay "Codigo"
@nLin,008 PSay "Evento"
@nLin,030 PSay "Creditos"
@nLin,050 PSay "Debitos"
nLin++

@nLin,000 PSay Replicate("-",60)
nLin++
For _nX:=1 To Len(aStruct)
	@nLin,000 PSay aStruct[_nX,1]
	@nLin,008 PSay aStruct[_nX,2]
	If aStruct[_nX,3] >= 0
		@nLin,020 PSay aStruct[_nX,3] Picture "@E 999,999,999,999.99"
		nTotCre+=aStruct[_nX,3]
	Else
		@nLin,040 PSay aStruct[_nX,3] Picture "@E 999,999,999,999.99"
		nTotDeb+=aStruct[_nX,3]
	EndIf
	nLin++

	If nLin > nMaxLin
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 9
	EndIf
Next _nX

@nLin,000 PSay Replicate("-",60)
nLin++
@nLin,000 PSay "Total"
@nLin,020 PSay nTotCre Picture "@E 999,999,999,999.99"
@nLin,040 PSay nTotDeb Picture "@E 999,999,999,999.99"
nLin++
@nLin,000 PSay "Valor Liquido"

If (nTotcre+ntotDeb) >= 0
	@nLin,020 PSay (nTotcre+ntotDeb) Picture "@E 999,999,999,999.99"
Else
	@nLin,040 PSay (nTotcre+ntotDeb) Picture "@E 999,999,999,999.99"
EndIf

nLin++

@ nLin,000 PSay __PrtThinLine()

//Imprime o totalizador Geral
nLin += 2
@nLin,000 PSay "Volume Total: "   + AllTrim(Transform(nTotVolGer,"@E 999,999,999,999"))
@nLin,100 PSay "Custo P/ Litro: " + AllTrim(Transform(nTotCre/nTotVolGer,"@E 999,999,999,999.9999"))

nLin++

Set Device To Screen

If aReturn[5]==1
	dbCommitAll()
	Set Printer To
	OurSpool(wnrel)
EndIf

MS_FLUSH()

Return

/*
===============================================================================================================================
Programa----------: showSubTotal
Autor-------------: Abrahao P. Santos
Data da Criacao---: 11/12/2008
Descrição---------: Imprime subtotal do fretista
Parametros--------: nLin
Retorno-----------: nLin
===============================================================================================================================
*/
Static Function showSubTotal(nLin)

Local _nX	:= 0

If nQtdLin > 1
	@nlin,000 PSay "Subtotal"+Replicate(".",15)
	@nlin,025 PSay nSubVol Picture "@E 99,999,999"
	@nlin,038 PSay nSubKm Picture  "@E 99,999,999"
	@nlin,046 PSay nSubDia Picture "@E 99,999,999"
	nPos1:=58
	For _nX:=1 To Len(aStruct)
		If _nX <= nMaxCol
			@nLin,nPos1 PSay aSubTots[_nX] Picture "@E 999,999.99"
			nPos1 += nTamCmp
		EndIf
		If _nX == Len(aStruct) .And. nOutros <> 0
			@nLin,nPos1 PSay aSubTots[_nX] Picture "@E 999,999.99"
			nPos1 += nTamCmp
		EndIf
		aSubTots[_nX]:=0
	Next _nX
	@nLin,205 PSay nSubLiq Picture "@E 99,999,999.99"
	nLin++
EndIf

For _nX:=1 To Len(aSubTots)
	aSubTots[_nX]:=0
Next _nX

nQtdLin:=0
nSubVol:=0
nSubKm :=0
nSubDia:=0
nSubLiq:=0

Return nLin
