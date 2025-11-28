/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 12/09/2024 | Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: REST011
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2017
Descrição---------: Relatório de auditoria de CC entre SA e atendimento de SA - Chamado 22875
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST011()

Local oReport
Local lMTR105 := .T.
Local aPerg := "REST011"

Private cAliasQRY := "SCP"
Private aRetCQ	:= {}

Pergunte(aPerg,.F.)

oReport := REST011R(lMTR105,aPerg)
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: REST011R
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2017
Descrição---------: Reportdef do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST011R(lMTR105,aPerg)

Local oReport 
Local oSection 

oReport := TReport():New("REST011","Posicao das Solicitacoes ao Almox.","REST011", {|oReport| REST011P(oReport)},"  Este relatorio lista a posicao das SA's de acordo com os para-"+" "+"metros selecionados.")  //## 
oReport:SetLandScape()

oSection := TRSection():New(oReport,"Solicitações ao armazem",{"SCP"}) //
oSection:SetHeaderPage()

TRCell():New(oSection,"CP_NUM","SCP",/*Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection,"CP_ITEM","SCP","Item") // 
TRCell():New(oSection,"D3_LOCAL","SD3") // "Item"
TRCell():New(oSection,"CP_PRODUTO","SCP")
TRCell():New(oSection,"CP_DESCRI","SCP")
TRCell():New(oSection,"CP_EMISSAO","SCP","Dt SA")
TRCell():New(oSection,"D3_EMISSAO","SD3","Dt Baixa")
TRCell():New(oSection,"CP_QUANT","SCP")
TRCell():New(oSection,"SALDO","SCP"	,"Saldo da SA")
TRCell():New(oSection,"CP_QUJE","SCP","Entregue Bx")
TRCell():New(oSection,"D3_DOC","SD3","Doc Baixa")
TRCell():New(oSection,"CP_CC","SCP","CC SA")
TRCell():New(oSection,"CQ_CC","SCP","CC Pre")
TRCell():New(oSection,"D3_CC","SD3","CC Baixa")
TRCell():New(oSection,"CTT_DESC01","CTT","Desc CC")
TRCell():New(oSection,"CP_OBS","SCP","OBS")
TRCell():New(oSection,"STATUS","SD3","Status","@!",15,,{|| U_REST011S()})
TRCell():New(oSection,"CP_SOLICIT","SCP","Usr SA","@X")
TRCell():New(oSection,"D3_USUARIO","SD3","Usr Baixa","@X")

Return(oReport)

/*
===============================================================================================================================
Programa----------: REST011P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2017
Descrição---------: Reportprint do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST011P(oReport)

Local oSection  := oReport:Section(1)
Local _cFiltro := ""

DBSelectArea("SCP")
SCP->(DBSetOrder(1))
//==========================================================================
// Filtragem do relatório                                                   
//==========================================================================

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	

cAliasQRY := GetNextAlias()

If !Empty(MV_PAR04)
	_cFiltro := "% CP_NUM   >= '"  + AllTrim(MV_PAR03) + "' AND CP_NUM <= '" +  AllTrim(MV_PAR04) + "' " 
EndIf

If !Empty(DToS(MV_PAR02))
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " CP_EMISSAO   >= '"  + DToS(MV_PAR01) + "' AND CP_EMISSAO <= '" +  DToS(MV_PAR02) + "' " 
EndIf 

If !Empty(MV_PAR05)
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " CP_SOLICIT   >= '"  + AllTrim(MV_PAR05) + "' AND CP_SOLICIT <= '" +  AllTrim(MV_PAR06) + "' " 
EndIf 

If !Empty(MV_PAR07)
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " CP_CC   >= '"  + AllTrim(MV_PAR07) + "' AND CP_CC <= '" +  AllTrim(MV_PAR08) + "' " 
EndIf 

If !Empty(MV_PAR09)
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " CP_PRODUTO   >= '"  + AllTrim(MV_PAR09) + "' AND CP_PRODUTO <= '" +  AllTrim(MV_PAR10) + "' " 
EndIf 

If !Empty(MV_PAR11)
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " B1_GRUPO   >= '"  + AllTrim(MV_PAR11) + "' AND B1_GRUPO <= '" +  AllTrim(MV_PAR12) + "' " 
EndIf 

If !Empty(MV_PAR13)
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " D3_LOCAL IN "+ FormatIn(AllTrim(MV_PAR13),";")		 
EndIf 

If MV_PAR14 == 1
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " CP_QUANT > CP_QUJE " 
EndIf 

If MV_PAR14 == 2
	If !Empty(_cFiltro)
		_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + " CP_QUANT = CP_QUJE " 
EndIf 

_cfiltro2 := ""

If  '1' $ MV_PAR15
	If !Empty(_cfiltro2)
		_cfiltro2 := _cfiltro2 + " OR "
	Else
		_cfiltro2 := "( "
	EndIf
	_cfiltro2 := _cfiltro2 + " (D3_CC = CP_CC AND (CP_CC = CQ_CC OR CQ_CC = ' ')) "	 
EndIf 

If  '2' $ MV_PAR15
	If !Empty(_cfiltro2)
		_cfiltro2 := _cfiltro2 + " OR "
	Else
		_cfiltro2 := "( "
	EndIf
	_cfiltro2 := _cfiltro2 + " (D3_CC <> CP_CC AND CP_CC = CQ_CC)  "	 
EndIf 

If  '3' $ MV_PAR15
	If !Empty(_cfiltro2)
		_cfiltro2 := _cfiltro2 + " OR "
	Else
		_cfiltro2 := "( "
	EndIf
	_cfiltro2 := _cfiltro2 + " (D3_CC = CQ_CC AND CP_CC <> CQ_CC) "	 
EndIf 

If  '4' $ MV_PAR15
	If !Empty(_cfiltro2)
		_cfiltro2 := _cfiltro2 + " OR "
	Else
		_cfiltro2 := "( "
	EndIf
	_cfiltro2 := _cfiltro2 + " (D3_CC = CP_CC AND CQ_CC <> CP_CC AND CP_CC <> ' ') "	 
EndIf 

If  '5' $ MV_PAR15
	If !Empty(_cfiltro2)
		_cfiltro2 := _cfiltro2 + " OR "
	Else
		_cfiltro2 := "( "
	EndIf
	_cfiltro2 := _cfiltro2 + " (D3_CC <> CP_CC AND CQ_CC <> CP_CC AND D3_CC <> CQ_CC) "	 
EndIf 

If !Empty(MV_PAR15) .And. !Empty(_cfiltro2)
	If !Empty(_cFiltro)
			_cFiltro := _cFiltro + " AND "
	Else
		_cFiltro := "% "
	EndIf
	_cFiltro := _cFiltro + _cfiltro2 + ")"
EndIf 	

If Empty(_cFiltro)
	_cFiltro := "% CP_FILIAL = '" + xFilial("SCP") + "' %"
Else
	_cFiltro := _cFiltro + " AND  CP_FILIAL = '" + xFilial("SCP") + "' %"
EndIf

BeginSql Alias cAliasQRY

SELECT  CP_FILIAL, CP_NUM, CP_ITEM, CP_PRODUTO, CP_DESCRI, CP_EMISSAO, CP_QUANT, CP_CC, CQ_CC, CP_SOLICIT, CQ_NUMREQ, D3_NUMSEQ, D3_CC,
        D3_LOCAL, D3_EMISSAO, D3_USUARIO, CP_QUANT-CP_QUJE AS SALDO, CP_QUJE, B1_GRUPO, D3_DOC, CP_OBS, CTT_DESC01
FROM %Table:SCP% SCP JOIN %Table:SCQ% SCQ ON CP_FILIAL = CQ_FILIAL AND
                                        CP_NUM = CQ_NUM AND
                                        CP_ITEM = CQ_ITEM
     JOIN %Table:SD3% SD3 ON D3_FILIAL = CP_FILIAL AND
                                        D3_NUMSEQ = CQ_NUMREQ
     JOIN %Table:SB1% SB1 ON B1_COD = CP_PRODUTO
     JOIN %Table:CTT% CTT ON CTT_CUSTO = D3_CC
WHERE %Exp:_cFiltro% AND
	SCP.%NotDel% AND 
	SCQ.%NotDel% AND
	SD3.%NotDel% AND
	SB1.%NotDel%
ORDER BY %Order:SCP%
		
EndSql 
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

// Necessario, devido 'a funcao externa ca100RetCQ(), que utiliza outros campos de SCP
TRPosition():New(oSection,"SCP",1,{|| xFilial("SCP")+(cAliasQRY)->CP_NUM+(cAliasQRY)->CP_ITEM })

//==========================================================================
// Inicio da impressao do fluxo do relatório                                
//==========================================================================

oSection:Print()

Return

/*
===============================================================================================================================
Programa----------: REST0113
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2017
Descrição---------: Corpo do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST0113(lMTR105,aPerg)

//==========================================================================
// Define Variaveis                                                         
//==========================================================================
Local Titulo  := "Posicao das Solicitacoes ao Almox." //  // Titulo do Relatorio
Local cDesc1  := "  Este relatorio lista a posicao das SA's de acordo com os para-" //  // Descricao 1
Local cDesc2  := "metros selecionados." //  // Descricao 2
Local cDesc3  := ""  // Descricao 3
Local cString := "SCP"  // Alias utilizado na Filtragem
Local lDic    := .F. // Habilita/Desabilita Dicionario
Local lComp   := .T. // Habilita/Desabilita o Formato Comprimido/Expandido
Local lFiltro := .T. // Habilita/Desabilita o Filtro
Local wnrel   := "REST011"  // Nome do Arquivo utilizado no Spool
Local nomeprog:= "REST011"  // nome do programa

Private Tamanho := "G" // P/M/G
Private Limite  := 220 // 80/132/220
Private aOrdem  := {}  // Ordem do Relatorio
Private cPerg   := "REST011"  // Pergunta do Relatorio
Private aReturn := { "Zebrado", 1,"Administracao", 1, 2, 1, "",1 } //###
//[1] Reservado para Formulario
//[2] Reservado para N§ de Vias
//[3] Destinatario
//[4] Formato => 1-Comprimido 2-Normal
//[5] Midia   => 1-Disco 2-Impressora
//[6] Porta ou Arquivo 1-LPT1... 4-COM1...
//[7] Expressao do Filtro
//[8] Ordem a ser selecionada
//[9]..[10]..[n] Campos a Processar (se houver)

Private lEnd    := .F.// Controle de cancelamento do relatorio
Private m_pag   := 1  // Contador de Paginas
Private nLastKey:= 0  // Controla o cancelamento da SetPrint e SetDefault

lMTR105 := If(ValType(lMTR105)#"L",.T.,lMTR105)

//==========================================================================
//  Verifica as Perguntas Seleciondas                                       
//  MV_PAR01  -  Da data      ?                                             
//  MV_PAR02  -  Ate a data   ?                                             
//  MV_PAR03  -  Numero de    ?                                             
//  MV_PAR04  -  Numero Ate   ?                                             
//==========================================================================
Pergunte(cPerg,.F.)
If !lMTR105 .And. ValType(aPerg) ==  "A"
	MV_PAR01:= aPerg[1]
	MV_PAR02:= aPerg[1]
	MV_PAR03:= aPerg[2]
	MV_PAR04:= aPerg[2]
	//==========================================================================
	// Envia para a SetPrinter                                                  
	//==========================================================================
	wnrel:=SetPrint(cString,wnrel,"",@titulo,cDesc1,cDesc2,cDesc3,lDic,aOrdem,lComp,Tamanho,lFiltro)	
Else
	//==========================================================================
	// Envia para a SetPrinter                                                  
	//==========================================================================
	wnrel:=SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,lDic,aOrdem,lComp,Tamanho,lFiltro)
EndIf
If ( nLastKey==27 )
	DBSelectArea(cString)
	DBSetOrder(1)
	Set Filter to
	Return
EndIf
SetDefault(aReturn,cString)
If ( nLastKey==27 )
	DBSelectArea(cString)
	DBSetOrder(1)
	Set Filter to
	Return
EndIf
RptStatus({|lEnd| REST011L(@lEnd,wnRel,cString,nomeprog,Titulo)},Titulo)

Return(.T.)

/*
===============================================================================================================================
Programa----------: REST011L
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/12/2017
Descrição---------: Imprime a linha detalhe do Relatorio.  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST011L(lEnd,wnrel,cString,nomeprog,Titulo)

Local li      := 100 // Contador de Linhas
Local lImp    := .F. // Indica se algo foi impresso
Local cbCont  := 0   // Numero de Registros Processados
Local aRetCQ
Local cbText  := ""  // Mensagem do Rodape

Local cCabec1 := "Numero  Item  Codigo             Descricao                        Emissao            Quantidade              Saldo        Qtd.Entregue   Requisicao    Centro de Custo    Solicitante"  
Local cCabec2:=  ""      //    123456   12   123456789012345    123456789012345678901234567890   99/99/9999       999.999.999,99    999.999.999,99     999.999.999,99       123456    123456789012345     1234567890
//                              0         1         2         3         4         5         6         7         8         9        10        11        12        13        14        15        16        17        18        19        20        21        22
//                              01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
                                                                                                                                                                       
DBSelectArea(cString)
SetRegua(LastRec())
DBSetOrder(1)
DBSeek(xFilial()+MV_PAR03,.T.)

While (!Eof() .And. xFilial()==SCP->CP_FILIAL .And. SCP->CP_NUM >= MV_PAR03 .And. SCP->CP_NUM <= MV_PAR04)
	lImp := .T.
	If !(SCP->CP_EMISSAO >= MV_PAR01 .And. SCP->CP_EMISSAO <= MV_PAR02)
		DBSkip()
		Loop
	EndIf
	If lEnd
		@ Prow()+1,001 PSAY "CANCELADO PELO OPERADOR" //
		Exit
	EndIf
	If ( li > 60 )
		li := cabec(Titulo,cCabec1,cCabec2,nomeprog,Tamanho,If(aReturn[4]==1,15,18))
		li++
	EndIf
	aRetCQ := ca100RetCQ(SCP->CP_NUM,SCP->CP_ITEM)
	@ li,000 PSay SCP->CP_NUM
	@ li,009 PSay SCP->CP_ITEM
	@ li,014 PSay SCP->CP_PRODUTO
	@ li,033 PSay Pad(SCP->CP_DESCRI, 30)
	@ li,066 PSay SCP->CP_EMISSAO
	@ li,083 PSay SCP->CP_QUANT	Picture PesqPict("SCP","CP_QUANT")
	@ li,102 PSay aRetCQ[1]		Picture PesqPict("SCP","CP_QUANT")
	@ li,121 PSay aRetCQ[7] 	Picture PesqPict("SCP","CP_QUANT")
	@ li,If(cPaisLoc$"BRA",141,136) PSay aRetCQ[6]
	@ li,151 PSay PadL(AllTrim(SCP->CP_CC),20)
	@ li,176 PSay SCP->CP_SOLICIT
	li++
	DBSelectArea(cString)
	DBSkip()
	cbCont++
	IncRegua()
EndDo

If ( lImp )
	Roda(cbCont,cbText,Tamanho)
EndIf
DBSelectArea(cString)
dbClearFilter()
DBSetOrder(1)
Set Printer To
If ( aReturn[5] = 1 )
	dbCommitAll()
	OurSpool(wnrel)
EndIf
MS_FLUSH()
Return(.T.)

/*
===============================================================================================================================
Programa----------: REST011C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 14/12/2017
Descrição---------: Consulta para a pergunta de tipo de registro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST011C()
Local _nI			:= 0

Private nTam		:= 0
Private nMaxSelect	:= 0
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ""
Private cTitulo		:= ""
Private MvParDef	:= ""

//==========================================
//Grava log de utilização da rotina
//==========================================
U_ITLOGACS()

//================================================================================
// Tratamento para carregar variaveis da lista de opcoes já selecionadas
//================================================================================
nTam		:= 1
nMaxSelect	:= 5
cTitulo		:= "Tipo de registro"

MvParDef := "12345"
aAdd( aCat , "OK" 	)
aAdd( aCat , "Avaliar Baixa" 		)
aAdd( aCat , "Avaliar SA" 		)
aAdd( aCat , "Avaliar Pre" 		)
aAdd( aCat , "Divergente" 		)
	
MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )

//================================================================================
// Executa funcao que monta tela de opcoes
//================================================================================

F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

//================================================================================
// Tratamento para separar retorno com barra ";"
//================================================================================
&MvRet := ""

For _nI := 1 To Len( MvPar ) //Step 1

	If !( SubStr( MvPar , _nI , 1 ) $ " |*" )
		&MvRet += SubStr( MvPar , _nI , 1 ) + ";"
	EndIf
	
Next

//================================================================================
// Trata para tirar o ultimo caracter
//================================================================================
&MvRet := SubStr( &MvRet , 1 , Len( &MvRet ) - 1 )

Return(.T.)                                                                                                                                                 

/*
===============================================================================================================================
Programa----------: REST011S
Autor-------------: Josué Danich Prestes
Data da Criacao---: 14/12/2017
Descrição---------: Análise de status do registro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST011S()

Local _cstatus := ""

Begin Sequence

If (cAliasQRY)->CP_CC == (cAliasQRY)->D3_CC  .And. ( (cAliasQRY)->CQ_CC == (cAliasQRY)->D3_CC .Or. (cAliasQRY)->CQ_CC == ' ')
 	_cstatus := "OK"
 	Break
EndIf

If (cAliasQRY)->CP_CC <> (cAliasQRY)->D3_CC  .And.  (cAliasQRY)->CQ_CC == (cAliasQRY)->CP_CC 
 	_cstatus := "Av. Baixa"
 	Break
EndIf

If (cAliasQRY)->CP_CC <> (cAliasQRY)->D3_CC  .And.  (cAliasQRY)->CQ_CC == (cAliasQRY)->D3_CC 
 	_cstatus := "Av. SA"
 	Break
EndIf

If (cAliasQRY)->CP_CC == (cAliasQRY)->D3_CC  .And. ( (cAliasQRY)->CQ_CC <> (cAliasQRY)->CP_CC .Or. (cAliasQRY)->CQ_CC <> ' ')
 	_cstatus := "Av. Pre"
 	Break
EndIf

If (cAliasQRY)->CP_CC <> (cAliasQRY)->D3_CC  .And.  (cAliasQRY)->CQ_CC <> (cAliasQRY)->CP_CC 
 	_cstatus := "Divergente"
 	Break
EndIf

End Sequence

Return _cStatus
