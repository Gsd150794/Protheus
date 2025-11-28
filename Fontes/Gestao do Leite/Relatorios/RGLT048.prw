/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |25/10/2017| Chamado 22184. Compatibilização do fonte nas normas da P12 e correção nos totalizadores
Lucas Borges  |21/06/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT048
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 20/04/2011
Descrição---------: Folha a pagar Fretista - Lista os Fretistas com seus eventos e respectivos valores totalizando o valor 
					liquido a pagar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT048()

Local cDesc1			:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2			:= "de acordo com os parametros informados pelo usuario."
Local cDesc3			:= "Folha a Pagar do Fretista   "
Local titulo			:= "Folha a Pagar do Fretista   "
Local Cabec1			:= " "
Local Cabec2			:= ""
Local aOrd				:= {}

Private nLin			:= 80
Private Tamanho			:= "G"
Private NomeProg		:= "RGLT048" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo			:= 18
Private aReturn			:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey		:= 0
Private m_pag			:= 01
Private wnrel			:= "RGLT048" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cPerg			:= "RGLT048"
Private cString			:= "ZLF"

pergunte("RGLT048",.F.)

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
Programa----------: RunReport
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 20/04/2011
Descrição---------: Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS monta a janela com a regua de processamento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RunReport(Cabec1,Cabec2,Titulo,nLin)

Local nAux		:= 0
Local cUltFret	:=""
Local nqtdregs	:=0
Local nTotVolGer:=0
Local _nX 		:= 0
Local _cAlias   := GetNextAlias()
Local _nPosicao	:= 0 
Local _nLiq 	:= 0
Local dt1,dt2

Private nTotDeb:=0
Private nTotCre:=0
Private nTamCmp := 11
Private aSubTots := {}
Private nSubVol := 0
Private nSubKm := 0
Private nSubDia := 0
Private nSubLiq := 0
Private nPos1 := 0
Private nMaxCol := 12 // maximo de colunas
Private nMaxLin := 60 // maximo de linhas
Private nOutros := 0
Private nQtdLin:=0
Private aStruct := {}
Private _aAux   := {}

// posiciona no Mix pra pegar datas
DBSelectArea("ZLE")
ZLE->( DBSetOrder(1) )
ZLE->( DBSeek( xFilial("ZLE") + MV_PAR02 ) )
	dt1:=ZLE->ZLE_DTINI
	dt2:=ZLE->ZLE_DTFIM
ZLE->(DBCloseArea())

Cabec1 := "Setor: "+MV_PAR01+" Mix: "+MV_PAR02 + " De: " + DToC(dt1) + ' ?' + DToC(dt2)

nLin := nMaxLin

// obtem campos dinamicos (eventos)
aStruct := getStruct(MV_PAR01,MV_PAR02)

// zera subtotal
For _nX:=1 To Len(aStruct)
	aAdd(aSubTots,0)
Next

// cabecalho
Cabec2:=PadR("CODIGO LINHA",29)
Cabec2+=PadR("VOLUME",10)
Cabec2+=PadR("KM RODADO",10)
Cabec2+=PadR("VIAGENS",9)

For _nX:=1 To Len(aStruct)
	If _nX<=nMaxCol
		Cabec2 += PadR(aStruct[_nX,2],nTamCmp)
	EndIf
	If _nX==Len(aStruct)
		Cabec2 += PadR("OUTROS",nTamCmp)
	EndIf
Next _nX

Cabec2:=PadR(Cabec2,206)
Cabec2+="VLR LIQUIDO"

BeginSql Alias _cAlias
	SELECT ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLD.ZLD_LINROT
   FROM %Table:ZLD% ZLD
  WHERE ZLD.D_E_L_E_T_ = ' '
    AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
    AND ZLD.ZLD_SETOR = %Exp:AllTrim(MV_PAR01)%
	AND ZLD.ZLD_DTCOLE BETWEEN %Exp:DToS(dt1)% AND %Exp:DToS(dt2)%
	AND ZLD.ZLD_FRETIS BETWEEN %Exp:MV_PAR03%  AND %Exp:MV_PAR05%
	AND ZLD.ZLD_LJFRET BETWEEN %Exp:MV_PAR04%  AND %Exp:MV_PAR06%
	AND ZLD.ZLD_LINROT BETWEEN %Exp:MV_PAR07%  AND %Exp:MV_PAR08%
	AND ZLD.ZLD_FRETIS <> ' '
  GROUP BY ZLD_FRETIS,ZLD_LJFRET,ZLD_LINROT
  ORDER BY ZLD_FRETIS,ZLD_LJFRET,ZLD_LINROT
EndSql

COUNT To nqtdregs
setRegua(nqtdregs)

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())

	IncRegua()

    If nLin >= nMaxLin 
   		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
   		nLin := 9
	EndIf

	// MOSTRA CABECALHO (LINHA E FRETISTA)
	If cUltFret != (_cAlias)->(ZLD_FRETIS+ZLD_LJFRET)

		If  Len(AllTrim(cUltFret)) > 0

			nLin := showSubTotal(nLin)
			nLin:= prtResumo(Cabec1,Cabec2,Titulo,nLin)
			_aAux := {}
			nTotDeb:=0
			nTotCre:=0 

			//Forca a quebra de pagina
			nLin :=1000
			If nLin >= nMaxLin 
				Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
			   	nLin := 9
			EndIf

		EndIf

		@nLin,000 PSAY "Fretista: "+(_cAlias)->ZLD_FRETIS+"-"+(_cAlias)->ZLD_LJFRET+" "+Posicione("SA2",1,xFilial("SA2")+(_cAlias)->(ZLD_FRETIS+ZLD_LJFRET),"A2_NOME")
		nLin++
		nLin++
	EndIf

	cUltFret:= (_cAlias)->(ZLD_FRETIS+ZLD_LJFRET)

	// MOSTRA PRODUTOR E SEUS RESPECTIVOS VALORES
	@nLin,000 PSAY (_cAlias)->ZLD_LINROT+" "+LEFT(Posicione("ZL3",1,xFilial("ZL3")+(_cAlias)->ZLD_LINROT,"ZL3_DESCRI"),15)

	// Volume de leite coletado
	nAux := U_VolFret(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,dt1,dt2,1)
	nSubVol   += nAux
	nTotVolGer+= nAux //Totalizador Geral do volume de leite
	
	@nLin,025 PSAY nAux Picture "@E 99,999,999"

	// Km RODADO
	nAux:= U_GetKm(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,dt1,dt2)
	nSubKm += nAux
	@nLin,038 PSAY nAux Picture "@E 99,999,999"
	
	// Viagens realizadas (dias)
	nAux:= u_getDiaFrt(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,dt1,dt2)
	nSubDia += nAux
	@nLin,046 PSAY nAux Picture "@E 99,999,999"

	// conta qtd de linhas por fretista
	nQtdLin++

	nPos1:=58
	For _nX:=1 To Len(aStruct)

		nVlrEvt := u_getEvtFrt(xFilial("ZLD"),MV_PAR01,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_FRETIS,(_cAlias)->ZLD_LJFRET,aStruct[_nX,1],MV_PAR02)

		aStruct[_nX,3] += nVlrEvt // total geral

		If nVlrEvt <> 0

			//Efetua o grupamento dos eventos em suas diversas rotas que o fretista percorreu
			_nPosicao := aScan(_aAux,{|y| y[1] == aStruct[_nX,1]})
		
			If _nPosicao == 0 
				aAdd(_aAux,{aStruct[_nX,1],aStruct[_nX,2],nVlrEvt})
			Else
				_aAux[_nPosicao,3]+= nVlrEvt
			EndIf

		EndIf

		If _nX<=nMaxCol
			@nLin,nPos1 PSAY nVlrEvt Picture "@E 999,999.99"
			nPos1 += nTamCmp
			aSubTots[_nX] += nVlrEvt // subtotal
		Else
			nOutros += nVlrEvt
		EndIf
		If _nX== Len(aStruct) .And. nOutros <> 0
			@nLin,nPos1 PSAY nOutros Picture "@E 999,999.99"
			nPos1 += nTamCmp
			aSubTots[_nX] += nOutros // subtotal
		EndIf

		_nLiq+=nVlrEvt
		nSubLiq += nVlrEvt
	Next _nX

	// MOSTRA VLR LIQUIDO
	@nLin,205 PSAY _nLiq Picture "@E 99,999,999.99"
	_nLiq:=0
	nOutros:=0

 	nLin++

	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

nLin := showSubTotal(nLin)	 
nLin := prtResumo(Cabec1,Cabec2,Titulo,nLin) 	

SET DEVICE TO SCREEN
If aReturn[5]==1
	dbCommitAll()
	SET PRINTER TO
	OurSpool(wnrel)
EndIf
MS_FLUSH()
Return

/*
===============================================================================================================================
Programa----------: showSubTotal
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 20/04/2011
Descrição---------: Imprime subtotal do fretista
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function showSubTotal(nLin)

Local _nX:= 0

If nQtdLin > 1
	@nlin,000 PSAY "Subtotal"+Replicate(".",15)
	@nlin,025 PSAY nSubVol Picture "@E 99,999,999"
	@nlin,038 PSAY nSubKm Picture  "@E 99,999,999"
	@nlin,046 PSAY nSubDia Picture "@E 99,999,999"
	nPos1:=58
	For _nX:=1 to Len(aStruct)
		If _nX<=nMaxCol
			@nLin,nPos1 PSAY aSubTots[_nX] Picture "@E 999,999.99"
			nPos1 += nTamCmp				
		EndIf
		If _nX==Len(aStruct) .And. nOutros <> 0
			@nLin,nPos1 PSAY aSubTots[_nX] Picture "@E 999,999.99"
			nPos1 += nTamCmp
		EndIf			
		aSubTots[_nX]:=0
	Next _nX

	@nLin,205 PSAY nSubLiq Picture "@E 99,999,999.99"
	nLin++
EndIf

For _nX:=1 To Len(aSubTots)
    aSubTots[_nX]:=0
Next

nQtdLin:=0
nSubVol:=0
nSubKm :=0
nSubDia:=0
nSubLiq:=0

Return nLin

/*
===============================================================================================================================
Programa----------: getStruct
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Retorna campos dinamicos que estao na ZLF
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function getStruct(cpSetor,cpMix)

Local _cAlias   := GetNextAlias()
Local _aCampos := {}

BeginSql Alias _cAlias
	SELECT ZLF_EVENTO CODIGO, MAX(ZLF_DEBCRE) DEBCRE
   FROM %Table:ZLF% ZLF
  WHERE ZLF.D_E_L_E_T_ = ' '
    AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
    AND ZLF.ZLF_CODZLE = %Exp:cpMix%
    AND ZLF.ZLF_SETOR = %Exp:cpSetor%
    AND ZLF.ZLF_TP_MIX = 'F'
  GROUP BY ZLF_EVENTO 
  ORDER BY ZLF_EVENTO  
EndSql   

While !(_cAlias)->(Eof())
	aAdd(_aCampos,{(_cAlias)->CODIGO,Posicione("ZL8",1,xFilial("ZL8")+(_cAlias)->CODIGO,"ZL8_NREDUZ"),0})
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

Return _aCampos

/*
===============================================================================================================================
Programa----------: prtResumo
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Imprime resumo
Parametros--------: Cabec1,Cabec2,Titulo,nLin
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function prtResumo(Cabec1,Cabec2,Titulo,nLin)

Local _nX:= 0

@ nLin,000 PSay __PrtThinLine()
nLin++

@nLin,000 PSAY "Resumo Geral"
nLin += 2

@nLin,000 PSAY "Codigo"
@nLin,008 PSAY "Evento"
@nLin,030 PSAY "Creditos"
@nLin,050 PSAY "Debitos"
nLin++

@nLin,000 PSAY Replicate("-",60)
nLin++
For _nX:=1 to Len(_aAux)
	@nLin,000 PSAY _aAux[_nX,1]
	@nLin,008 PSAY _aAux[_nX,2]
	If _aAux[_nX,3] >= 0
		@nLin,020 PSAY _aAux[_nX,3] Picture "@E 999,999,999,999.99"
		nTotCre+=_aAux[_nX,3]
	Else
		@nLin,040 PSAY _aAux[_nX,3] Picture "@E 999,999,999,999.99"
		nTotDeb+=_aAux[_nX,3]
	EndIf
	nLin++
    
	If nLin > nMaxLin
		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
		nLin := 9
	EndIf

Next _nX

@nLin,000 PSAY Replicate("-",60)
nLin++
@nLin,000 PSAY "Total"
@nLin,020 PSAY nTotCre Picture "@E 999,999,999,999.99"
@nLin,040 PSAY nTotDeb Picture "@E 999,999,999,999.99"
nLin++
@nLin,000 PSAY "Valor Liquido"  
If (nTotCre+nTotDeb) >= 0
	@nLin,020 PSAY (nTotCre+nTotDeb) Picture "@E 999,999,999,999.99"
Else
	@nLin,040 PSAY (nTotCre+nTotDeb) Picture "@E 999,999,999,999.99"
EndIf
nLin++

@ nLin,000 PSay __PrtThinLine()

Return nLin
