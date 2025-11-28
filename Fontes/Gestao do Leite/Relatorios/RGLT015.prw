/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/04/2022| Chamado 39723. Corrigida query para soma dos grupos
Lucas Borges  |04/06/2024| Chamado 47460. Ajustado pra permitir imprimir mais de um setor
Lucas Borges  |11/02/2025| Chamado 49877. Removido tratamento sobre a versão do Mix
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT015
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Relatório da folha a pagar aos produtores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT015

Local cDesc1			:= "Este programa tem como objetivo imprimir relatorio "
Local cDesc2			:= "de acordo com os parametros informados pelo usuario."
Local cDesc3			:= "Folha a Pagar do Produtor   "
Local titulo			:= "Folha a Pagar do Produtor   "
Local nLin				:= 80
Local Cabec1			:= " "
Local Cabec2			:= ""
Local aOrd				:= {}
Private Tamanho			:= "G"
Private NomeProg		:= "RGLT015" // Coloque aqui o nome do programa para impressao no cabecalho
Private nTipo			:= 18
Private aReturn			:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private nLastKey		:= 0
Private m_pag			:= 01
Private wnrel			:= "RGLT015" // Coloque aqui o nome do arquivo usado para impressao em disco
Private cPerg			:= "RGLT015"
Private cString			:= "ZLF"

Pergunte("RGLT015",.F.)

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
Local _cAlias2	:= ""
Local _nX		:= 0
Local _cFiltro	:= "%"
Local _cFiltro2	:= "%"
Local _cFilZLF	:= "%"
Local nTotDeb	:= 0
Local nTotCre	:= 0
Local nLiq		:= 0
Local nMaxLin	:= 60 // maximo de linhas
Local cUltLin	:= ""
Local nqtdregs	:= 0
Local nPreco	:= 0
Local nVolume	:= 0
Local nTotVolGer:= 0
Local nVlrPrd	:= 0
Local aVlrPrd	:= {}

Private nIniPos	:= 50
Private nMaxCol	:= 11 // maximo de colunas
Private nTamCmp	:= 11
Private nOutros	:= 0
Private dt1		:= Nil
Private dt2		:= Nil
Private nSubVolume:= 0
Private aSubTotal:= {}
Private aLin	:= {}
Private aStruct	:= {}
	
// posiciona no Mix pra pegar datas
DBSelectArea("ZLE")
ZLE->(DBSetOrder(1))
ZLE->(DBSeek(xFilial("ZLE")+MV_PAR02))
dt1:=ZLE->ZLE_DTINI
dt2:=ZLE->ZLE_DTFIM
ZLE->(DBCloseArea())

nLin := nMaxLin
Cabec1 := "Mix: "+MV_PAR02

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFilZLF += " AND ZLF.ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf
_cFilZLF += "%"

// Obtem campos dinamicos (eventos)
If MV_PAR14 == 1
	DBSelectArea("ZL7")
	ZL7->( DBSetOrder(1) )
	ZL7->( DBGoTop() )
	While ZL7->( !Eof() )
		aAdd( aStruct , { ZL7->ZL7_COD , LEFT( ZL7->ZL7_NREDUZ , 8 ) , 0 , 0 } )
	ZL7->( DBSkip() )
	EndDo
Else
	BeginSql alias _cAlias
		SELECT ZL8.ZL8_COD, ZL8.ZL8_NREDUZ
		  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
		 WHERE ZLF.D_E_L_E_T_ = ' '
		   AND ZL8.D_E_L_E_T_ = ' '
		   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
		   AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
		   AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
		   %exp:_cFilZLF%
		   AND ZLF.ZLF_CODZLE = %exp:MV_PAR02%
		   AND ZLF.ZLF_TP_MIX = 'L'
		 GROUP BY ZL8.ZL8_COD, ZL8.ZL8_NREDUZ
		 ORDER BY ZL8.ZL8_COD
	EndSql
	While !(_cAlias)->(Eof())
		aAdd(aStruct,{(_cAlias)->ZL8_COD,(_cAlias)->ZL8_NREDUZ,0})
		(_cAlias)->(DBSkip())
	EndDo
	(_cAlias)->(DBCloseArea())
EndIf


//====================================================================================================
// Monta cabecalho com os campos dinamicos (eventos)
//====================================================================================================
Cabec2 := PadR( "CODIGO LOJA PRODUTOR" , 29 )
Cabec2 += Space(3) +"VOLUME"
Cabec2 += Space(5) +"PRECO"

For _nX := 1 To Len(aStruct)
	If _nX <= nMaxCol
		Cabec2 += PadL( aStruct[_nX][2] , nTamCmp )
	EndIf
	If _nX == Len(aStruct) .And. _nX > nMaxCol
		Cabec2 += PadL( "OUTROS" , nTamCmp )
	EndIf
	aAdd( aSubTotal , 0 ) // subtotal das linhas
Next _nX

Cabec2 += PadL( "VLR LIQUIDO" , 12 )

//====================================================================================================
// Filtra somente os usuarios de um determinado tanque.
//====================================================================================================
If !Empty(MV_PAR18) .And. !Empty(MV_PAR19)
	_cFiltro += " AND SA2.A2_L_TANQ  = '"+ MV_PAR18 +"' "
	_cFiltro += " AND SA2.A2_L_TANLJ = '"+ MV_PAR19 +"' "
EndIf

If MV_PAR20 == 1//Sob Produção
	_cFiltro += " AND SA2.A2_INDCP  = '1' "
ElseIf MV_PAR20 == 2 //Sob Folha de Pagamento
	_cFiltro += " AND SA2.A2_INDCP  = '2' "
EndIf
If MV_PAR21 == 1 //Pessoa Física
	_cFiltro += " AND SA2.A2_TIPO  = 'F' "
ElseIf MV_PAR21 == 2 //Pessoa Jurídica
	_cFiltro += " AND SA2.A2_TIPO  = 'J' "
EndIf

_cFiltro2 := _cFiltro
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLD.ZLD_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
	_cFiltro2 += " AND ZLF.ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

_cFiltro += " %"
_cFiltro2 += " %"
_cAlias := GetNextAlias()
// obtem Produtores que movimentaram

BeginSql alias _cAlias
	SELECT ZLD.ZLD_SETOR, ZLD.ZLD_LINROT, ZLD.ZLD_RETIRO, ZLD.ZLD_RETILJ, ZL3.ZL3_DESCRI, SA2.A2_NOME NOMEPROD, ZL3.ZL3_FRETIS, ZL3.ZL3_FRETLJ, SA2F.A2_NOME NOMEFRET
	  FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:SA2% SA2F
	 WHERE ZLD.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZL3.D_E_L_E_T_ = ' '
	   AND SA2F.D_E_L_E_T_ (+) = ' '
	   AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
   	   AND SA2F.A2_FILIAL (+) = %xFilial:SA2%
	   AND ZLD.ZLD_RETIRO = SA2.A2_COD
	   AND ZLD.ZLD_RETILJ = SA2.A2_LOJA
	   AND ZL3.ZL3_FRETIS = SA2F.A2_COD (+)
	   AND ZL3.ZL3_FRETLJ = SA2F.A2_LOJA (+)
	   AND ZLD.ZLD_LINROT = ZL3.ZL3_COD
	   %exp:_cFiltro%
	   AND ZLD.ZLD_DTCOLE BETWEEN %exp:dt1% AND %exp:dt2%
	   AND ZLD.ZLD_FRETIS BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
	   AND ZLD.ZLD_LJFRET BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
	   AND ZLD.ZLD_LINROT BETWEEN %exp:MV_PAR12% AND %exp:MV_PAR13%
	   AND ZLD.ZLD_RETIRO BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
	   AND ZLD.ZLD_RETILJ BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
	   AND ZLD.ZLD_RETIRO <> ' '
	 GROUP BY ZLD.ZLD_RETIRO, ZLD.ZLD_RETILJ, ZLD.ZLD_SETOR, ZLD.ZLD_LINROT, ZL3.ZL3_DESCRI, SA2.A2_NOME, ZL3.ZL3_FRETIS, ZL3.ZL3_FRETLJ, SA2F.A2_NOME
	UNION
	SELECT ZLF.ZLF_SETOR ZLD_SETOR, ZLF.ZLF_LINROT ZLD_LINROT, ZLF.ZLF_A2COD ZLD_RETIRO, ZLF.ZLF_A2LOJA ZLD_RETILJ, ZL3.ZL3_DESCRI, 
			SA2.A2_NOME NOMEPROD, ZL3.ZL3_FRETIS, ZL3.ZL3_FRETLJ, SA2F.A2_NOME NOMEFRET
	  FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:SA2% SA2F
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZL3.D_E_L_E_T_ = ' '
	   AND SA2F.D_E_L_E_T_ (+) = ' '
	   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
   	   AND SA2F.A2_FILIAL (+) = %xFilial:SA2% 
	   AND ZLF.ZLF_A2COD = SA2.A2_COD
	   AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
	   AND ZL3.ZL3_FRETIS = SA2F.A2_COD (+)
	   AND ZL3.ZL3_FRETLJ = SA2F.A2_LOJA (+)
	   AND ZLF.ZLF_LINROT = ZL3.ZL3_COD
	   %exp:_cFiltro2%
	   AND ZLF.ZLF_DTINI BETWEEN %exp:dt1% AND %exp:dt2%
	   AND ZLF.ZLF_LINROT BETWEEN %exp:MV_PAR12% AND %exp:MV_PAR13%
	   AND ZLF.ZLF_A2COD BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
	   AND ZLF.ZLF_A2LOJA BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
	   AND SubStr(ZLF.ZLF_A2COD,1,1) = 'P'
	   GROUP BY ZLF.ZLF_SETOR, ZLF.ZLF_LINROT, ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZL3.ZL3_DESCRI, SA2.A2_NOME, ZL3.ZL3_FRETIS, ZL3.ZL3_FRETLJ, SA2F.A2_NOME
	 ORDER BY 1,2,3,4
EndSql

Count To nqtdregs
SetRegua(nqtdregs)
(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())

	IncRegua()
	
    If nLin >= nMaxLin
   		Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
   		nLin := 9
	EndIf

	//Mostra Cabeçalho(Linha e Fretista)
	If cUltLin != (_cAlias)->ZLD_LINROT

		// Mostra subtotal da linha
		If cUltLin != ""
			nLin := showSubTotal(nLin)
			nSubVolume:=0
		EndIf

		@nLin,000 PSay "Setor: "+(_cAlias)->ZLD_SETOR+"  Linha: "+(_cAlias)->ZLD_LINROT+"-"+(_cAlias)->ZL3_DESCRI+"    Fretista: "+(_cAlias)->NOMEFRET
		nLin++

	EndIf
	cUltLin := (_cAlias)->ZLD_LINROT

	// Obtem valores dos eventos do produtor corrente
	// e ja calcula valor liquido
	// Utiliza o array aLin para armazenar os valores de cada evento
	// para nao precisar buscar esses valores novamente
	aLin := {}

	For _nX := 1 To Len( aStruct )

		If MV_PAR14 == 1

			aVlrPrd := getTotGp( xFilial("ZLD") , aStruct[_nX,1] , (_cAlias)->ZLD_SETOR , (_cAlias)->ZLD_LINROT , (_cAlias)->ZLD_RETIRO , (_cAlias)->ZLD_RETILJ , MV_PAR02 , MV_PAR03 , "L" , .T. )

			// Armazena total geral
			aStruct[_nX,3] += aVlrPrd[01]
			aStruct[_nX,4] += aVlrPrd[02]

			// Armazena subtotal
			aSubTotal[_nX] += ( aVlrPrd[01] + aVlrPrd[02] )

			aAdd( aLin , ( aVlrPrd[01] + aVlrPrd[02] ) )
			nLiq += ( aVlrPrd[01] + aVlrPrd[02] )

		Else
			_cAlias2 := GetNextAlias()
			BeginSql alias _cAlias2
				SELECT NVL(SUM(Case WHEN ZL8.ZL8_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END),0) TOTAL
				FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
				WHERE ZLF.D_E_L_E_T_ = ' '
				AND ZL8.D_E_L_E_T_ = ' '
				AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
				AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
				AND ZLF.ZLF_CODZLE = %exp:MV_PAR02%
				AND ZLF.ZLF_EVENTO = %exp:aStruct[_nX,1]%
				AND ZL8.ZL8_COD = ZLF.ZLF_EVENTO
				%exp:_cFilZLF%
				AND ZLF.ZLF_LINROT = %exp:(_cAlias)->ZLD_LINROT%
				AND ZLF.ZLF_RETIRO = %exp:(_cAlias)->ZLD_RETIRO%
				AND ZLF.ZLF_RETILJ = %exp:(_cAlias)->ZLD_RETILJ%
				AND ZLF.ZLF_TP_MIX = 'L'
			EndSql

			nVlrPrd := (_cAlias2)->TOTAL
			(_cAlias2)->( DBCloseArea() )

			// Armazena total geral
			aStruct[_nX,3] += nVlrPrd

			// Armazena subtotal
			aSubTotal[_nX] += nVlrPrd

			aAdd(aLin,nVlrPrd)
			nLiq += nVlrPrd

		EndIf

	Next _nX

	// Verifica parametro: se mostra apenas os valores liquido negativos
	// ou todos.
	If ((nLiq < 0 .And. MV_PAR15 == 1) .Or. MV_PAR15 <> 1)

		// MOSTRA PRODUTOR E SEUS RESPECTIVOS VALORES
		@nLin,000 PSay (_cAlias)->ZLD_RETIRO + "-" +(_cAlias)->ZLD_RETILJ + " "+Left((_cAlias)->NOMEPROD,15)

		// Obtem volume do produtor
		nVolume := U_VolLeite(xFilial("ZLD"),dt1,dt2,(_cAlias)->ZLD_SETOR,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_RETIRO,(_cAlias)->ZLD_RETILJ,"")

		// armazena volume para o subtotal
		nSubVolume += nVolume 
		// armazena volume para o total geral   
		nTotVolGer += nVolume
		@nLin,030 PSay nVolume Picture "@E 9,999,999"

		// Mostra o preco do leite
		nPreco := u_getTotCr(xFilial("ZLD"),(_cAlias)->ZLD_SETOR,(_cAlias)->ZLD_LINROT,(_cAlias)->ZLD_RETIRO,(_cAlias)->ZLD_RETILJ,MV_PAR02,MV_PAR03)
		nPreco := nPreco/nVolume
		@nLin,040 PSay nPreco Picture "@E 9999.9999"

		nPos1:=nIniPos
		For _nX:=1 To Len(aStruct)
			nVlrPrd := aLin[_nX]
			If _nX <= nMaxCol
				@nLin,nPos1 PSay nVlrPrd Picture "@E 9,999,999.99"
				//nPos1 += nTamCmp 
				nPos1 += nTamCmp 
			Else
				nOutros += nVlrPrd
			EndIf
			If _nX == Len(aStruct)
				@nLin,nPos1 PSay nOutros Picture "@E 9,999,999.99"
				nPos1 += nTamCmp 
			EndIf
		Next _nX
	    
		//Mostra Valor Líquido
		@nLin,nPos1 PSay nLiq Picture "@E 99,999,999.99"
	 	nLin++

	    nOutros:=0
	EndIf

	nLiq:=0
	nOutros:=0

	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

nLin := showSubTotal(nLin)

//---------------------------------------------------
// Mostra Resumo (se nao For apenas negativos)
//---------------------------------------------------
If MV_PAR15 <> 1
	Cabec1 := "Setor: "+ MV_PAR01 +" Mix: "+MV_PAR02
	Cabec(Titulo,Cabec1,Cabec2,NomeProg,Tamanho,nTipo)
	nLin := 9

	@nLin,000 PSay "Resumo Geral"
	nLin += 2

	@nLin,000 PSay "Codigo"
	@nLin,008 PSay "Evento"
	@nLin,030 PSay "Creditos"
	@nLin,050 PSay "Debitos"
	nLin++

	@nLin,000 PSay Replicate("-",60)
	nLin++

	For _nX := 1 To Len(aStruct)
		@nLin,000 PSay aStruct[_nX,1]
		@nLin,008 PSay aStruct[_nX,2]

		If MV_PAR14 == 1
			@nLin,020 PSay aStruct[_nX,3] Picture "@E 999,999,999,999.99"
			nTotCre += aStruct[_nX,3]

			@nLin,040 PSay aStruct[_nX,4] Picture "@E 999,999,999,999.99"
			nTotDeb += aStruct[_nX,4]
		Else
			If aStruct[_nX,3] >= 0
				@nLin,020 PSay aStruct[_nX,3] Picture "@E 999,999,999,999.99"
				nTotCre+=aStruct[_nX,3]
			Else
				@nLin,040 PSay aStruct[_nX,3] Picture "@E 999,999,999,999.99"
				nTotDeb+=aStruct[_nX,3]
			EndIf
		EndIf

		nLin++
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
		
	nLin++
	
EndIf

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
Programa--------: showSubTotal
Autor-----------: Abrahao P. Santos
Data da Criacao-: 09/12/2008
Descrição---------: Imprime subtotal do fretista
Parametros--------: nLin
Retorno-----------: nLin
===============================================================================================================================
*/
Static Function showSubTotal(nLin)

Local _nX		:= 0
Local nSubLiq	:= 0

@nLin,000 PSay "SubTotal -------->"
@nLin,030 PSay nSubVolume Picture "@E 9,999,999"

nOutros	:= 0
nPos1	:= nIniPos

For _nX := 1 To Len( aStruct )
	nVlrPrd			:= aSubTotal[_nX]
	aSubTotal[_nX]	:= 0
	nSubLiq			+= nVlrPrd
	If _nX <= nMaxCol
		@nLin,nPos1 PSay nVlrPrd Picture "@E 999,999.99"
		nPos1 += nTamCmp
	Else
		nOutros += nVlrPrd
	EndIf
	If _nX == Len(aStruct)
		@nLin,nPos1 PSay nOutros Picture "@E 999,999.99"
		nPos1 += nTamCmp
	EndIf

Next _nX

For _nX:=1 To Len(aSubTotal)
	aSubTotal[_nX]:= 0
Next _nX

@nLin,nPos1 PSay nSubLiq Picture "@E 99,999,999.99"
nLin++

@ nLin,000 PSay __PrtThinLine()
nLin++

nOutros := 0

Return nLin

/*
===============================================================================================================================
Programa----------: getTotGp
Autor-------------: Renato/Abrahao
Data da Criacao---: 08/10/2008
Descrição---------: Retorna total de movimentos na ZLF de determinado evento
Parametros--------: _cFilial,_cGrupo,_cSetor,_cLinha,_cFornece,_cLoja,_cCodMix,_cEntMix,_cTpMix,_lRetArr
Retorno-----------: xRet - retorno conforme o parametro _lRetArr
===============================================================================================================================
*/
Static Function getTotGp(_cFilial,_cGrupo,_cSetor,_cLinha,_cFornece,_cLoja,_cCodMix,_cEntMix,_cTpMix,_lRetArr)

Local _aArea	:= FWGetArea()
Local _cAliasZLF:= GetNextAlias()
Local _cFiltro	:= ''
Local _xRet		:= NIL

Default _lRetArr := .F.

//Verifica o tipo de retorno esperado
If _lRetArr
	_xRet := { 0 , 0 }
Else
	_xRet := 0
EndIf

//Obtendo grupos de eventos
_cFiltro:= "%"
If !Empty(_cFilial)
	_cFiltro += " AND	ZL8_FILIAL = '"+ _cFilial +"' "
EndIf
If !Empty(_cEntMix)
	_cFiltro += " AND	ZL8_MIX = '"+ _cEntMix +"' "
EndIf
_cFiltro+= "%"

//Obtendo movimentos na ZLF do grupo corrente
BeginSql alias _cAliasZLF
	SELECT SUM( Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else 0 END ) CREDITO,
			SUM( Case WHEN ZLF_DEBCRE = 'D' THEN ZLF_TOTAL Else 0 END ) DEBITO
	FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
	WHERE ZLF.D_E_L_E_T_ = ' '
	AND ZL8.D_E_L_E_T_ = ' '
	AND ZLF_FILIAL = ZL8_FILIAL
	AND ZLF_EVENTO = ZL8_COD
	%Exp:_cFiltro%
	AND ZLF_CODZLE	= %exp:_cCodMix%
	AND ZLF_FILIAL = %exp:_cFilial%
	AND ZLF_SETOR	= %exp:_cSetor%
	AND ZLF_LINROT = %exp:_cLinha%
	AND ZLF_RETIRO = %exp:_cFornece%
	AND ZLF_RETILJ = %exp:_cLoja%
	AND ZLF_TP_MIX = %exp:_cTpMix%
	AND ZL8_GRUPO = %Exp:_cGrupo%
	GROUP BY ZL8_COD
EndSql

While (_cAliasZLF)->( !Eof() )
	// Verifica o tipo de retorno esperado
	If _lRetArr
		_xRet[01] += (_cAliasZLF)->CREDITO
		_xRet[02] -= (_cAliasZLF)->DEBITO
	Else
		_xRet += (_cAliasZLF)->CREDITO
		_xRet -= (_cAliasZLF)->DEBITO
	EndIf
	(_cAliasZLF)->( DBSkip() )
EndDo
(_cAliasZLF)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_xRet)
